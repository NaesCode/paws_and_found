-- =====================================================================
-- Migration: Add user status to profiles and enable admin status updates
-- with automated user notifications
-- =====================================================================

-- 1. Ensure status column exists in public.profiles
alter table public.profiles
  add column if not exists status text not null default 'Active';

-- Add check constraint for allowed statuses
alter table public.profiles
  drop constraint if exists profiles_status_check;

alter table public.profiles
  add constraint profiles_status_check
  check (status in ('Active', 'Warning', 'Suspension', 'Suspended'));

-- Grant update on status on public.profiles to authenticated users
grant update (status) on public.profiles to authenticated;

-- 2. Update notifications check constraint to allow status notification types
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
    'suspension'
  ));

-- 3. Atomic RPC function for Admin to update user status and dispatch notification
create or replace function public.admin_update_user_status(
  p_user_id uuid,
  p_status  text,
  p_message text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_caller_uid uuid := (select auth.uid());
  v_is_admin boolean;
  v_notification_message text;
  v_notification_type text;
begin
  if v_caller_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- Verify caller is admin via app_metadata
  v_is_admin := coalesce(
    (select auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean,
    false
  ) or (
    select auth.jwt() -> 'app_metadata' ->> 'role'
  ) in ('admin', 'ADMIN');

  if not v_is_admin then
    raise exception 'unauthorized: admin privileges required' using errcode = '42501';
  end if;

  if p_status not in ('Active', 'Warning', 'Suspension', 'Suspended') then
    raise exception 'invalid status: %', p_status;
  end if;

  -- 1. Update user profile status
  update public.profiles
  set status = p_status
  where id = p_user_id;

  -- 2. Determine notification message and type
  if p_status in ('Suspended', 'Suspension') then
    v_notification_type := 'suspension';
    v_notification_message := coalesce(p_message, 'Your account has been suspended by administration. If you believe this is an error, please contact support.');
  elsif p_status = 'Warning' then
    v_notification_type := 'warning';
    v_notification_message := coalesce(p_message, 'Your account has received an administrative warning regarding community guidelines.');
  else
    v_notification_type := 'status_update';
    v_notification_message := coalesce(p_message, 'Your account status has been set to Active. You have full access to community features.');
  end if;

  -- 3. Insert notification for target user
  insert into public.notifications (user_id, type, message)
  values (p_user_id, v_notification_type, v_notification_message);

end;
$$;

grant execute on function public.admin_update_user_status(uuid, text, text) to authenticated;



-- 4. Atomic RPC function for Admin to send a warning to the author of a specific post
create or replace function public.admin_warn_user_for_post(
  p_post_id uuid,
  p_user_id uuid default null,
  p_reason  text default 'Community Guidelines Violation',
  p_message text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_caller_uid uuid := (select auth.uid());
  v_is_admin boolean;
  v_target_user_id uuid := p_user_id;
  v_notification_message text;
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

  -- 1. Resolve user ID from report if not explicitly passed
  if v_target_user_id is null then
    select reporter_id into v_target_user_id
    from public.reports
    where id = p_post_id;
  end if;

  if v_target_user_id is not null then
    -- 2. Update author profile status to 'Warning'
    update public.profiles
    set status = 'Warning'
    where id = v_target_user_id;

    -- 3. Build warning notification message
    v_notification_message := coalesce(
      p_message,
      format('Your post has received an administrative warning for: %s. Please review our community guidelines.', coalesce(p_reason, 'guidelines violation'))
    );

    -- 4. Insert warning notification for target user
    insert into public.notifications (user_id, type, message)
    values (v_target_user_id, 'warning', v_notification_message);
  end if;

end;
$$;

grant execute on function public.admin_warn_user_for_post(uuid, uuid, text, text) to authenticated;

-- 5. Atomic RPC function for Admin to delete a post and optionally notify author
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
  v_notification_message text;
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

  -- 1. Fetch reporter ID before deletion if notification is requested
  select reporter_id into v_reporter_id
  from public.reports
  where id = p_post_id;

  if v_reporter_id is not null and p_notify_user then
    v_notification_message := coalesce(
      p_reason,
      'One of your sighting reports has been removed by administration due to a community guidelines violation.'
    );

    insert into public.notifications (user_id, type, message)
    values (v_reporter_id, 'report_update', v_notification_message);
  end if;

  -- 2. Permanently delete the report
  delete from public.reports
  where id = p_post_id;

end;
$$;

grant execute on function public.admin_delete_post(uuid, text, boolean) to authenticated;
