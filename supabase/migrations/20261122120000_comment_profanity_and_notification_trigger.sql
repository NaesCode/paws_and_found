-- Migration: 20261122120000_comment_profanity_and_notification_trigger.sql
-- Description:
-- 1. Adds infraction_count to public.profiles and an atomic RPC to record profanity violations
--    (automatically moving user to 'Warning' or 'Suspended' status).
-- 2. Prevents suspended users from inserting comments.
-- 3. Implements Step 3 (Option B): Automated notification trigger on public.comments
--    alerting report owners and parent comment authors of new discussion comments.

-- =============================================================================
-- 1. Infraction Tracking & Auto Warning/Suspension RPC
-- =============================================================================

alter table public.profiles
  add column if not exists infraction_count int not null default 0;

create or replace function public.record_profanity_infraction(
  p_detected_words text default null
)
returns json
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := (select auth.uid());
  v_count int;
  v_new_status text;
  v_msg text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- 1. Increment user infraction count
  update public.profiles
  set infraction_count = coalesce(infraction_count, 0) + 1
  where id = v_uid
  returning infraction_count into v_count;

  -- 2. Evaluate behavior limit: 3+ violations -> Warning; 5+ violations -> Suspended
  if v_count >= 5 then
    v_new_status := 'Suspended';
    v_msg := 'Your account has been suspended due to repeated prohibited language violations in community discussions.';
    
    update public.profiles set status = v_new_status where id = v_uid;

    insert into public.notifications (user_id, type, message)
    values (v_uid, 'suspension', v_msg);

  elsif v_count >= 3 then
    v_new_status := 'Warning';
    v_msg := 'Warning: Repeated use of prohibited language will lead to account suspension (' || v_count || ' violations recorded).';
    
    update public.profiles set status = v_new_status where id = v_uid;

    insert into public.notifications (user_id, type, message)
    values (v_uid, 'warning', v_msg);

  else
    select coalesce(status, 'Active') into v_new_status
    from public.profiles
    where id = v_uid;
  end if;

  return json_build_object(
    'infraction_count', v_count,
    'status', v_new_status
  );
end;
$$;

grant execute on function public.record_profanity_infraction(text) to authenticated;


-- =============================================================================
-- 2. Comment Posting Policy (Block Suspended Users)
-- =============================================================================

drop policy if exists "Allow insert comments" on public.comments;
drop policy if exists "Allow insert comments for active users" on public.comments;

create policy "Allow insert comments for active users" on public.comments
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and not exists (
      select 1 from public.profiles
      where id = auth.uid()
        and status in ('Suspended', 'Suspension')
    )
  );


-- =============================================================================
-- 3. Step 3 (Option B): Automated Comment Notification Trigger
-- =============================================================================

create or replace function public.on_comment_created_dispatch_notification()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_reporter_id uuid;
  v_commenter_name text;
  v_parent_author_id uuid;
  v_snippet text;
  v_short_report_id text;
begin
  -- 1. Fetch report details
  select reporter_id into v_reporter_id
  from public.reports
  where id = NEW.post_id;

  if v_reporter_id is null then
    return NEW;
  end if;

  -- 2. Fetch commenter display name
  select coalesce(name, 'A community member') into v_commenter_name
  from public.profiles
  where id = NEW.user_id;

  -- 3. Build brief message snippet (max 45 chars)
  v_snippet := substring(NEW.content from 1 for 45);
  if length(NEW.content) > 45 then
    v_snippet := v_snippet || '...';
  end if;

  v_short_report_id := substring(NEW.post_id::text from 1 for 8);

  -- A. Notify the Report Owner (if commenter is not the author themselves)
  if NEW.user_id <> v_reporter_id then
    insert into public.notifications (
      user_id,
      type,
      message,
      related_report_id
    )
    values (
      v_reporter_id,
      'report_update',
      v_commenter_name || ' commented on your pet sighting: "' || v_snippet || '"',
      NEW.post_id
    );
  end if;

  -- B. If this is a reply to another comment, notify the parent comment author
  if NEW.parent_id is not null then
    select user_id into v_parent_author_id
    from public.comments
    where id = NEW.parent_id;

    if v_parent_author_id is not null
       and v_parent_author_id <> NEW.user_id
       and v_parent_author_id <> v_reporter_id then
      insert into public.notifications (
        user_id,
        type,
        message,
        related_report_id
      )
      values (
        v_parent_author_id,
        'report_update',
        v_commenter_name || ' replied to your comment: "' || v_snippet || '"',
        NEW.post_id
      );
    end if;
  end if;

  return NEW;
end;
$$;

-- Drop trigger if exists and recreate cleanly
drop trigger if exists trg_comment_dispatch_notification on public.comments;

create trigger trg_comment_dispatch_notification
  after insert on public.comments
  for each row
  execute function public.on_comment_created_dispatch_notification();
