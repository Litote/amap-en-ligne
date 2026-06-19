package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentPasswordResetTest : E2eTestSupport() {
    private val email = "reset-e2e@test.invalid"
    private val password = "ResetTest123!"
    private val newPassword = "ResetTestNew456!"

    @Test
    fun `GIVEN admin-generated recovery token WHEN flutter confirms reset THEN sign-in with new password succeeds`() {
        // producerAccountId == sub by invariant: the GoTrue sub (UUID) is the tenant id
        val userId =
            ContainerSuite.createUser(
                email = email,
                password = password,
                roles = listOf("PRODUCER"),
            )
        val recoveryToken = ContainerSuite.getRecoveryToken(email)

        runFlutterTests(
            testFile = "test/acceptance/cross_component/password_reset_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "GOTRUE_URL" to gotrueUrl,
                    "TEST_EMAIL" to email,
                    "NEW_PASSWORD" to newPassword,
                    "RECOVERY_TOKEN" to recoveryToken,
                    "PRODUCER_ACCOUNT_ID" to userId,
                ),
        )
    }
}
