package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

/**
 * Tests the complete flow for AMAP admin account creation, activation, and login:
 * 1. Organization request creation (public)
 * 2. Owner approval via sync
 * 3. Admin activation with email confirmation
 * 4. Admin login verification (sync succeeds only with ADMIN role)
 *
 * This is a regression test for the GoTrue email confirmation fix:
 * createAdminUser must mark email_confirmed_at so admins can login.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentOrganizationAdminActivationE2eTest : E2eTestSupport() {
    private val unique = System.currentTimeMillis()
    private val adminEmail = "amap-admin-e2e-$unique@test.invalid"
    private val adminPassword = "AmapAdmin123!"
    private val ownerEmail = "owner-e2e-$unique@test.invalid"

    @Test
    fun `GIVEN organization request WHEN approved and admin activates THEN admin can login`() {
        // Setup: create owner account (for approving the request)
        ContainerSuite.createUser(
            email = ownerEmail,
            password = "Owner123!",
            roles = listOf("OWNER"),
        )

        // The actual test flow: organization request → approval → activation → login
        runFlutterTests(
            testFile = "test/acceptance/cross_component/organization_admin_activation_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "GOTRUE_URL" to ContainerSuite.gotrueUrl,
                    "MAILHOG_URL" to ContainerSuite.mailhogApiUrl,
                    "OWNER_EMAIL" to ownerEmail,
                    "ADMIN_EMAIL" to adminEmail,
                    "ADMIN_PASSWORD" to adminPassword,
                ),
        )
    }
}
