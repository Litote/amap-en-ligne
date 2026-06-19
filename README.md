# amap-en-ligne

## Test entrypoints

```bash
# Full repository checks (back + front composite build)
./gradlew check

# Acceptance suites (server + Flutter)
./gradlew acceptanceTest

# Flutter-specific shortcuts exposed at the repository root
./gradlew frontTest
./gradlew frontAcceptanceTest
```

Acceptance scenarios are documented in [`acceptance/README.md`](acceptance/README.md) and stored under [`acceptance/scenarios/`](acceptance/scenarios/).

## User data export

Authenticated users can export their local offline cache from the **Preferences** screen. The app packages the current local SQLite database into a `.zip` archive containing `amap_en_ligne.sqlite`; on web it downloads in the browser, and on native platforms it is saved to the device downloads directory when available.

## Direction: federated instances

The long-term target is a **federated** model where different users may belong to different AMAP servers/instances. The current front-end server preset list is therefore temporary bootstrap infrastructure. The intended direction is per-instance discovery (for example via a `/.well-known/...` document) plus cached local config, rather than a permanent server list shipped in the app binary.

## Local GoTrue dev flow

This project can run locally with the JVM backend, Postgres, and a self-hosted GoTrue.

Start the auth/database stack:

```bash
docker compose -f back/deploy/jvm/docker-compose.yml up -d
cp back/deploy/jvm/.env.example back/deploy/jvm/.env
./gradlew :deploy:jvm:run
```

### 1. Create a local GoTrue user

```bash
SIGNUP_RESPONSE=$(curl -s -X POST http://localhost:9999/signup \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"password123"}')

echo "$SIGNUP_RESPONSE" | jq
```

GoTrue returns an `access_token` right away because email confirmation is disabled in local dev.

### 2. Verify password login

```bash
curl -s -X POST 'http://localhost:9999/token?grant_type=password' \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq
```

If this returns a JSON payload containing `access_token`, the same `POST /token` flow used by Flutter web is working.

### 3. Extract the GoTrue user id

The admin API needs the GoTrue user id. The easiest local-dev path is to read the JWT `sub` claim from the signup token:

```bash
ACCESS_TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.access_token')

USER_ID=$(python - <<'PY' "$ACCESS_TOKEN"
import base64
import json
import sys

token = sys.argv[1]
payload = token.split(".")[1]
payload += "=" * (-len(payload) % 4)
claims = json.loads(base64.urlsafe_b64decode(payload))
print(claims["sub"])
PY
)

echo "$USER_ID"
```

### 4. Set `app_metadata.producer_account_id`

The JVM backend resolves the tenant from `app_metadata.producer_account_id`, so a freshly created GoTrue user is not enough on its own.

`/admin/users/*` expects an admin JWT signed with `GOTRUE_JWT_SECRET`. `GOTRUE_OPERATOR_TOKEN` is not the right bearer token for this endpoint.

```bash
export GOTRUE_JWT_SECRET=dev-jwt-secret-change-me-dev-jwt-secret-change-me

ADMIN_TOKEN=$(python - <<'PY' "$GOTRUE_JWT_SECRET"
import base64
import hashlib
import hmac
import json
import sys

secret = sys.argv[1].encode()
header = {"alg": "HS256", "typ": "JWT"}
payload = {"role": "supabase_admin"}

def b64url(data):
    raw = json.dumps(data, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).rstrip(b"=")

signing_input = b".".join((b64url(header), b64url(payload)))
signature = hmac.new(secret, signing_input, hashlib.sha256).digest()
token = signing_input + b"." + base64.urlsafe_b64encode(signature).rstrip(b"=")
print(token.decode())
PY
)

curl -s -X PUT "http://localhost:9999/admin/users/$USER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "app_metadata": {
      "producer_account_id": "producer-dev",
      "roles": ["PRODUCER"]
    }
  }' \
  | jq
```

Use a `producer_account_id` that matches the tenant you expect to hit in the backend.

### 5. Mint a fresh token with the new claims

Update the user first, then sign in again so the new access token contains the updated `app_metadata`:

```bash
curl -s -X POST 'http://localhost:9999/token?grant_type=password' \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq
```

At that point:

- GoTrue login works locally.
- The returned access token carries `app_metadata.producer_account_id`.
- The JVM backend can resolve the tenant from the token.
- The Flutter web `POST /token` flow should succeed against the same GoTrue instance.
