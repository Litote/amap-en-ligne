#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="$(cd "$(dirname "$0")" && pwd)/docker-compose.yml"

docker compose -f "$COMPOSE_FILE" down -v
