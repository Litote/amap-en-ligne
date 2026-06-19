package e2e

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import deploy.jvm.bootstrap
import io.ktor.server.engine.EmbeddedServer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.Assumptions
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.koin.core.context.GlobalContext
import org.koin.core.context.stopKoin
import org.slf4j.LoggerFactory
import org.testcontainers.containers.GenericContainer
import org.testcontainers.containers.Network
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.containers.wait.strategy.Wait
import java.io.File
import java.net.ServerSocket
import java.net.Socket
import java.net.URI
import java.net.URLDecoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.sql.DriverManager
import java.util.Date

private val responseJson = Json { ignoreUnknownKeys = true }

internal object ContainerSuite {
    internal const val JWT_SECRET = "e2e-test-jwt-secret-e2e-test-jwt-secret-e2e"
    internal const val JWT_ISSUER = "http://gotrue-e2e:9999"
    internal const val JWT_AUDIENCE = "authenticated"

    // The instance must have exactly one configured server for activation flows
    // (ActivationService uses serverDAO.list().singleOrNull()). Seed one canonical
    // row suite-wide so every test shares it instead of inserting divergent ones.
    internal const val E2E_SERVER_ID = "e2e-instance-server"

    private val network: Network by lazy { Network.newNetwork() }

    internal val postgres: PostgreSQLContainer<*> by lazy {
        PostgreSQLContainer("postgres:16")
            .withNetwork(network)
            .withNetworkAliases("postgres-e2e")
            .withUsername("postgres")
            .withPassword("postgres")
            .withDatabaseName("postgres")
            .withInitScript("e2e/init-schemas.sql")
            .waitingFor(Wait.forListeningPort())
            .also { it.start() }
    }

    internal val mailhogContainer: GenericContainer<*> by lazy {
        GenericContainer("mailhog/mailhog:v1.0.1").apply {
            withNetwork(network)
            withNetworkAliases("mailhog-e2e")
            addExposedPort(1025)
            addExposedPort(8025)
            waitingFor(Wait.forHttp("/api/v2/messages").forPort(8025))
            start()
        }
    }

    internal val mailhogApiUrl: String by lazy {
        "http://localhost:${mailhogContainer.getMappedPort(8025)}"
    }

    internal val gotrueContainer: GenericContainer<*> by lazy {
        // Start Postgres and MailHog first so their mapped ports are known.
        val pg = postgres
        val mh = mailhogContainer
        // Docker's internal DNS (127.0.0.11) is unreliable in this environment —
        // container-to-container hostnames (postgres-e2e, mailhog-e2e) cannot be
        // resolved. Route GoTrue's outbound connections through the host instead
        // via host.docker.internal (resolved to the host gateway IP).
        GenericContainer("supabase/gotrue:v2.158.1").apply {
            addExposedPort(9999)
            withExtraHost("host.docker.internal", "host-gateway")
            withEnv("GOTRUE_API_HOST", "0.0.0.0")
            withEnv("GOTRUE_API_PORT", "9999")
            withEnv("API_EXTERNAL_URL", "http://localhost:9999")
            withEnv("GOTRUE_SITE_URL", "http://localhost:8080")
            withEnv("GOTRUE_DB_DRIVER", "postgres")
            withEnv(
                "GOTRUE_DB_DATABASE_URL",
                "postgres://${pg.username}:${pg.password}@host.docker.internal:${pg.getMappedPort(
                    5432,
                )}/${pg.databaseName}?sslmode=disable&search_path=auth",
            )
            withEnv("GOTRUE_JWT_SECRET", JWT_SECRET)
            withEnv("GOTRUE_JWT_ISSUER", JWT_ISSUER)
            withEnv("GOTRUE_JWT_AUD", JWT_AUDIENCE)
            withEnv("GOTRUE_JWT_EXP", "3600")
            withEnv("GOTRUE_DISABLE_SIGNUP", "false")
            withEnv("GOTRUE_MAILER_AUTOCONFIRM", "true")
            withEnv("GOTRUE_EXTERNAL_EMAIL_ENABLED", "true")
            withEnv("GOTRUE_EXTERNAL_PHONE_ENABLED", "false")
            withEnv("GOTRUE_JWT_ADMIN_ROLES", "service_role,supabase_admin")
            withEnv("GOTRUE_SMTP_HOST", "host.docker.internal")
            withEnv("GOTRUE_SMTP_PORT", "${mh.getMappedPort(1025)}")
            withEnv("GOTRUE_SMTP_ADMIN_EMAIL", "noreply@test.invalid")
            withEnv("GOTRUE_SMTP_SENDER_NAME", "AMAP Test")
            withEnv("GOTRUE_URI_ALLOW_LIST", "http://localhost:**")
            waitingFor(Wait.forHttp("/health").forPort(9999))
            start()
        }
    }

    internal val gotrueUrl: String by lazy { "http://localhost:${gotrueContainer.getMappedPort(9999)}" }

    private val httpClient: HttpClient = HttpClient.newHttpClient()

    internal fun mintAdminJwt(): String =
        JWT
            .create()
            .withClaim("role", "supabase_admin")
            .sign(Algorithm.HMAC256(JWT_SECRET))

    internal fun mintServiceRoleJwt(): String {
        val now = java.time.Instant.now()
        return JWT
            .create()
            .withIssuer(JWT_ISSUER)
            .withClaim("role", "service_role")
            .withIssuedAt(java.util.Date.from(now))
            .withExpiresAt(java.util.Date.from(now.plusSeconds(3600)))
            .sign(Algorithm.HMAC256(JWT_SECRET))
    }

    internal fun mintGoTrueToken(
        subject: String = "00000000-0000-0000-0000-000000000001",
        email: String = "user@example.com",
        roles: List<String> = emptyList(),
        organizationId: String? = null,
        producerAccountId: String? = null,
    ): String {
        val now = java.time.Instant.now()
        val appMetadata =
            mapOf(
                "producer_account_id" to producerAccountId,
                "organization_id" to organizationId,
                "roles" to roles,
                "scopes" to listOf<String>(),
            ).filterValues { it != null }
        return JWT
            .create()
            .withIssuer(JWT_ISSUER)
            .withAudience(JWT_AUDIENCE)
            .withSubject(subject)
            .withIssuedAt(Date.from(now))
            .withExpiresAt(Date.from(now.plusSeconds(3600)))
            .withClaim("email", email)
            .withClaim("email_verified", true)
            .withClaim("app_metadata", appMetadata)
            .withClaim(
                "user_metadata",
                mapOf(
                    "given_name" to "Test",
                    "family_name" to "User",
                ),
            ).sign(Algorithm.HMAC256(JWT_SECRET))
    }

    internal fun createUser(
        email: String,
        password: String,
        producerAccountId: String? = null,
        organizationId: String? = null,
        roles: List<String> = emptyList(),
    ): String {
        // 1. Create user via signup (idempotent — GoTrue returns 422 if exists)
        postJson("$gotrueUrl/signup", """{"email":"$email","password":"$password"}""")

        // 2. Resolve user id via admin list
        val adminToken = mintAdminJwt()
        val usersBody = getJson("$gotrueUrl/admin/users", adminToken)
        val userId =
            responseJson
                .parseToJsonElement(usersBody)
                .jsonObject["users"]!!
                .jsonArray
                .first { it.jsonObject["email"]!!.jsonPrimitive.content == email }
                .jsonObject["id"]!!
                .jsonPrimitive
                .content

        // 3. Patch app_metadata and password
        val appMetadata = buildAppMetadata(producerAccountId, organizationId, roles)
        putJson(
            "$gotrueUrl/admin/users/$userId",
            """{"password":"$password","email_confirm":true,"app_metadata":$appMetadata}""",
            adminToken,
        )

        return userId
    }

    internal fun signIn(
        email: String,
        password: String,
    ): String {
        val body =
            postJson(
                "$gotrueUrl/token?grant_type=password",
                """{"email":"$email","password":"$password"}""",
            )
        return responseJson
            .parseToJsonElement(body)
            .jsonObject["access_token"]!!
            .jsonPrimitive
            .content
    }

    internal fun getRecoveryToken(email: String): String {
        val adminToken = mintAdminJwt()
        val body =
            postJson(
                "$gotrueUrl/admin/generate_link",
                """{"type":"recovery","email":"$email","redirect_to":"http://localhost/"}""",
                adminToken,
            )
        return responseJson
            .parseToJsonElement(body)
            .jsonObject["email_otp"]!!
            .jsonPrimitive
            .content
    }

    private fun postJson(
        url: String,
        body: String,
        bearerToken: String? = null,
    ): String {
        val builder =
            HttpRequest
                .newBuilder()
                .uri(URI(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
        if (bearerToken != null) builder.header("Authorization", "Bearer $bearerToken")
        val response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString())
        check(response.statusCode() < 300 || response.statusCode() == 422) {
            "POST $url failed: ${response.statusCode()} — ${response.body()}"
        }
        return response.body()
    }

    private fun putJson(
        url: String,
        body: String,
        bearerToken: String? = null,
    ): String {
        val builder =
            HttpRequest
                .newBuilder()
                .uri(URI(url))
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(body))
        if (bearerToken != null) builder.header("Authorization", "Bearer $bearerToken")
        val response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString())
        check(response.statusCode() < 300) {
            "PUT $url failed: ${response.statusCode()} — ${response.body()}"
        }
        return response.body()
    }

    private fun getJson(
        url: String,
        bearerToken: String? = null,
    ): String {
        val builder =
            HttpRequest
                .newBuilder()
                .uri(URI(url))
                .GET()
        if (bearerToken != null) builder.header("Authorization", "Bearer $bearerToken")
        val response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString())
        check(response.statusCode() < 300) {
            "GET $url failed: ${response.statusCode()} — ${response.body()}"
        }
        return response.body()
    }

    internal fun waitForEmail(
        to: String,
        timeoutMs: Long = 15_000,
    ): String {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            val body = getJson(mailhogApiUrl + "/api/v2/messages")
            val items =
                responseJson
                    .parseToJsonElement(body)
                    .jsonObject["items"]
                    ?.jsonArray
                    ?: emptyList()
            for (item in items) {
                val toList = item.jsonObject["To"]?.jsonArray ?: continue
                val match =
                    toList.any { recipient ->
                        val mailbox = recipient.jsonObject["Mailbox"]?.jsonPrimitive?.content ?: ""
                        val domain = recipient.jsonObject["Domain"]?.jsonPrimitive?.content ?: ""
                        "$mailbox@$domain" == to
                    }
                if (match) {
                    return item.jsonObject["Content"]
                        ?.jsonObject
                        ?.get("Body")
                        ?.jsonPrimitive
                        ?.content
                        ?: ""
                }
            }
            Thread.sleep(500)
        }
        error("No email received for $to within ${timeoutMs}ms")
    }

    /**
     * Generates a fresh recovery OTP for [email] via GoTrue's admin API and
     * returns the `email_otp` field.  Unlike reading from MailHog, this avoids
     * CORS and quoted-printable parsing issues entirely.  Calling this
     * invalidates any previously issued recovery token for that user.
     */
    internal fun generateRecoveryOtp(email: String): String? =
        try {
            val body =
                postJson(
                    "$gotrueUrl/admin/generate_link",
                    """{"type":"recovery","email":"$email","redirect_to":"http://localhost/"}""",
                    mintAdminJwt(),
                )
            responseJson
                .parseToJsonElement(body)
                .jsonObject["email_otp"]
                ?.jsonPrimitive
                ?.content
        } catch (e: Exception) {
            null
        }

    /**
     * Polls MailHog until a recovery email addressed to [email] arrives, then
     * extracts the OTP token from the `token=` query parameter in the recovery
     * link.  Handles quoted-printable encoding that GoTrue applies to email
     * bodies.  Returns `null` if no email arrives within [timeoutMs].
     */
    internal fun extractOtpFromEmail(
        email: String,
        timeoutMs: Long = 20_000,
    ): String? {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            val body = getJson("$mailhogApiUrl/api/v2/messages")
            val items =
                responseJson
                    .parseToJsonElement(body)
                    .jsonObject["items"]
                    ?.jsonArray
                    ?: emptyList()

            for (item in items) {
                val toList = item.jsonObject["To"]?.jsonArray ?: continue
                val addressMatch =
                    toList.any { recipient ->
                        val mailbox = recipient.jsonObject["Mailbox"]?.jsonPrimitive?.content ?: ""
                        val domain = recipient.jsonObject["Domain"]?.jsonPrimitive?.content ?: ""
                        "$mailbox@$domain" == email
                    }
                if (!addressMatch) continue

                val candidates = mutableListOf<String>()

                fun collectParts(parts: kotlinx.serialization.json.JsonArray?) {
                    parts?.forEach { part ->
                        (part.jsonObject["Body"] as? kotlinx.serialization.json.JsonPrimitive)
                            ?.content
                            ?.let { candidates.add(it) }
                        collectParts(
                            (part.jsonObject["MIME"] as? kotlinx.serialization.json.JsonObject)
                                ?.get("Parts") as? kotlinx.serialization.json.JsonArray,
                        )
                    }
                }
                collectParts(
                    (item.jsonObject["MIME"] as? kotlinx.serialization.json.JsonObject)
                        ?.get("Parts") as? kotlinx.serialization.json.JsonArray,
                )
                (
                    (item.jsonObject["Content"] as? kotlinx.serialization.json.JsonObject)
                        ?.get("Body") as? kotlinx.serialization.json.JsonPrimitive
                )?.content
                    ?.let { candidates.add(it) }

                for (text in candidates) {
                    val decoded =
                        text
                            .replace("=\r\n", "")
                            .replace("=\n", "")
                            .replace(Regex("=([0-9A-Fa-f]{2})")) { m ->
                                m.groupValues[1]
                                    .toInt(16)
                                    .toChar()
                                    .toString()
                            }
                    val token = Regex("[?&]token=([a-zA-Z0-9_%-]+)").find(decoded)?.groupValues?.get(1)
                    if (!token.isNullOrEmpty()) return token
                }
            }
            Thread.sleep(500)
        }
        return null
    }

    internal fun clearEmails() {
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI(mailhogApiUrl + "/api/v1/messages"))
                .DELETE()
                .build()
        httpClient.send(request, HttpResponse.BodyHandlers.discarding())
    }

    internal fun insertOrganization(
        organizationId: String,
        name: String,
        contactEmail: String,
    ) {
        DriverManager
            .getConnection(postgres.jdbcUrl, postgres.username, postgres.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization(organization_id, name, contact_email, active_status)
                        VALUES (?, ?, ?, true)
                        ON CONFLICT (organization_id) DO NOTHING
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId)
                        stmt.setString(2, name)
                        stmt.setString(3, contactEmail)
                        stmt.executeUpdate()
                    }
            }
    }

    internal fun insertServer(
        serverId: String,
        name: String,
        url: String,
    ) {
        DriverManager
            .getConnection(postgres.jdbcUrl, postgres.username, postgres.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO server(server_id, name, url)
                        VALUES (?, ?, ?)
                        ON CONFLICT (server_id) DO NOTHING
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, serverId)
                        stmt.setString(2, name)
                        stmt.setString(3, url)
                        stmt.executeUpdate()
                    }
            }
    }

    internal fun insertMember(
        memberId: String,
        organizationId: String,
        roles: List<String> = listOf("VOLUNTEER"),
        firstName: String? = null,
        lastName: String? = null,
        email: String? = null,
        serverId: String = "e2e-default-server",
    ) {
        val userSettingsJson =
            """{"language":"fr","timezone":"Europe/Paris","server_id":"$serverId","last_updated_instant":"1970-01-01T00:00:00Z"}"""
        DriverManager
            .getConnection(postgres.jdbcUrl, postgres.username, postgres.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO member(
                            member_id, organization_id, roles, active_status,
                            first_name, last_name, email,
                            account_status,
                            member_settings, member_preferences, user_preferences, user_settings,
                            created_instant, last_updated_instant
                        )
                        VALUES (?, ?, ?, true, ?, ?, ?, 'ACTIVE',
                            '{"delivery_reminders":{"days_before":1,"reminder_time":"08:00"},"accessibility_options":{"high_contrast":false,"large_text":false,"screen_reader":false},"last_updated_instant":"1970-01-01T00:00:00Z"}'::jsonb,
                            '{"delivery_reminders_enabled":true,"volunteer_alerts_enabled":true,"last_updated_instant":"1970-01-01T00:00:00Z"}'::jsonb,
                            '{"email_notifications_enabled":true,"push_notifications_enabled":true,"last_updated_instant":"1970-01-01T00:00:00Z"}'::jsonb,
                            ?::jsonb,
                            0, 0)
                        ON CONFLICT (member_id) DO UPDATE SET
                            roles = EXCLUDED.roles,
                            first_name = EXCLUDED.first_name,
                            last_name = EXCLUDED.last_name,
                            email = EXCLUDED.email,
                            last_updated_instant = EXCLUDED.last_updated_instant
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, memberId)
                        stmt.setString(2, organizationId)
                        stmt.setArray(3, conn.createArrayOf("text", roles.toTypedArray()))
                        stmt.setString(4, firstName)
                        stmt.setString(5, lastName)
                        stmt.setString(6, email)
                        stmt.setString(7, userSettingsJson)
                        stmt.executeUpdate()
                    }
            }
    }

    internal fun insertOrganizationWithDelivery(
        organizationId: String,
        name: String,
        contactEmail: String,
        deliveryJson: String,
    ) {
        DriverManager
            .getConnection(postgres.jdbcUrl, postgres.username, postgres.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization(organization_id, name, contact_email, active_status, deliveries)
                        VALUES (?, ?, ?, true, ?::jsonb)
                        ON CONFLICT (organization_id) DO UPDATE SET
                            deliveries = EXCLUDED.deliveries
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId)
                        stmt.setString(2, name)
                        stmt.setString(3, contactEmail)
                        stmt.setString(4, deliveryJson)
                        stmt.executeUpdate()
                    }
            }
    }

    private fun buildAppMetadata(
        producerAccountId: String?,
        organizationId: String?,
        roles: List<String>,
    ): String {
        val rolesList = roles.joinToString(",") { "\"$it\"" }
        return buildString {
            append("{")
            if (producerAccountId != null) {
                append("\"producer_account_id\":\"$producerAccountId\",")
            }
            if (organizationId != null) {
                append("\"organization_id\":\"$organizationId\",")
            }
            append("\"roles\":[$rolesList]}")
        }
    }
}

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
internal abstract class E2eTestSupport {
    companion object {
        private val logger = LoggerFactory.getLogger(E2eTestSupport::class.java)
    }

    protected var backPort: Int = 0
        private set

    protected lateinit var bearerToken: String
        private set

    protected val gotrueUrl: String
        get() = ContainerSuite.gotrueUrl

    private var server: EmbeddedServer<*, *>? = null
    private var emulatorProcess: Process? = null

    @BeforeAll
    fun setUpE2eTestSupport() {
        try {
            // Initialize shared containers (idempotent after first call)
            ContainerSuite.gotrueUrl

            System.setProperty("POSTGRES_URL", ContainerSuite.postgres.jdbcUrl)
            System.setProperty("POSTGRES_USER", ContainerSuite.postgres.username)
            System.setProperty("POSTGRES_PASSWORD", ContainerSuite.postgres.password)
            System.setProperty("GOTRUE_JWT_SECRET", ContainerSuite.JWT_SECRET)
            System.setProperty("GOTRUE_JWT_ISSUER", ContainerSuite.JWT_ISSUER)
            System.setProperty("GOTRUE_JWT_AUDIENCE", ContainerSuite.JWT_AUDIENCE)
            System.setProperty("GOTRUE_SERVICE_ROLE_KEY", ContainerSuite.mintServiceRoleJwt())
            // The JWT issuer is a container-internal hostname (token validation), but the
            // GoTrue admin API must be reached from this in-JVM server via the host-mapped
            // port — otherwise createAdminUser/activation cannot provision auth users.
            System.setProperty("GOTRUE_ADMIN_API_URL", ContainerSuite.gotrueUrl)
            System.setProperty("INSTANCE_NAME", "E2E Test Instance")
            // Activation emails (ORGANIZATION_ADMIN) are delivered by a poll loop;
            // run it fast so the org-admin activation flow gets its email promptly.
            System.setProperty("ACTIVATION_EMAIL_INTERVAL_MS", "500")
            // Point the in-JVM back server's SMTP at the e2e MailHog container so its
            // transactional emails land in the same inbox the Flutter tests poll
            // (default localhost:1025 would hit an unrelated dev MailHog).
            System.setProperty("SMTP_HOST", "localhost")
            System.setProperty(
                "SMTP_PORT",
                ContainerSuite.mailhogContainer.getMappedPort(1025).toString(),
            )

            backPort = ServerSocket(0).use { it.localPort }
            System.setProperty("INSTANCE_API_URL", "http://127.0.0.1:$backPort/")

            runCatching { stopKoin() }
            server = bootstrap(backPort).also { it.start(wait = false) }

            // Flyway has migrated by now (bootstrap starts the Postgres client); seed
            // the single canonical server row required by activation flows.
            ContainerSuite.insertServer(
                serverId = ContainerSuite.E2E_SERVER_ID,
                name = "E2E Instance Server",
                url = "http://127.0.0.1:$backPort",
            )
        } catch (e: Throwable) {
            tearDownE2eTestSupport()
            throw e
        }
    }

    @AfterAll
    fun tearDownE2eTestSupport() {
        try {
            server?.let { runningServer ->
                runCatching { runningServer.stop(0, 1_000) }
                    .onFailure { logger.warn("Failed to stop embedded E2E server cleanly", it) }
            }
            server = null

            runCatching {
                val koin = GlobalContext.getOrNull()
                if (koin != null) {
                    runCatching {
                        val dataSource = koin.get<javax.sql.DataSource>()
                        (dataSource as? AutoCloseable)?.close()
                    }
                }
                stopKoin()
            }.onFailure { logger.warn("Failed to stop Koin cleanly during E2E teardown", it) }

            // Stop emulator if one was started
            emulatorProcess?.let { process ->
                try {
                    process.destroy()
                    process.waitFor(5, java.util.concurrent.TimeUnit.SECONDS)
                } catch (_: Exception) {
                    // Ignore errors during cleanup
                }
            }
            emulatorProcess = null
        } finally {
            System.clearProperty("POSTGRES_URL")
            System.clearProperty("POSTGRES_USER")
            System.clearProperty("POSTGRES_PASSWORD")
            System.clearProperty("GOTRUE_JWT_SECRET")
            System.clearProperty("GOTRUE_JWT_ISSUER")
            System.clearProperty("GOTRUE_JWT_AUDIENCE")
            System.clearProperty("GOTRUE_SERVICE_ROLE_KEY")
            System.clearProperty("GOTRUE_ADMIN_API_URL")
            System.clearProperty("INSTANCE_NAME")
            System.clearProperty("INSTANCE_API_URL")
            System.clearProperty("ACTIVATION_EMAIL_INTERVAL_MS")
            System.clearProperty("SMTP_HOST")
            System.clearProperty("SMTP_PORT")
        }
    }

    protected fun runFlutterTests(
        testFile: String,
        dartDefines: Map<String, String>,
    ) {
        val frontDir = System.getProperty("front.dir")
        Assumptions.assumeTrue(frontDir != null, "front.dir system property not set")

        val flutterAvailable =
            runCatching {
                ProcessBuilder("flutter", "--version")
                    .redirectErrorStream(true)
                    .start()
                    .waitFor()
            }.getOrElse { 1 } == 0
        Assumptions.assumeTrue(flutterAvailable, "flutter not available in PATH")

        val command =
            mutableListOf(
                "flutter",
                "test",
                testFile,
                "--tags",
                "cross-component",
            )
        dartDefines.forEach { (k, v) -> command += "--dart-define=$k=$v" }

        val process =
            ProcessBuilder(command)
                .directory(File(frontDir!!))
                .inheritIO()
                .start()

        val exitCode = process.waitFor()
        check(exitCode == 0) { "Flutter test $testFile failed with exit code $exitCode" }
    }

    protected fun runFlutterMobileIntegrationTests(
        target: String,
        dartDefines: Map<String, String> = emptyMap(),
    ) {
        val frontDir = System.getProperty("front.dir")
        Assumptions.assumeTrue(frontDir != null, "front.dir system property not set")

        val flutterAvailable =
            runCatching {
                ProcessBuilder("flutter", "--version")
                    .redirectErrorStream(true)
                    .start()
                    .waitFor()
            }.getOrElse { 1 } == 0
        Assumptions.assumeTrue(flutterAvailable, "flutter not available in PATH")

        val emulatorId = ensureAndroidEmulatorRunning()

        val command = mutableListOf("flutter", "test", "-d", emulatorId, target)
        // Android emulator accesses the host machine via 10.0.2.2, not localhost
        val emulatorDartDefines =
            dartDefines.mapValues { (_, value) ->
                value.replace("localhost", "10.0.2.2")
            }
        emulatorDartDefines.forEach { (k, v) -> command += "--dart-define=$k=$v" }

        val process =
            ProcessBuilder(command)
                .directory(File(frontDir!!))
                .inheritIO()
                .start()

        val exitCode = process.waitFor()
        check(exitCode == 0) { "Flutter mobile integration test $target failed with exit code $exitCode" }
    }

    /**
     * Ensures an Android device is available for mobile E2E tests.
     *
     * Behavior:
     * 1. Checks if any Android device is already connected/running via `flutter devices`
     * 2. If not, lists available emulators via `flutter emulators`
     * 3. Starts the first available emulator via `flutter emulators --launch <id>`
     * 4. Waits up to 3 minutes for the emulator to become ready
     * 5. The process is stored and cleaned up in [tearDownE2eTestSupport]
     *
     * Prerequisites:
     * - Flutter SDK (handles both discovery and startup)
     * - At least one Android Virtual Device created (via `flutter emulators --create`)
     * - `flutter devices` must work to detect connected devices
     *
     * If an emulator cannot be started, the test is skipped via [Assumptions.assumeTrue]
     * rather than failing, allowing CI to continue if Android setup is unavailable.
     */
    private fun ensureAndroidEmulatorRunning(): String {
        // Check if an Android device is already connected
        val devicesOutput =
            runCatching {
                ProcessBuilder("flutter", "devices", "--machine")
                    .redirectErrorStream(true)
                    .start()
                    .inputStream
                    .bufferedReader()
                    .readText()
            }.getOrElse { "" }

        if (devicesOutput.contains("android")) {
            logger.info("Android device already running")
            // Extract device ID from flutter devices JSON output
            val deviceId =
                responseJson
                    .parseToJsonElement(devicesOutput)
                    .jsonArray
                    .firstOrNull { device ->
                        device.jsonObject["targetPlatform"]
                            ?.jsonPrimitive
                            ?.content
                            ?.startsWith("android") == true
                    }?.jsonObject
                    ?.get("id")
                    ?.jsonPrimitive
                    ?.content
            return deviceId ?: error("no device id found")
        }

        // Skip test if no Android device and E2E_SKIP_IF_NO_ANDROID_DEVICE is enabled (default: true)
        val skipIfNoDevice = System.getenv("E2E_SKIP_IF_NO_ANDROID_DEVICE")?.toBoolean() ?: true
        Assumptions.assumeTrue(
            !skipIfNoDevice,
            "No Android device found. Set E2E_SKIP_IF_NO_ANDROID_DEVICE=false to start an emulator.",
        )

        logger.info("No Android device found, attempting to start emulator...")

        // List available emulators via flutter
        val emulatorsOutput =
            runCatching {
                ProcessBuilder("flutter", "emulators")
                    .redirectErrorStream(true)
                    .start()
                    .inputStream
                    .bufferedReader()
                    .readText()
            }.getOrElse { "" }

        // Parse emulator IDs from flutter output (first column of the table)
        val emulatorIds =
            emulatorsOutput
                .split("\n")
                .drop(2) // Skip header and separator line
                .filter { it.isNotEmpty() && !it.contains("---") && !it.contains("To run") }
                .mapNotNull { line ->
                    line
                        .split("•")
                        .firstOrNull()
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                }
        Assumptions.assumeTrue(emulatorIds.isNotEmpty(), "No Android emulators found. Create one with 'flutter emulators --create'")

        val emulatorId = emulatorIds.first()
        logger.info("Starting emulator: $emulatorId")

        // Start the emulator in background via flutter emulators --launch
        emulatorProcess =
            ProcessBuilder("flutter", "emulators", "--launch", emulatorId)
                .redirectError(ProcessBuilder.Redirect.DISCARD)
                .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                .start()

        // Wait for emulator to be ready (poll flutter devices)
        val maxWaitTime = 180_000L // 3 minutes
        val pollInterval = 5_000L // 5 seconds
        val deadline = System.currentTimeMillis() + maxWaitTime
        var emulatorReady = false

        while (System.currentTimeMillis() < deadline && !emulatorReady) {
            Thread.sleep(pollInterval)
            val output =
                runCatching {
                    ProcessBuilder("flutter", "devices", "--machine")
                        .redirectErrorStream(true)
                        .start()
                        .inputStream
                        .bufferedReader()
                        .readText()
                }.getOrElse { "" }

            if (output.contains("\"category\":\"mobile\"") || output.contains("\"category\":\"tablet\"")) {
                emulatorReady = true
                logger.info("Emulator is ready!")
            }
        }

        Assumptions.assumeTrue(emulatorReady, "Android emulator failed to start within ${maxWaitTime / 1000}s")
        return emulatorId
    }

    /**
     * Builds the Flutter web app and returns the `build/web` output directory.
     *
     * The server URL (backend + GoTrue) is **not** baked at build time — it is
     * injected at runtime via [flutterServerConfigScript] / [Page.addInitScript].
     * This means the build output is identical across test runs and Flutter's
     * incremental cache is fully effective (warm runs take < 2 s).
     *
     * Takes ~30–60 s on first run (warm cache is much faster).
     */
    protected fun buildFlutterWeb(): File {
        val frontDir = System.getProperty("front.dir")
        Assumptions.assumeTrue(frontDir != null, "front.dir system property not set")

        val flutterAvailable =
            runCatching {
                ProcessBuilder("flutter", "--version")
                    .redirectErrorStream(true)
                    .start()
                    .waitFor()
            }.getOrElse { 1 } == 0
        Assumptions.assumeTrue(flutterAvailable, "flutter not available in PATH")

        val command = mutableListOf("flutter", "build", "web", "--wasm")

        val process =
            ProcessBuilder(command)
                .directory(File(frontDir!!))
                .inheritIO()
                .start()

        val exitCode = process.waitFor()
        check(exitCode == 0) { "flutter build web failed with exit code $exitCode" }

        val webBuildDir = File(frontDir, "build/web")

        // Patch flutter_bootstrap.js to use the locally-bundled CanvasKit rather than loading
        // it from the Google CDN (gstatic.com). This ensures headless Playwright tests work
        // in offline / restricted network environments. The patch is idempotent.
        val bootstrapFile = File(webBuildDir, "flutter_bootstrap.js")
        if (bootstrapFile.exists()) {
            val content = bootstrapFile.readText()
            if (!content.contains("config: { canvasKitBaseUrl")) {
                bootstrapFile.writeText(
                    content.replace(
                        "_flutter.loader.load({\n  serviceWorkerSettings:",
                        "_flutter.loader.load({\n  config: { canvasKitBaseUrl: 'canvaskit/' },\n  serviceWorkerSettings:",
                    ),
                )
            }
        }

        return webBuildDir
    }

    /**
     * Starts a minimal static-file HTTP server that serves [directory] on a
     * random port.  Handles the Flutter SPA pattern: unknown paths fall back to
     * `index.html`.  Returns the listening port and the server handle; call
     * `server.stop(0)` to shut it down.
     */
    protected fun serveStaticFiles(directory: File): Pair<Int, com.sun.net.httpserver.HttpServer> {
        val port = ServerSocket(0).use { it.localPort }
        val server =
            com.sun.net.httpserver.HttpServer.create(
                java.net.InetSocketAddress("127.0.0.1", port),
                0,
            )
        server.createContext("/") { exchange ->
            val rawPath = exchange.requestURI.path.let { if (it == "/" || it.isEmpty()) "/index.html" else it }
            val file = File(directory, rawPath.removePrefix("/"))
            val (statusCode, contentType, bytes) =
                if (file.exists() && file.isFile) {
                    Triple(200, staticMimeType(file.extension), file.readBytes())
                } else {
                    val index = File(directory, "index.html")
                    Triple(200, "text/html; charset=utf-8", index.readBytes())
                }
            exchange.responseHeaders.set("Content-Type", contentType)
            exchange.sendResponseHeaders(statusCode, bytes.size.toLong())
            exchange.responseBody.use { it.write(bytes) }
        }
        server.executor = null
        server.start()
        return Pair(port, server)
    }

    /**
     * Returns a JavaScript snippet to inject via [Page.addInitScript] that
     * writes the given server config into Flutter's `SharedPreferences`
     * localStorage key before the app initialises.
     *
     * Flutter web reads `SharedPreferences` from `localStorage` using the key
     * prefix `flutter.`.  The `ServerConfigStorage` persists the selected
     * `ServerConfig` under the `server.selected.config.v2` key.  By writing
     * this key before navigation the app picks up the test server on first
     * load without any build-time dart-defines.
     */
    protected fun flutterServerConfigScript(
        backendUrl: String,
        gotrueUrl: String,
    ): String {
        val escapedBackend = backendUrl.replace("'", "\\'")
        val escapedGotrue = gotrueUrl.replace("'", "\\'")
        return """
            // shared_preferences_web 2.x JSON-encodes string values, so a stored
            // String "foo" appears in localStorage as '"foo"' (double-encoded).
            // We must do the same: JSON.stringify the config object to get the
            // inner JSON string, then JSON.stringify *that* string so that the
            // SharedPreferences decode step (json.decode) returns a String, not
            // a Map.
            const config = {
              id: 'e2e-test-server',
              name: 'E2E Test Server',
              provider: 'gotrue',
              backend_url: '$escapedBackend',
              gotrue_url: '$escapedGotrue'
            };
            localStorage.setItem(
              'flutter.server.selected.config.v2',
              JSON.stringify(JSON.stringify(config))
            );
            """.trimIndent()
    }

    private fun staticMimeType(extension: String): String =
        when (extension.lowercase()) {
            "html" -> "text/html; charset=utf-8"
            "js", "mjs" -> "application/javascript"
            "css" -> "text/css"
            "png" -> "image/png"
            "jpg", "jpeg" -> "image/jpeg"
            "ico" -> "image/x-icon"
            "wasm" -> "application/wasm"
            "json" -> "application/json"
            "ttf" -> "font/ttf"
            "woff" -> "font/woff"
            "woff2" -> "font/woff2"
            "svg" -> "image/svg+xml"
            else -> "application/octet-stream"
        }

    /**
     * Starts a tiny HTTP server that serves the GoTrue recovery OTP for a given
     * email address.  The server polls MailHog server-side (no CORS restriction)
     * and responds with CORS headers so the Flutter web app can call it from
     * within Chrome.
     *
     * Returns the listening port and the [ServerSocket] — close the socket to
     * stop the server.
     */
    protected fun startOtpProxy(): Pair<Int, ServerSocket> {
        val serverSocket = ServerSocket(0)
        Thread {
            try {
                while (!serverSocket.isClosed) {
                    val client = serverSocket.accept()
                    Thread { handleOtpProxyRequest(client) }
                        .apply { isDaemon = true }
                        .start()
                }
            } catch (e: Exception) {
                // Server socket closed — normal shutdown.
            }
        }.apply {
            isDaemon = true
            start()
        }
        return Pair(serverSocket.localPort, serverSocket)
    }

    private fun handleOtpProxyRequest(client: Socket) {
        client.use {
            val input = client.getInputStream().bufferedReader()
            val output = client.getOutputStream()
            val requestLine = input.readLine() ?: return
            // Drain remaining request headers.
            var header = input.readLine()
            while (header != null && header.isNotEmpty()) {
                header = input.readLine()
            }
            val corsHeaders =
                "Access-Control-Allow-Origin: *\r\n" +
                    "Access-Control-Allow-Methods: GET, OPTIONS\r\n"
            if (requestLine.startsWith("OPTIONS")) {
                output.write("HTTP/1.1 200 OK\r\n${corsHeaders}Content-Length: 0\r\n\r\n".toByteArray())
                output.flush()
                return
            }
            val queryString = requestLine.substringAfter("?", "").substringBefore(" ")
            val email =
                queryString
                    .split("&")
                    .find { it.startsWith("email=") }
                    ?.drop(6)
                    ?.let { URLDecoder.decode(it, "UTF-8") }
                    ?: ""
            val otp =
                try {
                    ContainerSuite.getRecoveryToken(email)
                } catch (e: Exception) {
                    ""
                }
            val body = otp.toByteArray()
            output.write(
                "HTTP/1.1 200 OK\r\n${corsHeaders}Content-Type: text/plain\r\nContent-Length: ${body.size}\r\n\r\n"
                    .toByteArray(),
            )
            output.write(body)
            output.flush()
        }
    }
}
