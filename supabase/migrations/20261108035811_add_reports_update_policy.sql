-- 1. Grant full UPDATE permission on the table to logged-in users
grant update on public.reports to authenticated;

-- 2. Ensure the RLS policy allows authors to edit their own posts
drop policy if exists "Allow update for authenticated users" on public.reports;

create policy "Allow update for authenticated users"
on public.reports
for update
to authenticated
using (auth.uid() = reporter_id)
with check (auth.uid() = reporter_id);