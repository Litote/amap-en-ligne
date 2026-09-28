-- A pending invitation is unique per email regardless of letter case
-- ("Alice@x.fr" and "alice@x.fr" are the same person), like the member and
-- join-request email checks.
DROP INDEX IF EXISTS public.member_invitation_unique_pending_email;
CREATE UNIQUE INDEX member_invitation_unique_pending_email
    ON public.member_invitation USING btree (lower(email))
    WHERE (status = 'PENDING_ACTIVATION'::text);
