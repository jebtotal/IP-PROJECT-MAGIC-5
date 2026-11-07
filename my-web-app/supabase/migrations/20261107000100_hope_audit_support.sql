-- Source audit/soft-delete support from HopeDB_audit.sql.
-- audit_user() is intentionally unchanged from the source for S1-DBA-06.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $guard_audit_user$
BEGIN
    IF to_regprocedure('public.audit_user()') IS NULL THEN
        EXECUTE $ddl_audit_user$
CREATE OR REPLACE FUNCTION audit_user() RETURNS TEXT
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(NULLIF(current_setting('app.username', true), ''),
                    session_user::text);
$$;
$ddl_audit_user$;
    END IF;
END;
$guard_audit_user$;

-- Builds the stamp text, e.g.  EDIT user1 2026-10-12 11:18 AM
-- (time shown in Asia/Manila; change the zone here if needed)
DO $guard_audit_stamp$
BEGIN
    IF to_regprocedure('public.audit_stamp(text)') IS NULL THEN
        EXECUTE $ddl_audit_stamp$
CREATE OR REPLACE FUNCTION audit_stamp(p_action TEXT) RETURNS TEXT
LANGUAGE sql STABLE AS $$
    SELECT p_action || ' ' || audit_user() || ' ' ||
           to_char(now() AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM');
$$;
$ddl_audit_stamp$;
    END IF;
END;
$guard_audit_stamp$;

-- 3. Trigger functions --------------------------------------------------

-- 3a. Sets the stamp column on every INSERT / UPDATE
DO $guard_trg_set_stamp$
BEGIN
    IF to_regprocedure('public.trg_set_stamp()') IS NULL THEN
        EXECUTE $ddl_trg_set_stamp$
CREATE OR REPLACE FUNCTION trg_set_stamp() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.stamp := audit_stamp('ADD');
    ELSIF (to_jsonb(OLD) - 'stamp') = (to_jsonb(NEW) - 'stamp') THEN
        NEW.stamp := OLD.stamp;                      -- nothing changed
    ELSIF NOT OLD.is_deleted AND NEW.is_deleted THEN
        NEW.stamp := audit_stamp('DELETE');
    ELSIF OLD.is_deleted AND NOT NEW.is_deleted THEN
        NEW.stamp := audit_stamp('RESTORE');
    ELSE
        NEW.stamp := audit_stamp('EDIT');
    END IF;
    RETURN NEW;
END;
$$;
$ddl_trg_set_stamp$;
    END IF;
END;
$guard_trg_set_stamp$;

-- 3b. Writes the history row to audit_log (key columns passed as arguments)
DO $guard_trg_audit_log$
BEGIN
    IF to_regprocedure('public.trg_audit_log()') IS NULL THEN
        EXECUTE $ddl_trg_audit_log$
CREATE OR REPLACE FUNCTION trg_audit_log() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_action TEXT;
    v_key    TEXT;
BEGIN
    SELECT string_agg(to_jsonb(NEW) ->> k, '|' ORDER BY ord)
      INTO v_key
      FROM unnest(TG_ARGV) WITH ORDINALITY AS t(k, ord);

    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, action, record_key, old_values, new_values, action_by)
        VALUES (TG_TABLE_NAME, 'ADD', v_key, NULL, to_jsonb(NEW), audit_user());
    ELSE
        IF (to_jsonb(OLD) - 'stamp') = (to_jsonb(NEW) - 'stamp') THEN
            RETURN NULL;                             -- nothing changed, no log
        END IF;
        v_action := CASE
                      WHEN NOT OLD.is_deleted AND NEW.is_deleted THEN 'DELETE'
                      WHEN OLD.is_deleted AND NOT NEW.is_deleted THEN 'RESTORE'
                      ELSE 'EDIT'
                    END;
        INSERT INTO audit_log (table_name, action, record_key, old_values, new_values, action_by)
        VALUES (TG_TABLE_NAME, v_action, v_key, to_jsonb(OLD), to_jsonb(NEW), audit_user());
    END IF;
    RETURN NULL;
END;
$$;
$ddl_trg_audit_log$;
    END IF;
END;
$guard_trg_audit_log$;

-- 3c. Blocks hard DELETE / TRUNCATE (soft delete only)
DO $guard_trg_block_hard_delete$
BEGIN
    IF to_regprocedure('public.trg_block_hard_delete()') IS NULL THEN
        EXECUTE $ddl_trg_block_hard_delete$
CREATE OR REPLACE FUNCTION trg_block_hard_delete() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Hard delete/truncate not allowed on %. Use UPDATE ... SET is_deleted = true.', TG_TABLE_NAME;
END;
$$;
$ddl_trg_block_hard_delete$;
    END IF;
END;
$guard_trg_block_hard_delete$;

-- 3d. Blocks any change to audit_log itself (history is append-only)
DO $guard_trg_protect_audit_log$
BEGIN
    IF to_regprocedure('public.trg_protect_audit_log()') IS NULL THEN
        EXECUTE $ddl_trg_protect_audit_log$
CREATE OR REPLACE FUNCTION trg_protect_audit_log() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'audit_log is append-only.';
END;
$$;
$ddl_trg_protect_audit_log$;
    END IF;
END;
$guard_trg_protect_audit_log$;

-- 3e. A parent row cannot be soft-deleted while it still has active children
DO $guard_trg_check_children$
BEGIN
    IF to_regprocedure('public.trg_check_children()') IS NULL THEN
        EXECUTE $ddl_trg_check_children$
CREATE OR REPLACE FUNCTION trg_check_children() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_n INT := 0;
BEGIN
    IF NOT (NEW.is_deleted AND NOT OLD.is_deleted) THEN
        RETURN NEW;                                  -- not a soft delete
    END IF;

    CASE TG_TABLE_NAME
        WHEN 'employee' THEN
            SELECT count(*) INTO v_n FROM (
                SELECT 1 FROM jobhistory WHERE empno = OLD.empno AND NOT is_deleted
                UNION ALL
                SELECT 1 FROM sales      WHERE empno = OLD.empno AND NOT is_deleted) c;
        WHEN 'department' THEN
            SELECT count(*) INTO v_n FROM jobhistory
             WHERE deptcode = OLD.deptcode AND NOT is_deleted;
        WHEN 'job' THEN
            SELECT count(*) INTO v_n FROM jobhistory
             WHERE jobcode = OLD.jobcode AND NOT is_deleted;
        WHEN 'customer' THEN
            SELECT count(*) INTO v_n FROM sales
             WHERE custno = OLD.custno AND NOT is_deleted;
        WHEN 'sales' THEN
            SELECT count(*) INTO v_n FROM (
                SELECT 1 FROM salesdetail WHERE transno = OLD.transno AND NOT is_deleted
                UNION ALL
                SELECT 1 FROM payment     WHERE transno = OLD.transno AND NOT is_deleted) c;
        WHEN 'product' THEN
            SELECT count(*) INTO v_n FROM (
                SELECT 1 FROM salesdetail WHERE prodcode = OLD.prodcode AND NOT is_deleted
                UNION ALL
                SELECT 1 FROM pricehist   WHERE prodcode = OLD.prodcode AND NOT is_deleted) c;
        ELSE
            NULL;                                    -- child tables: nothing to check
    END CASE;

    IF v_n > 0 THEN
        RAISE EXCEPTION 'Cannot delete % row: % active related record(s) still exist.', TG_TABLE_NAME, v_n;
    END IF;
    RETURN NEW;
END;
$$;
$ddl_trg_check_children$;
    END IF;
END;
$guard_trg_check_children$;

DO $$
DECLARE
    r RECORD;
    v_args TEXT;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('employee',    'empno'),
            ('department',  'deptcode'),
            ('job',         'jobcode'),
            ('jobhistory',  'empno,jobcode,effdate'),
            ('customer',    'custno'),
            ('sales',       'transno'),
            ('salesdetail', 'transno,prodcode'),
            ('product',     'prodcode'),
            ('payment',     'orno'),
            ('pricehist',   'effdate,prodcode')
        ) AS t(tbl, keycols)
    LOOP
        EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE', r.tbl);
        EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS stamp VARCHAR(60)', r.tbl);
        EXECUTE format(
            'UPDATE %I SET stamp = %L WHERE stamp IS NULL',
            r.tbl,
            'ADD system ' || to_char(now() AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM')
        );

        SELECT string_agg(quote_literal(k), ',') INTO v_args
          FROM unnest(string_to_array(r.keycols, ',')) AS k;

        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger AS t
            JOIN pg_class AS c ON c.oid = t.tgrelid
            JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = r.tbl AND t.tgname = r.tbl || '_bu_check'
              AND NOT t.tgisinternal
        ) THEN
            EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION trg_check_children()', r.tbl || '_bu_check', r.tbl);
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger AS t
            JOIN pg_class AS c ON c.oid = t.tgrelid
            JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = r.tbl AND t.tgname = r.tbl || '_biu_stamp'
              AND NOT t.tgisinternal
        ) THEN
            EXECUTE format('CREATE TRIGGER %I BEFORE INSERT OR UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION trg_set_stamp()', r.tbl || '_biu_stamp', r.tbl);
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger AS t
            JOIN pg_class AS c ON c.oid = t.tgrelid
            JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = r.tbl AND t.tgname = r.tbl || '_bd_block'
              AND NOT t.tgisinternal
        ) THEN
            EXECUTE format('CREATE TRIGGER %I BEFORE DELETE ON %I FOR EACH ROW EXECUTE FUNCTION trg_block_hard_delete()', r.tbl || '_bd_block', r.tbl);
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger AS t
            JOIN pg_class AS c ON c.oid = t.tgrelid
            JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = r.tbl AND t.tgname = r.tbl || '_bt_block'
              AND NOT t.tgisinternal
        ) THEN
            EXECUTE format('CREATE TRIGGER %I BEFORE TRUNCATE ON %I FOR EACH STATEMENT EXECUTE FUNCTION trg_block_hard_delete()', r.tbl || '_bt_block', r.tbl);
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger AS t
            JOIN pg_class AS c ON c.oid = t.tgrelid
            JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = r.tbl AND t.tgname = r.tbl || '_aiu_audit'
              AND NOT t.tgisinternal
        ) THEN
            EXECUTE format('CREATE TRIGGER %I AFTER INSERT OR UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION trg_audit_log(%s)', r.tbl || '_aiu_audit', r.tbl, v_args);
        END IF;

        IF to_regclass(format('public.%I', r.tbl || '_active')) IS NULL THEN
            EXECUTE format('CREATE VIEW %I AS SELECT * FROM %I WHERE NOT is_deleted', r.tbl || '_active', r.tbl);
        END IF;
    END LOOP;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger AS t
        JOIN pg_class AS c ON c.oid = t.tgrelid
        JOIN pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relname = 'audit_log'
          AND t.tgname = 'audit_log_protect_row' AND NOT t.tgisinternal
    ) THEN
        CREATE TRIGGER audit_log_protect_row
            BEFORE UPDATE OR DELETE ON audit_log
            FOR EACH ROW EXECUTE FUNCTION trg_protect_audit_log();
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger AS t
        JOIN pg_class AS c ON c.oid = t.tgrelid
        JOIN pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relname = 'audit_log'
          AND t.tgname = 'audit_log_protect_truncate' AND NOT t.tgisinternal
    ) THEN
        CREATE TRIGGER audit_log_protect_truncate
            BEFORE TRUNCATE ON audit_log
            FOR EACH STATEMENT EXECUTE FUNCTION trg_protect_audit_log();
    END IF;
END;
$$;

COMMIT;
