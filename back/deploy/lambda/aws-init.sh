#!/usr/bin/env bash
# Seeds the AWS dev environment with one test user per role.
# Run from the repo root or from any directory — uses the script's own location.
#
# Customise via env vars (all optional if Terraform outputs are available):
#   DYNAMO_TABLE_NAME      default: terraform output dynamo_table_name
#   COGNITO_USER_POOL_ID   default: terraform output cognito_user_pool_id
#   COGNITO_CLIENT_ID      default: terraform output cognito_client_id
#   AWS_REGION             default: eu-west-3
#   INFRA_DIR              default: <script>/../../../infra
#   DEV_PASSWORD           default: Pass1234567890
#   DEV_DOMAIN             default: example.com
#
# Users created (8 accounts; ADMIN/COORDINATOR/VOLUNTEER share organization "amap-dev",
# and PRODUCER is linked to that same organization via their Cognito sub):
#   owner@example.com                        roles: [OWNER]                           (instance-level)
#   admin@example.com                        roles: [ADMIN]                           organization_id: amap-dev
#   producer@example.com                     roles: [PRODUCER]                        producer_account_id: <sub>
#   coordinator@example.com                  roles: [COORDINATOR]                     organization_id: amap-dev
#   volunteer@example.com                    roles: [VOLUNTEER]                       organization_id: amap-dev
#   admin-coordinator@example.com            roles: [ADMIN, COORDINATOR]              organization_id: amap-dev
#   coordinator-volunteer@example.com        roles: [COORDINATOR, VOLUNTEER]          organization_id: amap-dev
#   admin-coordinator-volunteer@example.com  roles: [ADMIN, COORDINATOR, VOLUNTEER]   organization_id: amap-dev
#
# NOTE: In the Lambda/Cognito deployment, producerAccountId == Cognito sub by invariant
# (AuthorizedScopeResolver). The producer's sub is therefore used as the DynamoDB
# ProducerAccount id and embedded in the Organization.producers list.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="${INFRA_DIR:-$(cd "$SCRIPT_DIR/../../../infra" && pwd)}"
REGION="${AWS_REGION:-eu-west-3}"
DEV_PASSWORD="${DEV_PASSWORD:-Pass1234567890}"
DEV_DOMAIN="${DEV_DOMAIN:-example.com}"

resolve_tf() {
  terraform -chdir="$INFRA_DIR" output -raw "$1" 2>/dev/null || true
}

resolve_aws() {
  local key="$1"
  case "$key" in
    dynamo_table_name)
      aws dynamodb describe-table --table-name "data" --region "$REGION" \
        --query 'Table.TableName' --output text 2>/dev/null || true ;;
    cognito_user_pool_id)
      aws cognito-idp list-user-pools --max-results 60 --region "$REGION" \
        --query 'UserPools[?starts_with(Name, `amap-en-ligne`)].Id | [0]' \
        --output text 2>/dev/null | grep -v None || true ;;
    cognito_client_id)
      local pool_id="${USER_POOL_ID:-}"
      [ -z "$pool_id" ] && return
      aws cognito-idp list-user-pool-clients --user-pool-id "$pool_id" --region "$REGION" \
        --query 'UserPoolClients[0].ClientId' --output text 2>/dev/null || true ;;
  esac
}

TABLE_NAME="${DYNAMO_TABLE_NAME:-$(resolve_tf dynamo_table_name)}"
TABLE_NAME="${TABLE_NAME:-$(resolve_aws dynamo_table_name)}"
USER_POOL_ID="${COGNITO_USER_POOL_ID:-$(resolve_tf cognito_user_pool_id)}"
USER_POOL_ID="${USER_POOL_ID:-$(resolve_aws cognito_user_pool_id)}"
CLIENT_ID="${COGNITO_CLIENT_ID:-$(resolve_tf cognito_client_id)}"
CLIENT_ID="${CLIENT_ID:-$(resolve_aws cognito_client_id)}"

if [ -z "$TABLE_NAME" ] || [ -z "$USER_POOL_ID" ] || [ -z "$CLIENT_ID" ]; then
  printf 'ERROR: TABLE_NAME, USER_POOL_ID, and CLIENT_ID could not be resolved automatically.\n' >&2
  printf '\nSet them explicitly before running this script:\n' >&2
  printf '  export DYNAMO_TABLE_NAME=$(terraform -chdir=%s output -raw dynamo_table_name)\n' "$INFRA_DIR" >&2
  printf '  export COGNITO_USER_POOL_ID=$(terraform -chdir=%s output -raw cognito_user_pool_id)\n' "$INFRA_DIR" >&2
  printf '  export COGNITO_CLIENT_ID=$(terraform -chdir=%s output -raw cognito_client_id)\n' "$INFRA_DIR" >&2
  printf '  ./aws-init.sh\n' >&2
  exit 1
fi

# boto3 is required for DynamoDB seeding — install if missing.
if ! python3 -c "import boto3" 2>/dev/null; then
  printf 'boto3 not found — installing...\n'
  pip3 install --user boto3 -q
fi

printf 'TABLE:    %s\n' "$TABLE_NAME"
printf 'POOL:     %s\n' "$USER_POOL_ID"
printf 'CLIENT:   %s\n' "$CLIENT_ID"
printf 'REGION:   %s\n' "$REGION"

# ---------------------------------------------------------------------------
# 1. Helpers
# ---------------------------------------------------------------------------

# create_user <email> <group> [<group> ...]
# Creates the Cognito user (idempotent), sets permanent password, adds to groups.
create_user() {
  local email="$1"
  shift
  local groups=("$@")

  aws cognito-idp admin-create-user \
    --user-pool-id "$USER_POOL_ID" \
    --username "$email" \
    --message-action SUPPRESS \
    --region "$REGION" \
    > /dev/null 2>&1 || true   # ignore UsernameExistsException

  aws cognito-idp admin-set-user-password \
    --user-pool-id "$USER_POOL_ID" \
    --username "$email" \
    --password "$DEV_PASSWORD" \
    --permanent \
    --region "$REGION"

  for group in "${groups[@]}"; do
    aws cognito-idp admin-add-user-to-group \
      --user-pool-id "$USER_POOL_ID" \
      --username "$email" \
      --group-name "$group" \
      --region "$REGION" \
      > /dev/null 2>&1 || true  # ignore if already in group
  done
}

get_sub() {
  aws cognito-idp admin-get-user \
    --user-pool-id "$USER_POOL_ID" \
    --username "$1" \
    --region "$REGION" \
    --query 'UserAttributes[?Name==`sub`].Value | [0]' \
    --output text
}

get_token() {
  aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id "$CLIENT_ID" \
    --auth-parameters "USERNAME=${1},PASSWORD=${DEV_PASSWORD}" \
    --region "$REGION" \
    --query 'AuthenticationResult.AccessToken' \
    --output text
}

# ---------------------------------------------------------------------------
# 2. Create Cognito users
# ---------------------------------------------------------------------------
printf '\nSeeding Cognito users...\n'

create_user "owner@${DEV_DOMAIN}"                        "OWNER"
create_user "admin@${DEV_DOMAIN}"                        "ADMIN"
create_user "producer@${DEV_DOMAIN}"                     "PRODUCER"
create_user "coordinator@${DEV_DOMAIN}"                  "COORDINATOR"
create_user "volunteer@${DEV_DOMAIN}"                    "VOLUNTEER"
create_user "admin-coordinator@${DEV_DOMAIN}"            "ADMIN" "COORDINATOR"
create_user "coordinator-volunteer@${DEV_DOMAIN}"        "COORDINATOR" "VOLUNTEER"
create_user "admin-coordinator-volunteer@${DEV_DOMAIN}"  "ADMIN" "COORDINATOR" "VOLUNTEER"

# ---------------------------------------------------------------------------
# 3. Resolve Cognito subs (used as DynamoDB keys)
# ---------------------------------------------------------------------------
printf 'Resolving Cognito subs...\n'

OWNER_SUB=$(get_sub "owner@${DEV_DOMAIN}")
ADMIN_SUB=$(get_sub "admin@${DEV_DOMAIN}")
PRODUCER_SUB=$(get_sub "producer@${DEV_DOMAIN}")
COORDINATOR_SUB=$(get_sub "coordinator@${DEV_DOMAIN}")
VOLUNTEER_SUB=$(get_sub "volunteer@${DEV_DOMAIN}")
ADMIN_COORDINATOR_SUB=$(get_sub "admin-coordinator@${DEV_DOMAIN}")
COORDINATOR_VOLUNTEER_SUB=$(get_sub "coordinator-volunteer@${DEV_DOMAIN}")
ADMIN_COORDINATOR_VOLUNTEER_SUB=$(get_sub "admin-coordinator-volunteer@${DEV_DOMAIN}")

# ---------------------------------------------------------------------------
# 4. Seed DynamoDB
#    Key conventions (MemberSyncDynamoDAO / OwnerDynamoDAO / ProducerAccountSyncDynamoDAO):
#      - memberId == sub (sk of MEMBER# rows, and MEMBER_SUB lookup)
#      - ownerId  == sub (sk of OWNER row)
#      - producerAccountId == sub (AuthorizedScopeResolver invariant for PRODUCER role)
#    Instants embedded in JSON strings use ISO-8601; top-level instants use epoch-ms N type.
# ---------------------------------------------------------------------------
printf '\nSeeding DynamoDB table %s...\n' "$TABLE_NAME"

AWS_REGION_VAL="$REGION" \
DYNAMO_TABLE="$TABLE_NAME" \
DEV_DOMAIN="$DEV_DOMAIN" \
OWNER_SUB="$OWNER_SUB" \
ADMIN_SUB="$ADMIN_SUB" \
PRODUCER_SUB="$PRODUCER_SUB" \
COORDINATOR_SUB="$COORDINATOR_SUB" \
VOLUNTEER_SUB="$VOLUNTEER_SUB" \
ADMIN_COORDINATOR_SUB="$ADMIN_COORDINATOR_SUB" \
COORDINATOR_VOLUNTEER_SUB="$COORDINATOR_VOLUNTEER_SUB" \
ADMIN_COORDINATOR_VOLUNTEER_SUB="$ADMIN_COORDINATOR_VOLUNTEER_SUB" \
python3 <<'PYTHON'
import boto3, json, os

region       = os.environ['AWS_REGION_VAL']
table        = os.environ['DYNAMO_TABLE']
dev_domain   = os.environ['DEV_DOMAIN']
owner_sub    = os.environ['OWNER_SUB']
producer_sub = os.environ['PRODUCER_SUB']

def _email(prefix):
    return f'{prefix}@{dev_domain}'

dynamodb = boto3.client('dynamodb', region_name=region)

# Server row seeded by Terraform (needed for UserSettings.server_id).
resp = dynamodb.query(
    TableName=table,
    KeyConditionExpression='pk = :pk',
    ExpressionAttributeValues={':pk': {'S': 'SERVER'}},
)
server_id = resp['Items'][0]['sk']['S'] if resp.get('Items') else ''

EPOCH = '1970-01-01T00:00:00Z'

def _member_settings():
    return json.dumps({
        'delivery_reminders': {'days_before': 1, 'reminder_time': '08:00'},
        'accessibility_options': {'high_contrast': False, 'large_text': False, 'screen_reader': False},
        'last_updated_instant': EPOCH,
    }, separators=(',', ':'))

def _member_prefs():
    return json.dumps({
        'delivery_reminders_enabled': True,
        'volunteer_alerts_enabled': True,
        'last_updated_instant': EPOCH,
    }, separators=(',', ':'))

def _user_prefs():
    return json.dumps({
        'email_notifications_enabled': True,
        'push_notifications_enabled': False,
        'last_updated_instant': EPOCH,
    }, separators=(',', ':'))

def _user_settings():
    return json.dumps({
        'language': 'fr',
        'timezone': 'Europe/Paris',
        'server_id': server_id,
        'last_updated_instant': EPOCH,
    }, separators=(',', ':'))

# ── Organization ─────────────────────────────────────────────────────────────
dynamodb.put_item(TableName=table, Item={
    'pk':                    {'S': 'ORGANIZATION'},
    'sk':                    {'S': 'amap-dev'},
    'entity_type':           {'S': 'Organization'},
    'name':                  {'S': 'AMAP Dev'},
    'contact_email':         {'S': f'contact@amap-dev.{dev_domain}'},
    'active_status':         {'BOOL': True},
    'timezone':              {'S': 'Europe/Paris'},
    'default_language':      {'S': 'fr'},
    'created_instant':       {'N': '0'},
    'last_updated_instant':  {'N': '0'},
    'producers': {'S': json.dumps([{
        'producer_account_id': producer_sub,
        'association_instant': EPOCH,
        'status': 'ACTIVE',
    }], separators=(',', ':'))},
    'products':   {'S': '[]'},
    'deliveries': {'S': '[]'},
})

# ── ProducerAccount ───────────────────────────────────────────────────────────
# Two rows per ProducerAccountSyncDynamoDAO schema:
#   pk=PA#<orgId>     — queried by org (getByOrganizationId)
#   pk=PA#UNASSIGNED  — queried by id (findById / listAll)
for pk_suffix in ['amap-dev', 'UNASSIGNED']:
    dynamodb.put_item(TableName=table, Item={
        'pk':                    {'S': f'PA#{pk_suffix}'},
        'sk':                    {'S': producer_sub},
        'entity_type':           {'S': 'ProducerAccount'},
        'name':                  {'S': 'Producteur Dev'},
        'active_status':         {'BOOL': True},
        'created_instant':       {'N': '0'},
        'last_updated_instant':  {'N': '0'},
        'management_mode':       {'S': 'ACCOUNT_BACKED'},
        'organizations': {'S': json.dumps([{
            'organization_id': 'amap-dev',
            'association_instant': EPOCH,
            'status': 'ACTIVE',
        }], separators=(',', ':'))},
        'products':          {'S': '[]'},
        'user_preferences':  {'S': _user_prefs()},
    })

# ── Owner ─────────────────────────────────────────────────────────────────────
dynamodb.put_item(TableName=table, Item={
    'pk':                   {'S': 'OWNER'},
    'sk':                   {'S': owner_sub},
    'entity_type':          {'S': 'Owner'},
    'owner_id':             {'S': owner_sub},
    'first_name':           {'S': 'Olivier'},
    'last_name':            {'S': 'Owner'},
    'email':                {'S': _email('owner')},
    'account_status':       {'S': 'ACTIVE'},
    'registered_at':        {'N': '0'},
    'updated_at':           {'N': '0'},
    'user_preferences':     {'S': _user_prefs()},
})

# ── Members (organization-scoped) ─────────────────────────────────────────────
# memberId == sub by MemberSyncDynamoDAO convention.
# Producer is NOT a member row — their scope is ProducerAccount via sub.
members = [
    (os.environ['ADMIN_SUB'],                        ['ADMIN'],                             _email('admin')),
    (os.environ['COORDINATOR_SUB'],                  ['COORDINATOR'],                       _email('coordinator')),
    (os.environ['VOLUNTEER_SUB'],                    ['VOLUNTEER'],                         _email('volunteer')),
    (os.environ['ADMIN_COORDINATOR_SUB'],            ['ADMIN', 'COORDINATOR'],              _email('admin-coordinator')),
    (os.environ['COORDINATOR_VOLUNTEER_SUB'],        ['COORDINATOR', 'VOLUNTEER'],          _email('coordinator-volunteer')),
    (os.environ['ADMIN_COORDINATOR_VOLUNTEER_SUB'],  ['ADMIN', 'COORDINATOR', 'VOLUNTEER'], _email('admin-coordinator-volunteer')),
]

for sub, roles, email in members:
    dynamodb.put_item(TableName=table, Item={
        'pk':                  {'S': 'MEMBER#amap-dev'},
        'sk':                  {'S': sub},
        'entity_type':         {'S': 'Member'},
        'member_id':           {'S': sub},
        'organization_id':     {'S': 'amap-dev'},
        'roles':               {'SS': roles},
        'active_status':       {'BOOL': True},
        'account_status':      {'S': 'ACTIVE'},
        'email':               {'S': email},
        'contracts':           {'S': '[]'},
        'registrations':       {'S': '[]'},
        'member_settings':     {'S': _member_settings()},
        'member_preferences':  {'S': _member_prefs()},
        'user_preferences':    {'S': _user_prefs()},
        'user_settings':       {'S': _user_settings()},
    })
    # Lightweight sub→organizationId lookup (used by findOrganizationIdBySub)
    dynamodb.put_item(TableName=table, Item={
        'pk':              {'S': 'MEMBER_SUB'},
        'sk':              {'S': sub},
        'organization_id': {'S': 'amap-dev'},
    })

print('DynamoDB seeding complete.')
PYTHON

# ---------------------------------------------------------------------------
# 5. Fetch access tokens and print summary
# ---------------------------------------------------------------------------
printf '\nFetching access tokens...\n'

declare -A USER_TOKENS
USER_TOKENS["owner@${DEV_DOMAIN}"]=$(get_token "owner@${DEV_DOMAIN}")
USER_TOKENS["admin@${DEV_DOMAIN}"]=$(get_token "admin@${DEV_DOMAIN}")
USER_TOKENS["producer@${DEV_DOMAIN}"]=$(get_token "producer@${DEV_DOMAIN}")
USER_TOKENS["coordinator@${DEV_DOMAIN}"]=$(get_token "coordinator@${DEV_DOMAIN}")
USER_TOKENS["volunteer@${DEV_DOMAIN}"]=$(get_token "volunteer@${DEV_DOMAIN}")
USER_TOKENS["admin-coordinator@${DEV_DOMAIN}"]=$(get_token "admin-coordinator@${DEV_DOMAIN}")
USER_TOKENS["coordinator-volunteer@${DEV_DOMAIN}"]=$(get_token "coordinator-volunteer@${DEV_DOMAIN}")
USER_TOKENS["admin-coordinator-volunteer@${DEV_DOMAIN}"]=$(get_token "admin-coordinator-volunteer@${DEV_DOMAIN}")

print_user() {
  local label="$1"
  local email="$2"
  local sub="$3"
  printf '\n%-12s %s\n  sub:   %s\n  token: %s\n' \
    "$label" "$email" "$sub" "${USER_TOKENS[$email]}"
}

printf '\n%s\n' "$(printf '%.0s─' {1..72})"
printf 'Dev users (password: %s)\n' "$DEV_PASSWORD"
printf '%s\n' "$(printf '%.0s─' {1..72})"
print_user "OWNER"           "owner@${DEV_DOMAIN}"                        "$OWNER_SUB"
print_user "ADMIN"           "admin@${DEV_DOMAIN}"                        "$ADMIN_SUB"
print_user "PRODUCER"        "producer@${DEV_DOMAIN}"                     "$PRODUCER_SUB"
print_user "COORDINATOR"     "coordinator@${DEV_DOMAIN}"                  "$COORDINATOR_SUB"
print_user "VOLUNTEER"       "volunteer@${DEV_DOMAIN}"                    "$VOLUNTEER_SUB"
print_user "ADMIN+COORD"     "admin-coordinator@${DEV_DOMAIN}"            "$ADMIN_COORDINATOR_SUB"
print_user "COORD+VOL"       "coordinator-volunteer@${DEV_DOMAIN}"        "$COORDINATOR_VOLUNTEER_SUB"
print_user "ADMIN+COORD+VOL" "admin-coordinator-volunteer@${DEV_DOMAIN}"  "$ADMIN_COORDINATOR_VOLUNTEER_SUB"
printf '\n'
