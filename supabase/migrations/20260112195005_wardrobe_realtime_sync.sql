-- Location: supabase/migrations/20260112195005_wardrobe_realtime_sync.sql
-- Schema Analysis: Database is empty - FRESH_PROJECT
-- Integration Type: New module creation for wardrobe management
-- Dependencies: None (fresh database)

-- 1. Create enum types for wardrobe items
CREATE TYPE public.clothing_category AS ENUM (
    'Tops',
    'Bottoms',
    'Shoes',
    'Outerwear',
    'Accessories',
    'Dresses',
    'Activewear'
);

-- 2. Create user_profiles table (intermediary for auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create wardrobe_items table
CREATE TABLE public.wardrobe_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    category public.clothing_category NOT NULL,
    brand TEXT,
    image_url TEXT,
    semantic_label TEXT,
    wear_count INTEGER DEFAULT 0,
    last_worn TIMESTAMPTZ,
    cost_per_wear DECIMAL(10,2),
    purchase_date DATE,
    purchase_price DECIMAL(10,2),
    notes TEXT,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create outfit_logs table for tracking outfit history
CREATE TABLE public.outfit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    outfit_name TEXT,
    worn_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    weather TEXT,
    occasion TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create outfit_items junction table
CREATE TABLE public.outfit_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outfit_id UUID REFERENCES public.outfit_logs(id) ON DELETE CASCADE NOT NULL,
    item_id UUID REFERENCES public.wardrobe_items(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(outfit_id, item_id)
);

-- 6. Create indexes for efficient queries
CREATE INDEX idx_wardrobe_items_user_id ON public.wardrobe_items(user_id);
CREATE INDEX idx_wardrobe_items_category ON public.wardrobe_items(category);
CREATE INDEX idx_wardrobe_items_created_at ON public.wardrobe_items(created_at DESC);
CREATE INDEX idx_outfit_logs_user_id ON public.outfit_logs(user_id);
CREATE INDEX idx_outfit_logs_worn_date ON public.outfit_logs(worn_date DESC);
CREATE INDEX idx_outfit_items_outfit_id ON public.outfit_items(outfit_id);
CREATE INDEX idx_outfit_items_item_id ON public.outfit_items(item_id);

-- 7. Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_items ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies - Pattern 1: Core user table
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 9. RLS Policies - Pattern 2: Simple user ownership
CREATE POLICY "users_manage_own_wardrobe_items"
ON public.wardrobe_items
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_outfit_logs"
ON public.outfit_logs
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 10. RLS Policies for outfit_items - Access through owned outfits
CREATE OR REPLACE FUNCTION public.user_owns_outfit(outfit_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.outfit_logs ol
    WHERE ol.id = outfit_uuid AND ol.user_id = auth.uid()
)
$$;

CREATE POLICY "users_manage_own_outfit_items"
ON public.outfit_items
FOR ALL
TO authenticated
USING (public.user_owns_outfit(outfit_id))
WITH CHECK (public.user_owns_outfit(outfit_id));

-- 11. Function to automatically create user profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN NEW;
END;
$$;

-- 12. Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 13. Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 14. Triggers for updated_at columns
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_wardrobe_items_updated_at
    BEFORE UPDATE ON public.wardrobe_items
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 15. Function to increment wear count when item is added to outfit
CREATE OR REPLACE FUNCTION public.increment_wear_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.wardrobe_items
    SET 
        wear_count = wear_count + 1,
        last_worn = CURRENT_TIMESTAMP
    WHERE id = NEW.item_id;
    RETURN NEW;
END;
$$;

-- 16. Trigger to increment wear count
CREATE TRIGGER on_outfit_item_created
    AFTER INSERT ON public.outfit_items
    FOR EACH ROW
    EXECUTE FUNCTION public.increment_wear_count();