# Acceptance tests

`acceptance/scenarios/*.json` is the documented catalog of offline-first sync stories.

## Purpose

The repository exercises acceptance coverage in three complementary layers:

1. **Server acceptance** — `back/deploy/jvm/.../AcceptanceScenariosTest.kt`
   - executes the JSON scenarios as real `POST /v1/sync` calls against the JVM deployment fixture
   - validates HTTP status, mutation outcomes, snapshots, and incremental changes
2. **Flutter acceptance** — `front/test/acceptance/`
   - validates client-side offline-first behavior with real drift + real repositories + a scripted `SyncApi`
   - keeps the tests deterministic and fast without a device-level UI E2E stack
3. **Cross-component e2e** — `acceptance/e2e/` (Kotlin) + `front/test/acceptance/cross_component/` (Dart)
   - tests the full Flutter → GoTrue → back chain against real services in Docker containers
   - requires Docker (Testcontainers) and `flutter` in PATH
   - runs via `./gradlew crossComponentTest` from the repo root
   - **Mobile UI tests** (`CrossComponentUiAuthTest`, `CrossComponentUiPasswordResetTest`): run the Flutter Android and iOS app via `flutter test -d <device>`
   - **Web UI tests** (`CrossComponentWebUiAuthTest`, `CrossComponentWebUiPasswordResetTest`): run the Flutter web build in headless Chromium via [Playwright](https://playwright.dev/java/); see `AI_CONTEXT.md → Flutter web Playwright tests` for input-interaction quirks

## Scenario model

Each scenario file documents:

- `id` — stable story identifier reused by the test suites
- `title` — human-readable story name
- `targets` — any of `server`, `flutter`
- `given` — supported fixture labels (`backendState`, `appState`)
- `when` — ordered sync steps
- `then.lastResponse` — server expectations for the final HTTP response

The server runner executes only scenarios tagged with `server`.

Flutter acceptance tests currently reuse the same story ids and titles, but keep their richer local-state assertions in Dart code because they validate database state, pending mutations, and tmp-id remapping rather than raw HTTP output alone.

## Commands

From the repository root:

```bash
# ⚠️ REQUIRED BEFORE MERGING: All acceptance tests (must pass for any feature/bug fix)
./gradlew allAcceptanceTests

# Individual test suites:
# Back + Flutter acceptance tests (server + scripted API)
./gradlew acceptanceTest
./gradlew frontAcceptanceTest

# Full cross-component e2e (requires Docker + flutter in PATH)
./gradlew crossComponentTest
```

**⚠️ Before merging any feature or bug fix, ALWAYS run `./gradlew allAcceptanceTests`**. This ensures:
- Back acceptance tests pass
- Flutter acceptance tests pass  
- Cross-component E2E tests pass (auth, password reset, sync flows with real services)

From component directories:

```bash
cd back && ./gradlew acceptanceTest
cd front && flutter test test/acceptance/ --tags acceptance

# Flutter-side cross-component tests (only meaningful with --dart-define env vars set)
cd front && flutter test test/acceptance/cross_component/ --tags cross-component
```

## Mobile E2E tests setup

The mobile E2E tests (`CrossComponentUiAuthTest` and `CrossComponentUiPasswordResetTest`) run the Flutter app on an Android emulator. The test infrastructure automatically:

1. Detects if an Android device is already connected/running
2. Lists available Android Virtual Devices (AVDs)
3. Starts the first available AVD if no device is detected
4. Waits up to 3 minutes for the emulator to be ready
5. Cleans up the emulator after tests complete

### Prerequisites

Create an Android Virtual Device (AVD) — if you don't have one:

```bash
# List available AVDs
emulator -list-avds

# If empty, create one via Android Studio or command line:
# (requires Android SDK installed)
sdkmanager "system-images;android-34;google_apis;x86_64"
avdmanager create avd -n "test_emulator" -k "system-images;android-34;google_apis;x86_64"
```

### Running mobile E2E tests

From the repo root:

```bash
# Automatic emulator startup + tests
./gradlew crossComponentTest
```

Or manually:

```bash
# Start emulator first
emulator -avd test_emulator &

# Run tests
./gradlew crossComponentTest
```

### Troubleshooting

- **"No Android emulator AVDs found"** → Create an AVD (see Prerequisites above)
- **"Android emulator failed to start within 180s"** → 
  - Check that `emulator` is in PATH (usually `$ANDROID_HOME/emulator/emulator`)
  - Try starting the emulator manually to see error messages
  - Increase the timeout in `E2eTestSupport.ensureAndroidEmulatorRunning()` if your system is slow
- **Tests skipped with "Assumptions"** → Check that `flutter` is in PATH and working

## When to add a scenario

Add or update a scenario when a change affects a documented story:

- bootstrap behavior
- optimistic create / tmp-id remap
- incremental sync
- delete propagation
- offline queue + reconnect
- mutation rejection / authorization cases
