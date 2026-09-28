#!/usr/bin/env bash
# Tears down the AWS dev data: wipes ALL DynamoDB items and ALL Cognito users.
# Run from the repo root or from any directory — uses the script's own location.
#
# Customise via env vars (all optional if Terraform outputs are available):
#   DYNAMO_TABLE_NAME      default: terraform output dynamo_table_name
#   COGNITO_USER_POOL_ID   default: terraform output cognito_user_pool_id
#   AWS_REGION             default: eu-west-3
#   INFRA_DIR              default: <script>/../../../infra
#
# Dependencies: aws cli, jq
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="${INFRA_DIR:-$(cd "$SCRIPT_DIR/../../../infra" && pwd)}"
REGION="${AWS_REGION:-eu-west-3}"

resolve_tf() {
  terraform -chdir="$INFRA_DIR" output -raw "$1" 2>/dev/null || true
}

resolve_aws() {
  local key="$1"
  case "$key" in
    dynamo_table_name)
      # Try the default table name first, then look for one tagged with the project.
      aws dynamodb describe-table --table-name "data" --region "$REGION" \
        --query 'Table.TableName' --output text 2>/dev/null || true ;;
    cognito_user_pool_id)
      # Filter by the expected name prefix used by the Terraform module.
      aws cognito-idp list-user-pools --max-results 60 --region "$REGION" \
        --query 'UserPools[?starts_with(Name, `amap-en-ligne`)].Id | [0]' \
        --output text 2>/dev/null | grep -v None || true ;;
  esac
}

TABLE_NAME="${DYNAMO_TABLE_NAME:-$(resolve_tf dynamo_table_name)}"
TABLE_NAME="${TABLE_NAME:-$(resolve_aws dynamo_table_name)}"
USER_POOL_ID="${COGNITO_USER_POOL_ID:-$(resolve_tf cognito_user_pool_id)}"
USER_POOL_ID="${USER_POOL_ID:-$(resolve_aws cognito_user_pool_id)}"

if [ -z "$TABLE_NAME" ] || [ -z "$USER_POOL_ID" ]; then
  printf 'ERROR: TABLE_NAME and USER_POOL_ID could not be resolved automatically.\n' >&2
  printf '\nSet them explicitly before running this script:\n' >&2
  printf '  export DYNAMO_TABLE_NAME=$(terraform -chdir=%s output -raw dynamo_table_name)\n' "$INFRA_DIR" >&2
  printf '  export COGNITO_USER_POOL_ID=$(terraform -chdir=%s output -raw cognito_user_pool_id)\n' "$INFRA_DIR" >&2
  printf '  ./aws-reset.sh\n' >&2
  exit 1
fi

printf 'TABLE:    %s\n' "$TABLE_NAME"
printf 'POOL:     %s\n' "$USER_POOL_ID"
printf 'REGION:   %s\n' "$REGION"

# ---------------------------------------------------------------------------
# 1. DynamoDB: full-table scan (auto-paginated) then delete each item
#    Uses aws-cli scan (auto-paginates by default) + delete-item loop.
#    Batching via batch-write-item is faster but requires jq chunking;
#    for a dev table the simple loop is fast enough.
# ---------------------------------------------------------------------------
printf '\nClearing DynamoDB table %s...\n' "$TABLE_NAME"

ITEMS=$(aws dynamodb scan \
  --table-name "$TABLE_NAME" \
  --region "$REGION" \
  --projection-expression "pk,sk" \
  --query 'Items[*].[pk.S,sk.S]' \
  --output text)

COUNT=0
if [ -n "$ITEMS" ]; then
  while IFS=$'\t' read -r pk sk; do
    aws dynamodb delete-item \
      --table-name "$TABLE_NAME" \
      --region "$REGION" \
      --key "{\"pk\":{\"S\":\"${pk}\"},\"sk\":{\"S\":\"${sk}\"}}" > /dev/null
    COUNT=$((COUNT + 1))
  done <<< "$ITEMS"
fi

printf 'DynamoDB cleared: %d item(s) deleted.\n' "$COUNT"

# ---------------------------------------------------------------------------
# 2. Cognito: page through all users and delete them
# ---------------------------------------------------------------------------
printf '\nClearing Cognito User Pool %s...\n' "$USER_POOL_ID"

PAGINATION_TOKEN=""
TOTAL=0

while true; do
  if [ -z "$PAGINATION_TOKEN" ]; then
    RESPONSE=$(aws cognito-idp list-users \
      --user-pool-id "$USER_POOL_ID" \
      --region "$REGION" \
      --output json)
  else
    RESPONSE=$(aws cognito-idp list-users \
      --user-pool-id "$USER_POOL_ID" \
      --pagination-token "$PAGINATION_TOKEN" \
      --region "$REGION" \
      --output json)
  fi

  USERNAMES=$(echo "$RESPONSE" | jq -r '.Users[].Username // empty')

  if [ -n "$USERNAMES" ]; then
    while IFS= read -r username; do
      printf '  deleting %s\n' "$username"
      aws cognito-idp admin-delete-user \
        --user-pool-id "$USER_POOL_ID" \
        --username "$username" \
        --region "$REGION"
      TOTAL=$((TOTAL + 1))
    done <<< "$USERNAMES"
  fi

  PAGINATION_TOKEN=$(echo "$RESPONSE" | jq -r '.PaginationToken // empty')
  [ -z "$PAGINATION_TOKEN" ] && break
done

printf 'Cognito cleared: %d user(s) deleted.\n' "$TOTAL"
printf '\nReset complete.\n'
