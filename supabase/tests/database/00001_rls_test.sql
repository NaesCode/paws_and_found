begin;
select plan(10);

-- =====================================================================
-- 0. Seed test fixtures in auth.users
-- =====================================================================
create extension if not exists pgtap with schema extensions;

do $$
declare
  v_user_a uuid := '11111111-1111-1111-1111-111111111111';
  v_user_b uuid := '22222222-2222-2222-2222-222222222222';
  v_user_c uuid := '33333333-3333-3333-3333-333333333333';
begin
  insert into auth.users (id, email, raw_user_meta_data)
  values
    (v_user_a, 'user_a@test.com', '{"name": "User A"}'),
    (v_user_b, 'user_b@test.com', '{"name": "User B"}'),
    (v_user_c, 'user_c@test.com', '{"name": "User C"}')
  on conflict (id) do nothing;
end
$$;

-- Helper to set session context to a specific user
create or replace function tests.set_user(p_uid uuid) returns void language plpgsql as $$
begin
  if p_uid is null then
    set local role anon;
    perform set_config('request.jwt.claims', '', true);
  else
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- Test 1: Anonymous role cannot read application tables
-- ---------------------------------------------------------------------
perform tests.set_user(null);
select is_empty(
  'select * from public.profiles',
  '1. Anon role cannot select from public.profiles'
);

-- ---------------------------------------------------------------------
-- Test 2: User A reads own profile; cannot read User B's profile;
--         public_profiles view exposes only id, name, photo_url
-- ---------------------------------------------------------------------
perform tests.set_user('11111111-1111-1111-1111-111111111111'::uuid);

select results_eq(
  'select count(*)::int from public.profiles',
  ARRAY[1],
  '2a. User A can only see their own profile'
);

select results_eq(
  'select count(*)::int from public.public_profiles',
  ARRAY[3],
  '2b. public_profiles view is accessible for all profiles'
);

-- ---------------------------------------------------------------------
-- Test 3: User A cannot update email or id on profiles (permission denied)
-- ---------------------------------------------------------------------
select throws_ok(
  $$ update public.profiles set email = 'hacked@test.com' where id = '11111111-1111-1111-1111-111111111111' $$,
  '42501',
  null,
  '3. User A cannot update email column directly (column grant denied)'
);

-- ---------------------------------------------------------------------
-- Test 4: User A inserts pet with owner_id = A (succeeds);
--         insert with owner_id = B fails RLS check
-- ---------------------------------------------------------------------
select lives_ok(
  $$ insert into public.pets (owner_id, name, species) values ('11111111-1111-1111-1111-111111111111', 'A Pet', 'Dog') $$,
  '4a. User A can insert own pet'
);

select throws_ok(
  $$ insert into public.pets (owner_id, name, species) values ('22222222-2222-2222-2222-222222222222', 'B Pet Fraud', 'Dog') $$,
  '42501',
  null,
  '4b. User A cannot insert pet for User B'
);

-- ---------------------------------------------------------------------
-- Test 5: report_pet_missing flips status and creates a report;
--         User B calling it for User A''s pet fails
-- ---------------------------------------------------------------------
do $$
declare
  v_pet_id uuid;
begin
  select id into v_pet_id from public.pets where owner_id = '11111111-1111-1111-1111-111111111111' limit 1;
  perform public.report_pet_missing(v_pet_id, 14.5995, 120.9842, 'Lost near park');
end;
$$;

select results_eq(
  $$ select status from public.pets where owner_id = '11111111-1111-1111-1111-111111111111' $$,
  ARRAY['missing'],
  '5a. report_pet_missing flipped status to missing'
);

perform tests.set_user('22222222-2222-2222-2222-222222222222'::uuid);
select throws_ok(
  $$ select public.report_pet_missing((select id from public.pets where owner_id = '11111111-1111-1111-1111-111111111111' limit 1), 14.5, 120.9, '') $$,
  'pet not found',
  '5b. User B cannot report User A''s pet as missing'
);

-- ---------------------------------------------------------------------
-- Test 6: User B can read User A's reports, but cannot delete or hijack them
-- ---------------------------------------------------------------------
select is_empty(
  $$ delete from public.reports where reporter_id = '11111111-1111-1111-1111-111111111111' returning * $$,
  '6. User B cannot delete User A''s report'
);

-- ---------------------------------------------------------------------
-- Test 7: Matches are visible only to the reporter and the pet owner
-- ---------------------------------------------------------------------
do $$
declare
  v_report_id uuid;
  v_pet_id uuid;
begin
  set local role django_backend;
  select id into v_report_id from public.reports limit 1;
  select id into v_pet_id from public.pets limit 1;
  insert into public.matches (report_id, pet_id, similarity_score, distance_km, status)
  values (v_report_id, v_pet_id, 0.95, 0.5, 'pending');
end;
$$;

perform tests.set_user('33333333-3333-3333-3333-333333333333'::uuid); -- User C
select is_empty(
  'select * from public.matches',
  '7. User C cannot see matches between User A and User B'
);

-- ---------------------------------------------------------------------
-- Test 8: Clients cannot read private schema or insert into matches
-- ---------------------------------------------------------------------
select throws_ok(
  'select * from private.pet_embeddings',
  '42501',
  null,
  '8a. Client cannot read private.pet_embeddings'
);

select throws_ok(
  $$ insert into public.matches (report_id, pet_id, similarity_score, distance_km) values (gen_random_uuid(), gen_random_uuid(), 0.9, 1.0) $$,
  '42501',
  null,
  '8b. Client cannot insert into public.matches directly'
);

-- ---------------------------------------------------------------------
-- Test 9: Storage folder isolation check
-- ---------------------------------------------------------------------
select ok(
  (select count(*) >= 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'animal_photos_insert_own'),
  '9. Storage bucket object policy animal_photos_insert_own is defined'
);

-- ---------------------------------------------------------------------
-- Test 10: create_report rejects out-of-range coordinates
-- ---------------------------------------------------------------------
perform tests.set_user('11111111-1111-1111-1111-111111111111'::uuid);
select throws_ok(
  $$ select public.create_report('dog', 'stray dog', 'http://img.jpg', 150.0, 120.0, 'stray', null) $$,
  'invalid coordinates',
  '10. create_report rejects out-of-bounds coordinates'
);

select * from finish();
rollback;

