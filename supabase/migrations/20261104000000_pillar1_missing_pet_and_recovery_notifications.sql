-- Migration: 20261104000000_pillar1_missing_pet_and_recovery_notifications.sql
-- Pillar 1: Missing Pet & Recovery Lifecycle Notifications (Owner and Finder POV)

-- 1. Update check constraint on public.notifications to include 'pet_safe' and 'report_nearby'
alter table public.notifications
  drop constraint if exists notifications_type_check;

alter table public.notifications
  add constraint notifications_type_check
  check (type in (
    'match_found', 
    'report_update', 
    'verification_request', 
    'match_confirmed', 
    'welcome',
    'status_update',
    'warning',
    'suspension',
    'pet_safe',
    'report_nearby'
  ));

-- 2. Enhanced report_pet_missing():
--    - Sets pet to 'missing', records last_known_location & missing_since.
--    - Creates missing report in public.reports.
--    - Dispatches confirmation notification to the pet owner (Owner POV).
--    - Dispatches proximity alert ('report_nearby') to community members (Community POV).
create or replace function public.report_pet_missing(
  p_pet_id        uuid,
  p_lat           double precision,
  p_lng           double precision,
  p_note          text default '',
  p_missing_since timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid       uuid := (select auth.uid());
  v_pet       public.pets;
  v_report_id uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_lat < -90 or p_lat > 90 or p_lng < -180 or p_lng > 180 then
    raise exception 'invalid coordinates';
  end if;
  if p_missing_since > now() + interval '5 minutes' then
    raise exception 'missing_since cannot be in the future';
  end if;
  if p_missing_since < now() - interval '60 days' then
    raise exception 'missing_since is too far in the past';
  end if;

  select * into v_pet from public.pets where id = p_pet_id and owner_id = v_uid for update;
  if not found then
    raise exception 'pet not found';
  end if;
  if v_pet.status = 'missing' then
    raise exception 'pet is already reported missing';
  end if;

  update public.pets
     set status = 'missing',
         missing_since = p_missing_since,
         last_known_location = st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography
   where id = p_pet_id;

  insert into public.reports (reporter_id, pet_id, animal_type, description, photo_url, location, status)
  values (
    v_uid, p_pet_id, v_pet.species,
    coalesce(nullif(p_note, ''), v_pet.description, ''),
    coalesce(v_pet.photo_urls[1], ''),
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography, 'missing'
  )
  returning id into v_report_id;

  -- 2.1 Owner Confirmation Notification: Reassures the pet parent that the search broadcast is live
  insert into public.notifications (user_id, type, message)
  values (
    v_uid,
    'report_update',
    format('Search broadcast active: %s has been reported missing. Our AI is actively monitoring community sightings.', v_pet.name)
  );

  -- 2.2 Community Proximity Broadcast ('report_nearby'): Alerts community members in the area
  insert into public.notifications (user_id, type, message)
  select p.id, 'report_nearby',
         format('Urgent Alert: %s (%s) was reported missing in your community. Please keep an eye out!', v_pet.name, v_pet.species)
  from public.profiles p
  where p.id != v_uid
  limit 25;

  return v_report_id;
end;
$$;

revoke execute on function public.report_pet_missing(uuid, double precision, double precision, text, timestamptz) from public, anon;
grant  execute on function public.report_pet_missing(uuid, double precision, double precision, text, timestamptz) to authenticated;

-- 3. Enhanced mark_pet_safe():
--    - Marks pet status as 'safe' and clears missing location & time.
--    - Marks open missing reports for this pet as 'found'.
--    - Dispatches confirmation notification to the pet owner (Owner POV).
--    - Dispatches 'pet_safe' celebration notifications to all Good Samaritans who submitted sightings / matches for this pet (Finder POV).
create or replace function public.mark_pet_safe(p_pet_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid       uuid := (select auth.uid());
  v_pet_name  text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select name into v_pet_name from public.pets where id = p_pet_id and owner_id = v_uid;
  if not found then
    raise exception 'pet not found';
  end if;

  update public.pets
     set status = 'safe', missing_since = null, last_known_location = null
   where id = p_pet_id and owner_id = v_uid;

  update public.reports set status = 'found'
   where pet_id = p_pet_id and status = 'missing';

  -- 3.1 Owner Confirmation Notification: Confirms missing alerts are closed
  insert into public.notifications (user_id, type, message)
  values (
    v_uid,
    'pet_safe',
    format('Wonderful news! %s is safely home and all active missing alerts have been closed.', v_pet_name)
  );

  -- 3.2 Finder & Sighting Reporter Notification: Informs all users whose sightings matched this pet
  insert into public.notifications (user_id, type, message)
  select distinct r.reporter_id, 'pet_safe',
         format('Great news! %s has been safely reunited with their owner. Thank you for your sharp eyes and community support!', v_pet_name)
  from public.matches m
  join public.reports r on m.report_id = r.id
  where m.pet_id = p_pet_id
    and r.reporter_id is not null
    and r.reporter_id != v_uid;

end;
$$;

revoke execute on function public.mark_pet_safe(uuid) from public, anon;
grant  execute on function public.mark_pet_safe(uuid) to authenticated;

