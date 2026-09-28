-- Pre-create schemas that downstream containers (GoTrue) expect to already
-- exist before they run their own migrations.
--
-- This file is mounted into Postgres' /docker-entrypoint-initdb.d/ and runs
-- exactly once, on first DB initialization (when the data volume is empty).
-- After that, the schemas persist on disk and this script is ignored.
--
-- A real Supabase deployment provisions these via its installer; we mirror
-- the bare minimum needed for the JVM dev stack.

CREATE SCHEMA IF NOT EXISTS auth;
