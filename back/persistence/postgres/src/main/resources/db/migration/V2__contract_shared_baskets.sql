-- Shared baskets: groups of members sharing a single physical basket in alternation on a contract.
-- Embedded as a JSON list inside the Contract aggregate (parallel to coordinators / members).
ALTER TABLE public.contract
    ADD COLUMN shared_baskets jsonb DEFAULT '[]'::jsonb NOT NULL;
