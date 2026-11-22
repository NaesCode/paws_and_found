-- Migration: 20261122100000_create_user_device_tokens.sql
-- Description: Stores FCM device tokens for mobile push notifications.

create table if not exists public.user_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null unique,
  device_type text not null default 'android',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index for speedy lookup by recipient user_id
create index if not exists user_device_tokens_user_idx
  on public.user_device_tokens(user_id);

-- Enable Row Level Security
alter table public.user_device_tokens enable row level security;

-- Policies:
-- 1. Authenticated users can insert their own token (upsert)
create policy "user_device_tokens_insert_own"
  on public.user_device_tokens
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- 2. Authenticated users can select their own tokens
create policy "user_device_tokens_select_own"
  on public.user_device_tokens
  for select
  to authenticated
  using (auth.uid() = user_id);

-- 3. Authenticated users can update their own tokens
create policy "user_device_tokens_update_own"
  on public.user_device_tokens
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. Authenticated users can delete their own tokens (e.g. on sign out)
create policy "user_device_tokens_delete_own"
  on public.user_device_tokens
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- 5. Service role / backend access to select all tokens for push notifications
grant select, delete on public.user_device_tokens to authenticated;
grant all on public.user_device_tokens to service_role;
