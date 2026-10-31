-- =====================================================================
-- Migration: Add smart content moderation status to reports
--
-- Enables SSDLite320 / PyTorch AI pipeline to automatically tag reports
-- as 'approved' (animal detected with high confidence) or 'flagged'
-- (low animal confidence, non-pet image, or potential guideline violation).
--
-- Admins can query flagged reports to review, approve, or reject.
-- =====================================================================

-- 1. Add moderation columns to public.reports
alter table public.reports
  add column if not exists moderation_status text not null default 'approved'
    check (moderation_status in ('approved', 'flagged', 'rejected')),
  add column if not exists moderation_notes text;

-- 2. Index for admin review dashboard to quickly retrieve pending/flagged reports
create index if not exists reports_moderation_idx
  on public.reports (created_at desc)
  where moderation_status = 'flagged';

-- 3. Safely drop view aliases and view with cascade
drop view if exists public.posts_with_coordinates cascade;
drop view if exists public.reports_with_coordinates cascade;
drop view if exists public.feed_reports cascade;

-- 4. Re-create public.feed_reports view
create view public.feed_reports
with (security_invoker = true)
as
select
  r.id,
  r.reporter_id,
  coalesce(p.name, 'Community Member') as reporter_name,
  r.pet_id,
  coalesce(pet.name, 'Unnamed Pet') as pet_name,
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

-- 5. Re-create view aliases
create view public.reports_with_coordinates
with (security_invoker = true)
as
select * from public.feed_reports;

create view public.posts_with_coordinates
with (security_invoker = true)
as
select * from public.feed_reports;

-- 6. Re-create get_feed_reports function (in case cascade touched it)
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

-- 7. Permissions & Security
grant select on public.feed_reports to authenticated;
grant select on public.feed_reports to django_backend;
grant select on public.reports_with_coordinates to authenticated;
grant select on public.reports_with_coordinates to django_backend;
grant select on public.posts_with_coordinates to authenticated;
grant select on public.posts_with_coordinates to django_backend;

grant execute on function public.get_feed_reports(int, int) to authenticated;
grant execute on function public.get_feed_reports(int, int) to django_backend;

grant update (moderation_status, moderation_notes) on public.reports to django_backend;
