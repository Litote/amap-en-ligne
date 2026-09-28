package http

enum class HttpMethod {
    GET,
    POST,
    PUT,
    DELETE,
}

fun String.toHttpMethod(): HttpMethod = HttpMethod.entries.firstOrNull { it.name.equals(this, ignoreCase = true) } ?: HttpMethod.GET
