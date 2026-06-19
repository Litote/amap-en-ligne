package coroutine

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.async

suspend fun <A, B> CoroutineScope.zipAsync(
    fa: suspend CoroutineScope.() -> A,
    fb: suspend CoroutineScope.() -> B,
): Pair<A, B> {
    val da = async { fa() }
    val db = async { fb() }
    return da.await() to db.await()
}
