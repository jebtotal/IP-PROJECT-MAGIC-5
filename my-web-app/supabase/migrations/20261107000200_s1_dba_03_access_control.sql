-- S1-DBA-03: normalized roles and rights linked to the existing Supabase profiles.
-- The app's JSON user_permissions table and Supabase Auth credentials are untouched.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    unknown_roles TEXT;
    has_role_id BOOLEAN;
    has_blocked BOOLEAN;
    has_status BOOLEAN;
BEGIN
    IF to_regclass('public.profiles') IS NULL THEN
        RAISE EXCEPTION
            'S1-DBA-03 stopped: public.profiles is missing; inspect the login schema before applying.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'profiles'
           AND column_name = 'id'
           AND data_type = 'uuid'
    ) OR NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'profiles'
           AND column_name = 'role'
           AND data_type IN ('text', 'character varying')
    ) OR NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'profiles'
           AND column_name = 'email'
           AND data_type IN ('text', 'character varying')
    ) THEN
        RAISE EXCEPTION
            'S1-DBA-03 stopped: public.profiles must retain UUID id, text email, and text role columns.';
    END IF;

    SELECT string_agg(DISTINCT role::TEXT, ', ' ORDER BY role::TEXT)
      INTO unknown_roles
      FROM public.profiles
     WHERE role IS NOT NULL
       AND role::TEXT NOT IN ('user', 'admin', 'superadmin');

    IF unknown_roles IS NOT NULL THEN
        RAISE EXCEPTION
            'S1-DBA-03 stopped: public.profiles contains role value(s) not in the agreed role catalogue: %.',
            unknown_roles;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role_id'
    ) INTO has_role_id;
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'blocked'
    ) INTO has_blocked;
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'status'
    ) INTO has_status;

    IF has_role_id AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'profiles'
           AND column_name = 'role_id' AND data_type IN ('text', 'character varying')
    ) THEN
        RAISE EXCEPTION 'S1-DBA-03 stopped: public.profiles.role_id exists with an incompatible type.';
    END IF;

    IF has_blocked AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'profiles'
           AND column_name = 'blocked' AND data_type = 'boolean'
    ) THEN
        RAISE EXCEPTION 'S1-DBA-03 stopped: public.profiles.blocked exists with an incompatible type.';
    END IF;

    ALTER TABLE public.profiles
        ADD COLUMN IF NOT EXISTS role_id TEXT,
        ADD COLUMN IF NOT EXISTS blocked BOOLEAN NOT NULL DEFAULT FALSE;

    UPDATE public.profiles
       SET role_id = role::TEXT
     WHERE role_id IS NULL
       AND role IS NOT NULL;

    IF NOT has_blocked AND has_status THEN
        UPDATE public.profiles
           SET blocked = status::TEXT IN ('blocked', 'rejected')
         WHERE status IS NOT NULL;
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.role (
    role_code TEXT PRIMARY KEY,
    role_name TEXT NOT NULL UNIQUE
);

INSERT INTO public.role (role_code, role_name)
VALUES
    ('user', 'User'),
    ('admin', 'Admin'),
    ('superadmin', 'Superadmin')
ON CONFLICT (role_code) DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conrelid = 'public.profiles'::REGCLASS
           AND conname = 'profiles_role_id_fkey'
           AND contype = 'f'
           AND confrelid = 'public.role'::REGCLASS
    ) THEN
        IF EXISTS (
            SELECT 1
              FROM pg_constraint
             WHERE conrelid = 'public.profiles'::REGCLASS
               AND conname = 'profiles_role_id_fkey'
        ) THEN
            RAISE EXCEPTION 'S1-DBA-03 stopped: profiles_role_id_fkey exists with a different definition.';
        END IF;

        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_role_id_fkey
            FOREIGN KEY (role_id) REFERENCES public.role (role_code) NOT VALID;
    END IF;

    ALTER TABLE public.profiles
        VALIDATE CONSTRAINT profiles_role_id_fkey;
END;
$$;

DO $$
BEGIN
    IF to_regprocedure('public.sync_profiles_role_reference_s1_dba_03()') IS NULL THEN
        EXECUTE $function$
            CREATE FUNCTION public.sync_profiles_role_reference_s1_dba_03()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            SET search_path = public, pg_temp
            AS $body$
            BEGIN
                IF TG_OP = 'INSERT' OR NEW.role IS DISTINCT FROM OLD.role THEN
                    NEW.role_id := NEW.role;
                ELSIF NEW.role_id IS DISTINCT FROM OLD.role_id THEN
                    NEW.role := NEW.role_id;
                END IF;
                RETURN NEW;
            END;
            $body$;
        $function$;
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_trigger AS t
          JOIN pg_class AS c ON c.oid = t.tgrelid
          JOIN pg_namespace AS n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public'
           AND c.relname = 'profiles'
           AND t.tgname = 'profiles_role_reference_biu'
           AND NOT t.tgisinternal
    ) THEN
        CREATE TRIGGER profiles_role_reference_biu
            BEFORE INSERT OR UPDATE ON public.profiles
            FOR EACH ROW
            EXECUTE FUNCTION public.sync_profiles_role_reference_s1_dba_03();
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.module (
    module_code TEXT PRIMARY KEY,
    module_name TEXT NOT NULL UNIQUE
);

INSERT INTO public.module (module_code, module_name)
VALUES
    ('customers', 'Customer'),
    ('products', 'Product'),
    ('hr', 'Human Resources'),
    ('sales', 'Sales'),
    ('reports', 'Reports')
ON CONFLICT (module_code) DO NOTHING;

DO $$
DECLARE
    mismatched_roles TEXT;
    mismatched_modules TEXT;
BEGIN
    SELECT string_agg(expected.role_code, ', ' ORDER BY expected.role_code)
      INTO mismatched_roles
      FROM (VALUES
          ('user', 'User'),
          ('admin', 'Admin'),
          ('superadmin', 'Superadmin')
      ) AS expected(role_code, role_name)
      LEFT JOIN public.role AS actual
        ON actual.role_code = expected.role_code
       AND actual.role_name = expected.role_name
     WHERE actual.role_code IS NULL;

    IF mismatched_roles IS NOT NULL THEN
        RAISE EXCEPTION 'S1-DBA-03 stopped: existing role catalogue conflicts with: %.', mismatched_roles;
    END IF;

    SELECT string_agg(expected.module_code, ', ' ORDER BY expected.module_code)
      INTO mismatched_modules
      FROM (VALUES
          ('customers', 'Customer'),
          ('products', 'Product'),
          ('hr', 'Human Resources'),
          ('sales', 'Sales'),
          ('reports', 'Reports')
      ) AS expected(module_code, module_name)
      LEFT JOIN public.module AS actual
        ON actual.module_code = expected.module_code
       AND actual.module_name = expected.module_name
     WHERE actual.module_code IS NULL;

    IF mismatched_modules IS NOT NULL THEN
        RAISE EXCEPTION 'S1-DBA-03 stopped: existing module catalogue conflicts with: %.', mismatched_modules;
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.right_catalog (
    right_code TEXT PRIMARY KEY,
    module_code TEXT NOT NULL REFERENCES public.module (module_code),
    resource_code TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('view', 'add', 'edit', 'delete')),
    CONSTRAINT right_catalog_module_resource_action_key
        UNIQUE (module_code, resource_code, action)
);

INSERT INTO public.right_catalog (right_code, module_code, resource_code, action)
VALUES
    ('customers.view', 'customers', 'customers', 'view'),
    ('customers.add', 'customers', 'customers', 'add'),
    ('customers.edit', 'customers', 'customers', 'edit'),
    ('customers.delete', 'customers', 'customers', 'delete'),
    ('products.view', 'products', 'products', 'view'),
    ('products.add', 'products', 'products', 'add'),
    ('products.edit', 'products', 'products', 'edit'),
    ('products.delete', 'products', 'products', 'delete'),
    ('hr.view', 'hr', 'hr', 'view'),
    ('hr.jobAdd', 'hr', 'jobs', 'add'),
    ('hr.jobEdit', 'hr', 'jobs', 'edit'),
    ('hr.jobDelete', 'hr', 'jobs', 'delete'),
    ('hr.deptAdd', 'hr', 'departments', 'add'),
    ('hr.deptEdit', 'hr', 'departments', 'edit'),
    ('hr.deptDelete', 'hr', 'departments', 'delete'),
    ('hr.empAdd', 'hr', 'employees', 'add'),
    ('hr.empEdit', 'hr', 'employees', 'edit'),
    ('hr.empDelete', 'hr', 'employees', 'delete'),
    ('sales.view', 'sales', 'sales', 'view'),
    ('sales.add', 'sales', 'sales', 'add'),
    ('sales.edit', 'sales', 'sales', 'edit'),
    ('sales.delete', 'sales', 'sales', 'delete'),
    ('reports.view', 'reports', 'reports', 'view'),
    ('sales.details.view', 'sales', 'sale_details', 'view'),
    ('sales.details.add', 'sales', 'sale_details', 'add'),
    ('sales.details.edit', 'sales', 'sale_details', 'edit'),
    ('sales.details.delete', 'sales', 'sale_details', 'delete'),
    ('hr.jobHistory.view', 'hr', 'job_history', 'view'),
    ('reports.topCustomers.view', 'reports', 'top_customers', 'view'),
    ('reports.productsMaster.view', 'reports', 'products_master', 'view')
ON CONFLICT (right_code) DO NOTHING;

DO $$
DECLARE
    mismatched_rights TEXT;
BEGIN
    SELECT string_agg(expected.right_code, ', ' ORDER BY expected.right_code)
      INTO mismatched_rights
      FROM (
          VALUES
              ('customers.view', 'customers', 'customers', 'view'),
              ('customers.add', 'customers', 'customers', 'add'),
              ('customers.edit', 'customers', 'customers', 'edit'),
              ('customers.delete', 'customers', 'customers', 'delete'),
              ('products.view', 'products', 'products', 'view'),
              ('products.add', 'products', 'products', 'add'),
              ('products.edit', 'products', 'products', 'edit'),
              ('products.delete', 'products', 'products', 'delete'),
              ('hr.view', 'hr', 'hr', 'view'),
              ('hr.jobAdd', 'hr', 'jobs', 'add'),
              ('hr.jobEdit', 'hr', 'jobs', 'edit'),
              ('hr.jobDelete', 'hr', 'jobs', 'delete'),
              ('hr.deptAdd', 'hr', 'departments', 'add'),
              ('hr.deptEdit', 'hr', 'departments', 'edit'),
              ('hr.deptDelete', 'hr', 'departments', 'delete'),
              ('hr.empAdd', 'hr', 'employees', 'add'),
              ('hr.empEdit', 'hr', 'employees', 'edit'),
              ('hr.empDelete', 'hr', 'employees', 'delete'),
              ('sales.view', 'sales', 'sales', 'view'),
              ('sales.add', 'sales', 'sales', 'add'),
              ('sales.edit', 'sales', 'sales', 'edit'),
              ('sales.delete', 'sales', 'sales', 'delete'),
              ('reports.view', 'reports', 'reports', 'view'),
              ('sales.details.view', 'sales', 'sale_details', 'view'),
              ('sales.details.add', 'sales', 'sale_details', 'add'),
              ('sales.details.edit', 'sales', 'sale_details', 'edit'),
              ('sales.details.delete', 'sales', 'sale_details', 'delete'),
              ('hr.jobHistory.view', 'hr', 'job_history', 'view'),
              ('reports.topCustomers.view', 'reports', 'top_customers', 'view'),
              ('reports.productsMaster.view', 'reports', 'products_master', 'view')
      ) AS expected(right_code, module_code, resource_code, action)
      LEFT JOIN public.right_catalog AS actual
        ON actual.right_code = expected.right_code
       AND actual.module_code = expected.module_code
       AND actual.resource_code = expected.resource_code
       AND actual.action = expected.action
     WHERE actual.right_code IS NULL;

    IF mismatched_rights IS NOT NULL THEN
        RAISE EXCEPTION 'S1-DBA-03 stopped: existing rights catalogue conflicts with: %.', mismatched_rights;
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.user_permission (
    user_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    right_code TEXT NOT NULL REFERENCES public.right_catalog (right_code),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    stamp VARCHAR(60),
    CONSTRAINT user_permission_pkey PRIMARY KEY (user_id, right_code)
);

CREATE OR REPLACE FUNCTION public.trg_user_permission_delete_guard_s1_dba_03()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Preserve Auth-driven FK cascades while rejecting direct permission deletes.
    IF pg_trigger_depth() > 1 THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION
        'Hard delete not allowed on %. Use UPDATE ... SET is_deleted = true.',
        TG_TABLE_NAME;
END;
$$;

CREATE INDEX IF NOT EXISTS profiles_role_id_idx
    ON public.profiles (role_id);
CREATE UNIQUE INDEX IF NOT EXISTS profiles_email_unique_idx
    ON public.profiles (LOWER(email));
CREATE INDEX IF NOT EXISTS right_catalog_module_code_idx
    ON public.right_catalog (module_code);
CREATE INDEX IF NOT EXISTS user_permission_right_code_idx
    ON public.user_permission (right_code);

ALTER TABLE public.role ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.right_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permission ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.role, public.module, public.right_catalog TO authenticated;
GRANT SELECT ON public.user_permission TO authenticated;
GRANT ALL ON public.role, public.module, public.right_catalog, public.user_permission TO service_role;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
         WHERE schemaname = 'public' AND tablename = 'role'
           AND policyname = 'Authenticated users can read roles'
    ) THEN
        CREATE POLICY "Authenticated users can read roles"
            ON public.role FOR SELECT TO authenticated USING (TRUE);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
         WHERE schemaname = 'public' AND tablename = 'module'
           AND policyname = 'Authenticated users can read modules'
    ) THEN
        CREATE POLICY "Authenticated users can read modules"
            ON public.module FOR SELECT TO authenticated USING (TRUE);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
         WHERE schemaname = 'public' AND tablename = 'right_catalog'
           AND policyname = 'Authenticated users can read rights'
    ) THEN
        CREATE POLICY "Authenticated users can read rights"
            ON public.right_catalog FOR SELECT TO authenticated USING (TRUE);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
         WHERE schemaname = 'public' AND tablename = 'user_permission'
           AND policyname = 'Users can read their own normalized permissions'
    ) THEN
        CREATE POLICY "Users can read their own normalized permissions"
            ON public.user_permission FOR SELECT TO authenticated
            USING ((SELECT auth.uid()) = user_id);
    END IF;
END;
$$;

DO $$
DECLARE
    trigger_name TEXT;
    trigger_sql TEXT;
BEGIN
    FOR trigger_name, trigger_sql IN
        SELECT * FROM (VALUES
            ('user_permission_biu_stamp',
             'CREATE TRIGGER %I BEFORE INSERT OR UPDATE ON public.user_permission FOR EACH ROW EXECUTE FUNCTION public.trg_set_stamp()'),
            ('user_permission_bd_block',
             'CREATE TRIGGER %I BEFORE DELETE ON public.user_permission FOR EACH ROW EXECUTE FUNCTION public.trg_user_permission_delete_guard_s1_dba_03()'),
            ('user_permission_bt_block',
             'CREATE TRIGGER %I BEFORE TRUNCATE ON public.user_permission FOR EACH STATEMENT EXECUTE FUNCTION public.trg_block_hard_delete()')
        ) AS trigger_def(name, command)
    LOOP
        IF NOT EXISTS (
            SELECT 1
              FROM pg_trigger AS t
              JOIN pg_class AS c ON c.oid = t.tgrelid
              JOIN pg_namespace AS n ON n.oid = c.relnamespace
             WHERE n.nspname = 'public'
               AND c.relname = 'user_permission'
               AND t.tgname = trigger_name
               AND NOT t.tgisinternal
        ) THEN
            EXECUTE format(trigger_sql, trigger_name);
        END IF;
    END LOOP;
END;
$$;

COMMIT;
