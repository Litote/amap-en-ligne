package lang

fun <K, V : Any> mapOfNotNullValues(vararg pairs: Pair<K, V?>): Map<K, V> =
    buildMap {
        for ((k, v) in pairs) {
            if (v != null) put(k, v)
        }
    }

fun <K, V : Any> mapOfNotNull(vararg pairs: Pair<K, V>?): Map<K, V> =
    buildMap {
        for (p in pairs) {
            if (p != null) put(p.first, p.second)
        }
    }
