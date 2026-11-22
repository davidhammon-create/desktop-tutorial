-- Drop existing permissive policies
DROP POLICY IF EXISTS "Allow all access to cases" ON public.cases;
DROP POLICY IF EXISTS "Allow all access to arguments" ON public.arguments;
DROP POLICY IF EXISTS "Allow all access to edges" ON public.edges;
DROP POLICY IF EXISTS "Allow all access to evidence" ON public.evidence;
DROP POLICY IF EXISTS "Allow all access to persons" ON public.persons;
-- Cases: authenticated users can do everything
CREATE POLICY "Authenticated users can manage cases" ON public.cases FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- Arguments
CREATE POLICY "Authenticated users can manage arguments" ON public.arguments FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- Edges
CREATE POLICY "Authenticated users can manage edges" ON public.edges FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- Evidence
CREATE POLICY "Authenticated users can manage evidence" ON public.evidence FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- Persons
CREATE POLICY "Authenticated users can manage persons" ON public.persons FOR ALL TO authenticated USING (true) WITH CHECK (true);
