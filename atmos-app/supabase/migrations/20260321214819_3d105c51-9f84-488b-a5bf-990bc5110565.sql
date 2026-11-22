-- Cases table
CREATE TABLE public.cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  number text DEFAULT '',
  court text DEFAULT '',
  type text DEFAULT '',
  goal text DEFAULT '',
  status text DEFAULT 'Vorbereitung',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
-- Arguments table
CREATE TABLE public.arguments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  side text NOT NULL CHECK (side IN ('own', 'opp')),
  label text NOT NULL,
  strength numeric DEFAULT 5,
  content text DEFAULT '',
  description text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
-- Edges table
CREATE TABLE public.edges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  from_arg_id uuid NOT NULL REFERENCES public.arguments(id) ON DELETE CASCADE,
  to_arg_id uuid NOT NULL REFERENCES public.arguments(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('supports', 'weakens', 'exclude'))
);
-- Evidence table
CREATE TABLE public.evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  argument_id uuid NOT NULL REFERENCES public.arguments(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text DEFAULT '',
  type text DEFAULT '',
  validity numeric DEFAULT 50,
  strength numeric DEFAULT 5
);
-- Persons table
CREATE TABLE public.persons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('Richter', 'Zeuge')),
  party text,
  court text DEFAULT '',
  historical_cases int DEFAULT 0,
  historical_consistency numeric DEFAULT 50,
  prior_contradictions int DEFAULT 0,
  plaintiff_win_rate numeric,
  settle_rate numeric,
  avg_duration text,
  conflict_of_interest numeric DEFAULT 0,
  hidden_motive numeric DEFAULT 0,
  competence_level numeric DEFAULT 50,
  self_preservation numeric DEFAULT 0,
  loyalty_signals numeric DEFAULT 0,
  fear_factor numeric DEFAULT 0,
  legal_levers jsonb DEFAULT '[]',
  psych_levers jsonb DEFAULT '[]',
  question_modules jsonb DEFAULT '[]',
  past_case_notes text DEFAULT ''
);
-- Enable RLS on all tables
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.arguments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
-- Public access policies (no auth yet)
CREATE POLICY "Allow all access to cases" ON public.cases FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to arguments" ON public.arguments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to edges" ON public.edges FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to evidence" ON public.evidence FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to persons" ON public.persons FOR ALL USING (true) WITH CHECK (true);
-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;
CREATE TRIGGER update_cases_updated_at
  BEFORE UPDATE ON public.cases
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
