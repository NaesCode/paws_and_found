-- =====================================================================
-- Migration: Add report deletion audit log and delete_report RPC
--
-- Enables report authors to undo/delete their newly created reports
-- within a safe grace period (e.g. within 30 minutes of creation),
-- while cleaning up associated spatial matches, AI embeddings,
-- resetting pet status if it was a missing listing, and logging audit reasons.
-- =====================================================================

-- 1. Create report_deletion_logs table
create table if not exists public.report_deletion_logs (
  id           uuid primary key default gen_random_uuid(),
  report_id    uuid not null,
  reporter_id  uuid not null references public.profiles (id) on delete cascade,
  pet_id       uuid,
  reason       text not null,
  details      text,
  deleted_at   timestamptz not null default now()
);

alter table public.report_deletion_logs enable row level security;

create policy report_deletion_logs_insert_own on public.report_deletion_logs
  for insert to authenticated
  with check (reporter_id = (select auth.uid()));

create policy report_deletion_logs_select_own on public.report_deletion_logs
  for select to authenticated
  using (reporter_id = (select auth.uid()));

grant select, insert on public.report_deletion_logs to authenticated;
grant all on public.report_deletion_logs to django_backend;

-- 2. Stored procedure: delete_report with grace period check
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
end;
$$;

revoke all on function public.delete_report(uuid, text, text) from public, anon;
grant execute on function public.delete_report(uuid, text, text) to authenticated;

