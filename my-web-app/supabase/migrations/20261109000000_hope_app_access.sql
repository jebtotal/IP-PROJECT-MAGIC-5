-- Add app record support without changing the existing application audit_log.
-- RLS follows the app's active-profile and per-module permissions checks.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    IF to_regclass('public.audit_log') IS NULL
       OR to_regclass('public.profiles') IS NULL
       OR to_regclass('public.user_permissions') IS NULL THEN
        RAISE EXCEPTION
            'HOPE app access migration stopped: public.audit_log, public.profiles, and public.user_permissions are required.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('audit_log', 'actor_id'),
            ('audit_log', 'event_type'),
            ('audit_log', 'old_values'),
            ('audit_log', 'new_values'),
            ('profiles', 'id'),
            ('profiles', 'role'),
            ('profiles', 'status'),
            ('user_permissions', 'user_id'),
            ('user_permissions', 'permissions')
    )
    SELECT string_agg(r.table_name || '.' || r.column_name, ', ' ORDER BY r.table_name, r.column_name)
      INTO missing_columns
      FROM required_columns AS r
      LEFT JOIN information_schema.columns AS c
        ON c.table_schema = 'public'
       AND c.table_name = r.table_name
       AND c.column_name = r.column_name
     WHERE c.column_name IS NULL;

    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'HOPE app access migration stopped: missing required application columns: %',
            missing_columns;
    END IF;
END;
$$;

-- A user must not be able to grant themselves an administrator profile.
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own pending profile" ON public.profiles;
CREATE POLICY "Users can insert their own pending profile"
    ON public.profiles FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = id
        AND COALESCE(role::TEXT, 'user') = 'user'
        AND COALESCE(status::TEXT, 'pending') = 'pending'
    );
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
REVOKE UPDATE ON public.profiles FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.hope_can_access(
    p_module TEXT,
    p_resource TEXT,
    p_action TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile JSONB;
    v_role TEXT;
    v_module_name TEXT;
    v_normalized_action TEXT;
    v_has_normalized_assignments BOOLEAN := FALSE;
    v_allowed BOOLEAN := FALSE;
    v_legacy_allowed TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    SELECT to_jsonb(p), p.role::TEXT
      INTO v_profile, v_role
      FROM public.profiles AS p
     WHERE p.id = v_user_id;

    IF v_profile IS NULL
       OR COALESCE(v_profile ->> 'status', '') IN ('blocked', 'rejected', 'pending')
       OR v_profile ->> 'blocked' = 'true' THEN
        RETURN FALSE;
    END IF;

    IF v_role IN ('admin', 'superadmin') THEN
        RETURN TRUE;
    END IF;

    -- Match the app: if any normalized assignments exist, they replace the
    -- legacy JSON permission document for authorization.
    IF to_regclass('public.user_permission') IS NOT NULL
       AND to_regclass('public.right_catalog') IS NOT NULL THEN
        EXECUTE $query$
            SELECT EXISTS (
                SELECT 1
                  FROM public.user_permission AS up
                 WHERE up.user_id = $1
                   AND NOT up.is_deleted
            )
        $query$
        INTO v_has_normalized_assignments
        USING v_user_id;

        IF v_has_normalized_assignments THEN
            v_normalized_action := CASE p_action
                WHEN 'create' THEN 'add'
                ELSE p_action
            END;

            EXECUTE $query$
                SELECT EXISTS (
                    SELECT 1
                      FROM public.user_permission AS up
                      JOIN public.right_catalog AS rc
                        ON rc.right_code = up.right_code
                     WHERE up.user_id = $1
                       AND NOT up.is_deleted
                       AND rc.module_code = $2
                       AND rc.resource_code = $3
                       AND rc.action = $4
                )
            $query$
            INTO v_allowed
            USING v_user_id, p_module, p_resource, v_normalized_action;

            RETURN v_allowed;
        END IF;
    END IF;

    v_module_name := CASE p_module
        WHEN 'customers' THEN 'Customer'
        WHEN 'products' THEN 'Product'
        WHEN 'hr' THEN 'Human Resources'
        WHEN 'sales' THEN 'Sales'
        WHEN 'reports' THEN 'Reports'
        ELSE NULL
    END;

    IF v_module_name IS NULL OR p_action NOT IN ('view', 'create', 'edit', 'delete') THEN
        RETURN FALSE;
    END IF;

    SELECT up.permissions -> v_module_name ->> p_action
      INTO v_legacy_allowed
      FROM public.user_permissions AS up
     WHERE up.user_id = v_user_id;

    RETURN v_legacy_allowed = 'true';
END;
$$;

REVOKE ALL ON FUNCTION public.hope_can_access(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hope_can_access(TEXT, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.hope_set_record_stamp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_action TEXT;
    v_actor TEXT;
BEGIN
    v_actor := left(
        COALESCE(auth.jwt() ->> 'email', auth.uid()::TEXT, 'system'),
        24
    );

    IF TG_OP = 'INSERT' THEN
        NEW.is_deleted := FALSE;
        v_action := 'ADD';
    ELSIF (to_jsonb(OLD) - 'stamp') = (to_jsonb(NEW) - 'stamp') THEN
        NEW.stamp := OLD.stamp;
        RETURN NEW;
    ELSIF OLD.is_deleted IS DISTINCT FROM NEW.is_deleted THEN
        v_action := CASE WHEN NEW.is_deleted THEN 'DELETE' ELSE 'RESTORE' END;
    ELSE
        v_action := 'EDIT';
    END IF;

    NEW.stamp := left(
        v_action || ' ' || v_actor || ' ' ||
        to_char(now() AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM'),
        60
    );
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_protect_record_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_module TEXT := TG_ARGV[0];
    v_resource TEXT := TG_ARGV[1];
    v_role TEXT;
BEGIN
    IF (to_jsonb(OLD) - 'stamp' - 'is_deleted')
       IS DISTINCT FROM
       (to_jsonb(NEW) - 'stamp' - 'is_deleted')
       AND NOT public.hope_can_access(v_module, v_resource, 'edit') THEN
        RAISE EXCEPTION 'Edit permission required for % records.', TG_TABLE_NAME
            USING ERRCODE = '42501';
    END IF;

    IF OLD.is_deleted IS DISTINCT FROM NEW.is_deleted THEN
        IF NOT public.hope_can_access(v_module, v_resource, 'delete') THEN
            RAISE EXCEPTION 'Delete permission required for % records.', TG_TABLE_NAME
                USING ERRCODE = '42501';
        END IF;

        IF OLD.is_deleted AND NOT NEW.is_deleted THEN
            SELECT p.role::TEXT INTO v_role
              FROM public.profiles AS p
             WHERE p.id = auth.uid();

            IF v_role NOT IN ('admin', 'superadmin') THEN
                RAISE EXCEPTION 'Only administrators can restore inactive records.'
                    USING ERRCODE = '42501';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_audit_record_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_action TEXT;
    v_old JSONB;
    v_new JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_action := 'ADD';
        v_new := to_jsonb(NEW);
    ELSE
        IF (to_jsonb(OLD) - 'stamp') = (to_jsonb(NEW) - 'stamp') THEN
            RETURN NEW;
        END IF;

        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
        v_action := CASE
            WHEN NOT OLD.is_deleted AND NEW.is_deleted THEN 'DELETE'
            WHEN OLD.is_deleted AND NOT NEW.is_deleted THEN 'RESTORE'
            ELSE 'EDIT'
        END;
    END IF;

    INSERT INTO public.audit_log (actor_id, event_type, old_values, new_values)
    VALUES (
        auth.uid(),
        'hope.' || TG_TABLE_NAME || '.' || v_action,
        v_old,
        v_new
    );
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.hope_set_record_stamp() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.hope_protect_record_update() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.hope_audit_record_change() FROM PUBLIC;

DO $$
DECLARE
    r RECORD;
    table_name TEXT;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('employee', 'hr', 'employees'),
            ('department', 'hr', 'departments'),
            ('job', 'hr', 'jobs'),
            ('jobhistory', 'hr', 'job_history'),
            ('customer', 'customers', 'customers'),
            ('sales', 'sales', 'sales'),
            ('salesdetail', 'sales', 'sale_details'),
            ('payment', 'sales', 'sales'),
            ('product', 'products', 'products'),
            ('pricehist', 'products', 'price_history')
        ) AS t(table_name, module_code, resource_code)
    LOOP
        table_name := r.table_name;

        EXECUTE format(
            'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE',
            table_name
        );
        EXECUTE format(
            'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS stamp VARCHAR(60)',
            table_name
        );
        EXECUTE format(
            'UPDATE public.%I SET stamp = %L WHERE stamp IS NULL',
            table_name,
            'ADD system ' || to_char(now() AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM')
        );

        EXECUTE format(
            'CREATE OR REPLACE VIEW public.%I WITH (security_invoker = true) AS SELECT * FROM public.%I WHERE NOT is_deleted',
            table_name || '_active',
            table_name
        );

        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
        EXECUTE format(
            'REVOKE DELETE, TRUNCATE ON public.%I FROM PUBLIC, anon, authenticated',
            table_name
        );
        EXECUTE format(
            'GRANT SELECT, INSERT, UPDATE ON public.%I TO authenticated',
            table_name
        );
        EXECUTE format(
            'GRANT SELECT ON public.%I TO authenticated',
            table_name || '_active'
        );

        EXECUTE format(
            'DROP POLICY IF EXISTS hope_select_by_permission ON public.%I',
            table_name
        );
        EXECUTE format(
            'CREATE POLICY hope_select_by_permission ON public.%I FOR SELECT TO authenticated USING (public.hope_can_access(%L, %L, %L))',
            table_name,
            r.module_code,
            r.resource_code,
            'view'
        );

        EXECUTE format(
            'DROP POLICY IF EXISTS hope_insert_by_permission ON public.%I',
            table_name
        );
        EXECUTE format(
            'CREATE POLICY hope_insert_by_permission ON public.%I FOR INSERT TO authenticated WITH CHECK (public.hope_can_access(%L, %L, %L))',
            table_name,
            r.module_code,
            r.resource_code,
            'create'
        );

        EXECUTE format(
            'DROP POLICY IF EXISTS hope_update_by_permission ON public.%I',
            table_name
        );
        EXECUTE format(
            'CREATE POLICY hope_update_by_permission ON public.%I FOR UPDATE TO authenticated USING (public.hope_can_access(%L, %L, %L) OR public.hope_can_access(%L, %L, %L)) WITH CHECK (public.hope_can_access(%L, %L, %L) OR public.hope_can_access(%L, %L, %L))',
            table_name,
            r.module_code,
            r.resource_code,
            'edit',
            r.module_code,
            r.resource_code,
            'delete',
            r.module_code,
            r.resource_code,
            'edit',
            r.module_code,
            r.resource_code,
            'delete'
        );

        EXECUTE format(
            'DROP TRIGGER IF EXISTS hope_00_protect_update ON public.%I',
            table_name
        );
        EXECUTE format(
            'CREATE TRIGGER hope_00_protect_update BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.hope_protect_record_update(%L, %L)',
            table_name,
            r.module_code,
            r.resource_code
        );
        EXECUTE format(
            'DROP TRIGGER IF EXISTS hope_10_set_stamp ON public.%I',
            table_name
        );
        EXECUTE format(
            'CREATE TRIGGER hope_10_set_stamp BEFORE INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.hope_set_record_stamp()',
            table_name
        );
        EXECUTE format(
            'DROP TRIGGER IF EXISTS hope_20_audit_change ON public.%I',
            table_name
        );
        EXECUTE format(
            'CREATE TRIGGER hope_20_audit_change AFTER INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.hope_audit_record_change()',
            table_name
        );
    END LOOP;
END;
$$;

COMMIT;
