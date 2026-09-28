package deploy.lambda

import com.asyncant.aws.lambda.runtime.runLambda
import kotlinx.coroutines.runBlocking
import volunteershortage.VolunteerShortageService
import kotlin.time.Clock

/**
 * Entry point of the Lambda triggered by the EventBridge Scheduler (`rate(15 minutes)`,
 * `infra/modules/lambda`) that sends the volunteer shortage alerts. The scheduler payload
 * is ignored; the default lookback (two intervals) tolerates a delayed invocation.
 */
fun volunteerShortageMain() {
    val service = startDataKoin().koin.get<VolunteerShortageService>()
    runLambda { _, _ ->
        runBlocking { service.run(Clock.System.now()) }
        ""
    }
}
