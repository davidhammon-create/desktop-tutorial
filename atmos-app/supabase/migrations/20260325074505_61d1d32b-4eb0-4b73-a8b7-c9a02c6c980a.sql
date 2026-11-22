CREATE POLICY "Allow anonymous uploads" ON storage.objects FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'business-files');
CREATE POLICY "Allow anonymous reads" ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = 'business-files');
