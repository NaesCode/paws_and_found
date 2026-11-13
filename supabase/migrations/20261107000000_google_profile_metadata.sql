-- Migration: Update handle_new_user() to support Google OAuth claims (name/picture).
-- Timestamped after 20261104000003 to ensure forward application on existing environments.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, email, phone_number, profile_photo_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name',
      ''
    ),
    new.email,
    nullif(new.phone, ''),
    coalesce(
      new.raw_user_meta_data ->> 'picture',
      new.raw_user_meta_data ->> 'avatar_url'
    )
  )
  on conflict (id) do update set
    name = case
      when public.profiles.name is null or public.profiles.name = '' then
        coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name', '')
      else public.profiles.name
    end,
    profile_photo_url = coalesce(
      public.profiles.profile_photo_url,
      new.raw_user_meta_data ->> 'picture',
      new.raw_user_meta_data ->> 'avatar_url'
    );
  return new;
end;
$$;
