#!/usr/bin/env bash
# Starts the local dev stack and seeds one test user per role.
# Run from the repo root or from any directory — uses the script's own location.
#
# Customise via env vars (all optional):
#   DEV_PASSWORD      default: pass1234
#   DEV_DOMAIN        default: example.com
#   GOTRUE_JWT_SECRET default: value from docker-compose.yml
#
# Users created (8 accounts; ADMIN/COORDINATOR/VOLUNTEER share organization "amap-dev",
# and PRODUCER is linked to that same organization via organization_producer).
#
# After sub/id unification: entity IDs equal the GoTrue subject (UUID).
# The backend resolves organizationId from the member table — it is no longer
# carried in the JWT. Only `roles` remain in app_metadata.
#
#   owner@DEV_DOMAIN                        roles: [OWNER]
#   admin@DEV_DOMAIN                        roles: [ADMIN]
#   producer@DEV_DOMAIN                     roles: [PRODUCER]
#   coordinator@DEV_DOMAIN                  roles: [COORDINATOR]
#   volunteer@DEV_DOMAIN                    roles: [VOLUNTEER]
#   admin-coordinator@DEV_DOMAIN            roles: [ADMIN, COORDINATOR]
#   coordinator-volunteer@DEV_DOMAIN        roles: [COORDINATOR, VOLUNTEER]
#   admin-coordinator-volunteer@DEV_DOMAIN  roles: [ADMIN, COORDINATOR, VOLUNTEER]
set -euo pipefail

COMPOSE_FILE="$(cd "$(dirname "$0")" && pwd)/docker-compose.yml"
GOTRUE_URL="http://localhost:9999"

DEV_PASSWORD="${DEV_PASSWORD:-pass1234}"
DEV_DOMAIN="${DEV_DOMAIN:-example.com}"
JWT_SECRET="${GOTRUE_JWT_SECRET:-dev-jwt-secret-change-me-dev-jwt-secret-change-me}"

# ---------------------------------------------------------------------------
# 1. Start the stack
# ---------------------------------------------------------------------------
docker compose -f "$COMPOSE_FILE" up -d

# ---------------------------------------------------------------------------
# 2. Wait for GoTrue
# ---------------------------------------------------------------------------
printf 'Waiting for GoTrue'
until curl -sf "${GOTRUE_URL}/health" > /dev/null 2>&1; do
  printf '.'
  sleep 1
done
printf ' ready.\n'

# ---------------------------------------------------------------------------
# 3. Seed the organization row in Postgres (fixed ID — safe before user UUIDs
#    are known). Waits for Flyway migrations to finish first.
# ---------------------------------------------------------------------------
printf 'Waiting for Flyway migrations to complete...\n'
docker compose -f "$COMPOSE_FILE" wait flyway > /dev/null

printf 'Seeding amap-dev organization row...\n'
docker compose -f "$COMPOSE_FILE" exec -T postgres \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<SQL
INSERT INTO organization (organization_id, name, contact_email)
VALUES ('amap-dev', 'AMAP Dev', 'contact@amap-dev.${DEV_DOMAIN}')
ON CONFLICT (organization_id) DO NOTHING;
SQL

# ---------------------------------------------------------------------------
# 3.5. Seed the server row (required for member join request approval)
# ---------------------------------------------------------------------------
printf 'Seeding server row...\n'
docker compose -f "$COMPOSE_FILE" exec -T postgres \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<SQL
INSERT INTO server (server_id, name, url)
VALUES ('server-dev', 'Dev Server', 'http://localhost:8080')
ON CONFLICT (server_id) DO NOTHING;
SQL

# ---------------------------------------------------------------------------
# 4. Generate an admin JWT (openssl + base64, no Python required)
# ---------------------------------------------------------------------------
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

HEADER=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
PAYLOAD=$(printf '{"role":"supabase_admin"}' | b64url)
SIGNING_INPUT="${HEADER}.${PAYLOAD}"
SIG=$(printf '%s' "$SIGNING_INPUT" \
      | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | b64url)
ADMIN_TOKEN="${SIGNING_INPUT}.${SIG}"

# ---------------------------------------------------------------------------
# 5. Seed one user per role
#    seed_user <email> <app_metadata_json>
#
#    Populates the global associative arrays USER_IDS[email]=sub and
#    USER_TOKENS[email]=access_token. The sub is the GoTrue user UUID and
#    is used downstream as the entity ID (owner_id / member_id /
#    producer_account_id) in Postgres — entity ID == sub by invariant.
# ---------------------------------------------------------------------------
declare -A USER_IDS
declare -A USER_TOKENS

seed_user() {
  local email="$1"
  local metadata="$2"

  # Create (idempotent — ignore 422 if already exists)
  curl -sf -X POST "${GOTRUE_URL}/signup" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${email}\",\"password\":\"${DEV_PASSWORD}\"}" \
    > /dev/null || true

  # Resolve id
  local user_id
  user_id=$(curl -sf "${GOTRUE_URL}/admin/users" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    | jq -r --arg e "$email" '.users[] | select(.email == $e) | .id')

  if [ -z "$user_id" ]; then
    echo "Error: user ${email} not found after signup." >&2
    exit 1
  fi

  # Set password + app_metadata + mark email as confirmed (idempotent).
  # email_confirm is required because docker-compose sets
  # GOTRUE_MAILER_AUTOCONFIRM=false, so /signup leaves users in an unconfirmed
  # state and the password grant returns 400 until email is confirmed.
  curl -sf -X PUT "${GOTRUE_URL}/admin/users/${user_id}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{\"password\":\"${DEV_PASSWORD}\",\"email_confirm\":true,\"app_metadata\":${metadata}}" \
    > /dev/null

  # Sign in and capture access token
  local access_token
  access_token=$(curl -sf -X POST "${GOTRUE_URL}/token?grant_type=password" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${email}\",\"password\":\"${DEV_PASSWORD}\"}" \
    | jq -r '.access_token')

  USER_IDS[$email]=$user_id
  USER_TOKENS[$email]=$access_token
}

# ---------------------------------------------------------------------------
# 6. Create users
#    Note: organizationId is no longer carried in the JWT. The backend
#    resolves it from the member table via AuthorizedScopeResolver.
#    Only `roles` remain in app_metadata.
# ---------------------------------------------------------------------------
printf '\nSeeding users...\n'

seed_user "owner@${DEV_DOMAIN}" \
  '{"roles":["OWNER"]}'

seed_user "admin@${DEV_DOMAIN}" \
  '{"roles":["ADMIN"]}'

seed_user "producer@${DEV_DOMAIN}" \
  '{"roles":["PRODUCER"]}'

seed_user "coordinator@${DEV_DOMAIN}" \
  '{"roles":["COORDINATOR"]}'

seed_user "volunteer@${DEV_DOMAIN}" \
  '{"roles":["VOLUNTEER"]}'

seed_user "admin-coordinator@${DEV_DOMAIN}" \
  '{"roles":["ADMIN","COORDINATOR"]}'

seed_user "coordinator-volunteer@${DEV_DOMAIN}" \
  '{"roles":["COORDINATOR","VOLUNTEER"]}'

seed_user "admin-coordinator-volunteer@${DEV_DOMAIN}" \
  '{"roles":["ADMIN","COORDINATOR","VOLUNTEER"]}'

# ---------------------------------------------------------------------------
# 7. Seed the matching Postgres rows using the GoTrue UUIDs as entity IDs.
#
#    After sub/id unification:
#      owner_id  = sub  (no separate `sub` column — dropped by V35)
#      member_id = sub  (no separate `sub` column — dropped by V35)
#      producer_account_id = sub of producer@DEV_DOMAIN
#
#    member rows also give the backend the organization mapping that
#    AuthorizedScopeResolver reads via findOrganizationIdBySub.
#    Idempotent — safe to re-run (ON CONFLICT DO UPDATE).
# ---------------------------------------------------------------------------
printf '\nSeeding owner / member / producer rows in Postgres...\n'
docker compose -f "$COMPOSE_FILE" exec -T postgres \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<SQL

-- Owner: owner_id == sub
INSERT INTO owner (
  owner_id, first_name, last_name, email, account_status,
  registered_at, updated_at
)
VALUES (
  '${USER_IDS[owner@${DEV_DOMAIN}]}',
  'Olivier',
  'Owner',
  'owner@${DEV_DOMAIN}',
  'ACTIVE',
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
)
ON CONFLICT (owner_id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name  = EXCLUDED.last_name,
  email      = EXCLUDED.email,
  updated_at = EXCLUDED.updated_at;

-- Producer account: producer_account_id == sub of producer@DEV_DOMAIN
INSERT INTO producer_account (
  producer_account_id, name, created_instant, last_updated_instant
)
VALUES (
  '${USER_IDS[producer@${DEV_DOMAIN}]}',
  'Producteur Dev',
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
)
ON CONFLICT (producer_account_id) DO NOTHING;

INSERT INTO organization_producer (
  organization_id, producer_account_id, association_instant, status
)
VALUES (
  'amap-dev',
  '${USER_IDS[producer@${DEV_DOMAIN}]}',
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  'ACTIVE'
)
ON CONFLICT (organization_id, producer_account_id) DO NOTHING;

-- Producer without account (NO_ACCOUNT mode)
INSERT INTO producer_account (
  producer_account_id, name, management_mode, created_instant, last_updated_instant, active_status
)
VALUES (
  'prod-no-account-dev',
  'Producteur Sans Compte',
  'NO_ACCOUNT',
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  true
)
ON CONFLICT (producer_account_id) DO NOTHING;

INSERT INTO organization_producer (
  organization_id, producer_account_id, association_instant, status
)
VALUES (
  'amap-dev',
  'prod-no-account-dev',
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  'ACTIVE'
)
ON CONFLICT (organization_id, producer_account_id) DO NOTHING;

-- Product type for NO_ACCOUNT producer with 2 basket sizes
INSERT INTO product_type (
  producer_account_id, product_type_id, name, description, supported_basket_sizes
)
VALUES (
  'prod-no-account-dev',
  'prod-type-no-account-dev',
  'Légumes de saison',
  'Assortiment de légumes frais de saison',
  '[{"name":"Petit panier"},{"name":"Grand panier"}]'::jsonb
)
ON CONFLICT (producer_account_id, product_type_id) DO NOTHING;

-- Link product to organization for NO_ACCOUNT producer
INSERT INTO organization_product (
  organization_id, producer_account_id, product_type_id, name, supported_basket_sizes, description
)
VALUES (
  'amap-dev',
  'prod-no-account-dev',
  'prod-type-no-account-dev',
  'Légumes de saison',
  '[{"name":"Petit panier"},{"name":"Grand panier"}]',
  'Assortiment de légumes frais de saison'
)
ON CONFLICT (organization_id, producer_account_id, product_type_id) DO NOTHING;

-- Delivery template with early volunteer arrival time (30 min before) and early slot (45 min before)
INSERT INTO delivery_template (
  delivery_template_id, organization_id, name, standard_start_time, standard_end_time,
  desired_volunteer_count, volunteer_arrival_time, early_slot
)
VALUES (
  'dlv-tmpl-no-account-dev',
  'amap-dev',
  'Modèle standard (Prod sans compte)',
  '10:00',
  '11:30',
  3,
  '09:30',
  '{"arrival_time":"09:15","explanation":"Créneau anticipé","max_volunteers":2}'
)
ON CONFLICT (delivery_template_id) DO NOTHING;

-- Member rows: member_id == sub. AuthorizedScopeResolver uses member_id to
-- resolve the organization for ADMIN/COORDINATOR/VOLUNTEER callers.
WITH member_seed(member_id, first_name, last_name, email, roles_array) AS (
  VALUES
    ('${USER_IDS[admin@${DEV_DOMAIN}]}',                        'Alice',    'Admin',     'admin@${DEV_DOMAIN}',                        ARRAY['ADMIN']::TEXT[]),
    ('${USER_IDS[coordinator@${DEV_DOMAIN}]}',                  'Carl',     'Coord',     'coordinator@${DEV_DOMAIN}',                  ARRAY['COORDINATOR']::TEXT[]),
    ('${USER_IDS[volunteer@${DEV_DOMAIN}]}',                    'Victor',   'Volunteer', 'volunteer@${DEV_DOMAIN}',                    ARRAY['VOLUNTEER']::TEXT[]),
    ('${USER_IDS[producer@${DEV_DOMAIN}]}',                     'Pierre',   'Producer',  'producer@${DEV_DOMAIN}',                     ARRAY['PRODUCER']::TEXT[]),
    ('${USER_IDS[admin-coordinator@${DEV_DOMAIN}]}',            'Anne',     'AdminCoord','admin-coordinator@${DEV_DOMAIN}',            ARRAY['ADMIN','COORDINATOR']::TEXT[]),
    ('${USER_IDS[coordinator-volunteer@${DEV_DOMAIN}]}',        'Celine',   'CoordVol',  'coordinator-volunteer@${DEV_DOMAIN}',        ARRAY['COORDINATOR','VOLUNTEER']::TEXT[]),
    ('${USER_IDS[admin-coordinator-volunteer@${DEV_DOMAIN}]}',  'Auguste',  'AllRoles',  'admin-coordinator-volunteer@${DEV_DOMAIN}',  ARRAY['ADMIN','COORDINATOR','VOLUNTEER']::TEXT[])
)
INSERT INTO member (
  member_id, organization_id, roles, active_status,
  first_name, last_name, email, account_status,
  member_settings, member_preferences, user_preferences, user_settings,
  created_instant, last_updated_instant
)
SELECT
  member_id,
  'amap-dev',
  roles_array,
  true,
  first_name,
  last_name,
  email,
  'ACTIVE',
  '{"delivery_reminders":{"days_before":1,"reminder_time":"08:00"},"accessibility_options":{"high_contrast":false,"large_text":false,"screen_reader":false},"last_updated_instant":"1970-01-01T00:00:00Z"}'::jsonb,
  '{"delivery_reminders_enabled":true,"volunteer_alerts_enabled":true,"last_updated_instant":"1970-01-01T00:00:00Z"}'::jsonb,
  '{"email_notifications_enabled":true,"push_notifications_enabled":true,"last_updated_instant":"1970-01-01T00:00:00Z"}'::jsonb,
  '{"language":"fr","timezone":"Europe/Paris","server_id":"server-dev","last_updated_instant":"1970-01-01T00:00:00Z"}'::jsonb,
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
FROM member_seed
ON CONFLICT (member_id) DO UPDATE SET
  roles              = EXCLUDED.roles,
  first_name         = EXCLUDED.first_name,
  last_name          = EXCLUDED.last_name,
  email              = EXCLUDED.email,
  last_updated_instant = EXCLUDED.last_updated_instant;
SQL

# ---------------------------------------------------------------------------
# 8. Summary
# ---------------------------------------------------------------------------
print_user() {
  local label="$1"
  local email="$2"
  printf '\n%-12s %s  (id: %s)\n  token: %s\n' \
    "$label" "$email" "${USER_IDS[$email]}" "${USER_TOKENS[$email]}"
}

printf '\n%s\n' "$(printf '%.0s─' {1..72})"
printf 'Dev users (password: %s)\n' "$DEV_PASSWORD"
printf '%s\n' "$(printf '%.0s─' {1..72})"
print_user "OWNER"             "owner@${DEV_DOMAIN}"
print_user "ADMIN"             "admin@${DEV_DOMAIN}"
print_user "PRODUCER"          "producer@${DEV_DOMAIN}"
print_user "COORDINATOR"       "coordinator@${DEV_DOMAIN}"
print_user "VOLUNTEER"         "volunteer@${DEV_DOMAIN}"
print_user "ADMIN+COORD"       "admin-coordinator@${DEV_DOMAIN}"
print_user "COORD+VOLUNT"      "coordinator-volunteer@${DEV_DOMAIN}"
print_user "ADMIN+COORD+VOLUNT" "admin-coordinator-volunteer@${DEV_DOMAIN}"
printf '\n'
