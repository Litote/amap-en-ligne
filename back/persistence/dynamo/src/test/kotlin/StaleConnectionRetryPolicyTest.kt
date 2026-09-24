package persistence.dynamo

import aws.smithy.kotlin.runtime.retries.policy.RetryDirective
import aws.smithy.kotlin.runtime.retries.policy.RetryErrorType
import org.junit.jupiter.api.Test
import software.amazon.awssdk.crt.CrtRuntimeException
import kotlin.test.assertEquals

class StaleConnectionRetryPolicyTest {
    // Message observed in production (CloudWatch) — CrtRuntimeException parses errorName from it.
    private fun crtError(errorName: String) =
        CrtRuntimeException(
            "HttpClientConnection.MakeRequest: Unable to Execute Request " +
                "(aws_last_error: $errorName(2058), The connection has closed or is closing.) $errorName(2058)",
        )

    @Test
    fun `GIVEN a request failed on a connection closed while idle WHEN evaluated THEN retried as transient`() {
        assertEquals(
            RetryDirective.RetryError(RetryErrorType.Transient),
            StaleConnectionRetryPolicy.evaluate(Result.failure(crtError("AWS_ERROR_HTTP_CONNECTION_CLOSED"))),
        )
    }

    @Test
    fun `GIVEN the stale connection error is wrapped WHEN evaluated THEN retried as transient`() {
        val error = IllegalStateException("wrapper", crtError("AWS_ERROR_HTTP_SERVER_CLOSED"))

        assertEquals(
            RetryDirective.RetryError(RetryErrorType.Transient),
            StaleConnectionRetryPolicy.evaluate(Result.failure(error)),
        )
    }

    @Test
    fun `GIVEN another CRT error WHEN evaluated THEN left to the default AWS policy`() {
        assertEquals(
            RetryDirective.TerminateAndFail,
            StaleConnectionRetryPolicy.evaluate(Result.failure(crtError("AWS_IO_BROKEN_PIPE"))),
        )
    }

    @Test
    fun `GIVEN other outcomes WHEN evaluated THEN delegated to the default AWS policy`() {
        assertEquals(
            RetryDirective.TerminateAndSucceed,
            StaleConnectionRetryPolicy.evaluate(Result.success("ok")),
        )
        assertEquals(
            RetryDirective.TerminateAndFail,
            StaleConnectionRetryPolicy.evaluate(Result.failure(IllegalArgumentException("bad input"))),
        )
    }
}
