CREATE UNIQUE INDEX IF NOT EXISTS uq_pet_claims_one_active_per_report
ON public.pet_claims (report_id)
WHERE status NOT IN ('declined');

CREATE OR REPLACE FUNCTION public.has_active_claim_by_other(
  p_report_id uuid,
  p_user_id uuid
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.pet_claims
    WHERE report_id = p_report_id
      AND claimer_id <> p_user_id
      AND lower(COALESCE(status, '')) NOT IN ('declined', 'cancelled', 'rejected')
  );
$$;

GRANT EXECUTE ON FUNCTION public.has_active_claim_by_other(uuid, uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.handle_pet_claim_handover_completed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_linked_id uuid;
  v_pet_id uuid;
BEGIN
  IF (NEW.finder_confirmed_handover = true AND NEW.claimer_confirmed_handover = true)
     OR lower(COALESCE(NEW.status, '')) = 'completed' THEN

    NEW.status := 'completed';

    -- Grab linked_report_id / pet_id from the spotted report before updating
    SELECT linked_report_id, pet_id
    INTO v_linked_id, v_pet_id
    FROM public.reports
    WHERE id = NEW.report_id;

    -- 1. Mark the spotted/found report (report_id) as 'safe'
    UPDATE public.reports
    SET status = 'safe'
    WHERE id = NEW.report_id;

    -- 2. Mark the linked Missing report AND any other sightings linked to it as 'safe'
    IF v_linked_id IS NOT NULL THEN
      UPDATE public.reports
      SET status = 'safe'
      WHERE id = v_linked_id
         OR linked_report_id = v_linked_id;
    END IF;

    -- 3. Also mark any report that directly linked TO NEW.report_id as 'safe'
    UPDATE public.reports
    SET status = 'safe'
    WHERE linked_report_id = NEW.report_id;

    -- 4. Fallback: if the claimant has an open 'missing' report for this pet_id, mark it 'safe'
    IF v_pet_id IS NOT NULL THEN
      UPDATE public.reports
      SET status = 'safe'
      WHERE user_id = NEW.claimer_id
        AND pet_id = v_pet_id
        AND lower(COALESCE(status, '')) = 'missing';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pet_claim_handover_completed ON public.pet_claims;

CREATE TRIGGER trg_pet_claim_handover_completed
BEFORE UPDATE ON public.pet_claims
FOR EACH ROW
EXECUTE FUNCTION public.handle_pet_claim_handover_completed();