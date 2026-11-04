-- =====================================================================
-- Migration: 20261104000002_admin_post_moderation_rpc.sql
-- Admin AI Flagged Post Review RPC (Decide whether for deletion, edit, or approval)
-- =====================================================================

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
  v_caller_uid uuid := (select auth.uid());
  v_is_admin   boolean;
  v_reporter_id uuid;
  v_short_id   text;
  v_message    text;
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
      insert into public.notifications (user_id, type, message)
      values (v_reporter_id, 'report_update', v_message);
    end if;

  elsif p_decision = 'request_edit' then
    update public.reports
       set moderation_status = 'flagged',
           moderation_notes = coalesce(p_notes, 'Admin requested edits: please update details or photo.')
     where id = p_post_id;

    if p_notify and v_reporter_id is not null then
      v_message := format('Action Required: An administrator reviewed sighting #%s and requested edits: %s. Please update your post in Personal Reports.', v_short_id, coalesce(p_notes, 'Please provide a clearer photo or details.'));
      insert into public.notifications (user_id, type, message)
      values (v_reporter_id, 'warning', v_message);
    end if;

  elsif p_decision = 'rejected' then
    update public.reports
       set moderation_status = 'rejected',
           moderation_notes = coalesce(p_notes, 'Rejected by administrator.')
     where id = p_post_id;

    if p_notify and v_reporter_id is not null then
      v_message := format('Your sighting post #%s was reviewed and rejected: %s.', v_short_id, coalesce(p_notes, 'Did not meet community standards.'));
      insert into public.notifications (user_id, type, message)
      values (v_reporter_id, 'warning', v_message);
    end if;

  else
    raise exception 'invalid decision: must be approved, request_edit, or rejected';
  end if;

end;
$$;

revoke all on function public.admin_review_flagged_post(uuid, text, text, boolean) from public, anon;
grant execute on function public.admin_review_flagged_post(uuid, text, text, boolean) to authenticated;

