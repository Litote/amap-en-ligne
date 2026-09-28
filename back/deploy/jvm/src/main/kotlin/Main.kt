package deploy.jvm

import authentication.GoTrueAuthenticationModule
import email.delivery.EmailDeliveryModule
import http.HttpModule
import instanceconfig.BuildInfo
import instanceconfig.GoTrueInstanceConfigModule
import io.github.oshai.kotlinlogging.KotlinLogging
import io.ktor.server.cio.CIO
import io.ktor.server.engine.EmbeddedServer
import io.ktor.server.engine.embeddedServer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.koin.core.context.startKoin
import org.koin.core.logger.Level
import org.koin.core.logger.PrintLogger
import org.koin.ksp.generated.module
import persistence.postgres.PostgresModule
import properties.Properties
import provisioning.gotrue.ProvisioningGoTrueModule
import routing.dataRoutingModule
import sync.SyncModule
import volunteershortage.VolunteerShortageService
import kotlin.time.Clock
import kotlin.time.Duration.Companion.milliseconds

private val logger = KotlinLogging.logger {}

fun main() {
    val port = Properties.Instance.intProperty("PORT", 8080)
    bootstrap(port).start(wait = true)
}

fun bootstrap(
    port: Int,
    vararg extraModules: org.koin.core.module.Module,
): EmbeddedServer<*, *> {
    logger.info { "Starting amap-en-ligne back ${BuildInfo.VERSION} (${BuildInfo.COMMIT ?: "local"})" }
    val koin =
        startKoin {
            Properties.Instance.propertyOrNull("KOIN_LOG_LEVEL")?.let {
                logger(PrintLogger(Level.valueOf(it)))
            }
            if (extraModules.isNotEmpty()) {
                allowOverride(true)
            }
            modules(
                SyncModule().module,
                PostgresModule().module,
                GoTrueAuthenticationModule().module,
                GoTrueInstanceConfigModule().module,
                HttpModule().module,
                JvmEmailModule().module,
                EmailDeliveryModule().module,
                ProvisioningGoTrueModule().module,
                *extraModules,
            )
        }
    return embeddedServer(CIO, port = port) {
        installCorsIfConfigured()
        dataRoutingModule(koin)
        // Activation emails (ORGANIZATION_ADMIN) are delivered out-of-band by this
        // poll loop. It runs on the Application coroutine scope so it is cancelled
        // when the server stops — and so every bootstrap path (prod main + e2e) gets
        // it, not just main(). Interval is overridable via ACTIVATION_EMAIL_INTERVAL_MS.
        val intervalMs = Properties.Instance.intProperty("ACTIVATION_EMAIL_INTERVAL_MS", 60_000)
        val cronJob = koin.koin.get<ActivationEmailCronJob>()
        launchPollLoop(intervalMs.toLong(), "activation email cron job") { cronJob.processPending() }
        // Volunteer shortage alerts (ADR-005): same in-process poll loop. The lookback covers
        // two intervals so a delayed tick never drops an alert. Interval is overridable via
        // VOLUNTEER_SHORTAGE_INTERVAL_MS.
        val shortageIntervalMs = Properties.Instance.intProperty("VOLUNTEER_SHORTAGE_INTERVAL_MS", 900_000).toLong()
        val shortageService = koin.koin.get<VolunteerShortageService>()
        launchPollLoop(shortageIntervalMs, "volunteer shortage alert job") {
            shortageService.run(Clock.System.now(), lookback = (2 * shortageIntervalMs).milliseconds)
        }
    }
}

/**
 * Runs [job] every [intervalMs] until the scope is cancelled; a failing tick is logged and
 * never stops the loop.
 */
private fun CoroutineScope.launchPollLoop(
    intervalMs: Long,
    jobName: String,
    job: suspend () -> Unit,
) {
    launch {
        while (isActive) {
            delay(intervalMs)
            try {
                job()
            } catch (e: Throwable) {
                logger.error(e) { "Error in $jobName" }
            }
        }
    }
}
