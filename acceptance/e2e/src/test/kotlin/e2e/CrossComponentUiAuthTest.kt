package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentUiAuthTest : E2eTestSupport() {
    private val producerAccountId = "ui-auth-e2e-producer"
    private val email = "ui-auth-e2e@test.invalid"
    private val password = "UiAuthTest123!"

    @Test
    fun `GIVEN valid credentials WHEN user signs in on the web app THEN product types screen is shown`() {
        ContainerSuite.createUser(
            email = email,
            password = password,
            producerAccountId = producerAccountId,
            roles = listOf("PRODUCER"),
        )

        runFlutterMobileIntegrationTests(
            target = "integration_test/auth_flow_integration_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "GOTRUE_URL" to gotrueUrl,
                    "TEST_EMAIL" to email,
                    "TEST_PASSWORD" to password,
                ),
        )
    }
}
