
CREATE TABLE IF NOT EXISTS public.recovery_claims (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id uuid NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    finder_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    claimer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    -- Stage & Status Tracking
    current_stage integer NOT NULL DEFAULT 1 CHECK (current_stage IN (1, 2, 3)),
    status text NOT NULL DEFAULT 'pending_agreement' CHECK (
        status IN (
            'pending_agreement',
            'pending_verification',
            'verification_submitted',
            'meetup_scheduled',
            'completed',
            'rejected',
            'expired'
        )
    ),

    -- Stage 1: Agreement & Expiry
    agreed_terms_at timestamptz,
    expires_at timestamptz NOT NULL DEFAULT (now() + interval '48 hours'),
    rejection_reason text,

    -- Stage 2: Practical Ownership Verification
    unique_features_note text,
    proof_photo_urls text[] NOT NULL DEFAULT '{}',
    supporting_doc_urls text[] NOT NULL DEFAULT '{}',

    -- Stage 3: Safe Meetup & Mutual Handover
    meetup_location_name text,
    meetup_lat double precision,
    meetup_lng double precision,
    meetup_scheduled_at timestamptz,
    finder_confirmed_handover boolean NOT NULL DEFAULT false,
    claimer_confirmed_handover boolean NOT NULL DEFAULT false,

    -- Timestamps
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- Prevent duplicate claims by the same user on the same report, and self-claiming
    CONSTRAINT unique_report_claimer UNIQUE (report_id, claimer_id),
    CONSTRAINT prevent_self_claim CHECK (finder_id <> claimer_id)
);

-- Indexes for fast lookup by report, finder, or claimer
CREATE INDEX IF NOT EXISTS idx_recovery_claims_report_id ON public.recovery_claims(report_id);
CREATE INDEX IF NOT EXISTS idx_recovery_claims_finder_id ON public.recovery_claims(finder_id);
CREATE INDEX IF NOT EXISTS idx_recovery_claims_claimer_id ON public.recovery_claims(claimer_id);
CREATE INDEX IF NOT EXISTS idx_recovery_claims_status ON public.recovery_claims(status);

-- Trigger: Keep updated_at current & handle mutual handover completion
CREATE OR REPLACE FUNCTION public.handle_recovery_claim_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    NEW.updated_at := now();

    -- When both parties confirm handover, complete the claim and auto-close the report
    IF NEW.finder_confirmed_handover = true
        AND NEW.claimer_confirmed_handover = true
        AND OLD.status <> 'completed' THEN

        NEW.status := 'completed';

        -- Mark the parent report as 'found'
        UPDATE public.reports
        SET status = 'found'
        WHERE id = NEW.report_id;

        -- Close any other competing open claims on this same report
        UPDATE public.recovery_claims
        SET status = 'rejected',
            rejection_reason = 'Pet has been reunited with its verified owner.'
        WHERE report_id = NEW.report_id
            AND id <> NEW.id
            AND status NOT IN ('completed', 'rejected', 'expired');
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_recovery_claim_update ON public.recovery_claims;
CREATE TRIGGER trg_recovery_claim_update
    BEFORE UPDATE ON public.recovery_claims
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_recovery_claim_update();

-- Enable Row-Level Security (RLS)
ALTER TABLE public.recovery_claims ENABLE ROW LEVEL SECURITY;

-- Policy: Both Finder and Claimer can view their own claims
CREATE POLICY "Participants can view their recovery claims"
    ON public.recovery_claims
    FOR SELECT
    USING (auth.uid() = finder_id OR auth.uid() = claimer_id);

-- Policy: Authenticated users can initiate a claim as the claimer (not on their own report)
CREATE POLICY "Users can create a recovery claim"
    ON public.recovery_claims
    FOR INSERT
    WITH CHECK (
        auth.uid() = claimer_id
        AND auth.uid() <> finder_id
    );

-- Policy: Both Finder and Claimer can update their active claim
CREATE POLICY "Participants can update their recovery claims"
    ON public.recovery_claims
    FOR UPDATE
    USING (auth.uid() = finder_id OR auth.uid() = claimer_id)
    WITH CHECK (auth.uid() = finder_id OR auth.uid() = claimer_id);

-- Policy: Claimer can withdraw/delete while still in Stage 1
CREATE POLICY "Claimer can cancel pending Stage 1 claim"
    ON public.recovery_claims
    FOR DELETE
    USING (auth.uid() = claimer_id AND current_stage = 1);

-- Enable Supabase Realtime for live stage updates between Finder & Claimer
ALTER PUBLICATION supabase_realtime ADD TABLE public.recovery_claims;

-- ============================================================================
--    Private Storage Bucket for Stage 2 Verification Photos & Documents
--    Folder convention: recovery-proofs/{claim_id}/{filename}
-- ============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('recovery-proofs', 'recovery-proofs', false)
ON CONFLICT (id) DO NOTHING;

-- Allow claim participants (finder or claimer of {claim_id}) to upload files
CREATE POLICY "Claim participants can upload recovery proofs"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'recovery-proofs'
        AND EXISTS (
            SELECT 1 FROM public.recovery_claims rc
            WHERE rc.id::text = (storage.foldername(name))[1]
                AND (rc.claimer_id = auth.uid() OR rc.finder_id = auth.uid())
        )
    );

-- Allow claim participants to view/create signed URLs for files in their claim folder
CREATE POLICY "Claim participants can view recovery proofs"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'recovery-proofs'
        AND EXISTS (
            SELECT 1 FROM public.recovery_claims rc
            WHERE rc.id::text = (storage.foldername(name))[1]
                AND (rc.claimer_id = auth.uid() OR rc.finder_id = auth.uid())
        )
    );

-- Allow claimer to delete their uploaded proof files if replacing them
CREATE POLICY "Claimer can delete own recovery proofs"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'recovery-proofs'
        AND EXISTS (
            SELECT 1 FROM public.recovery_claims rc
            WHERE rc.id::text = (storage.foldername(name))[1]
                AND rc.claimer_id = auth.uid()
        )
    );