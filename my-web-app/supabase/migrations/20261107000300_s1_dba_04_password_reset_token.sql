-- S1-DBA-04: hashed, expiring, one-time password action tokens.
-- public.profiles is the app's user table; there is no public.app_user table.
BEGIN;
SET LOCAL search_path = public, pg_temp;

CREATE TABLE IF NOT EXISTS public.password_reset_token (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL
        REFERENCES public.profiles (id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE
        CONSTRAINT password_reset_token_hash_format_check
        CHECK (token_hash ~ '^[0-9a-f]{64}$'),
    purpose TEXT NOT NULL
        CONSTRAINT password_reset_token_purpose_check
        CHECK (purpose IN ('reset', 'set_password')),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS password_reset_token_user_id_idx
    ON public.password_reset_token (user_id);

ALTER TABLE public.password_reset_token ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.password_reset_token FROM PUBLIC, anon, authenticated;
GRANT ALL ON TABLE public.password_reset_token TO service_role;

COMMIT;
