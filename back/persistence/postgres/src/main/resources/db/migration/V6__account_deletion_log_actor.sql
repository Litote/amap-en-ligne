-- The actor of an account deletion may now be an organization Admin, not only an instance Owner.
ALTER TABLE public.account_deletion_log RENAME COLUMN actor_owner_id TO actor_id;
ALTER TABLE public.account_deletion_log ADD COLUMN actor_role text NOT NULL DEFAULT 'OWNER';
