import org.gradle.api.services.BuildService
import org.gradle.api.services.BuildServiceParameters

plugins {
    base
}

// ── Flutter tasks ──────────────────────────────────────────────────────────

// `flutter test` writes shared bundle assets under build/unit_test_assets (e.g. compiled
// shaders like ink_sparkle.frag). Two `flutter test` invocations in the same project race
// on those writes and fail with "Could not write file ...". This only surfaces under
// Gradle's parallel execution (org.gradle.parallel=true) — e.g. the CI `allAcceptanceTests`
// job running frontAcceptanceTest and frontCrossComponentTest concurrently. A shared build
// service capped at one usage serialises every flutter-test task without disabling
// parallelism for the rest of the build.
abstract class FlutterTestLockService : BuildService<BuildServiceParameters.None>

val flutterTestLock = gradle.sharedServices.registerIfAbsent(
    "flutterTestLock",
    FlutterTestLockService::class.java,
) {
    maxParallelUsages.set(1)
}

// Resolve flutter executable from local.properties if available, fallback to PATH.
val flutterBin = project.file("android/local.properties").let { propFile ->
    if (propFile.exists()) {
        val props = java.util.Properties()
        propFile.inputStream().use { props.load(it) }
        val sdk = props.getProperty("flutter.sdk")
        if (sdk != null) "$sdk/bin" else null
    } else null
}
val flutterCmd = flutterBin?.let { "$it/flutter" } ?: "flutter"
val dartCmd = flutterBin?.let { "$it/dart" } ?: "dart"

val flutterPubGet by tasks.registering(Exec::class) {
    group = "front"
    description = "Installs Flutter dependencies."
    workingDir = projectDir
    commandLine(flutterCmd, "pub", "get", "--enforce-lockfile")
}

val frontAnalyze by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter static analysis."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine(flutterCmd, "analyze", "--fatal-infos")
}

val frontTest by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter unit + widget + (scripted) acceptance tests with coverage."
    dependsOn(flutterPubGet)
    usesService(flutterTestLock)
    workingDir = projectDir
    // --coverage generates coverage/lcov.info consumed by SonarQube. Acceptance
    // tests are scripted (real drift + fake SyncApi, no backend), so they run
    // here and contribute coverage; only golden (macOS-only) and cross-component
    // (live-backend) tests are excluded.
    val resolvedFlutterCmd = flutterCmd
    commandLine(flutterCmd, "--version")
    doFirst {
        val gitHash = try {
            val process = ProcessBuilder("git", "rev-parse", "--short", "HEAD")
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.inputStream.bufferedReader().readText().trim().takeIf { it.isNotEmpty() } ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
        (this as Exec).commandLine(
            resolvedFlutterCmd, "test", "test/",
            "--exclude-tags", "golden || cross-component",
            "--coverage",
            "--dart-define=GIT_COMMIT_HASH=$gitHash",
        )
    }
}

val frontAcceptanceTest by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter acceptance tests (cross-component tests run via frontCrossComponentTest only)."
    dependsOn(flutterPubGet)
    usesService(flutterTestLock)
    workingDir = projectDir
    val resolvedFlutterCmd = flutterCmd
    commandLine(flutterCmd, "--version")
    doFirst {
        val gitHash = try {
            val process = ProcessBuilder("git", "rev-parse", "--short", "HEAD")
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.inputStream.bufferedReader().readText().trim().takeIf { it.isNotEmpty() } ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
        (this as Exec).commandLine(
            resolvedFlutterCmd, "test", "test/acceptance/",
            "--tags", "acceptance",
            "--exclude-tags", "cross-component",
            "--dart-define=GIT_COMMIT_HASH=$gitHash",
        )
    }
}

val frontCrossComponentTest by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter cross-component acceptance tests (individually skipped when env vars absent)."
    dependsOn(flutterPubGet)
    usesService(flutterTestLock)
    workingDir = projectDir
    // Placeholder — overridden in doFirst so per-run values (runId, testDeliveryDate,
    // .env reload) are computed at execution time, not cached by the configuration cache.
    commandLine(flutterCmd, "--version")
    // Capture as plain strings so the doFirst action is configuration-cache serializable
    // (task/project object references cannot be serialized by the configuration cache).
    val envFilePath = projectDir.parentFile.resolve("back/deploy/jvm/.env").absolutePath
    val resolvedFlutterCmd = flutterCmd
    doFirst {
        // Re-read .env at execution time so a token refresh between runs is picked up.
        val envFile = File(envFilePath)
        val dotEnv: Map<String, String> = if (envFile.exists()) {
            envFile.readLines()
                .filter { it.isNotBlank() && !it.trimStart().startsWith("#") }
                .mapNotNull { line ->
                    val eq = line.indexOf('=')
                    if (eq < 0) null else line.substring(0, eq).trim() to line.substring(eq + 1)
                }
                .toMap()
        } else emptyMap()
        // Shell env → .env file → fallback (empty means the test skips gracefully).
        fun env(name: String, fallback: String = "") = System.getenv(name) ?: dotEnv[name] ?: fallback

        // INSTANCE_API_URL and GOTRUE_JWT_ISSUER are the .env names for the same URLs.
        val gotrueBaseUrl = env("GOTRUE_URL", dotEnv["GOTRUE_JWT_ISSUER"] ?: "")
        val jwtSecret = env("GOTRUE_JWT_SECRET")
        val serviceKey = env("GOTRUE_SERVICE_ROLE_KEY")

        // Fetch all GoTrue users once — reused for token generation, password reset, and OTP.
        // Falls back to an empty list when GoTrue is unreachable (tests skip gracefully).
        @Suppress("UNCHECKED_CAST")
        val gotrueUsers: List<Map<*, *>> =
            if (gotrueBaseUrl.isNotEmpty() && serviceKey.isNotEmpty()) {
                try {
                    val conn = java.net.URI("$gotrueBaseUrl/admin/users")
                        .toURL().openConnection() as java.net.HttpURLConnection
                    conn.setRequestProperty("Authorization", "Bearer $serviceKey")
                    val result = (groovy.json.JsonSlurper().parse(conn.inputStream)
                        as Map<*, *>)["users"] as List<Map<*, *>>
                    conn.disconnect()
                    result
                } catch (_: Exception) { emptyList() }
            } else emptyList()

        // Generate a fresh HS256 JWT for a GoTrue user looked up by email.
        // Returns empty string when the user is not found or the secret is absent.
        fun generateJwtForEmail(email: String): String {
            if (email.isEmpty() || jwtSecret.isEmpty()) return ""
            val user = gotrueUsers.firstOrNull { it["email"] == email } ?: return ""
            val userId = user["id"] as? String ?: return ""
            val appMetadata = user["app_metadata"] as? Map<*, *> ?: emptyMap<Any, Any>()
            val now = System.currentTimeMillis() / 1000L
            val payload = mapOf(
                "iss" to gotrueBaseUrl,
                "sub" to userId,
                "aud" to "authenticated",
                "iat" to now,
                "exp" to now + 7L * 24 * 3600,
                "email" to email,
                "app_metadata" to appMetadata,
                "role" to "",
                "aal" to "aal1",
                "is_anonymous" to false,
            )
            return try {
                val header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
                val payloadStr = java.util.Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(groovy.json.JsonOutput.toJson(payload).toByteArray())
                val signingInput = "$header.$payloadStr"
                val mac = javax.crypto.Mac.getInstance("HmacSHA256")
                mac.init(javax.crypto.spec.SecretKeySpec(jwtSecret.toByteArray(), "HmacSHA256"))
                val sig = java.util.Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(mac.doFinal(signingInput.toByteArray()))
                "$signingInput.$sig"
            } catch (_: Exception) { "" }
        }

        // Re-sign an existing JWT with a fresh 7-day expiry — fallback when no email is configured.
        fun refreshJwt(staleToken: String): String {
            if (staleToken.isEmpty() || jwtSecret.isEmpty()) return staleToken
            return try {
                val parts = staleToken.split(".")
                if (parts.size != 3) return staleToken
                val padding = (4 - parts[1].length % 4) % 4
                val payloadJson = String(java.util.Base64.getUrlDecoder().decode(parts[1] + "=".repeat(padding)))
                @Suppress("UNCHECKED_CAST")
                val payload = (groovy.json.JsonSlurper().parseText(payloadJson) as Map<*, *>).toMutableMap()
                val now = System.currentTimeMillis() / 1000L
                payload["iat"] = now
                payload["exp"] = now + 7L * 24 * 3600
                val newPayloadStr = java.util.Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(groovy.json.JsonOutput.toJson(payload).toByteArray())
                val signingInput = "${parts[0]}.$newPayloadStr"
                val mac = javax.crypto.Mac.getInstance("HmacSHA256")
                mac.init(javax.crypto.spec.SecretKeySpec(jwtSecret.toByteArray(), "HmacSHA256"))
                val sig = java.util.Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(mac.doFinal(signingInput.toByteArray()))
                "$signingInput.$sig"
            } catch (_: Exception) { staleToken }
        }

        // Resolve a token: generate fresh from GoTrue if an email is configured, else re-sign stale.
        fun resolveToken(emailKey: String, tokenKey: String) =
            generateJwtForEmail(env(emailKey)).takeIf { it.isNotEmpty() }
                ?: refreshJwt(env(tokenKey))

        // Resolve a user id: look up live sub from GoTrue, else fall back to .env value.
        fun resolveUserId(email: String, fallbackKey: String): String {
            if (email.isNotEmpty() && gotrueUsers.isNotEmpty())
                (gotrueUsers.firstOrNull { it["email"] == email }?.get("id") as? String)
                    ?.let { return it }
            return env(fallbackKey)
        }

        // Per-run unique values computed fresh here — not cached by the configuration cache.
        val runId = System.currentTimeMillis()
        val testDeliveryDate = run {
            val d = java.time.LocalDate.now().plusYears(100)
            "${d.year}-${d.monthValue.toString().padStart(2, '0')}-${d.dayOfMonth.toString().padStart(2, '0')}T17:30:00"
        }

        // Pre-reset TEST_EMAIL password and auto-generate a fresh recovery OTP.
        // Reuses the already-fetched gotrueUsers list — no extra API call.
        val testEmail = env("TEST_EMAIL")
        val testPassword = env("TEST_PASSWORD")
        if (testPassword.isNotEmpty() && gotrueUsers.isNotEmpty()) {
            val userId = gotrueUsers.firstOrNull { it["email"] == testEmail }?.get("id") as? String
            if (userId != null) {
                try {
                    val resetConn = java.net.URI("$gotrueBaseUrl/admin/users/$userId")
                        .toURL().openConnection() as java.net.HttpURLConnection
                    resetConn.requestMethod = "PUT"
                    resetConn.setRequestProperty("Content-Type", "application/json")
                    resetConn.setRequestProperty("Authorization", "Bearer $serviceKey")
                    resetConn.doOutput = true
                    resetConn.outputStream.write("""{"password":"$testPassword"}""".toByteArray())
                    resetConn.responseCode
                    resetConn.disconnect()
                } catch (_: Exception) { /* best-effort */ }
            }
        }
        val autoRecoveryToken: String =
            if (env("RECOVERY_TOKEN").isEmpty() && gotrueUsers.isNotEmpty() && testEmail.isNotEmpty()) {
                try {
                    val otpConn = java.net.URI("$gotrueBaseUrl/admin/generate_link")
                        .toURL().openConnection() as java.net.HttpURLConnection
                    otpConn.requestMethod = "POST"
                    otpConn.setRequestProperty("Content-Type", "application/json")
                    otpConn.setRequestProperty("Authorization", "Bearer $serviceKey")
                    otpConn.doOutput = true
                    otpConn.outputStream.write("""{"type":"recovery","email":"$testEmail"}""".toByteArray())
                    val body = if (otpConn.responseCode == 200) otpConn.inputStream.bufferedReader().readText() else ""
                    otpConn.disconnect()
                    Regex(""""email_otp"\s*:\s*"([^"]+)"""").find(body)?.groupValues?.get(1) ?: ""
                } catch (_: Exception) { "" }
            } else env("RECOVERY_TOKEN")

        val gitHash = try {
            val process = ProcessBuilder("git", "rev-parse", "--short", "HEAD")
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.inputStream.bufferedReader().readText().trim().takeIf { it.isNotEmpty() } ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
        val dartDefines = listOf(
            "GIT_COMMIT_HASH" to gitHash,
            "BACK_URL" to env("BACK_URL", dotEnv["INSTANCE_API_URL"] ?: ""),
            "GOTRUE_URL" to gotrueBaseUrl,
            // Tokens: generated fresh from GoTrue when *_EMAIL is set, else stale JWT re-signed.
            "BEARER_TOKEN" to resolveToken("ADMIN_EMAIL", "BEARER_TOKEN"),
            // OWNER role token — required by producer_request_sync_e2e_test (instance-owner scope).
            "OWNER_BEARER_TOKEN" to resolveToken("OWNER_EMAIL", "OWNER_BEARER_TOKEN"),
            "COORDINATOR_TOKEN" to resolveToken("COORDINATOR_EMAIL", "COORDINATOR_TOKEN"),
            "MEMBER_TOKEN" to resolveToken("MEMBER_EMAIL", "MEMBER_TOKEN"),
            "ORGANIZATION_ID" to env("ORGANIZATION_ID"),
            "TEST_EMAIL" to testEmail,
            "TEST_PASSWORD" to testPassword,
            // NEW_PASSWORD must satisfy GoTrue's strength check (PUT /user via OTP flow enforces
            // it). Default is strong enough; TEST_PASSWORD (pass1234) is rejected with 422.
            // After the test, password is NEW_PASSWORD; the next doFirst pre-resets it back.
            "NEW_PASSWORD" to env("NEW_PASSWORD", "TestReset99!"),
            "ADMIN_EMAIL" to env("ADMIN_EMAIL"),
            "RECOVERY_TOKEN" to autoRecoveryToken,
            // Per-run unique — omit from .env to avoid cross-run conflicts.
            "NO_ACCOUNT_NAME" to env("NO_ACCOUNT_NAME", "Test CC $runId"),
            "NO_ACCOUNT_EMAIL" to env("NO_ACCOUNT_EMAIL", "test-cc-$runId@example.com"),
            "REQUESTER_EMAIL" to env("REQUESTER_EMAIL", "req-$runId@example.com"),
            // Per-run unique — used by invitation_sync_e2e_test.
            "INVITE_CREATE_EMAIL" to env("INVITE_CREATE_EMAIL", "inv-create-$runId@example.com"),
            "INVITE_RESEND_EMAIL" to env("INVITE_RESEND_EMAIL", "inv-resend-$runId@example.com"),
            // Per-run unique — used by producer_request_sync_e2e_test.
            // The back checks both producer_name and admin_email for uniqueness
            // (excluding REJECTED), so both must differ across runs.
            "PRODUCER_REQUEST_EMAIL" to env("PRODUCER_REQUEST_EMAIL", "prod-req-$runId@example.com"),
            "PRODUCER_REQUEST_NAME" to env("PRODUCER_REQUEST_NAME", "Test Prod $runId"),
            // Resolved live from GoTrue when TEST_EMAIL is set, else falls back to .env.
            "PRODUCER_ACCOUNT_ID" to resolveUserId(testEmail, "PRODUCER_ACCOUNT_ID"),
            // Resolved live from GoTrue when MEMBER_EMAIL is set, else falls back to .env.
            "MEMBER_SUB" to resolveUserId(env("MEMBER_EMAIL"), "MEMBER_SUB"),
            "PRODUCER_NAME" to env("PRODUCER_NAME"),
            // Unique delivery date to avoid server-side uniqueness conflicts on repeated runs.
            "TEST_DELIVERY_DATE" to env("TEST_DELIVERY_DATE", testDeliveryDate),
        ).map { (name, value) -> "--dart-define=$name=$value" }
        (this as Exec).commandLine(
            listOf(resolvedFlutterCmd, "test", "test/acceptance/cross_component/", "--tags", "cross-component") +
                dartDefines,
        )
    }
}

val frontFormat by tasks.registering(Exec::class) {
    group = "front"
    description = "Formats Flutter source and test files."
    workingDir = projectDir
    commandLine(dartCmd, "format", "lib", "test")
}

val frontBuildAndroid by tasks.registering(Exec::class) {
    group = "front"
    description = "Builds the Android APK (release)."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine(flutterCmd, "--version")
    val resolvedFlutterCmd = flutterCmd
    doFirst {
        val gitHash = try {
            val process = ProcessBuilder("git", "rev-parse", "--short", "HEAD")
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.inputStream.bufferedReader().readText().trim().takeIf { it.isNotEmpty() } ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
        (this as Exec).commandLine(
            resolvedFlutterCmd, "build", "apk", "--release",
            "--dart-define=GIT_COMMIT_HASH=$gitHash",
        )
    }
}

tasks.named("check") {
    dependsOn(frontAnalyze, frontTest, frontAcceptanceTest)
}

tasks.register("lint") {
    dependsOn(frontAnalyze)
}

tasks.register("format") {
    dependsOn(frontFormat)
}

val frontBuildIos by tasks.registering(Exec::class) {
    group = "front"
    description = "Builds the iOS app (simulator, no codesign)."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine(flutterCmd, "--version")
    val resolvedFlutterCmd = flutterCmd
    doFirst {
        val gitHash = try {
            val process = ProcessBuilder("git", "rev-parse", "--short", "HEAD")
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.inputStream.bufferedReader().readText().trim().takeIf { it.isNotEmpty() } ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
        (this as Exec).commandLine(
            resolvedFlutterCmd, "build", "ios",
            "--no-codesign", "--simulator", "--debug",
            "--dart-define=GIT_COMMIT_HASH=$gitHash",
        )
    }
}

val frontBuildWeb by tasks.registering(Exec::class) {
    group = "front"
    description = "Builds the Flutter web app (release)."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine(flutterCmd, "--version")
    val resolvedFlutterCmd = flutterCmd
    doFirst {
        val gitHash = try {
            val process = ProcessBuilder("git", "rev-parse", "--short", "HEAD")
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .start()
            process.inputStream.bufferedReader().readText().trim().takeIf { it.isNotEmpty() } ?: "unknown"
        } catch (_: Exception) {
            "unknown"
        }
        (this as Exec).commandLine(
            resolvedFlutterCmd, "build", "web",
            "--release",
            "--dart-define=GIT_COMMIT_HASH=$gitHash",
        )
    }
}
