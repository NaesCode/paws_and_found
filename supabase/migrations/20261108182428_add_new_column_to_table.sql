-- 1. Safely add animal_name column if it does not already exist
alter table public.reports 
add column if not exists animal_name text;

-- 2. Drop dependent views to recreate them cleanly with animal_name support
drop view if exists public.reports_with_coordinates cascade;
drop view if exists public.posts_with_coordinates cascade;
drop view if exists public.feed_reports cascade;

-- 3. Re-create public.feed_reports view with animal_name & fallback hierarchy
create view public.feed_reports
with (security_invoker = true)
as
select
  r.id,
  r.reporter_id,
  coalesce(p.name, 'Community Member') as reporter_name,
  r.pet_id,
  r.animal_name,
  coalesce(nullif(pet.name, ''), nullif(r.animal_name, ''), 'Unknown Pet') as pet_name,
  r.animal_type,
  r.description,
  r.photo_url,
  r.location_name,
  r.status,
  r.analysis_status,
  r.moderation_status,
  r.moderation_notes,
  r.created_at,
  extensions.st_y(r.location::extensions.geometry) as latitude,
  extensions.st_x(r.location::extensions.geometry) as longitude
from public.reports r
left join public.profiles p on p.id = r.reporter_id
left join public.pets pet on pet.id = r.pet_id;

-- 4. Re-create view aliases
create view public.reports_with_coordinates
with (security_invoker = true)
as
select * from public.feed_reports;

create view public.posts_with_coordinates
with (security_invoker = true)
as
select * from public.feed_reports;

-- 5. Re-create get_feed_reports function (in case cascade touched it)
create or replace function public.get_feed_reports(
  p_limit  int default 50,
  p_offset int default 0
)
returns table (
  id              uuid,
  reporter_id     uuid,
  reporter_name   text,
  pet_id          uuid,
  pet_name        text,
  animal_type     text,
  description     text,
  photo_url       text,
  status          text,
  analysis_status text,
  created_at      timestamptz,
  latitude        double precision,
  longitude       double precision
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
  select
    id,
    reporter_id,
    reporter_name,
    pet_id,
    pet_name,
    animal_type,
    description,
    photo_url,
    status,
    analysis_status,
    created_at,
    latitude,
    longitude
  from public.feed_reports
  order by created_at desc
  limit least(p_limit, 200)
  offset greatest(p_offset, 0);
$$;

-- 6. Permissions & Grants
grant select on public.feed_reports to authenticated;
grant select on public.feed_reports to django_backend;
grant select on public.reports_with_coordinates to authenticated;
grant select on public.reports_with_coordinates to django_backend;
grant select on public.posts_with_coordinates to authenticated;
grant select on public.posts_with_coordinates to django_backend;

grant execute on function public.get_feed_reports(int, int) to authenticated;
grant execute on function public.get_feed_reports(int, int) to django_backend;
