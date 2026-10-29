-- =====================================================================
-- Migration: Add coordinate-unpacked view and RPC for reports / feed
--
-- Exposes latitude and longitude as standard float8 numbers (WGS84 EPSG:4326)
-- using PostGIS ST_Y and ST_X, preventing raw EWKB binary strings from being
-- returned to Flutter / web clients.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. feed_reports View
--    SECURITY INVOKER: Enforces RLS policies of underlying tables (Postgres 15+).
-- ---------------------------------------------------------------------
create or replace view public.feed_reports
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
  r.status,
  r.analysis_status,
  r.created_at,
  -- Extract latitude and longitude from geography(Point, 4326)
  extensions.st_y(r.location::extensions.geometry) as latitude,
  extensions.st_x(r.location::extensions.geometry) as longitude
from public.reports r
left join public.profiles p on p.id = r.reporter_id
left join public.pets pet on pet.id = r.pet_id;

-- ---------------------------------------------------------------------
-- 2. Aliases for flexibility (reports_with_coordinates & posts_with_coordinates)
-- ---------------------------------------------------------------------
create or replace view public.reports_with_coordinates
with (security_invoker = true)
as
select * from public.feed_reports;

create or replace view public.posts_with_coordinates
with (security_invoker = true)
as
select * from public.feed_reports;

-- ---------------------------------------------------------------------
-- 3. Permissions & Security Model (Deny anon, allow authenticated & backend)
-- ---------------------------------------------------------------------
revoke all on public.feed_reports from anon, authenticated;
grant select on public.feed_reports to authenticated;
grant select on public.feed_reports to django_backend;

revoke all on public.reports_with_coordinates from anon, authenticated;
grant select on public.reports_with_coordinates to authenticated;
grant select on public.reports_with_coordinates to django_backend;

revoke all on public.posts_with_coordinates from anon, authenticated;
grant select on public.posts_with_coordinates to authenticated;
grant select on public.posts_with_coordinates to django_backend;

-- ---------------------------------------------------------------------
-- 4. RPC Function: get_feed_reports
-- ---------------------------------------------------------------------
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

revoke all on function public.get_feed_reports(int, int) from anon, authenticated;
grant execute on function public.get_feed_reports(int, int) to authenticated;
grant execute on function public.get_feed_reports(int, int) to django_backend;
