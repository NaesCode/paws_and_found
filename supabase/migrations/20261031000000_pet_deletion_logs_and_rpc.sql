-- =====================================================================
-- Migration: Add pet deletion audit log and delete_pet RPC
--
-- Safely deletes a pet, cleans up associated missing reports, matches,
-- and records the deletion reason for administrative analytics.
-- =====================================================================

-- 1. Create pet_deletion_logs table for admin analytics
create table if not exists public.pet_deletion_logs (
  id           uuid primary key default gen_random_uuid(),
  pet_id       uuid not null,
  owner_id     uuid not null references public.profiles (id) on delete cascade,
  pet_name     text not null,
  species      text not null,
  reason       text not null,
  details      text,
  deleted_at   timestamptz not null default now()
);

-- RLS for pet_deletion_logs
alter table public.pet_deletion_logs enable row level security;

-- Owners can insert their own deletion logs
create policy pet_deletion_logs_insert_own on public.pet_deletion_logs
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

-- Only owners and backend/admins can view deletion logs
create policy pet_deletion_logs_select_own on public.pet_deletion_logs
  for select to authenticated
  using (owner_id = (select auth.uid()));

grant select, insert on public.pet_deletion_logs to authenticated;
grant all on public.pet_deletion_logs to django_backend;

-- 2. Create atomic delete_pet stored procedure
create or replace function public.delete_pet(
  p_pet_id uuid,
  p_reason text,
  p_details text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := (select auth.uid());
  v_pet public.pets%rowtype;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- Verify ownership and retrieve pet details
  select * into v_pet
    from public.pets
   where id = p_pet_id and owner_id = v_uid;

  if not found then
    raise exception 'Pet not found or unauthorized';
  end if;

  -- 1. Log the deletion reason for admin analytics
  insert into public.pet_deletion_logs (pet_id, owner_id, pet_name, species, reason, details)
  values (v_pet.id, v_uid, v_pet.name, v_pet.species, p_reason, p_details);

  -- 2. Delete any reports associated with this pet (e.g. missing pet listings on the map/feed)
  -- Note: deleting the reports will automatically cascade-delete associated matches
  delete from public.reports
   where pet_id = p_pet_id;

  -- 3. Delete any matches directly referencing this pet (if any remain)
  delete from public.matches
   where pet_id = p_pet_id;

  -- 4. Delete the pet itself (cascades to private.pet_embeddings)
  delete from public.pets
   where id = p_pet_id and owner_id = v_uid;
end;
$$;

revoke all on function public.delete_pet(uuid, text, text) from public, anon;
grant execute on function public.delete_pet(uuid, text, text) to authenticated;

