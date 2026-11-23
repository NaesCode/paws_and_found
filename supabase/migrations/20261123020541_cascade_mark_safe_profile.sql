CREATE OR REPLACE FUNCTION public.sync_pet_status_on_report_resolved()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.pet_id IS NOT NULL
     AND lower(COALESCE(NEW.status, '')) = 'safe'
     AND lower(COALESCE(OLD.status, '')) IS DISTINCT FROM 'safe' THEN
    UPDATE public.pets
    SET status = 'safe'
    WHERE id = NEW.pet_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_pet_status_on_report_resolved ON public.reports;

CREATE TRIGGER trg_sync_pet_status_on_report_resolved
AFTER UPDATE OF status ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.sync_pet_status_on_report_resolved();