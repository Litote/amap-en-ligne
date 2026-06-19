# Contributing — Flutter (`front/`)

> Flutter-specific contributing guide. Global rules (commit signing, branch naming): see [`../CONTRIBUTING.md`](../CONTRIBUTING.md).

All commands below are run from `front/` unless stated otherwise.

---

## Prerequisites

- Flutter SDK — exact version in `front/.flutter-version` at repo root
- Xcode (macOS, for iOS builds)
- Android Studio / Java 17 (for Android builds)

---

## Quick Reference

```bash
# Install dependencies
flutter pub get

# Analyze
flutter analyze --fatal-infos

# Unit + widget tests (excludes golden + acceptance tests)
flutter test test/ --exclude-tags "golden || acceptance"

# Acceptance tests
flutter test test/acceptance/ --tags acceptance

# Golden tests (macOS only)
flutter test test/golden/ --tags golden

# Regenerate code (Freezed, etc.) after model changes
dart run build_runner build --delete-conflicting-outputs

# Run locally
flutter run
```

---

## Run locally

Use the provided IntelliJ/Android Studio run configuration **`App`** (in `front/.run/`), or run directly:

```bash
flutter run
```

## Web builds

Web builds use **WebAssembly (WASM) by default** — this reduces code size 4.8% vs JavaScript and provides better performance for sync/drift logic.

```bash
# Build for web (WASM)
flutter build web --release

# (Rare) To build with JavaScript instead, use
flutter build web --release --no-wasm
```

WASM is supported in all modern browsers (95%+ market share); older browsers (IE11) are not supported. First-load time: WASM is compiled by the browser (~1s on modern hardware), then cached in the service worker.

## Acceptance tests

Flutter acceptance tests live under `test/acceptance/`.

- They use **real drift + real repositories + a scripted `SyncApi`**
- They should model the live scope-based sync contract (`authorized_scopes`, scope-keyed cursors, `ScopeSyncResult`) rather than the legacy per-entity `data/changes` shape
- They validate offline-first client behavior, not device-level UI E2E
- They reuse the documented story ids/titles from `../acceptance/scenarios/`
