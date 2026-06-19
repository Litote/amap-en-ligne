package lambda

import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json.Default.encodeToString
import org.koin.core.KoinApplication
import serialization.json

abstract class SynchronousLambdaBase<R>(
    koin: KoinApplication,
) : LambdaBase(koin) {
    abstract suspend fun call(): R

    abstract val responseSerializer: KSerializer<R>

    final override suspend fun handle(): String =
        json.encodeToString(
            responseSerializer,
            try {
                call()
            } catch (e: Throwable) {
                logger.error(e) { "Technical Error: ${e.message}" }
                technicalError()
            },
        )

    abstract fun technicalError(): R
}

private val logger = KotlinLogging.logger {}
