-- Migration: 20261122110000_add_alert_sound_to_pets.sql
-- Description: Adds per-pet notification alert sound preference to public.pets.
-- The alert_sound column stores the sound type ID (matches NotificationSoundType enum ids).
-- Defaults to 'cat' — consistent with the global app default.

alter table public.pets
  add column if not exists alert_sound text not null default 'cat';

-- Constrain to valid sound type IDs matching the Flutter NotificationSoundType enum
alter table public.pets
  drop constraint if exists pets_alert_sound_check;

alter table public.pets
  add constraint pets_alert_sound_check
    check (alert_sound in ('cat', 'kitten', 'dog', 'puppy', 'bird', 'macaw', 'system'));

-- Grant full table-level INSERT and UPDATE permissions to authenticated users for PostgREST
-- (Row-level security policies `pets_update_own` & `pets_insert_own` ensure users only modify their own pets)
grant insert, update on public.pets to authenticated;

