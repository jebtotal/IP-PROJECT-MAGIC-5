-- S1-DBA-06: attribute audit rows to the authenticated Supabase user.
BEGIN;
SET LOCAL search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION public.audit_user()
RETURNS TEXT
LANGUAGE sql
STABLE
SET search_path = pg_catalog, public, auth
AS $$
    SELECT COALESCE(
        auth.uid()::TEXT,
        NULLIF(current_setting('app.username', true), ''),
        'system'
    );
$$;

COMMIT;
