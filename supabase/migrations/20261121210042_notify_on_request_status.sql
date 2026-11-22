CREATE OR REPLACE FUNCTION public.notify_on_pet_claim_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_finder_name text;
  v_claimer_name text;
  v_pet_name text;
  v_proposer_name text;
  v_recipient_id uuid;
  v_schedule_text text;
BEGIN
  SELECT COALESCE(name, 'The finder') INTO v_finder_name
  FROM public.profiles WHERE id = NEW.finder_id;

  SELECT COALESCE(name, 'The claimant') INTO v_claimer_name
  FROM public.profiles WHERE id = NEW.claimer_id;

  SELECT COALESCE(NULLIF(animal_name, ''), animal_type, 'the spotted pet') INTO v_pet_name
  FROM public.reports WHERE id = NEW.report_id;

  -- 1. Stage 1 Request Accepted -> Notify Claimer
  IF OLD.stage1_approved IS DISTINCT FROM TRUE AND NEW.stage1_approved = TRUE THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES (
      NEW.claimer_id,
      'claim_update',
      v_finder_name || ' accepted your claim request for ' || v_pet_name || '! Tap to submit Stage 2 verification.',
      NEW.report_id,
      false
    );

  -- 2. Stage 1 Request Declined -> Notify Claimer
  ELSIF OLD.status IS DISTINCT FROM 'declined' AND NEW.status = 'declined' THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES (
      NEW.claimer_id,
      'claim_update',
      v_finder_name || ' declined your claim request for ' || v_pet_name || '.',
      NEW.report_id,
      false
    );

  -- 3. Finder Asked / Resent More Info Question -> Notify Claimer
  ELSIF NEW.stage2_proof_submitted = FALSE
    AND NEW.stage2_feedback IS NOT NULL
    AND NEW.stage2_feedback <> ''
    AND (OLD.stage2_feedback IS DISTINCT FROM NEW.stage2_feedback OR OLD.stage2_proof_submitted = TRUE) THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES (
      NEW.claimer_id,
      'claim_update',
      v_finder_name || ' requested more info for ' || v_pet_name || ': "' || NEW.stage2_feedback || '"',
      NEW.report_id,
      false
    );

  -- 4. Stage 2 Verification Proof Submitted -> Notify Finder
  ELSIF OLD.stage2_proof_submitted IS DISTINCT FROM TRUE AND NEW.stage2_proof_submitted = TRUE THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES (
      NEW.finder_id,
      'claim_update',
      v_claimer_name || ' submitted ownership verification proofs for ' || v_pet_name || '. Tap to review.',
      NEW.report_id,
      false
    );

  -- 5. Stage 2 Verification Approved -> Notify Claimer
  ELSIF OLD.stage2_approved IS DISTINCT FROM TRUE AND NEW.stage2_approved = TRUE THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES (
      NEW.claimer_id,
      'claim_update',
      v_finder_name || ' verified your ownership proofs for ' || v_pet_name || '! Stage 3 (Retrieval) is now unlocked.',
      NEW.report_id,
      false
    );
  END IF;

  -- 6. Stage 3 Meetup Proposed, Re-Proposed, or Agreed
  IF NEW.meetup_place IS NOT NULL AND NEW.meetup_place <> '' THEN
    v_schedule_text := COALESCE(' (' || NULLIF(NEW.meetup_time, '') || ')', '');

    -- Determine who proposed and who should be notified
    IF NEW.meetup_proposed_by = NEW.finder_id OR (NEW.meetup_proposed_by IS NULL AND NEW.meetup_confirmed_by_finder = TRUE AND NEW.meetup_confirmed_by_claimer = FALSE) THEN
      v_proposer_name := v_finder_name;
      v_recipient_id := NEW.claimer_id;
    ELSE
      v_proposer_name := v_claimer_name;
      v_recipient_id := NEW.finder_id;
    END IF;

    -- 6a. First-time Meetup Proposal
    IF OLD.meetup_place IS NULL OR OLD.meetup_place = '' THEN
      INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
      VALUES (
        v_recipient_id,
        'claim_update',
        v_proposer_name || ' proposed a safe meetup spot for ' || v_pet_name || ' at ' || NEW.meetup_place || v_schedule_text || '. Tap to review and agree.',
        NEW.report_id,
        false
      );

    -- 6b. Re-proposed Meetup Spot or Updated Date/Time
    ELSIF OLD.meetup_place IS DISTINCT FROM NEW.meetup_place
       OR OLD.meetup_lat IS DISTINCT FROM NEW.meetup_lat
       OR OLD.meetup_lng IS DISTINCT FROM NEW.meetup_lng
       OR OLD.meetup_time IS DISTINCT FROM NEW.meetup_time THEN
      INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
      VALUES (
        v_recipient_id,
        'claim_update',
        v_proposer_name || ' updated the proposed meetup details for ' || v_pet_name || ' to ' || NEW.meetup_place || v_schedule_text || '. Tap to confirm.',
        NEW.report_id,
        false
      );

    -- 6c. Other Party Agreed to the Proposed Meetup Spot
    ELSIF NOT (COALESCE(OLD.meetup_confirmed_by_finder, FALSE) AND COALESCE(OLD.meetup_confirmed_by_claimer, FALSE))
      AND (COALESCE(NEW.meetup_confirmed_by_finder, FALSE) AND COALESCE(NEW.meetup_confirmed_by_claimer, FALSE)) THEN
      -- Notify the proposer that their spot was accepted
      INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
      VALUES (
        COALESCE(NEW.meetup_proposed_by, CASE WHEN OLD.meetup_confirmed_by_finder THEN NEW.finder_id ELSE NEW.claimer_id END),
        'claim_update',
        CASE
          WHEN COALESCE(NEW.meetup_proposed_by, NEW.finder_id) = NEW.finder_id THEN v_claimer_name
          ELSE v_finder_name
        END || ' agreed to the meetup spot for ' || v_pet_name || ' at ' || NEW.meetup_place || v_schedule_text || '!',
        NEW.report_id,
        false
      );
    END IF;
  END IF;

  -- 7. Handover Confirmations
  IF OLD.status IS DISTINCT FROM 'completed' AND NEW.status = 'completed' THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES
      (
        NEW.finder_id,
        'claim_update',
        'Reunion confirmed! Both you and ' || v_claimer_name || ' confirmed the safe handover of ' || v_pet_name || '.',
        NEW.report_id,
        false
      ),
      (
        NEW.claimer_id,
        'claim_update',
        'Reunion confirmed! Both you and ' || v_finder_name || ' confirmed the safe handover of ' || v_pet_name || '.',
        NEW.report_id,
        false
      );

  ELSIF OLD.finder_confirmed_handover IS DISTINCT FROM TRUE AND NEW.finder_confirmed_handover = TRUE THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES (
      NEW.claimer_id,
      'claim_update',
      v_finder_name || ' confirmed the safe handover of ' || v_pet_name || '. Tap to confirm your side and complete the reunion!',
      NEW.report_id,
      false
    );

  ELSIF OLD.claimer_confirmed_handover IS DISTINCT FROM TRUE AND NEW.claimer_confirmed_handover = TRUE THEN
    INSERT INTO public.notifications (user_id, type, message, related_report_id, is_read)
    VALUES (
      NEW.finder_id,
      'claim_update',
      v_claimer_name || ' confirmed the safe handover of ' || v_pet_name || '. Tap to confirm your side and complete the reunion!',
      NEW.report_id,
      false
    );
  END IF;

  RETURN NEW;
END;
$$;