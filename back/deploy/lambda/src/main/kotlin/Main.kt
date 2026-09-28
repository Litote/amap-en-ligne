package deploy.lambda

import com.asyncant.aws.lambda.runtime.runLambda
import instanceconfig.BuildInfo
import io.github.oshai.kotlinlogging.KotlinLogging

fun main() {
    val logger = KotlinLogging.logger {}
    when (System.getenv("_HANDLER")) {
        "deploy.lambda.ActivationEmailMainKt" -> {
            logger.info { "Start Activation Lambda ${BuildInfo.VERSION} (${BuildInfo.COMMIT ?: "local"})" }
            activationEmailMain()
        }

        else -> {
            logger.info { "Start Data Lambda ${BuildInfo.VERSION} (${BuildInfo.COMMIT ?: "local"})" }
            val lambda = DataLambda()
            runLambda { event, _ ->
                lambda.handleRequest(event) { it }
            }
        }
    }
}
