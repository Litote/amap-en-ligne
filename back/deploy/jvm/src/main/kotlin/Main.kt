package deploy.jvm

import authentication.GoTrueAuthenticationModule
import email.delivery.EmailDeliveryModule
import http.HttpModule
import instanceconfig.GoTrueInstanceConfigModule
import io.github.oshai.kotlinlogging.KotlinLogging
import io.ktor.server.cio.CIO
import io.ktor.server.engine.EmbeddedServer
import io.ktor.server.engine.embeddedServer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.koin.core.context.GlobalContext
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
    val server = bootstrap(port)
    val intervalMs = Properties.Instance.intProperty("ACTIVATION_EMAIL_INTERVAL_MS", 60_000)
    val cronJob = GlobalContext.get().get<ActivationEmailCronJob>()
    CoroutineScope(Dispatchers.IO + SupervisorJob()).launch {
        while (true) {
            delay(intervalMs.toLong())
            try {
                cronJob.processPending()
            } catch (e: Throwable) {
                logger.error(e) { "Error in activation email cron job" }
            }
        }
    }
    server.start(wait = true)
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
    }
}
