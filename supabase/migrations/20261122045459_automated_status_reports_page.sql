CREATE OR REPLACE FUNCTION public.sync_report_on_claim_completed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pet_id uuid;
BEGIN
  IF OLD.status IS DISTINCT FROM 'completed' AND NEW.status = 'completed' THEN
    -- 1. Automatically mark the report as 'found'
    UPDATE public.reports
    SET status = 'found'
    WHERE id = NEW.report_id
      AND status IS DISTINCT FROM 'found';

    -- 2. If reports has a pet_id column and it is populated, mark that pet as 'safe'
    BEGIN
      EXECUTE 'SELECT pet_id FROM public.reports WHERE id = $1'
      INTO v_pet_id
      USING NEW.report_id;

      IF v_pet_id IS NOT NULL THEN
        UPDATE public.pets
        SET status = 'safe'
        WHERE id = v_pet_id
          AND status IS DISTINCT FROM 'safe';
      END IF;
    EXCEPTION WHEN undefined_column THEN
      -- Ignore if reports table does not have a pet_id column
      NULL;
    END;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_report_on_claim_completed ON public.pet_claims;
CREATE TRIGGER trg_sync_report_on_claim_completed
AFTER UPDATE OF status ON public.pet_claims
FOR EACH ROW
EXECUTE FUNCTION public.sync_report_on_claim_completed();