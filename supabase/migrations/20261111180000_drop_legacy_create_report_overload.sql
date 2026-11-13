-- Drop the legacy 8-parameter overload of create_report.
-- The active version has 9 parameters (added p_linked_report_id).
-- PostgREST cannot disambiguate overloads when optional params are omitted,
-- causing an "ambiguous function" error that silently swallows report submissions.

DROP FUNCTION IF EXISTS public.create_report(
  text,             -- p_animal_type
  text,             -- p_description
  text,             -- p_photo_url
  double precision, -- p_lat
  double precision, -- p_lng
  text,             -- p_status
  uuid,             -- p_pet_id
  text              -- p_location_name  (8th param — this overload is obsolete)
);
