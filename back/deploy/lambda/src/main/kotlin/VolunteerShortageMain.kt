package deploy.lambda

import com.asyncant.aws.lambda.runtime.runLambda
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.runBlocking
import organization.DeliveryAutoCloseService
import volunteershortage.VolunteerShortageService
import kotlin.time.Clock

/**
 * Entry point of the Lambda triggered by the EventBridge Scheduler (`rate(15 minutes)`,
 * `infra/modules/lambda`) running the scheduled jobs: the volunteer shortage alerts, then the
 * auto-close of past deliveries. The scheduler payload is ignored; the default lookback (two
 * intervals) tolerates a delayed invocation. Each job is isolated: a failing one never
 * prevents the other.
 */
fun volunteerShortageMain() {
    val koin = startDataKoin().koin
    val shortageService = koin.get<VolunteerShortageService>()
    val autoCloseService = koin.get<DeliveryAutoCloseService>()
    runLambda { _, _ ->
        runBlocking {
            val now = Clock.System.now()
            runCatching { shortageService.run(now) }
                .onFailure { logger.error(it) { "Volunteer shortage alert job failed" } }
            runCatching { autoCloseService.run(now) }
                .onFailure { logger.error(it) { "Delivery auto-close job failed" } }
        }
        ""
    }
}

private val logger = KotlinLogging.logger {}
