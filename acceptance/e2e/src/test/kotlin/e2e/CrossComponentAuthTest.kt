package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentAuthTest : E2eTestSupport() {
    private val email = "auth-e2e@test.invalid"
    private val password = "AuthTest123!"

    @Test
    fun `GIVEN valid credentials WHEN flutter signs in via GoTrue THEN sync with back succeeds`() {
        // producerAccountId == sub by invariant: the GoTrue sub (UUID) is the tenant id
        val userId =
            ContainerSuite.createUser(
                email = email,
                password = password,
                roles = listOf("PRODUCER"),
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/auth_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "GOTRUE_URL" to gotrueUrl,
                    "TEST_EMAIL" to email,
                    "TEST_PASSWORD" to password,
                    "PRODUCER_ACCOUNT_ID" to userId,
                ),
        )
    }
}
