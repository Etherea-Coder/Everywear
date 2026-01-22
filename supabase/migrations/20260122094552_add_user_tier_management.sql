-- Location: supabase/migrations/20260122094552_add_user_tier_management.sql
-- Schema Analysis: Existing user_profiles table with id, email, full_name, avatar_url, created_at, updated_at
-- Integration Type: Extension - Adding tier management columns
-- Dependencies: user_profiles table

-- Add tier management columns to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS tier TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS items_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_suggestions_used INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS items_limit INTEGER DEFAULT 30,
ADD COLUMN IF NOT EXISTS suggestions_limit INTEGER DEFAULT 10;

-- Add index for tier column for faster queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_tier ON public.user_profiles(tier);

-- Create function to check item limit based on tier
CREATE OR REPLACE FUNCTION public.check_item_limit_before_insert()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    current_count INTEGER;
    user_limit INTEGER;
BEGIN
    -- Get current count and limit for user
    SELECT items_count, items_limit 
    INTO current_count, user_limit
    FROM public.user_profiles 
    WHERE id = NEW.user_id;
    
    -- Check if limit exceeded
    IF current_count >= user_limit THEN
        RAISE EXCEPTION 'Item limit reached. Upgrade to premium for more items.';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger to enforce item limits
DROP TRIGGER IF EXISTS enforce_item_limit ON public.wardrobe_items;
CREATE TRIGGER enforce_item_limit
    BEFORE INSERT ON public.wardrobe_items
    FOR EACH ROW
    EXECUTE FUNCTION public.check_item_limit_before_insert();

-- Create function to increment items count
CREATE OR REPLACE FUNCTION public.increment_items_count()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.user_profiles
    SET items_count = items_count + 1
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$;

-- Create trigger to auto-increment items count
DROP TRIGGER IF EXISTS auto_increment_items_count ON public.wardrobe_items;
CREATE TRIGGER auto_increment_items_count
    AFTER INSERT ON public.wardrobe_items
    FOR EACH ROW
    EXECUTE FUNCTION public.increment_items_count();

-- Create function to decrement items count on delete
CREATE OR REPLACE FUNCTION public.decrement_items_count()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.user_profiles
    SET items_count = GREATEST(items_count - 1, 0)
    WHERE id = OLD.user_id;
    
    RETURN OLD;
END;
$$;

-- Create trigger to auto-decrement items count on delete
DROP TRIGGER IF EXISTS auto_decrement_items_count ON public.wardrobe_items;
CREATE TRIGGER auto_decrement_items_count
    AFTER DELETE ON public.wardrobe_items
    FOR EACH ROW
    EXECUTE FUNCTION public.decrement_items_count();

-- Create function to check suggestion limit
CREATE OR REPLACE FUNCTION public.can_request_suggestion(user_uuid UUID)
RETURNS BOOLEAN
SECURITY DEFINER
LANGUAGE sql
AS $$
    SELECT monthly_suggestions_used < suggestions_limit
    FROM public.user_profiles
    WHERE id = user_uuid;
$$;

-- Create function to increment suggestions count
CREATE OR REPLACE FUNCTION public.increment_suggestions_count(user_uuid UUID)
RETURNS VOID
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.user_profiles
    SET monthly_suggestions_used = monthly_suggestions_used + 1
    WHERE id = user_uuid;
END;
$$;

-- Update existing user profiles with default tier values
UPDATE public.user_profiles
SET 
    tier = COALESCE(tier, 'free'),
    items_count = COALESCE(items_count, 0),
    monthly_suggestions_used = COALESCE(monthly_suggestions_used, 0),
    items_limit = COALESCE(items_limit, 30),
    suggestions_limit = COALESCE(suggestions_limit, 10)
WHERE tier IS NULL;

-- Update items_count for existing users based on actual wardrobe items
UPDATE public.user_profiles up
SET items_count = (
    SELECT COUNT(*)
    FROM public.wardrobe_items wi
    WHERE wi.user_id = up.id
)
WHERE EXISTS (
    SELECT 1 FROM public.wardrobe_items WHERE user_id = up.id
);

-- Update items_limit for premium users (if tier column already has premium users)
UPDATE public.user_profiles
SET items_limit = 100
WHERE tier = 'premium';