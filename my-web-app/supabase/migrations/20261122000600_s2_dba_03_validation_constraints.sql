-- Validate Customer payment terms and Product units without rewriting data.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    violating_customers TEXT;
    violating_products TEXT;
    target_relation REGCLASS;
    target_column TEXT;
    target_constraint TEXT;
    target_attnum SMALLINT;
    existing_constraint RECORD;
BEGIN
    IF to_regclass('public.customer') IS NULL
       OR to_regclass('public.product') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-03 stopped: public.customer and public.product must exist before applying validation constraints.';
    END IF;

    LOCK TABLE public.customer, public.product IN SHARE ROW EXCLUSIVE MODE;

    SELECT string_agg(
               format('%s=%L', custno, payterm),
               E'\n' ORDER BY custno
           )
      INTO violating_customers
      FROM public.customer
     WHERE payterm IS NOT NULL
       AND payterm NOT IN ('COD', '30D', '45D');

    SELECT string_agg(
               format('%s=%L', prodcode, unit),
               E'\n' ORDER BY prodcode
           )
      INTO violating_products
      FROM public.product
     WHERE unit IS NOT NULL
       AND unit NOT IN ('pc', 'ea', 'mtr', 'pkg', 'ltr');

    IF violating_customers IS NOT NULL OR violating_products IS NOT NULL THEN
        RAISE EXCEPTION USING
            MESSAGE = format(
                'S2-DBA-03 stopped before adding constraints because existing rows have unapproved values. Customer custno=payterm violations:%sProduct prodcode=unit violations:%sReview/correct the listed rows, then rerun the migration.',
                COALESCE(E'\n' || violating_customers || E'\n', E'\n none\n'),
                COALESCE(E'\n' || violating_products || E'\n', E'\n none\n')
            );
    END IF;

    FOR target_relation, target_column, target_constraint IN
        SELECT 'public.customer'::REGCLASS, 'payterm', 'pay_ck'
        UNION ALL
        SELECT 'public.product'::REGCLASS, 'unit', 'unit_ck'
    LOOP
        SELECT attribute.attnum
          INTO target_attnum
          FROM pg_attribute AS attribute
         WHERE attribute.attrelid = target_relation
           AND attribute.attname = target_column
           AND NOT attribute.attisdropped;

        IF target_attnum IS NULL THEN
            RAISE EXCEPTION
                'S2-DBA-03 stopped: expected column %.% is missing.',
                target_relation,
                target_column;
        END IF;

        SELECT constraint_row.conname,
               constraint_row.contype,
               constraint_row.conkey,
               constraint_row.convalidated
          INTO existing_constraint
          FROM pg_constraint AS constraint_row
         WHERE constraint_row.conrelid = target_relation
           AND constraint_row.conname = target_constraint;

        IF FOUND THEN
            IF existing_constraint.contype <> 'c'
               OR existing_constraint.conkey IS DISTINCT FROM ARRAY[target_attnum]::SMALLINT[] THEN
                RAISE EXCEPTION
                    'S2-DBA-03 stopped: constraint name % on % exists but does not apply only to column %. Review the existing schema.',
                    target_constraint,
                    target_relation,
                    target_column;
            END IF;

            IF NOT existing_constraint.convalidated THEN
                EXECUTE format(
                    'ALTER TABLE %s VALIDATE CONSTRAINT %I',
                    target_relation,
                    target_constraint
                );
            END IF;
        ELSE
            IF EXISTS (
                SELECT 1
                  FROM pg_constraint AS constraint_row
                 WHERE constraint_row.conrelid = target_relation
                   AND constraint_row.contype = 'c'
                   AND target_attnum = ANY (constraint_row.conkey)
            ) THEN
                RAISE EXCEPTION
                    'S2-DBA-03 stopped: % has a differently named CHECK constraint on column %. Review it before adding %.',
                    target_relation,
                    target_column,
                    target_constraint;
            END IF;

            IF target_constraint = 'pay_ck' THEN
                ALTER TABLE public.customer
                    ADD CONSTRAINT pay_ck CHECK (payterm IN ('COD', '30D', '45D'));
            ELSE
                ALTER TABLE public.product
                    ADD CONSTRAINT unit_ck CHECK (unit IN ('pc', 'ea', 'mtr', 'pkg', 'ltr'));
            END IF;
        END IF;
    END LOOP;
END;
$$;

COMMIT;
