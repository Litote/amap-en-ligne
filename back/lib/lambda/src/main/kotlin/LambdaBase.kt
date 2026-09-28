package lambda

import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.ExperimentalSerializationApi
import org.koin.core.Koin
import org.koin.core.KoinApplication
import org.koin.core.component.KoinComponent
import serialization.json

abstract class LambdaBase(
    val koin: KoinApplication,
) : KoinComponent {
    override fun getKoin(): Koin = koin.koin

    lateinit var lambdaContext: LambdaContext

    fun handleRequest(
        input: String,
        context: (String) -> String,
    ): String {
        this.lambdaContext = LambdaRequestContext(input, context)
        return runBlocking {
            handle()
        }
    }

    @OptIn(ExperimentalSerializationApi::class)
    inline fun <reified T : Any> read(): T = json.decodeFromString(lambdaContext.input)

    abstract suspend fun handle(): String
}

interface LambdaContext {
    val input: String
    val context: (String) -> String
}

private class LambdaRequestContext(
    override val input: String,
    override val context: (String) -> String,
) : LambdaContext

private val logger = KotlinLogging.logger {}
