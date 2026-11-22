-- Expose each product's latest active price effective on the Manila business date.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
BEGIN
    IF to_regclass('public.pricehist_active') IS NULL
       OR to_regprocedure('public.hope_can_access(text, text, text)') IS NULL THEN
        RAISE EXCEPTION
            'S1-DBA-08 stopped: apply the HOPE app-access and price-history rights migrations first.';
    END IF;
END;
$$;

CREATE OR REPLACE VIEW public.pricehist_current
WITH (security_invoker = true)
AS
SELECT DISTINCT ON (prodcode)
       prodcode,
       effdate,
       unitprice
  FROM public.pricehist_active
 WHERE effdate <= (now() AT TIME ZONE 'Asia/Manila')::date
 ORDER BY prodcode, effdate DESC;

GRANT SELECT ON public.pricehist_current TO authenticated;

COMMIT;
