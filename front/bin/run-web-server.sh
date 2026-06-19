#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter run -d web-server --web-port 5000 --wasm
