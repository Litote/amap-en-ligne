package instanceconfig

import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import kotlin.test.assertEquals

@Execution(ExecutionMode.SAME_THREAD)
internal class CognitoInstanceConfigModuleTest {
    private val requiredProperties =
        mapOf(
            "INSTANCE_NAME" to "Test Instance",
            "INSTANCE_API_URL" to "http://localhost/",
            "COGNITO_ISSUER_URL" to "http://localhost/cognito",
            "COGNITO_CLIENT_ID" to "client-id",
        )

    @AfterEach
    fun tearDown() {
        requiredProperties.keys.forEach(System::clearProperty)
    }

    @Test
    fun `GIVEN required properties WHEN instanceConfig is built THEN it carries the build version and commit`() {
        requiredProperties.forEach { (name, value) -> System.setProperty(name, value) }

        val config = CognitoInstanceConfigModule().instanceConfig()

        assertEquals(BuildInfo.VERSION, config.serverVersion)
        assertEquals(BuildInfo.COMMIT, config.serverCommit)
        assertEquals("Test Instance", config.name)
        assertEquals("http://localhost/", config.apiUrl)
        assertEquals("1", config.protocolVersion)
        assertEquals(
            CognitoInstanceAuthConfig(issuerUrl = "http://localhost/cognito", clientId = "client-id"),
            config.auth,
        )
    }
}
