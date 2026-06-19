package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("onboarding.OnboardingModule",id="uooyd6")
public class _KSP_OnboardingOnboardingModule
@MetaDefinition("onboarding.AdminService",moduleTagId="uooyd6:OnboardingOnboardingModule", dependencies=["memberJoinRequestDAO:persistence.dao.MemberJoinRequestDAO"])
public class _KSP_OnboardingAdminService
@MetaDefinition("onboarding.PublicService",moduleTagId="uooyd6:OnboardingOnboardingModule", dependencies=["organizationDAO:persistence.dao.OrganizationDAO","serverDAO:persistence.dao.ServerDAO","organizationRequestDAO:persistence.dao.OrganizationRequestDAO","organizationRequestSyncDAO:persistence.dao.OrganizationRequestSyncDAO","producerRequestDAO:persistence.dao.ProducerRequestDAO","producerRequestSyncDAO:persistence.dao.ProducerRequestSyncDAO","memberJoinRequestDAO:persistence.dao.MemberJoinRequestDAO","memberJoinRequestSyncDAO:persistence.dao.MemberJoinRequestSyncDAO","memberJoinRequestNotificationEmailPort:email.MemberJoinRequestNotificationEmailPort","organizationRequestNotificationEmailPort:email.OrganizationRequestNotificationEmailPort","producerRequestNotificationEmailPort:email.ProducerRequestNotificationEmailPort","notificationPublisher:notificationpublisher.NotificationPublisher","ownerDAO:persistence.dao.OwnerSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO"])
public class _KSP_OnboardingPublicService