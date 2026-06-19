package deploy.jvm

import authentication.GoTrueAuthenticationModule
import email.delivery.EmailDeliveryModule
import http.HttpModule
import instanceconfig.GoTrueInstanceConfigModule
import io.github.oshai.kotlinlogging.KotlinLogging
import io.ktor.server.cio.CIO
import io.ktor.server.engine.EmbeddedServer
import io.ktor.server.engine.embeddedServer
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

private val logger = KotlinLogging.logger {}

fun main() {
    val port = Properties.Instance.intProperty("PORT", 8080)
    bootstrap(port).start(wait = true)
}

fun bootstrap(
    port: Int,
    vararg extraModules: org.koin.core.module.Module,
): EmbeddedServer<*, *> {
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
        launch {
            while (isActive) {
                delay(intervalMs.toLong())
                try {
                    cronJob.processPending()
                } catch (e: Throwable) {
                    logger.error(e) { "Error in activation email cron job" }
                }
            }
        }
    }
}
