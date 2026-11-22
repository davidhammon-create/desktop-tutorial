-- Fix RLS on cases to use user_id
DROP POLICY IF EXISTS "Authenticated users can manage cases" ON public.cases;
CREATE POLICY "Users can manage own cases" ON public.cases FOR ALL TO authenticated
  USING (user_id = auth.uid() OR user_id IS NULL)
  WITH CHECK (user_id = auth.uid());
-- Fix RLS on arguments to scope by case owner
DROP POLICY IF EXISTS "Authenticated users can manage arguments" ON public.arguments;
CREATE POLICY "Users can manage own arguments" ON public.arguments FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = arguments.case_id AND (cases.user_id = auth.uid() OR cases.user_id IS NULL)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = arguments.case_id AND cases.user_id = auth.uid()));
-- Fix RLS on edges
DROP POLICY IF EXISTS "Authenticated users can manage edges" ON public.edges;
CREATE POLICY "Users can manage own edges" ON public.edges FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = edges.case_id AND (cases.user_id = auth.uid() OR cases.user_id IS NULL)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = edges.case_id AND cases.user_id = auth.uid()));
-- Fix RLS on evidence
DROP POLICY IF EXISTS "Authenticated users can manage evidence" ON public.evidence;
CREATE POLICY "Users can manage own evidence" ON public.evidence FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = evidence.case_id AND (cases.user_id = auth.uid() OR cases.user_id IS NULL)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = evidence.case_id AND cases.user_id = auth.uid()));
-- Fix RLS on persons
DROP POLICY IF EXISTS "Authenticated users can manage persons" ON public.persons;
CREATE POLICY "Users can manage own persons" ON public.persons FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = persons.case_id AND (cases.user_id = auth.uid() OR cases.user_id IS NULL)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.cases WHERE cases.id = persons.case_id AND cases.user_id = auth.uid()));
