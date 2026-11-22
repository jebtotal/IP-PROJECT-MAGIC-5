-- Align the customer/Sprint 1 screens with guide 3.8 and account lifecycle rules.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_relations TEXT;
    missing_columns TEXT;
BEGIN
    SELECT string_agg(required.relation_name, ', ' ORDER BY required.relation_name)
      INTO missing_relations
      FROM (VALUES
          ('profiles'),
          ('right_catalog'),
          ('user_permission'),
          ('audit_log')
      ) AS required(relation_name)
     WHERE to_regclass('public.' || required.relation_name) IS NULL;

    IF missing_relations IS NOT NULL THEN
        RAISE EXCEPTION
            'S2-BLD-01 stopped: apply the existing profile, rights, and audit migrations first; missing: %.',
            missing_relations;
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('profiles', 'id'),
            ('profiles', 'email'),
            ('profiles', 'full_name'),
            ('profiles', 'status'),
            ('profiles', 'role'),
            ('profiles', 'blocked'),
            ('profiles', 'created_at'),
            ('profiles', 'updated_at'),
            ('profiles', 'empno'),
            ('right_catalog', 'right_code'),
            ('right_catalog', 'module_code'),
            ('right_catalog', 'resource_code'),
            ('right_catalog', 'action'),
            ('user_permission', 'user_id'),
            ('user_permission', 'right_code'),
            ('user_permission', 'is_deleted'),
            ('user_permission', 'stamp'),
            ('audit_log', 'actor_id'),
            ('audit_log', 'event_type'),
            ('audit_log', 'old_values'),
            ('audit_log', 'new_values')
    )
    SELECT string_agg(
               required.table_name || '.' || required.column_name,
               ', ' ORDER BY required.table_name, required.column_name
           )
      INTO missing_columns
      FROM required_columns AS required
      LEFT JOIN information_schema.columns AS actual
        ON actual.table_schema = 'public'
       AND actual.table_name = required.table_name
       AND actual.column_name = required.column_name
     WHERE actual.column_name IS NULL;

    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'S2-BLD-01 stopped: required existing columns are missing: %.',
            missing_columns;
    END IF;
END;
$$;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS stamp VARCHAR(60);

INSERT INTO public.right_catalog (right_code, module_code, resource_code, action)
VALUES
    ('hr.jobHistory.add', 'hr', 'job_history', 'add'),
    ('hr.jobHistory.edit', 'hr', 'job_history', 'edit'),
    ('hr.jobHistory.delete', 'hr', 'job_history', 'delete'),
    ('reports.topProducts.view', 'reports', 'top_products', 'view'),
    ('reports.activeEmployees.view', 'reports', 'active_employees', 'view'),
    ('reports.allEmployees.view', 'reports', 'all_employees', 'view'),
    ('reports.employeeJobHistory.view', 'reports', 'employee_job_history', 'view'),
    ('reports.topSales.view', 'reports', 'top_sales', 'view')
ON CONFLICT (right_code) DO NOTHING;

DO $$
DECLARE
    mismatched_rights TEXT;
BEGIN
    SELECT string_agg(expected.right_code, ', ' ORDER BY expected.right_code)
      INTO mismatched_rights
      FROM (
          VALUES
              ('hr.jobHistory.add', 'hr', 'job_history', 'add'),
              ('hr.jobHistory.edit', 'hr', 'job_history', 'edit'),
              ('hr.jobHistory.delete', 'hr', 'job_history', 'delete'),
              ('reports.topProducts.view', 'reports', 'top_products', 'view'),
              ('reports.activeEmployees.view', 'reports', 'active_employees', 'view'),
              ('reports.allEmployees.view', 'reports', 'all_employees', 'view'),
              ('reports.employeeJobHistory.view', 'reports', 'employee_job_history', 'view'),
              ('reports.topSales.view', 'reports', 'top_sales', 'view')
      ) AS expected(right_code, module_code, resource_code, action)
      LEFT JOIN public.right_catalog AS actual
        ON actual.right_code = expected.right_code
       AND actual.module_code = expected.module_code
       AND actual.resource_code = expected.resource_code
       AND actual.action = expected.action
     WHERE actual.right_code IS NULL;

    IF mismatched_rights IS NOT NULL THEN
        RAISE EXCEPTION
            'S2-BLD-01 stopped: rights catalogue conflicts with: %.',
            mismatched_rights;
    END IF;
END;
$$;

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
        v_action := 'CREATED';
    ELSIF (to_jsonb(OLD) - 'stamp') = (to_jsonb(NEW) - 'stamp') THEN
        NEW.stamp := OLD.stamp;
        RETURN NEW;
    ELSIF OLD.is_deleted IS DISTINCT FROM NEW.is_deleted THEN
        v_action := CASE WHEN NEW.is_deleted THEN 'DELETED' ELSE 'RESTORED' END;
    ELSE
        v_action := 'EDITED';
    END IF;

    NEW.stamp := left(
        v_action || ' ' || v_actor || ' ' ||
        to_char(now() AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM'),
        60
    );
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_user_permission_stamp_s1_dba_03()
RETURNS TRIGGER
LANGUAGE plpgsql
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
        IF NEW.stamp IS NOT NULL THEN
            RETURN NEW;
        END IF;
        v_action := 'CREATED';
    ELSIF NEW.stamp IS DISTINCT FROM OLD.stamp THEN
        RETURN NEW;
    ELSIF (to_jsonb(OLD) - 'stamp') = (to_jsonb(NEW) - 'stamp') THEN
        RETURN NEW;
    ELSIF OLD.is_deleted IS DISTINCT FROM NEW.is_deleted THEN
        v_action := CASE WHEN NEW.is_deleted THEN 'DELETED' ELSE 'RESTORED' END;
    ELSE
        v_action := 'EDITED';
    END IF;

    NEW.stamp := left(
        v_action || ' ' || v_actor || ' ' ||
        to_char(now() AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM'),
        60
    );
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_set_profile_stamp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_action TEXT;
    v_actor TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.is_deleted := FALSE;
        IF NEW.stamp IS NOT NULL THEN
            RETURN NEW;
        END IF;
        v_action := 'CREATED';
        v_actor := left(
            COALESCE(auth.jwt() ->> 'email', auth.uid()::TEXT, NEW.email, 'system'),
            24
        );
    ELSE
        IF NEW.stamp IS DISTINCT FROM OLD.stamp THEN
            RETURN NEW;
        END IF;
        IF (to_jsonb(OLD) - 'stamp') = (to_jsonb(NEW) - 'stamp') THEN
            RETURN NEW;
        END IF;
        v_action := CASE
            WHEN OLD.is_deleted IS DISTINCT FROM NEW.is_deleted
             AND NEW.is_deleted THEN 'DELETED'
            WHEN OLD.is_deleted IS DISTINCT FROM NEW.is_deleted THEN 'RESTORED'
            ELSE 'EDITED'
        END;
        v_actor := left(
            COALESCE(auth.jwt() ->> 'email', auth.uid()::TEXT, 'system'),
            24
        );
    END IF;

    NEW.stamp := left(
        v_action || ' ' || v_actor || ' ' ||
        to_char(now() AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM'),
        60
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_set_stamp_s2_bld_01 ON public.profiles;
CREATE TRIGGER profiles_set_stamp_s2_bld_01
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.hope_set_profile_stamp();

CREATE OR REPLACE FUNCTION public.hope_prevent_last_superadmin_disable()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
    was_superadmin BOOLEAN;
    remains_superadmin BOOLEAN;
    was_active_superadmin BOOLEAN;
    remains_active_superadmin BOOLEAN;
    remaining_count BIGINT;
BEGIN
    was_superadmin := OLD.role::TEXT = 'superadmin' AND NOT OLD.is_deleted;
    remains_superadmin := NEW.role::TEXT = 'superadmin' AND NOT NEW.is_deleted;
    was_active_superadmin :=
        was_superadmin
        AND NOT OLD.blocked
        AND OLD.status::TEXT = 'approved';
    remains_active_superadmin :=
        remains_superadmin
        AND NOT NEW.blocked
        AND NEW.status::TEXT = 'approved';

    IF was_superadmin AND NOT remains_superadmin THEN
        PERFORM pg_advisory_xact_lock(73420511);
        SELECT count(*)
          INTO remaining_count
          FROM public.profiles AS p
         WHERE p.id <> OLD.id
           AND p.role::TEXT = 'superadmin'
           AND NOT p.is_deleted;

        IF remaining_count = 0 THEN
            RAISE EXCEPTION 'The last Superadmin cannot be removed or demoted.'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    IF was_active_superadmin AND NOT remains_active_superadmin THEN
        PERFORM pg_advisory_xact_lock(73420511);
        SELECT count(*)
          INTO remaining_count
          FROM public.profiles AS p
         WHERE p.id <> OLD.id
           AND p.role::TEXT = 'superadmin'
           AND NOT p.is_deleted
           AND NOT p.blocked
           AND p.status::TEXT = 'approved';

        IF remaining_count = 0 THEN
            RAISE EXCEPTION 'The last active Superadmin cannot be blocked or removed.'
                USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_prevent_last_superadmin_s2_bld_01 ON public.profiles;
CREATE TRIGGER profiles_prevent_last_superadmin_s2_bld_01
    BEFORE UPDATE OF role, status, blocked, is_deleted ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.hope_prevent_last_superadmin_disable();

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
    v_normalized_resource TEXT;
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
       OR v_profile ->> 'blocked' = 'true'
       OR v_profile ->> 'is_deleted' = 'true' THEN
        RETURN FALSE;
    END IF;

    IF v_role IN ('admin', 'superadmin') THEN
        RETURN TRUE;
    END IF;

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
            v_normalized_resource := CASE
                WHEN p_module = 'products'
                 AND p_resource = 'price_history'
                 AND p_action = 'view'
                THEN 'products'
                ELSE p_resource
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
            USING v_user_id, p_module, v_normalized_resource, v_normalized_action;

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

    IF v_module_name IS NULL
       OR p_action NOT IN ('view', 'create', 'edit', 'delete')
       OR (p_resource = 'price_history' AND p_action <> 'view') THEN
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

CREATE OR REPLACE FUNCTION public.hope_customer_has_active_sales(p_custno TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
BEGIN
    IF NOT public.hope_can_access('customers', 'customers', 'delete') THEN
        RAISE EXCEPTION 'Customer delete permission required.'
            USING ERRCODE = '42501';
    END IF;

    RETURN EXISTS (
        SELECT 1
          FROM public.sales_active
         WHERE custno = p_custno
    );
END;
$$;

REVOKE ALL ON FUNCTION public.hope_customer_has_active_sales(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hope_customer_has_active_sales(TEXT) TO authenticated;

DO $$
BEGIN
    IF to_regclass('public.profiles_active') IS NOT NULL
       AND (
           SELECT c.relkind <> 'v'
             FROM pg_class AS c
            WHERE c.oid = to_regclass('public.profiles_active')
       ) THEN
        RAISE EXCEPTION
            'S2-BLD-01 stopped: public.profiles_active exists but is not a view.';
    END IF;
END;
$$;

CREATE OR REPLACE VIEW public.profiles_active WITH (security_invoker = true) AS
SELECT id, email, full_name, status, role, blocked, created_at, updated_at, empno, is_deleted, stamp
  FROM public.profiles
 WHERE NOT is_deleted;

GRANT SELECT ON public.profiles_active TO authenticated;

COMMIT;
