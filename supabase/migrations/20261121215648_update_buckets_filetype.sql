UPDATE storage.buckets
SET
  public = true,
  file_size_limit = 2097152, -- 2 MB per file
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf'
  ]
WHERE id = 'recovery-proofs';