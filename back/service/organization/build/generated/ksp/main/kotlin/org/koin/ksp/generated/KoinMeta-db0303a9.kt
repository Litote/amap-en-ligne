package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("organization.OrganizationModule",id="jx3cq", includes=["core.CoreModule"])
public class _KSP_OrganizationOrganizationModule
@MetaDefinition("organization.OrganizationService",moduleTagId="jx3cq:OrganizationOrganizationModule", dependencies=["organizationSyncDAO:persistence.dao.OrganizationSyncDAO","deliveryTemplateSyncDAO:persistence.dao.DeliveryTemplateSyncDAO","producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","notificationPublisher:notificationpublisher.NotificationPublisher","contractSyncDAO:persistence.dao.ContractSyncDAO"], binds=["core.EntityTypeService"])
public class _KSP_OrganizationOrganizationService
@MetaDefinition("organization.OrganizationService",moduleTagId="jx3cq:OrganizationOrganizationModule", dependencies=["organizationSyncDAO:persistence.dao.OrganizationSyncDAO","deliveryTemplateSyncDAO:persistence.dao.DeliveryTemplateSyncDAO","producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","notificationPublisher:notificationpublisher.NotificationPublisher","contractSyncDAO:persistence.dao.ContractSyncDAO"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit