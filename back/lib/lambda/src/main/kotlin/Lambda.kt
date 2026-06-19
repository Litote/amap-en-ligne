package lambda

import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.KoinApplication
import org.koin.core.context.startKoin
import org.koin.core.logger.Level
import org.koin.core.logger.PrintLogger
import properties.Properties

fun startKoin(vararg modules: org.koin.core.module.Module): KoinApplication =
    startKoin {
        Properties.Instance.propertyOrNull("KOIN_LOG_LEVEL")?.apply {
            logger(PrintLogger(Level.valueOf(this)))
        }
        modules(modules.toList())
    }

private val logger = KotlinLogging.logger {}
