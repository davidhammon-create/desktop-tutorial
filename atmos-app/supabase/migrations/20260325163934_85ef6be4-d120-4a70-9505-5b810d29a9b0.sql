ALTER TABLE public.persons
  ADD COLUMN narcissism numeric DEFAULT 0,
  ADD COLUMN cognitive_empathy numeric DEFAULT 50,
  ADD COLUMN affective_empathy numeric DEFAULT 50,
  ADD COLUMN manipulation_skill numeric DEFAULT 0,
  ADD COLUMN coldness numeric DEFAULT 0;
