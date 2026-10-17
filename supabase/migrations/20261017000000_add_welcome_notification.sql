-- =====================================================================
-- Add 'welcome' notification type and update trigger for new users
-- =====================================================================

-- 1. Update the check constraint on public.notifications to allow 'welcome'
alter table public.notifications
  drop constraint if exists notifications_type_check;

alter table public.notifications
  add constraint notifications_type_check
  check (type in (
    'match_found', 
    'report_update', 
    'verification_request', 
    'match_confirmed', 
    'welcome'
  ));

-- 2. Update the handle_new_user trigger to insert the welcome notification
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Step A: Auto-create the user profile
  insert into public.profiles (id, name, email, phone_number, profile_photo_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    nullif(new.phone, ''),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  -- Step B: Insert the Welcome notification
  insert into public.notifications (user_id, type, message)
  values (
    new.id,
    'welcome',
    'Welcome to Paws and Found! 🐾 Together, we can help protect and reunite pets with their families.'
  );

  return new;
end;
$$;

