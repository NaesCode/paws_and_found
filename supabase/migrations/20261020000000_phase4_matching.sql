-- =====================================================================
-- Paws and Found — Phase 4 matching support
--
-- Place at: supabase/migrations/20261020000000_phase4_matching.sql
-- Apply AFTER 20261015000000_init_schema.sql.
-- Contains NO secrets and NO destructive statements.
--
-- Adds: pets.missing_since (time-widening), notification de-duplication,
-- matches.triggered_by (two-way matching), embedding model versioning and
-- a 512-dimension guard (ResNet-18), and a new report_pet_missing()
-- signature that records WHEN the pet was last seen.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. pets.missing_since
--    NULL while safe; set when the pet is reported missing. Drives the
--    time-widening search radius.
-- ---------------------------------------------------------------------
alter table public.pets add column if not exists missing_since timestamptz;

-- Backfill any pet that is already marked missing.
update public.pets
   set missing_since = created_at
 where status = 'missing' and missing_since is null;

alter table public.pets
  add constraint pets_missing_since_required
  check (status <> 'missing' or missing_since is not null);

-- Table-level grants already cover new columns. missing_since is NOT in the
-- column-level insert/update grants for `authenticated`, so clients cannot
-- write it directly; only report_pet_missing() / mark_pet_safe() do.


-- ---------------------------------------------------------------------
-- 2. Index for the reverse search (pet -> recent unmatched sightings)
-- ---------------------------------------------------------------------
create index if not exists reports_sightings_idx
  on public.reports (created_at desc)
  where pet_id is null
    and status in ('stray', 'found')
    and analysis_status = 'done';


-- ---------------------------------------------------------------------
-- 3. Notification de-duplication
--    Re-running /analyze/ must never notify the same person twice about
--    the same match.
-- ---------------------------------------------------------------------
create unique index if not exists notifications_match_dedupe
  on public.notifications (user_id, related_match_id, type)
  where related_match_id is not null;


-- ---------------------------------------------------------------------
-- 4. matches.triggered_by
--    Which event produced the match: a new sighting ('report') or a pet
--    being reported missing ('pet').
-- ---------------------------------------------------------------------
alter table public.matches
  add column if not exists triggered_by text not null default 'report'
  check (triggered_by in ('report', 'pet'));


-- ---------------------------------------------------------------------
-- 5. Embeddings: model version + dimension guard
--    Vectors from different models must never be compared with each other.
--    The CHECK is NOT VALID so it applies to new/updated rows only and does
--    not fail on leftover stub vectors from earlier testing.
-- ---------------------------------------------------------------------
alter table private.pet_embeddings
  add column if not exists model_version text not null default 'unversioned';
alter table private.report_embeddings
  add column if not exists model_version text not null default 'unversioned';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'pet_embeddings_dim_512') then
    alter table private.pet_embeddings
      add constraint pet_embeddings_dim_512
      check (array_length(vector, 1) = 512) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'report_embeddings_dim_512') then
    alter table private.report_embeddings
      add constraint report_embeddings_dim_512
      check (array_length(vector, 1) = 512) not valid;
  end if;
end
$$;

-- OPTIONAL one-time cleanup (run MANUALLY, only if the earlier hash-based stub
-- produced test embeddings/matches you want to discard). Not part of the migration:
--   delete from public.notifications where related_match_id is not null;
--   delete from public.matches;
--   truncate private.pet_embeddings, private.report_embeddings;
--   update public.reports set analysis_status = 'pending' where analysis_status = 'done';


-- ---------------------------------------------------------------------
-- 6. report_pet_missing(): now also records when the pet was last seen.
--    New optional parameter p_missing_since (defaults to now). Old
--    named-argument calls from Flutter keep working.
-- ---------------------------------------------------------------------
drop function if exists public.report_pet_missing(uuid, double precision, double precision, text);

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

  return v_report_id;
end;
$$;

revoke execute on function public.report_pet_missing(uuid, double precision, double precision, text, timestamptz) from public, anon;
grant  execute on function public.report_pet_missing(uuid, double precision, double precision, text, timestamptz) to authenticated;


-- ---------------------------------------------------------------------
-- 7. mark_pet_safe(): also clears missing_since.
--    (Same signature, so existing grants are preserved.)
-- ---------------------------------------------------------------------
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
     set status = 'safe', missing_since = null, last_known_location = null
   where id = p_pet_id and owner_id = v_uid;
  if not found then
    raise exception 'pet not found';
  end if;

  update public.reports set status = 'found'
   where pet_id = p_pet_id and status = 'missing';
end;
$$;
