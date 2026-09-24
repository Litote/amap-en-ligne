-- Persist the producer's basket-component catalog (ProductType.item_types), which was
-- previously dropped on write: inline SVG icons included, as on organization.item_types.
ALTER TABLE public.product_type
    ADD COLUMN item_types jsonb DEFAULT '[]'::jsonb NOT NULL;
