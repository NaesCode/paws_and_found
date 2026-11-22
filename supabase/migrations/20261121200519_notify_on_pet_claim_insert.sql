create or replace function public.notify_on_pet_claim_insert()
returns trigger
language plpgsql
security definer
as $$
declare
    v_claimer_name text;
    v_pet_name text;
begin
    select coalesce(name, 'Someone') into v_claimer_name
    from public.profiles
    where id = new.claimer_id;

    select coalesce(nullif(animal_name, ''), animal_type, 'your spotted pet') into v_pet_name
    from public.reports
    where id = new.report_id;

    insert into public.notifications (
    user_id,
    type,
    message,
    related_report_id,
    is_read
    ) values (
    new.finder_id,
    'claim_request',
    v_claimer_name || ' submitted a claim request for ' || v_pet_name || '. Tap to review.',
    new.report_id,
    false
    );

    return new;
end;
$$;

drop trigger if exists trg_notify_pet_claim_insert on public.pet_claims;
create trigger trg_notify_pet_claim_insert
after insert on public.pet_claims
for each row
execute function public.notify_on_pet_claim_insert();