-- =============================================================================
-- Migration: Allow authenticated users to delete their own notifications
-- =============================================================================
-- 1. Grant table-level DELETE privilege to the authenticated role so PostgREST
--    allows DELETE operations.
-- 2. Create Row-Level Security (RLS) policy ensuring authenticated users can
--    ONLY delete their own notification rows (user_id = auth.uid()).
-- =============================================================================

-- 1. Table-level privilege grant
grant delete on public.notifications to authenticated;

-- 2. Row-Level Security policy
drop policy if exists "notifications_delete_own" on public.notifications;

create policy "notifications_delete_own"
  on public.notifications
  for delete
  to authenticated
  using (user_id = auth.uid());
