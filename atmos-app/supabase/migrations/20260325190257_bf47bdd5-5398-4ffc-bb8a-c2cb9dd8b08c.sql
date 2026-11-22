ALTER TABLE public.business_scenarios
  ADD COLUMN outcome_rating integer DEFAULT NULL,
  ADD COLUMN outcome_notes text DEFAULT '' NOT NULL,
  ADD COLUMN outcome_date timestamptz DEFAULT NULL;
ALTER TABLE public.cases
  ADD COLUMN outcome_rating integer DEFAULT NULL,
  ADD COLUMN outcome_notes text DEFAULT '' NOT NULL,
  ADD COLUMN outcome_date timestamptz DEFAULT NULL;
