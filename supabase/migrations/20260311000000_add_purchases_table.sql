-- Add purchases table for tracking clothing purchases

CREATE TABLE public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    brand TEXT,
    price DECIMAL(10,2) NOT NULL,
    category public.clothing_category,
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    image_url TEXT,
    notes TEXT,
    wardrobe_item_id UUID REFERENCES public.wardrobe_items(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_purchases_user_id ON public.purchases(user_id);
CREATE INDEX idx_purchases_purchase_date ON public.purchases(purchase_date DESC);
CREATE INDEX idx_purchases_category ON public.purchases(category);

-- RLS
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_manage_own_purchases"
ON public.purchases
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- updated_at trigger
CREATE TRIGGER update_purchases_updated_at
    BEFORE UPDATE ON public.purchases
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
