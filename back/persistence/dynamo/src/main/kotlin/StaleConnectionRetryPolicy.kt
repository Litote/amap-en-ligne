package persistence.dynamo

import aws.sdk.kotlin.runtime.http.retries.AwsRetryPolicy
import aws.smithy.kotlin.runtime.retries.policy.RetryDirective
import aws.smithy.kotlin.runtime.retries.policy.RetryErrorType
import aws.smithy.kotlin.runtime.retries.policy.RetryPolicy
import software.amazon.awssdk.crt.CrtRuntimeException

/**
 * [AwsRetryPolicy.Default] plus a retry on stale pooled CRT connections.
 *
 * When a Lambda is thawed, the CRT pool may still hold connections DynamoDB closed while the
 * execution environment was frozen. Reusing one fails synchronously in `makeRequest`, before the
 * request is sent. `CrtHttpEngine` would map that failure to a retryable `HttpException`, but it
 * only catches the Kotlin `aws.sdk.kotlin.crt.CrtRuntimeException`, while the JVM
 * `HttpClientConnectionJVM.makeRequest` (aws-crt-kotlin ≤ 0.13.0) lets the Java
 * [CrtRuntimeException] escape unwrapped — so the default policy terminates and the whole sync
 * answers 500. Only these connection-closed codes are retried: the request never left the client.
 */
internal object StaleConnectionRetryPolicy : RetryPolicy<Any?> {
    private val staleConnectionErrors =
        setOf(
            "AWS_ERROR_HTTP_CONNECTION_CLOSED",
            "AWS_ERROR_HTTP_SERVER_CLOSED",
        )

    private const val MAX_CAUSE_DEPTH = 10

    override fun evaluate(result: Result<Any?>): RetryDirective =
        if (result.exceptionOrNull()?.isStaleConnection() == true) {
            RetryDirective.RetryError(RetryErrorType.Transient)
        } else {
            AwsRetryPolicy.Default.evaluate(result)
        }

    private fun Throwable.isStaleConnection(): Boolean =
        generateSequence(this) { it.cause }
            .take(MAX_CAUSE_DEPTH)
            .filterIsInstance<CrtRuntimeException>()
            .any { it.errorName in staleConnectionErrors }
}
