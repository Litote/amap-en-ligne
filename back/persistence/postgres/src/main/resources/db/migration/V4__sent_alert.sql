-- Idempotency log of the alerts sent by scheduled jobs (volunteer shortage alerts).
-- sent_at is epoch millis; rows older than the retention are purged by the job.
CREATE TABLE public.sent_alert (
    alert_key text PRIMARY KEY,
    sent_at bigint NOT NULL
);
