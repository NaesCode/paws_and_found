ALTER TABLE public.notifications
    DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_type_check
    CHECK (type IN (
        'welcome',
        'match_found',
        'report_nearby',
        'pet_safe',
        'warning',
        'suspension',
        'status_update',
        'match_confirmed',
        'report_update',
        'verification_request',
        'claim_request',
        'claim_update'
    ));