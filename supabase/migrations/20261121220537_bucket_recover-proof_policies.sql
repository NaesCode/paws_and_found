-- 1. Allow public/authenticated read access so Image.network & Finder preview work
CREATE POLICY "recovery_proofs_select"
ON storage.objects FOR SELECT
USING (bucket_id = 'recovery-proofs');

-- 2. Allow logged-in users to upload into their own userId folder
CREATE POLICY "recovery_proofs_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'recovery-proofs'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Allow upsert/overwrite in their own userId folder
CREATE POLICY "recovery_proofs_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'recovery-proofs'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Allow cleanup deletion when claim closes or is declined
CREATE POLICY "recovery_proofs_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'recovery-proofs'
  AND (storage.foldername(name))[1] = auth.uid()::text
);