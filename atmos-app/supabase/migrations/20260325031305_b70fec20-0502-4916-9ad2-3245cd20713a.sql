-- Create storage bucket for business scenario files
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'business-files',
  'business-files',
  false,
  20971520,
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel', 'text/csv', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword', 'text/plain', 'application/json', 'application/xml']
);
-- RLS: authenticated users can upload to their own folder
CREATE POLICY "Users can upload business files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'business-files' AND (storage.foldername(name))[1] = auth.uid()::text);
-- RLS: users can read their own files
CREATE POLICY "Users can read own business files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'business-files' AND (storage.foldername(name))[1] = auth.uid()::text);
-- RLS: users can delete their own files
CREATE POLICY "Users can delete own business files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'business-files' AND (storage.foldername(name))[1] = auth.uid()::text);
