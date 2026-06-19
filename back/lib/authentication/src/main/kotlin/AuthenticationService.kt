package authentication

interface AuthenticationService {
    fun getAuthentication(token: String?): Authentication

    fun isUnauthenticatedPath(path: String): Boolean =
        path == "/" ||
            path == "/health" ||
            path == "/v1/auth/login" ||
            path == "/.well-known/amap-en-ligne.json" ||
            path == "/.well-known/apple-app-site-association" ||
            path == "/.well-known/assetlinks.json" ||
            path.startsWith("/v1/public/") ||
            path == "/v1/organization-requests" ||
            path == "/v1/producer-requests" ||
            path == "/v1/activate"
}

sealed class Authentication {
    data class Success(
        val info: AuthenticatedInfo,
    ) : Authentication()

    object InvalidToken : Authentication()

    object ExpiredToken : Authentication()

    /**
     * The token is structurally valid but was issued by a different server instance.
     * The client should redirect the user to [tokenIssuer] for authentication.
     */
    data class WrongServer(
        val tokenIssuer: String?,
    ) : Authentication()
}
