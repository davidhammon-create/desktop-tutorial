-- Business scenarios table
CREATE TABLE public.business_scenarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL DEFAULT '',
  description text NOT NULL DEFAULT '',
  category text NOT NULL DEFAULT 'Vertragsmanagement',
  company text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'Entwurf',
  selected_option_id text,
  notes text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.business_scenarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own scenarios"
  ON public.business_scenarios FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
-- Business options table (stores full option data as JSONB for flexibility)
CREATE TABLE public.business_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id uuid REFERENCES public.business_scenarios(id) ON DELETE CASCADE NOT NULL,
  option_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.business_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own options"
  ON public.business_options FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.business_scenarios bs
    WHERE bs.id = scenario_id AND bs.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.business_scenarios bs
    WHERE bs.id = scenario_id AND bs.user_id = auth.uid()
  ));
-- Trigger for updated_at
CREATE TRIGGER update_business_scenarios_updated_at
  BEFORE UPDATE ON public.business_scenarios
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_business_options_updated_at
  BEFORE UPDATE ON public.business_options
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
