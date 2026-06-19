package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val onboarding_OnboardingModule : Module get() = module {
	single(createdAtStart=true) { _ -> onboarding.AdminService(memberJoinRequestDAO=get())} 
	single(createdAtStart=true) { _ -> onboarding.PublicService(organizationDAO=get(),serverDAO=get(),organizationRequestDAO=get(),organizationRequestSyncDAO=get(),producerRequestDAO=get(),producerRequestSyncDAO=get(),memberJoinRequestDAO=get(),memberJoinRequestSyncDAO=get(),memberJoinRequestNotificationEmailPort=get(),organizationRequestNotificationEmailPort=get(),producerRequestNotificationEmailPort=get(),notificationPublisher=get(),ownerDAO=get(),memberSyncDAO=get(),producerAccountSyncDAO=get(),organizationSyncDAO=get())} 
}
public val onboarding.OnboardingModule.module : org.koin.core.module.Module get() = onboarding_OnboardingModule
