-- Migration: Thread Comments and Sighting Linking
-- Date: 2026-10-31
-- Description: Ensures the comments table supports report threads, user profile linking,
-- and embedded sighting references.

-- 1. Ensure comments table exists and has foreign key to reports
create table if not exists public.comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references public.reports(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    parent_id uuid references public.comments(id) on delete cascade,
    content text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 2. Indexes for fast thread queries and hierarchy
create index if not exists idx_comments_post_id on public.comments(post_id, created_at asc);
create index if not exists idx_comments_user_id on public.comments(user_id);
create index if not exists idx_comments_parent_id on public.comments(parent_id);

-- 3. Row Level Security (RLS)
alter table public.comments enable row level security;

-- Authenticated and anonymous users can read comments on reports
create policy "Allow read comments" on public.comments
    for select using (true);

-- Authenticated users can insert their own comments
create policy "Allow insert comments" on public.comments
    for insert with check (auth.uid() = user_id);

-- Authenticated users can update/delete their own comments
create policy "Allow update own comments" on public.comments
    for update using (auth.uid() = user_id);

create policy "Allow delete own comments" on public.comments
    for delete using (auth.uid() = user_id);

-- 4. Enable Supabase Realtime broadcast for live thread updates
do $$
begin
    if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'comments'
    ) then
        alter publication supabase_realtime add table public.comments;
    end if;
end $$;
