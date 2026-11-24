-- =====================================================================
-- Migration: 20261124154000_fix_admin_delete_post_rpc.sql
-- Fix Admin Post Deletion: Add role column to profiles, expand admin
-- verification, add admin delete RLS policy, and enhance moderation RPCs.
-- =====================================================================

-- 1. Ensure 'role' column exists in public.profiles table
-- This prevents error 42703 (column "role" does not exist)
alter table public.profiles
  add column if not exists role text not null default 'User';

-- Safely sync 'role' from auth.users metadata for any existing admin accounts
do $$
begin
  update public.profiles p
  set role = 'Admin'
  from auth.users u
  where p.id = u.id
    and (
      coalesce((u.raw_app_meta_data ->> 'is_admin')::boolean, false) = true
      or (u.raw_app_meta_data ->> 'role') in ('admin', 'ADMIN')
      or coalesce((u.raw_user_meta_data ->> 'is_admin')::boolean, false) = true
      or (u.raw_user_meta_data ->> 'role') in ('admin', 'ADMIN')
    );
exception
  when others then null;
end $$;

-- 2. Direct RLS Delete Policy for Admins on public.reports
-- Ensures that authorized administrators can delete any report directly
drop policy if exists reports_delete_admin on public.reports;
create policy reports_delete_admin on public.reports
  for delete to authenticated
  using (
    coalesce((auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean, false) = true
    or (auth.jwt() -> 'app_metadata' ->> 'role') in ('admin', 'ADMIN')
    or coalesce((auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean, false) = true
    or (auth.jwt() -> 'user_metadata' ->> 'role') in ('admin', 'ADMIN')
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and lower(coalesce(role, '')) = 'admin'
    )
  );

-- 3. Enhanced Atomic RPC function: admin_delete_post
create or replace function public.admin_delete_post(
  p_post_id     uuid,
  p_reason      text default null,
  p_notify_user boolean default false
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_caller_uid uuid := (select auth.uid());
  v_is_admin boolean;
  v_reporter_id uuid;
  v_pet_id uuid;
  v_notification_message text;
begin
  if v_caller_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- Verify admin identity across app_metadata, user_metadata, and profiles table
  v_is_admin := coalesce(
    (select auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean,
    false
  ) or (
    select auth.jwt() -> 'app_metadata' ->> 'role'
  ) in ('admin', 'ADMIN') or coalesce(
    (select auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean,
    false
  ) or (
    select auth.jwt() -> 'user_metadata' ->> 'role'
  ) in ('admin', 'ADMIN') or exists (
    select 1 from public.profiles
    where id = v_caller_uid and lower(coalesce(role, '')) = 'admin'
  );

  if not v_is_admin then
    raise exception 'unauthorized: admin privileges required' using errcode = '42501';
  end if;

  -- Fetch reporter ID and pet_id before deletion
  select reporter_id, pet_id into v_reporter_id, v_pet_id
  from public.reports
  where id = p_post_id;

  if not found then
    -- Already deleted or does not exist
    return;
  end if;

  -- Notify reporter if requested
  if v_reporter_id is not null and p_notify_user then
    v_notification_message := coalesce(
      p_reason,
      'One of your sighting reports has been removed by administration due to a community guidelines violation.'
    );

    insert into public.notifications (user_id, type, message)
    values (v_reporter_id, 'report_update', v_notification_message);
  end if;

  -- If this was an owner missing pet broadcast, safely reset pet status
  if v_pet_id is not null then
    update public.pets
       set status = 'safe',
           missing_since = null,
           last_known_location = null
     where id = v_pet_id;
  end if;

  -- Clean up associated matches if any
  delete from public.matches where report_id = p_post_id;

  -- Permanently delete the report
  delete from public.reports
  where id = p_post_id;

end;
$$;

grant execute on function public.admin_delete_post(uuid, text, boolean) to authenticated;

-- 4. Enhanced admin_review_flagged_post with expanded admin verification
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
  ) in ('admin', 'ADMIN') or coalesce(
    (select auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean,
    false
  ) or (
    select auth.jwt() -> 'user_metadata' ->> 'role'
  ) in ('admin', 'ADMIN') or exists (
    select 1 from public.profiles
    where id = v_caller_uid and lower(coalesce(role, '')) = 'admin'
  );

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

grant execute on function public.admin_review_flagged_post(uuid, text, text, boolean) to authenticated;
