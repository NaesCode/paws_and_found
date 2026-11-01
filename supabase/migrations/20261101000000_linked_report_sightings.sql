-- =====================================================================
-- Migration: Add linked_report_id for dedicated pet sightings dashboard
--
-- Enables spotter sighting reports to explicitly link to an existing missing
-- pet report, decoupling sightings from text comments and providing the pet
-- owner with a unified timeline/dashboard of potential leads.
-- =====================================================================

-- 1. Add column to reports table
alter table public.reports
add column if not exists linked_report_id uuid references public.reports(id) on delete set null;

-- 2. Fast lookup index for owner sightings dashboard
create index if not exists idx_reports_linked_report_id 
on public.reports(linked_report_id) 
where linked_report_id is not null;

-- 3. Update create_report RPC to support optional p_linked_report_id
create or replace function public.create_report(
  p_animal_type      text,
  p_description      text,
  p_photo_url        text,
  p_lat              double precision,
  p_lng              double precision,
  p_status           text default 'stray',
  p_pet_id           uuid default null,
  p_location_name    text default null,
  p_linked_report_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := (select auth.uid());
  v_id  uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_status not in ('stray', 'missing', 'found') then
    raise exception 'invalid status';
  end if;
  if p_lat < -90 or p_lat > 90 or p_lng < -180 or p_lng > 180 then
    raise exception 'invalid coordinates';
  end if;
  if p_pet_id is not null
     and not exists (select 1 from public.pets where id = p_pet_id and owner_id = v_uid) then
    raise exception 'pet not found';
  end if;

  insert into public.reports (
    reporter_id, pet_id, animal_type, description, photo_url,
    location, status, location_name, linked_report_id
  )
  values (
    v_uid, p_pet_id, p_animal_type, coalesce(p_description, ''), p_photo_url,
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
    p_status, p_location_name, p_linked_report_id
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke execute on function public.create_report(text, text, text, double precision, double precision, text, uuid, text, uuid) from public, anon;
grant execute on function public.create_report(text, text, text, double precision, double precision, text, uuid, text, uuid) to authenticated;

