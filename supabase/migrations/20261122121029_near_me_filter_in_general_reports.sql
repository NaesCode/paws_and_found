CREATE OR REPLACE FUNCTION public.get_reports_near_me(
    p_user_id uuid,
    p_lat double precision,
    p_lng double precision,
    p_radius_meters double precision DEFAULT 5000 -- 5 km radius; pass NULL to return all sorted by distance
)
RETURNS TABLE (
    id uuid,
    reporter_id uuid,
    pet_id uuid,
    animal_type text,
    animal_name text,
    description text,
    photo_url text,
    location_name text,
    status text,
    analysis_status text,
    moderation_status text,
    created_at timestamptz,
    reporter_name text,
    reporter_photo_url text,
    pet_table_name text,
    distance_meters double precision
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
    r.id,
    r.reporter_id,
    r.pet_id,
    r.animal_type,
    r.animal_name,
    r.description,
    r.photo_url,
    r.location_name,
    r.status,
    r.analysis_status,
    r.moderation_status,
    r.created_at,
    pr.name AS reporter_name,
    pr.profile_photo_url AS reporter_photo_url,
    pe.name AS pet_table_name,
    ST_Distance(
        r.location::geography,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) AS distance_meters
    FROM public.reports r
    LEFT JOIN public.profiles pr ON pr.id = r.reporter_id
    LEFT JOIN public.pets pe ON pe.id = r.pet_id
    WHERE r.reporter_id IS DISTINCT FROM p_user_id
    AND r.location IS NOT NULL
    AND (
        p_radius_meters IS NULL
        OR ST_DWithin(
        r.location::geography,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
        p_radius_meters
        )
    )
    ORDER BY distance_meters ASC, r.created_at DESC;
$$;