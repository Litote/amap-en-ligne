#!/usr/bin/env bash
# Creates (or repairs) the instance OWNER account of a self-hosted instance:
#
#   ./create-owner.sh owner@example.org Prénom Nom
#
# 1. creates the GoTrue user through the admin API (email confirmed, app_metadata.roles = [OWNER]);
# 2. sets the password typed at the prompt (never passed on the command line);
# 3. upserts the matching `owner` row (owner_id = the GoTrue sub).
#
# Idempotent: re-running it on an existing account resets its password and OWNER role.
# Run from this directory once `docker compose up -d` is healthy. Mirrors `seed_user` + the owner
# insert of ../dev-init.sh. GoTrue's admin API is not exposed publicly (nginx answers 404 on
# /auth/admin): calls go through a throw-away curl container on the compose network.
set -euo pipefail

cd "$(dirname "$0")"

CURL_IMAGE="curlimages/curl:8.11.1"
NETWORK="amap-en-ligne"
GOTRUE_URL="http://gotrue:9999"

if [ $# -ne 3 ]; then
  echo "Usage: $0 <email> <first name> <last name>" >&2
  exit 1
fi
email="$1"
first_name="$2"
last_name="$3"

if ! [[ "$email" =~ ^[^@[:space:]\"\\]+@[^@[:space:]\"\\]+\.[^@[:space:]\"\\]+$ ]]; then
  echo "Invalid email: $email" >&2
  exit 1
fi

service_role_key=$(grep -E '^GOTRUE_SERVICE_ROLE_KEY=' .env | tail -n 1 | cut -d= -f2-)
if [ -z "$service_role_key" ]; then
  echo "GOTRUE_SERVICE_ROLE_KEY missing from .env (run ./generate-secrets.sh >> .env)" >&2
  exit 1
fi

# Same policy as the activation screen (back routing/PasswordPolicy.kt).
read -r -s -p "Password for ${email}: " password
echo
read -r -s -p "Confirm password: " password_confirm
echo
if [ "$password" != "$password_confirm" ]; then
  echo "Passwords do not match." >&2
  exit 1
fi
if [ ${#password} -lt 12 ] || ! [[ "$password" =~ [a-z] ]] || ! [[ "$password" =~ [A-Z] ]] || ! [[ "$password" =~ [0-9] ]]; then
  echo "The password needs at least 12 characters, one lowercase, one uppercase and one digit." >&2
  exit 1
fi

json_string() {
  local value=${1//\\/\\\\}
  value=${value//\"/\\\"}
  printf '"%s"' "$value"
}

# Calls the GoTrue admin API; the JSON body is read from stdin (keeps the password out of `ps`).
gotrue_admin() {
  local method="$1" path="$2"
  docker run --rm -i --network "$NETWORK" "$CURL_IMAGE" -sS -o /dev/null -w '%{http_code}' \
    -X "$method" "${GOTRUE_URL}${path}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${service_role_key}" \
    --data-binary @-
}

psql_exec() {
  docker compose exec -T postgres psql -U postgres -d postgres -v ON_ERROR_STOP=1 -qtA "$@"
}

find_user_id() {
  psql_exec -v email="$email" <<'SQL'
SELECT id FROM auth.users WHERE lower(email) = lower(:'email');
SQL
}

user_id=$(find_user_id)
if [ -z "$user_id" ]; then
  status=$(printf '{"email":%s,"email_confirm":true,"app_metadata":{"roles":["OWNER"]}}' "$(json_string "$email")" \
    | gotrue_admin POST /admin/users)
  if [ "$status" != "200" ] && [ "$status" != "201" ]; then
    echo "GoTrue user creation failed (HTTP $status)." >&2
    exit 1
  fi
  user_id=$(find_user_id)
fi

status=$(printf '{"password":%s,"email_confirm":true,"app_metadata":{"roles":["OWNER"]}}' "$(json_string "$password")" \
  | gotrue_admin PUT "/admin/users/${user_id}")
if [ "$status" != "200" ]; then
  echo "GoTrue user update failed (HTTP $status)." >&2
  exit 1
fi

psql_exec -v owner_id="$user_id" -v email="$email" -v first_name="$first_name" -v last_name="$last_name" <<'SQL'
INSERT INTO owner (owner_id, first_name, last_name, email, account_status, registered_at, updated_at)
VALUES (:'owner_id', :'first_name', :'last_name', :'email', 'ACTIVE',
        (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT, (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT)
ON CONFLICT (owner_id) DO UPDATE SET
  first_name     = EXCLUDED.first_name,
  last_name      = EXCLUDED.last_name,
  email          = EXCLUDED.email,
  account_status = 'ACTIVE',
  updated_at     = EXCLUDED.updated_at;
SQL

echo "Owner ${email} ready (id ${user_id}). Log in on the web app with this email and password."
