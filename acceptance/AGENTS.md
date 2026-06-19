# Acceptance Tests — amap-en-ligne

> **Purpose**: Instructions for AI agents working on cross-component E2E and acceptance tests.
> For installation, configuration, and usage, see [`README.md`](README.md).
> For system architecture and test layers, see [`../AI_CONTEXT.md`](../AI_CONTEXT.md).

---

## Critical Rules

### NEVER Do

| Category         | Forbidden Actions                                                                |
|------------------|----------------------------------------------------------------------------------|
| **Scope**        | Modify back/ or front/ source code (use backend-agent or flutter-agent instead) |
| **Testing**      | Mock external services (use real Docker/Testcontainers; validate wire contract) |
| **OTP**          | Use `extractOtpFromEmail()` (wrong token type); always use `getRecoveryToken()`  |
| **Networking**   | Assume `localhost` works on Android emulator (convert to `10.0.2.2`)            |
| **Emulator**     | Force emulator startup; default to skip if no device (unless env var set)      |

### ALWAYS Do

| Category                   | Required Actions                                                                                          |
|----------------------------|-----------------------------------------------------------------------------------------------------------|
| **Validation**             | Run `./gradlew allAcceptanceTests` before marking tests complete                                         |
| **Real services**          | E2E tests use Docker containers (GoTrue, Postgres, MailHog, Ktor backend)                               |
| **Wire contract**          | Cross-component tests validate JSON wire format, JWT claims, sync outcomes                              |
| **Coordination**           | When tests span back+front, ensure both independently pass their acceptance tests                        |
| **Documentation**          | Add scenarios to `acceptance/scenarios/` when tests validate new stories                                |
| **Playwright setup**       | Web UI tests require `installPlaywrightBrowsers` task; check `AI_CONTEXT.md` for input quirks           |
| **Test fixtures**          | Use `ContainerSuite.*` helpers (createUser, getRecoveryToken, waitForEmail, etc.)                       |
| **Logging**                | Use `logger.info()` for test infrastructure (not `println`)                                              |
| **Environment vars**       | Document `E2E_SKIP_IF_NO_ANDROID_DEVICE`, `BACK_URL`, `GOTRUE_URL`, etc. in test code                 |

---

## Test Architecture

### Three acceptance layers:

1. **Server acceptance** — `back/deploy/jvm/.../AcceptanceScenariosTest.kt`
   - Executes JSON scenarios as real HTTP calls against the backend
   - Validates sync contract, mutation outcomes, snapshots

2. **Flutter acceptance** — `front/test/acceptance/`
   - Client-side offline behavior with real drift + repos + mocked `SyncApi`
   - Fast, deterministic, no device/emulator required

3. **Cross-component E2E** — `acceptance/e2e/` (Kotlin) + `front/test/acceptance/cross_component/` (Dart)
   - Full Flutter → GoTrue → backend chain with real Docker containers
   - Requires Docker (Testcontainers) and `flutter` in PATH
   - Mobile UI tests: Android emulator or connected device
   - Web UI tests: headless Chromium via Playwright

---

## Key Patterns

### OTP Recovery Flow
```kotlin
// ❌ WRONG: extracts 56-char magic token from email link
val otp = ContainerSuite.extractOtpFromEmail(email)

// ✅ CORRECT: gets 6-digit numeric OTP via GoTrue admin API
val otp = ContainerSuite.getRecoveryToken(email)
```

### Android Emulator Networking
```kotlin
// ❌ WRONG: emulator cannot reach localhost
val backUrl = "http://localhost:42619"

// ✅ CORRECT: emulator reaches host via 10.0.2.2
dartDefines["BACK_URL"] = backUrl.replace("localhost", "10.0.2.2")
```

### OTP Proxy (MailHog polling)
```kotlin
protected fun startOtpProxy(): Pair<Int, ServerSocket> {
    // Starts HTTP server that polls MailHog server-side (no CORS restriction)
    // Flutter web calls it with CORS-allowed headers
}
```

### Device Detection
```kotlin
private fun ensureAndroidEmulatorRunning(): String {
    // 1. Check if Android device already connected
    // 2. If not, skip test by default (unless E2E_SKIP_IF_NO_ANDROID_DEVICE=false)
    // 3. If env var allows, start emulator and wait up to 3 minutes
    // 4. Extract device ID dynamically from `flutter devices --machine` JSON
}
```

---

## Commands

From the repository root:

```bash
# ⚠️ REQUIRED BEFORE MERGING
./gradlew allAcceptanceTests

# Individual suites
./gradlew acceptanceTest          # back + flutter scripted tests
./gradlew crossComponentTest      # full E2E with Docker
./gradlew frontAcceptanceTest     # flutter scripted only

# Setup (for web UI tests)
./gradlew installPlaywrightBrowsers
```

---

## Definition of Done

A test change is complete when:

- [ ] `./gradlew allAcceptanceTests` passes
- [ ] New scenarios added to `acceptance/scenarios/` (if documenting stories)
- [ ] Test fixtures use `ContainerSuite.*` helpers correctly
- [ ] OTP flows use `getRecoveryToken()`, not `extractOtpFromEmail()`
- [ ] Android tests handle `localhost` → `10.0.2.2` conversion
- [ ] Logging uses `logger.info()`, not `println`
- [ ] IDE diagnostics (Problems panel) report zero errors
- [ ] If coordinating back+front changes: both components pass independently

---

## Common Workflows

### Adding a cross-component auth test
1. Create Kotlin test in `e2e/src/test/kotlin/e2e/CrossComponent*.kt`
2. Create Flutter test in `front/test/acceptance/cross_component/*_e2e_test.dart` (tag: `cross-component`)
3. Use `ContainerSuite.createUser()` to set up fixtures
4. Call `runFlutterMobileIntegrationTests()` or `runFlutterTests()` to execute Dart tests
5. Verify `./gradlew allAcceptanceTests` passes

### Updating an OTP flow
1. Ensure OTP proxy uses `ContainerSuite.getRecoveryToken(email)`
2. Test via password reset flow: `CrossComponentUiPasswordResetTest`
3. Verify email arrives in MailHog via `ContainerSuite.waitForEmail()`
4. Confirm both back and front acceptance tests pass

### Debugging a flaky E2E test
1. Check network access: `localhost` vs `10.0.2.2` on Android
2. Check OTP type: 6-digit numeric, not 56-char magic token
3. Check device detection: `flutter devices --machine` JSON (targetPlatform field)
4. Check emulator ready: Testcontainers may take 3+ minutes
5. Check Playwright dependencies: Run `installPlaywrightBrowsers` for web tests

---
