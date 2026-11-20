-- Add separate price-history mutation rights while inheriting Product View.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
BEGIN
    IF to_regclass('public.right_catalog') IS NULL
       OR to_regclass('public.user_permission') IS NULL
       OR to_regprocedure('public.hope_can_access(text, text, text)') IS NULL THEN
        RAISE EXCEPTION
            'S1-DBA-07 stopped: apply the access-control and HOPE app-access migrations first.';
    END IF;
END;
$$;

INSERT INTO public.right_catalog (right_code, module_code, resource_code, action)
VALUES
    ('products.priceHistory.add', 'products', 'price_history', 'add'),
    ('products.priceHistory.edit', 'products', 'price_history', 'edit'),
    ('products.priceHistory.delete', 'products', 'price_history', 'delete')
ON CONFLICT (right_code) DO NOTHING;

DO $$
DECLARE
    mismatched_rights TEXT;
BEGIN
    SELECT string_agg(expected.right_code, ', ' ORDER BY expected.right_code)
      INTO mismatched_rights
      FROM (
          VALUES
              ('products.priceHistory.add', 'products', 'price_history', 'add'),
              ('products.priceHistory.edit', 'products', 'price_history', 'edit'),
              ('products.priceHistory.delete', 'products', 'price_history', 'delete')
      ) AS expected(right_code, module_code, resource_code, action)
      LEFT JOIN public.right_catalog AS actual
        ON actual.right_code = expected.right_code
       AND actual.module_code = expected.module_code
       AND actual.resource_code = expected.resource_code
       AND actual.action = expected.action
     WHERE actual.right_code IS NULL;

    IF mismatched_rights IS NOT NULL THEN
        RAISE EXCEPTION
            'S1-DBA-07 stopped: existing right catalogue conflicts with: %.',
            mismatched_rights;
    END IF;
END;
$$;

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
       OR v_profile ->> 'blocked' = 'true' THEN
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

COMMIT;
