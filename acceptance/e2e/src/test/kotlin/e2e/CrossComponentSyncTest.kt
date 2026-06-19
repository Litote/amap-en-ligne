package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentSyncTest : E2eTestSupport() {
    private val producerAccountId = "sync-e2e-producer"
    private val email = "sync-e2e@test.invalid"
    private val password = "SyncTest123!"

    @Test
    fun `GIVEN authenticated producer WHEN flutter bootstraps sync THEN empty state received`() {
        ContainerSuite.createUser(
            email = email,
            password = password,
            producerAccountId = producerAccountId,
            roles = listOf("PRODUCER"),
        )
        val token = ContainerSuite.signIn(email, password)

        runFlutterTests(
            testFile = "test/acceptance/cross_component/sync_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "BEARER_TOKEN" to token,
                    "PRODUCER_ACCOUNT_ID" to producerAccountId,
                ),
        )
    }
}
