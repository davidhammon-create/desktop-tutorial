ALTER TABLE public.cases ADD COLUMN IF NOT EXISTS instanz text DEFAULT '';
ALTER TABLE public.cases ADD COLUMN IF NOT EXISTS kernfrage text DEFAULT '';
ALTER TABLE public.cases ADD COLUMN IF NOT EXISTS fristen jsonb DEFAULT '[]'::jsonb;
ALTER TABLE public.cases ADD COLUMN IF NOT EXISTS kosten jsonb DEFAULT NULL;
ALTER TABLE public.cases ADD COLUMN IF NOT EXISTS user_id uuid DEFAULT NULL;
