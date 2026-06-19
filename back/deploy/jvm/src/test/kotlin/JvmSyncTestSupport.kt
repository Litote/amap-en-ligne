package deploy.jvm

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import id.Id
import io.ktor.server.engine.EmbeddedServer
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.BeforeEach
import org.koin.core.context.stopKoin
import org.testcontainers.containers.PostgreSQLContainer
import persistence.changes.ClientMutation
import persistence.changes.OwnerInvitationPayload
import persistence.changes.SyncRequest
import persistence.changes.SyncResponse
import persistence.changes.Upsert
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import serialization.json
import java.net.ServerSocket
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.sql.DriverManager
import java.time.Instant
import java.util.Date
import kotlin.test.assertEquals
import kotlin.time.Clock

abstract class JvmSyncTestSupport {
    protected val container = PostgreSQLContainer("postgres:16")

    protected val httpClient: HttpClient = HttpClient.newHttpClient()
    protected lateinit var server: EmbeddedServer<*, *>
    protected var port: Int = 0

    protected val tenantId: String = "producerAccountId"

    // Test-only HS256 secret used to mint a GoTrue-shaped JWT that the
    // GoTrueAuthenticationService wired by `bootstrap` can verify against.
    protected val jwtSecret = "test-jwt-secret-test-jwt-secret-test-jwt-secret"
    protected val jwtIssuer = "http://localhost:9999/auth/v1"
    private val jwtAudience = "authenticated"

    protected lateinit var bearerToken: String

    @BeforeAll
    fun setUpJvmSyncTestSupport() {
        // Koin lives in a single process-wide global context shared by every test class in
        // this JVM. If a previous class leaked its context (e.g. its teardown threw before
        // reaching stopKoin), bootstrap()'s startKoin would fail here with
        // KoinApplicationAlreadyStartedException. Defensively clear any leaked context first;
        // stopKoin() is a no-op when nothing is started.
        stopKoin()
        container.start()
        System.setProperty("POSTGRES_URL", container.jdbcUrl)
        System.setProperty("POSTGRES_USER", container.username)
        System.setProperty("POSTGRES_PASSWORD", container.password)
        System.setProperty("GOTRUE_JWT_SECRET", jwtSecret)
        System.setProperty("GOTRUE_JWT_ISSUER", jwtIssuer)
        System.setProperty("GOTRUE_JWT_AUDIENCE", jwtAudience)
        System.setProperty("INSTANCE_NAME", "Test Instance")

        bearerToken = mintGoTrueToken()

        port = ServerSocket(0).use { it.localPort }
        System.setProperty("INSTANCE_API_URL", "http://127.0.0.1:$port/")
        System.setProperty("GOTRUE_SERVICE_ROLE_KEY", mintServiceRoleToken())
        server = bootstrap(port)
        server.start(wait = false)
    }

    @AfterAll
    fun tearDownJvmSyncTestSupport() {
        // stopKoin() must always run, even if the server failed to start or stop() throws —
        // otherwise the leaked global Koin context breaks the next test class's startKoin.
        try {
            if (::server.isInitialized) server.stop(0, 1_000)
        } finally {
            stopKoin()
        }
        container.stop()
        System.clearProperty("POSTGRES_URL")
        System.clearProperty("POSTGRES_USER")
        System.clearProperty("POSTGRES_PASSWORD")
        System.clearProperty("GOTRUE_JWT_SECRET")
        System.clearProperty("GOTRUE_JWT_ISSUER")
        System.clearProperty("GOTRUE_JWT_AUDIENCE")
        System.clearProperty("INSTANCE_NAME")
        System.clearProperty("INSTANCE_API_URL")
        System.clearProperty("GOTRUE_SERVICE_ROLE_KEY")
    }

    @AfterEach
    fun resetDb() {
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .createStatement()
                    .use {
                        it.execute(
                            "TRUNCATE producer, owner, owner_invitation, member_join_request, member_invitation, activation_token, product_type, changes, member, contract, delivery_template, organization_producer, organization_product, basket_exchange, organization, producer_account, server, organization_request",
                        )
                    }
            }
        insertDefaultProducer()
    }

    @BeforeEach
    fun insertDefaultProducer() {
        val producerPrefs = """{"production_alerts_enabled":true,"last_updated_instant":"1970-01-01T00:00:00Z"}"""
        val userPrefs =
            """{"email_notifications_enabled":true,"push_notifications_enabled":false,"last_updated_instant":"1970-01-01T00:00:00Z"}"""
        val userSettings =
            """{"language":"fr","timezone":"Europe/Paris","server_id":"default","last_updated_instant":"1970-01-01T00:00:00Z"}"""
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO producer (
                            producer_id, producer_account_id, role, association_instant,
                            status, producer_preferences, user_preferences, user_settings
                        )
                        VALUES (?, ?, 'OWNER', 0, 'ACTIVE', ?, ?, ?)
                        ON CONFLICT (producer_id) DO NOTHING
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, tenantId)
                        stmt.setString(2, tenantId)
                        stmt.setString(3, producerPrefs)
                        stmt.setString(4, userPrefs)
                        stmt.setString(5, userSettings)
                        stmt.executeUpdate()
                    }
            }
    }

    protected fun postRawSync(body: String): HttpResponse<String> {
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port/v1/sync"))
                .header("Authorization", "Bearer $bearerToken")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build()
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString())
    }

    protected fun postRawSync(request: SyncRequest): HttpResponse<String> =
        postRawSync(json.encodeToString(SyncRequest.serializer(), request))

    protected fun decodeSyncResponse(response: HttpResponse<String>): SyncResponse {
        assertEquals(200, response.statusCode())
        return json.decodeFromString(SyncResponse.serializer(), response.body())
    }

    protected fun postSync(request: SyncRequest): SyncResponse = decodeSyncResponse(postRawSync(request))

    protected fun postSyncAs(
        token: String,
        request: SyncRequest,
    ): SyncResponse {
        val httpRequest =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port/v1/sync"))
                .header("Authorization", "Bearer $token")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json.encodeToString(SyncRequest.serializer(), request)))
                .build()
        val response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString())
        return decodeSyncResponse(response)
    }

    /**
     * Inserts an Owner row directly into Postgres (no sync, no Change record).
     *
     * After the sub/id unification, [sub] is accepted for call-site compatibility but is
     * ignored — ownerId == sub by convention, so the same value is used for both.
     */
    protected fun insertOwnerDirectly(
        ownerId: String,
        @Suppress("UNUSED_PARAMETER") sub: String = ownerId,
        email: String,
    ) {
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO owner (owner_id, first_name, last_name, email,
                                          account_status, registered_at, updated_at)
                        VALUES (?, 'Test', 'Owner', ?, 'ACTIVE', 0, 0)
                        ON CONFLICT (owner_id) DO NOTHING
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, ownerId)
                        stmt.setString(2, email)
                        stmt.executeUpdate()
                    }
            }
    }

    /**
     * Inserts a bare Organization row directly into Postgres (no sync, no Change record).
     *
     * Required before [insertMemberDirectly] because the member table has a FK on organization_id.
     * The org sync mutation will later upsert the full data over this stub row.
     */
    protected fun insertOrganizationDirectly(
        organizationId: String,
        name: String = "Test Organization",
    ) {
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization (organization_id, name, contact_email, active_status)
                        VALUES (?, ?, 'test@example.com', true)
                        ON CONFLICT (organization_id) DO NOTHING
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId)
                        stmt.setString(2, name)
                        stmt.executeUpdate()
                    }
            }
    }

    /**
     * Inserts a bare Member row directly into Postgres (no sync, no Change record).
     *
     * After the sub/id unification, [memberId] must equal the auth subject so that
     * [MemberSyncDAO.findOrganizationIdBySub] can resolve the organization when the
     * corresponding JWT caller submits a sync request.
     */
    protected fun insertMemberDirectly(
        memberId: String,
        organizationId: String,
        roles: List<String>,
    ) {
        val roleArray = roles.joinToString(",", "{", "}") { "\"$it\"" }
        val memberSettingsJson =
            """{"delivery_reminders":{"days_before":1,"reminder_time":"08:00"},"accessibility_options":{"high_contrast":false,"large_text":false,"screen_reader":false},"last_updated_instant":"1970-01-01T00:00:00Z"}"""
        val memberPreferencesJson =
            """{"delivery_reminders_enabled":true,"volunteer_alerts_enabled":true,"last_updated_instant":"1970-01-01T00:00:00Z"}"""
        val userPreferencesJson =
            """{"email_notifications_enabled":true,"push_notifications_enabled":false,"last_updated_instant":"1970-01-01T00:00:00Z"}"""
        val userSettingsJson =
            """{"language":"fr","timezone":"Europe/Paris","server_id":"default","last_updated_instant":"1970-01-01T00:00:00Z"}"""
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO member (
                            member_id, organization_id, roles, active_status,
                            member_settings, member_preferences, user_preferences, user_settings
                        )
                        VALUES (?, ?, ?::TEXT[], true, ?::jsonb, ?::jsonb, ?::jsonb, ?::jsonb)
                        ON CONFLICT (member_id) DO UPDATE SET roles = EXCLUDED.roles
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, memberId)
                        stmt.setString(2, organizationId)
                        stmt.setString(3, roleArray)
                        stmt.setString(4, memberSettingsJson)
                        stmt.setString(5, memberPreferencesJson)
                        stmt.setString(6, userPreferencesJson)
                        stmt.setString(7, userSettingsJson)
                        stmt.executeUpdate()
                    }
            }
    }

    protected fun postOwnerInvitationMutation(
        ownerToken: String,
        firstName: String = "New",
        lastName: String = "Owner",
        email: String = "newowner@example.com",
    ): SyncResponse =
        postSyncAs(
            token = ownerToken,
            request =
                SyncRequest(
                    mutations =
                        listOf(
                            ClientMutation(
                                clientOpId = "owner-invite",
                                op =
                                    Upsert(
                                        OwnerInvitationPayload(
                                            OwnerInvitation(
                                                invitationId = Id("tmp_owner_invitation"),
                                                firstName = firstName,
                                                lastName = lastName,
                                                email = email,
                                                status = OwnerInvitationStatus.PENDING_ACTIVATION,
                                                submittedAt = Clock.System.now(),
                                            ),
                                        ),
                                    ),
                            ),
                        ),
                ),
        )

    protected fun resendOwnerInvitationMutation(
        ownerToken: String,
        invitationId: String,
    ): SyncResponse =
        postSyncAs(
            token = ownerToken,
            request =
                SyncRequest(
                    mutations =
                        listOf(
                            ClientMutation(
                                clientOpId = "owner-resend",
                                op =
                                    Upsert(
                                        OwnerInvitationPayload(
                                            OwnerInvitation(
                                                invitationId = Id(invitationId),
                                                firstName = "New",
                                                lastName = "Owner",
                                                email = readOwnerInvitationEmail(invitationId) ?: error("missing invitation"),
                                                status = OwnerInvitationStatus.PENDING_ACTIVATION,
                                                submittedAt = Clock.System.now(),
                                                resendRequestedAt = Clock.System.now(),
                                            ),
                                        ),
                                    ),
                            ),
                        ),
                ),
        )

    protected fun postActivate(
        token: String,
        password: String = "Password123!",
    ): HttpResponse<String> {
        val body = """{"token":"$token","password":"$password"}"""
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port/v1/activate"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build()
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString())
    }

    protected fun readActivationTokenForEmail(email: String): String? =
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        "SELECT token FROM activation_token WHERE admin_email = ? AND kind = 'OWNER' ORDER BY created_at DESC LIMIT 1",
                    ).use { stmt ->
                        stmt.setString(1, email)
                        stmt.executeQuery().use { rs ->
                            if (rs.next()) rs.getString("token") else null
                        }
                    }
            }

    protected fun readOwnerInvitationEmail(invitationId: String): String? =
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        "SELECT email FROM owner_invitation WHERE invitation_id = ?",
                    ).use { stmt ->
                        stmt.setString(1, invitationId)
                        stmt.executeQuery().use { rs ->
                            if (rs.next()) rs.getString("email") else null
                        }
                    }
            }

    protected fun mintServiceRoleToken(): String {
        val now = Instant.now()
        return JWT
            .create()
            .withIssuer(jwtIssuer)
            .withClaim("role", "service_role")
            .withIssuedAt(Date.from(now))
            .withExpiresAt(Date.from(now.plusSeconds(3600)))
            .sign(Algorithm.HMAC256(jwtSecret))
    }

    protected fun mintGoTrueToken(
        // After sub/id unification: for PRODUCER tokens, subject == producerAccountId.
        // Use tenantId as the default subject so that SyncScope.ProducerAccount(tenantId).key
        // matches the scope that AuthorizedScopeResolver derives from auth.memberId.
        subject: String = tenantId,
        email: String = "producer@example.com",
        roles: List<String> = listOf("PRODUCER"),
        organizationId: String? = null,
        @Suppress("UNUSED_PARAMETER") producerAccountId: String? = tenantId,
    ): String {
        val now = Instant.now()
        val appMetadata =
            mapOf(
                "roles" to roles,
                "scopes" to listOf<String>(),
            )
        return JWT
            .create()
            .withIssuer(jwtIssuer)
            .withAudience(jwtAudience)
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
            ).sign(Algorithm.HMAC256(jwtSecret))
    }
}
