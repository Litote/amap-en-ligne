package http

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class HttpServiceTest {
    private val service = HttpService()

    private val allErrors =
        listOf(
            service.internalServerError("/p"),
            service.expiredTokenError("/p"),
            service.invalidTokenError("/p"),
            service.conflictError("/p", "field"),
            service.forbiddenError("/p"),
            service.notFoundError("/p"),
            service.goneError("/p"),
            service.invalidPayloadError("/p", "reason"),
            service.weakPasswordError("/p", "reason"),
            service.mutationBatchTooLargeError("/p", 1, 2),
            service.wrongServerError("/p", null),
        )

    @Test
    fun `every problem type is a project URN`() {
        allErrors.forEach { error ->
            assertTrue(error.type.startsWith("urn:amap-en-ligne:problem:"), "unexpected type ${error.type}")
        }
    }

    @Test
    fun `invalid token error does not claim the token expired`() {
        val error = service.invalidTokenError("/p")

        assertEquals("INVALID_AUTH_TOKEN", error.error.code)
        assertEquals("missing or invalid authentication token", error.detail)
        assertEquals("Token missing or invalid", error.error.details?.get("reason"))
    }
}
