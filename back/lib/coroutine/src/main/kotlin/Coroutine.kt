package coroutine

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

suspend fun <A, B> zipAsync(
    fa: suspend CoroutineScope.() -> A,
    fb: suspend CoroutineScope.() -> B,
): Pair<A, B> =
    coroutineScope {
        val da = async { fa() }
        val db = async { fb() }
        da.await() to db.await()
    }
