CREATE OR REPLACE FUNCTION public.handle_pet_claim_handover_completed()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_linked_id uuid;
  v_pet_id uuid;
BEGIN
  IF (NEW.finder_confirmed_handover = true AND NEW.claimer_confirmed_handover = true)
     OR lower(COALESCE(NEW.status, '')) = 'completed' THEN

    NEW.status := 'completed';

    -- Grab linked_report_id and pet_id from the claim's primary report
    SELECT linked_report_id, pet_id
    INTO v_linked_id, v_pet_id
    FROM public.reports
    WHERE id = NEW.report_id;

    -- 1. Mark the primary report (report_id) as 'safe'
    UPDATE public.reports
    SET status = 'safe'
    WHERE id = NEW.report_id;

    -- 2. Mark any report linked TO or FROM report_id as 'safe' (missing or spotted)
    IF v_linked_id IS NOT NULL THEN
      UPDATE public.reports
      SET status = 'safe'
      WHERE id = v_linked_id
         OR linked_report_id = v_linked_id;
    END IF;

    UPDATE public.reports
    SET status = 'safe'
    WHERE linked_report_id = NEW.report_id;

    -- 3. Also mark any open 'missing' or 'spotted' report for the same pet_id
    --    owned by either the finder or the claimer as 'safe'
    IF v_pet_id IS NOT NULL THEN
      UPDATE public.reports
      SET status = 'safe'
      WHERE pet_id = v_pet_id
        AND reporter_id IN (NEW.finder_id, NEW.claimer_id)
        AND lower(COALESCE(status, '')) IN ('missing', 'spotted');
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;