#!/usr/bin/env sh
# Prints fresh secrets for a new instance, in `.env` format:
#
#   ./generate-secrets.sh >> .env
#
# - POSTGRES_PASSWORD: hex, so it can be embedded as-is in GoTrue's database URL.
# - GOTRUE_JWT_SECRET: HS256 key shared by GoTrue (signs tokens) and the back (verifies them).
# - GOTRUE_SERVICE_ROLE_KEY: long-lived JWT (role=service_role) signed with that secret, used by
#   the back and create-owner.sh to call GoTrue's admin API. Same claims as the dev Gradle task
#   `:deploy:jvm:generateServiceRoleToken`, without requiring a JDK.
#
# Run it once: regenerating GOTRUE_JWT_SECRET invalidates every session, and POSTGRES_PASSWORD is
# only applied by Postgres on the first start (empty volume).
# Requires: openssl.
set -eu

command -v openssl > /dev/null || { echo "openssl is required" >&2; exit 1; }

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

postgres_password=$(openssl rand -hex 24)
jwt_secret=$(openssl rand -hex 32)

now=$(date +%s)
expires=$((now + 3650 * 24 * 3600))
header=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
payload=$(printf '{"role":"service_role","iat":%s,"exp":%s}' "$now" "$expires" | b64url)
signature=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -hmac "$jwt_secret" -binary | b64url)

echo "POSTGRES_PASSWORD=${postgres_password}"
echo "GOTRUE_JWT_SECRET=${jwt_secret}"
echo "GOTRUE_SERVICE_ROLE_KEY=${header}.${payload}.${signature}"
