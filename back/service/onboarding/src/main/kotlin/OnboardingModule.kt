package onboarding

import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module

/**
 * Koin module for the public onboarding services ([PublicService], [AdminService])
 * backing the public REST submission endpoints and the admin join-request review.
 * Wired into the application graph via [sync.SyncModule].
 */
@Module
@ComponentScan
class OnboardingModule
