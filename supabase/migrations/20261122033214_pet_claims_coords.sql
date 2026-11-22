ALTER TABLE public.pet_claims
ADD COLUMN IF NOT EXISTS meetup_place text,
ADD COLUMN IF NOT EXISTS meetup_lat double precision,
ADD COLUMN IF NOT EXISTS meetup_lng double precision,
ADD COLUMN IF NOT EXISTS meetup_time text,
ADD COLUMN IF NOT EXISTS meetup_proposed_by uuid,
ADD COLUMN IF NOT EXISTS meetup_confirmed_by_finder boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS meetup_confirmed_by_claimer boolean DEFAULT false;