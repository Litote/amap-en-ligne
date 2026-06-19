package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentUiPasswordResetTest : E2eTestSupport() {
    private val producerAccountId = "ui-reset-e2e-producer"
    private val email = "ui-reset-e2e@test.invalid"
    private val password = "UiResetTest123!"
    private val newPassword = "UiResetNew456!"

    @Test
    fun `GIVEN user submits forgot-password form WHEN OTP arrives in MailHog THEN user resets password and signs in`() {
        ContainerSuite.clearEmails()
        ContainerSuite.createUser(
            email = email,
            password = password,
            producerAccountId = producerAccountId,
            roles = listOf("PRODUCER"),
        )

        val (otpProxyPort, otpProxySocket) = startOtpProxy()
        try {
            runFlutterMobileIntegrationTests(
                target = "integration_test/password_reset_integration_test.dart",
                dartDefines =
                    mapOf(
                        "BACK_URL" to "http://127.0.0.1:$backPort",
                        "GOTRUE_URL" to gotrueUrl,
                        "OTP_PROXY_URL" to "http://localhost:$otpProxyPort",
                        "TEST_EMAIL" to email,
                        "NEW_PASSWORD" to newPassword,
                    ),
            )
        } finally {
            otpProxySocket.close()
        }
    }
}
