package lambda.ktor

import io.ktor.server.application.Application
import io.ktor.server.engine.BaseApplicationCall
import kotlinx.coroutines.CoroutineScope
import lambda.APIGatewayV2HTTPEvent
import kotlin.coroutines.CoroutineContext

internal class LambdaApplicationCall(
    application: Application,
    event: APIGatewayV2HTTPEvent,
    override val coroutineContext: CoroutineContext,
) : BaseApplicationCall(application),
    CoroutineScope {
    override val request: LambdaApplicationRequest = LambdaApplicationRequest(this, event)
    override val response: LambdaApplicationResponse = LambdaApplicationResponse(this)

    init {
        putResponseAttribute()
    }
}
