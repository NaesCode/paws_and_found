-- Migration: Add user-profile-photo and animal-photos storage buckets and RLS policies

-- 1. User Profile Photos Bucket
insert into storage.buckets (id, name, public)
values ('user-profile-photo', 'user-profile-photo', true)
on conflict (id) do update set public = true;

create policy user_profile_photo_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'user-profile-photo'
              and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy user_profile_photo_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'user-profile-photo'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy user_profile_photo_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'user-profile-photo'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy user_profile_photo_select_public on storage.objects
  for select to public
  using (bucket_id = 'user-profile-photo');

-- 2. Animal Photos Bucket
insert into storage.buckets (id, name, public)
values ('animal-photos', 'animal-photos', true)
on conflict (id) do update set public = true;

create policy animal_photos_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'animal-photos'
              and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy animal_photos_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'animal-photos'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy animal_photos_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'animal-photos'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy animal_photos_select_public on storage.objects
  for select to public
  using (bucket_id = 'animal-photos');
