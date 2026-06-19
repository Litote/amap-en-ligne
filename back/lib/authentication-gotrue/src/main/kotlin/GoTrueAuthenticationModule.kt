package authentication

import org.koin.core.annotation.Module
import org.koin.core.annotation.Single

/**
 * Koin module wiring the GoTrue-backed [AuthenticationService]. Loaded by the JVM deployment
 * (self-hosted Supabase Auth + Postgres).
 */
@Module
class GoTrueAuthenticationModule {
    @Single(createdAtStart = true)
    fun authenticationService(): AuthenticationService = GoTrueAuthenticationService()
}
