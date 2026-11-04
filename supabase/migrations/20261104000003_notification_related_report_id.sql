-- =====================================================================
-- Migration: 20261104000003_notification_related_report_id.sql
-- Enable Post-Related Deep Linking for In-App Notifications
-- =====================================================================

-- 1. Add related_report_id foreign key column to public.notifications
alter table public.notifications
  add column if not exists related_report_id uuid references public.reports (id) on delete set null;

create index if not exists notifications_related_report_idx
  on public.notifications (related_report_id);

-- 2. Update report_pet_missing() to populate related_report_id
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

  select * into v_pet from public.pets where id = p_pet_id and owner_id = v_uid;
  if not found then
    raise exception 'pet not found or not owned by caller';
  end if;

  -- 1. Update pet status and missing details
  update public.pets
     set status = 'missing',
         missing_since = coalesce(p_missing_since, now()),
         last_known_location = st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography
   where id = p_pet_id and owner_id = v_uid;

  -- 2. Insert missing report into public.reports
  insert into public.reports (
    reporter_id, pet_id, animal_type, description, photo_url, location, status
  ) values (
    v_uid, p_pet_id, v_pet.species,
    coalesce(nullif(p_note, ''), v_pet.description, ''),
    coalesce(v_pet.photo_urls[1], ''),
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography, 'missing'
  )
  returning id into v_report_id;

  -- 2.1 Owner Confirmation Notification with related_report_id
  insert into public.notifications (user_id, type, message, related_report_id)
  values (
    v_uid,
    'report_update',
    format('Search broadcast active: %s has been reported missing. Our AI is actively monitoring community sightings.', v_pet.name),
    v_report_id
  );

  -- 2.2 Community Proximity Broadcast ('report_nearby') with related_report_id
  insert into public.notifications (user_id, type, message, related_report_id)
  select p.id, 'report_nearby',
         format('Urgent Alert: %s (%s) was reported missing in your community. Please keep an eye out!', v_pet.name, v_pet.species),
         v_report_id
  from public.profiles p
  where p.id != v_uid
  limit 25;

  return v_report_id;
end;
$$;

-- 3. Update admin_review_flagged_post() to populate related_report_id
create or replace function public.admin_review_flagged_post(
  p_post_id   uuid,
  p_decision  text, -- 'approved', 'request_edit', 'rejected'
  p_notes     text default null,
  p_notify    boolean default true
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_caller_uid  uuid := (select auth.uid());
  v_is_admin    boolean;
  v_reporter_id uuid;
  v_short_id    text;
  v_message     text;
begin
  if v_caller_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  v_is_admin := coalesce(
    (select auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean,
    false
  ) or (
    select auth.jwt() -> 'app_metadata' ->> 'role'
  ) in ('admin', 'ADMIN');

  if not v_is_admin then
    raise exception 'unauthorized: admin privileges required' using errcode = '42501';
  end if;

  select reporter_id into v_reporter_id
  from public.reports
  where id = p_post_id;

  if not found then
    raise exception 'post not found';
  end if;

  v_short_id := upper(substring(replace(p_post_id::text, '-', '') from 1 for 4));

  if p_decision = 'approved' then
    update public.reports
       set moderation_status = 'approved',
           moderation_notes = coalesce(p_notes, 'Approved by administrator review.')
     where id = p_post_id;

    if p_notify and v_reporter_id is not null then
      v_message := format('Great news! Your sighting post #%s has been reviewed and approved by an administrator.', v_short_id);
      insert into public.notifications (user_id, type, message, related_report_id)
      values (v_reporter_id, 'report_update', v_message, p_post_id);
    end if;

  elsif p_decision = 'request_edit' then
    update public.reports
       set moderation_status = 'flagged',
           moderation_notes = coalesce(p_notes, 'Admin requested edits: please update details or photo.')
     where id = p_post_id;

    if p_notify and v_reporter_id is not null then
      v_message := format('Action Required: An administrator reviewed sighting #%s and requested edits: %s. Please update your post in Personal Reports.', v_short_id, coalesce(p_notes, 'Please provide a clearer photo or details.'));
      insert into public.notifications (user_id, type, message, related_report_id)
      values (v_reporter_id, 'warning', v_message, p_post_id);
    end if;

  elsif p_decision = 'rejected' then
    update public.reports
       set moderation_status = 'rejected',
           moderation_notes = coalesce(p_notes, 'Rejected by administrator.')
     where id = p_post_id;

    if p_notify and v_reporter_id is not null then
      v_message := format('Your sighting post #%s was reviewed and rejected: %s.', v_short_id, coalesce(p_notes, 'Did not meet community standards.'));
      insert into public.notifications (user_id, type, message, related_report_id)
      values (v_reporter_id, 'warning', v_message, p_post_id);
    end if;

  else
    raise exception 'invalid decision: must be approved, request_edit, or rejected';
  end if;

end;
$$;

