-- =====================================================================
-- Paws and Found — initial schema for the hybrid architecture
--
-- Place at: supabase/migrations/20261015000000_init_schema.sql
--
-- This migration is the SOURCE OF TRUTH for the database. Django models
-- are UNMANAGED mirrors of these tables (managed = False).
-- Contains NO secrets: the django_backend password is set out-of-band.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. Extensions
-- ---------------------------------------------------------------------
create extension if not exists postgis with schema extensions;


-- ---------------------------------------------------------------------
-- 1. Schemas and the dedicated backend role
-- ---------------------------------------------------------------------
create schema if not exists private;   -- server-only data, never exposed by the Data API
create schema if not exists django;    -- Django's own bookkeeping tables (auth, sessions, migrations)

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'django_backend') then
    create role django_backend nologin;
  end if;
end
$$;

-- Django resolves unqualified table names through this path.
alter role django_backend set search_path = django, public, private, extensions;
grant usage on schema public, private, extensions to django_backend;
grant usage, create on schema django to django_backend;


-- ---------------------------------------------------------------------
-- 2. Tables
-- ---------------------------------------------------------------------
create table public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  name              text not null default '',
  email             text,
  phone_number      text,
  profile_photo_url text,
  bio               text,
  address           text,
  created_at        timestamptz not null default now()
);

create table public.pets (
  id                  uuid primary key default gen_random_uuid(),
  owner_id            uuid not null references public.profiles (id) on delete cascade,
  name                text not null,
  species             text not null,
  breed               text,
  color               text,
  description         text,
  photo_urls          text[] not null default '{}',
  -- Nullable: a SAFE pet has no last-known location. Set by report_pet_missing().
  last_known_location extensions.geography(Point, 4326),
  status              text not null default 'safe' check (status in ('safe', 'missing')),
  created_at          timestamptz not null default now()
);

create table public.reports (
  id              uuid primary key default gen_random_uuid(),
  reporter_id     uuid not null references public.profiles (id) on delete cascade,
  pet_id          uuid references public.pets (id) on delete set null,
  animal_type     text not null,
  description     text not null default '',
  photo_url       text not null,
  location        extensions.geography(Point, 4326) not null,
  status          text not null default 'stray' check (status in ('stray', 'missing', 'found')),
  -- Lets the backend (and a retry sweep) know whether AI analysis has happened.
  analysis_status text not null default 'pending' check (analysis_status in ('pending', 'done', 'failed')),
  created_at      timestamptz not null default now()
);

create table public.matches (
  id               uuid primary key default gen_random_uuid(),
  report_id        uuid not null references public.reports (id) on delete cascade,
  pet_id           uuid not null references public.pets (id) on delete cascade,
  similarity_score double precision not null,
  distance_km      double precision not null,
  status           text not null default 'pending' check (status in ('pending', 'confirmed', 'rejected')),
  created_at       timestamptz not null default now(),
  unique (report_id, pet_id)
);

create table public.notifications (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  type             text not null check (type in ('match_found', 'report_update', 'verification_request', 'match_confirmed')),
  message          text not null,
  related_match_id uuid references public.matches (id) on delete set null,
  is_read          boolean not null default false,
  created_at       timestamptz not null default now()
);

-- AI feature vectors live in the PRIVATE schema so clients can never read or forge them.
create table private.pet_embeddings (
  pet_id     uuid primary key references public.pets (id) on delete cascade,
  vector     double precision[] not null,
  updated_at timestamptz not null default now()
);

create table private.report_embeddings (
  report_id  uuid primary key references public.reports (id) on delete cascade,
  vector     double precision[] not null,
  updated_at timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 3. Indexes
-- ---------------------------------------------------------------------
create index pets_owner_idx             on public.pets (owner_id);
create index pets_missing_location_gix  on public.pets using gist (last_known_location) where status = 'missing';
create index reports_location_gix       on public.reports using gist (location);
create index reports_created_idx        on public.reports (created_at desc);
create index reports_reporter_idx       on public.reports (reporter_id);
create index matches_report_idx         on public.matches (report_id);
create index matches_pet_idx            on public.matches (pet_id);
create index notifications_user_idx     on public.notifications (user_id, created_at desc);


-- ---------------------------------------------------------------------
-- 4. Auto-create a profile whenever a Supabase Auth user is created
--    (replaces Django's lazy get_or_create). Reads the same 'name'
--    metadata contract the Flutter signUp() call already uses, and the
--    'full_name' / 'avatar_url' keys that social providers typically send.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, email, phone_number, profile_photo_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    nullif(new.phone, ''),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill accounts that already exist (e.g. the team's current test users).
insert into public.profiles (id, name, email, phone_number, profile_photo_url)
select
  u.id,
  coalesce(u.raw_user_meta_data ->> 'name', u.raw_user_meta_data ->> 'full_name', ''),
  u.email,
  nullif(u.phone, ''),
  u.raw_user_meta_data ->> 'avatar_url'
from auth.users u
on conflict (id) do nothing;


-- ---------------------------------------------------------------------
-- 5. Row Level Security + privileges
--    Principle: deny by default. anon gets nothing. Clients get the
--    narrowest column-level privileges that still support the UI.
--    (select auth.uid()) is wrapped in a sub-select so Postgres caches it.
-- ---------------------------------------------------------------------
alter table public.profiles          enable row level security;
alter table public.pets              enable row level security;
alter table public.reports           enable row level security;
alter table public.matches           enable row level security;
alter table public.notifications     enable row level security;
alter table private.pet_embeddings   enable row level security;
alter table private.report_embeddings enable row level security;

revoke all on public.profiles, public.pets, public.reports, public.matches, public.notifications
  from anon, authenticated;
revoke all on private.pet_embeddings, private.report_embeddings from anon, authenticated;

-- 5.1 profiles ---------------------------------------------------------
grant select on public.profiles to authenticated;
-- id, email and created_at are NOT client-editable.
grant update (name, phone_number, profile_photo_url, bio, address) on public.profiles to authenticated;

create policy profiles_select_own on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- Safe, limited view so the UI can show who reported something without
-- exposing phone/address. INTENTIONAL: it runs with the owner's rights and
-- therefore bypasses RLS; Supabase's security advisor may flag it.
create or replace view public.public_profiles as
  select id, name, profile_photo_url from public.profiles;
revoke all on public.public_profiles from anon, authenticated;
grant select on public.public_profiles to authenticated;

grant select on public.profiles to django_backend;
create policy profiles_backend on public.profiles
  for all to django_backend using (true) with check (true);

-- 5.2 pets -------------------------------------------------------------
grant select, delete on public.pets to authenticated;
-- status and last_known_location are changed ONLY through the RPC functions below.
grant insert (owner_id, name, species, breed, color, description, photo_urls) on public.pets to authenticated;
grant update (name, species, breed, color, description, photo_urls) on public.pets to authenticated;

create policy pets_select_own on public.pets
  for select to authenticated using (owner_id = (select auth.uid()));
create policy pets_insert_own on public.pets
  for insert to authenticated with check (owner_id = (select auth.uid()));
create policy pets_update_own on public.pets
  for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy pets_delete_own on public.pets
  for delete to authenticated using (owner_id = (select auth.uid()));

grant select, update on public.pets to django_backend;
create policy pets_backend on public.pets
  for all to django_backend using (true) with check (true);

-- 5.3 reports ----------------------------------------------------------
-- Everyone signed in can see community reports (this powers the map and feed).
-- Inserts happen through create_report() / report_pet_missing() only.
grant select, delete on public.reports to authenticated;
grant update (description, status) on public.reports to authenticated;

create policy reports_select_all on public.reports
  for select to authenticated using (true);
create policy reports_update_own on public.reports
  for update to authenticated
  using (reporter_id = (select auth.uid())) with check (reporter_id = (select auth.uid()));
create policy reports_delete_own on public.reports
  for delete to authenticated using (reporter_id = (select auth.uid()));

grant select, update on public.reports to django_backend;
create policy reports_backend on public.reports
  for all to django_backend using (true) with check (true);

-- 5.4 matches ----------------------------------------------------------
-- Visible only to the two parties. Written only by the backend.
grant select on public.matches to authenticated;

create policy matches_select_parties on public.matches
  for select to authenticated
  using (
    exists (select 1 from public.reports r
            where r.id = matches.report_id and r.reporter_id = (select auth.uid()))
    or exists (select 1 from public.pets p
               where p.id = matches.pet_id and p.owner_id = (select auth.uid()))
  );

grant select, insert, update on public.matches to django_backend;
create policy matches_backend on public.matches
  for all to django_backend using (true) with check (true);

-- 5.5 notifications ----------------------------------------------------
grant select on public.notifications to authenticated;
grant update (is_read) on public.notifications to authenticated;

create policy notifications_select_own on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));
create policy notifications_update_own on public.notifications
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

grant select, insert on public.notifications to django_backend;
create policy notifications_backend on public.notifications
  for all to django_backend using (true) with check (true);

-- 5.6 private embeddings (backend only) --------------------------------
grant select, insert, update, delete on private.pet_embeddings, private.report_embeddings to django_backend;
create policy pet_embeddings_backend on private.pet_embeddings
  for all to django_backend using (true) with check (true);
create policy report_embeddings_backend on private.report_embeddings
  for all to django_backend using (true) with check (true);


-- ---------------------------------------------------------------------
-- 6. RPC functions (called from Flutter via supabase.rpc)
--    Geography columns come back from the API in a raw format, so spatial
--    reads and writes go through functions that speak plain lat/lng.
-- ---------------------------------------------------------------------

-- 6.1 Map / feed read. SECURITY INVOKER: RLS still applies to the caller.
create or replace function public.nearby_reports(
  p_lat         double precision,
  p_lng         double precision,
  p_radius_m    double precision default 5000,
  p_animal_type text default null,
  p_limit       int default 200
)
returns table (
  id          uuid,
  reporter_id uuid,
  pet_id      uuid,
  animal_type text,
  description text,
  photo_url   text,
  status      text,
  created_at  timestamptz,
  lat         double precision,
  lng         double precision,
  distance_m  double precision
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
  select
    r.id, r.reporter_id, r.pet_id, r.animal_type, r.description, r.photo_url,
    r.status, r.created_at,
    st_y(r.location::geometry) as lat,
    st_x(r.location::geometry) as lng,
    st_distance(r.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography) as distance_m
  from public.reports r
  where st_dwithin(r.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography, p_radius_m)
    and (p_animal_type is null or r.animal_type = p_animal_type)
  order by distance_m
  limit least(p_limit, 500);
$$;

-- 6.2 Create a sighting. SECURITY DEFINER with explicit ownership checks,
--     because clients have no direct INSERT privilege on reports.
create or replace function public.create_report(
  p_animal_type text,
  p_description text,
  p_photo_url   text,
  p_lat         double precision,
  p_lng         double precision,
  p_status      text default 'stray',
  p_pet_id      uuid default null
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

  insert into public.reports (reporter_id, pet_id, animal_type, description, photo_url, location, status)
  values (
    v_uid, p_pet_id, p_animal_type, coalesce(p_description, ''), p_photo_url,
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography, p_status
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- 6.3 "Report Missing!" — flips the pet to missing AND creates the public report atomically.
create or replace function public.report_pet_missing(
  p_pet_id uuid,
  p_lat    double precision,
  p_lng    double precision,
  p_note   text default ''
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

  select * into v_pet from public.pets where id = p_pet_id and owner_id = v_uid for update;
  if not found then
    raise exception 'pet not found';
  end if;
  if v_pet.status = 'missing' then
    raise exception 'pet is already reported missing';
  end if;

  update public.pets
     set status = 'missing',
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

  return v_report_id;
end;
$$;

-- 6.4 "Mark as Safe" — returns the pet to safe and closes its missing report(s).
create or replace function public.mark_pet_safe(p_pet_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  update public.pets
     set status = 'safe', last_known_location = null
   where id = p_pet_id and owner_id = v_uid;
  if not found then
    raise exception 'pet not found';
  end if;

  update public.reports set status = 'found'
   where pet_id = p_pet_id and status = 'missing';
end;
$$;

-- Function privileges: authenticated users only.
revoke execute on function public.nearby_reports(double precision, double precision, double precision, text, int) from public, anon;
revoke execute on function public.create_report(text, text, text, double precision, double precision, text, uuid) from public, anon;
revoke execute on function public.report_pet_missing(uuid, double precision, double precision, text) from public, anon;
revoke execute on function public.mark_pet_safe(uuid) from public, anon;

grant execute on function public.nearby_reports(double precision, double precision, double precision, text, int) to authenticated;
grant execute on function public.create_report(text, text, text, double precision, double precision, text, uuid) to authenticated;
grant execute on function public.report_pet_missing(uuid, double precision, double precision, text) to authenticated;
grant execute on function public.mark_pet_safe(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 7. Storage: public-read bucket, writes restricted to the user's own folder
--    Object path convention: {user_id}/{uuid}.jpg
--    (Decision: public bucket. Switch to private + signed URLs if the team prefers.)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('animal-photos', 'animal-photos', true)
on conflict (id) do nothing;

create policy animal_photos_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'animal-photos'
              and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy animal_photos_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'animal-photos'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy animal_photos_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'animal-photos'
         and (storage.foldername(name))[1] = (select auth.uid())::text);


-- ---------------------------------------------------------------------
-- 8. Realtime (optional but cheap): live map updates and notification badges.
--    Guarded so the migration still applies if the publication is missing.
--    RLS applies to realtime events.
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.reports;
    alter publication supabase_realtime add table public.notifications;
  end if;
end
$$;
