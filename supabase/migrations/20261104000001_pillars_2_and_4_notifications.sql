-- =====================================================================
-- Migration: 20261104000001_pillars_2_and_4_notifications.sql
-- Pillar 2: Sighting Reports & AI Moderation Notifications
-- Pillar 4: Pet Profile Lifecycle & High-Confidence Alerts
-- =====================================================================

-- 1. Enhanced delete_pet() RPC:
-- Adds confirmation notification to owner when a pet is deleted.
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
  delete from public.reports
   where pet_id = p_pet_id;

  -- 3. Delete any matches directly referencing this pet
  delete from public.matches
   where pet_id = p_pet_id;

  -- 4. Delete the pet itself (cascades to private.pet_embeddings)
  delete from public.pets
   where id = p_pet_id and owner_id = v_uid;

  -- 5. Send confirmation notification to owner (Pillar 4: Pet Profile Lifecycle)
  insert into public.notifications (user_id, type, message)
  values (
    v_uid,
    'report_update',
    format('Pet Profile Removed: %s has been removed from your account.', v_pet.name)
  );
end;
$$;

revoke all on function public.delete_pet(uuid, text, text) from public, anon;
grant execute on function public.delete_pet(uuid, text, text) to authenticated;

-- 2. Enhanced delete_report() RPC:
-- Adds confirmation notification to reporter when their sighting report is deleted/withdrawn.
create or replace function public.delete_report(
  p_report_id uuid,
  p_reason    text,
  p_details   text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := (select auth.uid());
  v_report public.reports%rowtype;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select * into v_report
    from public.reports
   where id = p_report_id and reporter_id = v_uid;

  if not found then
    raise exception 'Report not found or unauthorized';
  end if;

  -- 1. Log the deletion for admin tracking and user feedback analytics
  insert into public.report_deletion_logs (report_id, reporter_id, pet_id, reason, details)
  values (v_report.id, v_uid, v_report.pet_id, p_reason, p_details);

  -- 2. If this report was an owner's missing pet broadcast, revert pet to safe
  if v_report.pet_id is not null then
    update public.pets
       set status = 'safe',
           missing_since = null,
           last_known_location = null
     where id = v_report.pet_id and owner_id = v_uid;
  end if;

  -- 3. Delete any matches associated with this report
  delete from public.matches
   where report_id = p_report_id;

  -- 4. Delete the report itself (cascades to private.report_embeddings)
  delete from public.reports
   where id = p_report_id and reporter_id = v_uid;

  -- 5. Send confirmation notification to reporter (Pillar 2: Sighting Deletion)
  insert into public.notifications (user_id, type, message)
  values (
    v_uid,
    'report_update',
    'Your sighting report has been successfully withdrawn.'
  );
end;
$$;

revoke all on function public.delete_report(uuid, text, text) from public, anon;
grant execute on function public.delete_report(uuid, text, text) to authenticated;

