#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Capture git commit hash
GIT_COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

flutter run -d chrome --web-port 5000 --wasm --dart-define=GIT_COMMIT_HASH="$GIT_COMMIT_HASH"
