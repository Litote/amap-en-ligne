-- When a member joined the instance (epoch millis, like owner.registered_at). Nullable:
-- members created before this column existed have no known registration date.
ALTER TABLE public.member
    ADD COLUMN registered_at bigint;
