#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter run -d chrome --web-port 5000 --wasm
