ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS style_preferences JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS work_environment TEXT,
ADD COLUMN IF NOT EXISTS social_frequency TEXT,
ADD COLUMN IF NOT EXISTS climate TEXT,
ADD COLUMN IF NOT EXISTS purchase_frequency REAL DEFAULT 3.0,
ADD COLUMN IF NOT EXISTS budget_consciousness REAL DEFAULT 3.0,
ADD COLUMN IF NOT EXISTS environmental_impact REAL DEFAULT 3.0;
