package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("persistence.postgres.PostgresModule",id="g128ff", includes=["properties.PropertiesModule"])
public class _KSP_PersistencePostgresPostgresModule
@MetaDefinition("persistence.postgres.postgresClient",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["properties:properties.Properties"], binds=["persistence.postgres.PostgresClient"])
public class _KSP_PersistencePostgresPostgresClient
@MetaDefinition("persistence.postgres.dataSource",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["postgresClient:persistence.postgres.PostgresClient"], binds=["javax.sql.DataSource"])
public class _KSP_PersistencePostgresDataSource
@MetaDefinition("persistence.postgres.dataSource",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["postgresClient:persistence.postgres.PostgresClient"], binds=["javax.sql.DataSource"])
public val _KSP_JavaxSqlDataSource : Unit get() = Unit
@MetaDefinition("persistence.postgres.OwnerInvitationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OwnerInvitationSyncDAO"])
public class _KSP_PersistencePostgresOwnerInvitationSyncPostgresDAO
@MetaDefinition("persistence.postgres.OwnerInvitationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OwnerInvitationSyncDAO"])
public val _KSP_PersistenceDaoOwnerInvitationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.MemberSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberSyncDAO"])
public class _KSP_PersistencePostgresMemberSyncPostgresDAO
@MetaDefinition("persistence.postgres.MemberSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberSyncDAO"])
public val _KSP_PersistenceDaoMemberSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.OrganizationRequestPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationRequestDAO"])
public class _KSP_PersistencePostgresOrganizationRequestPostgresDAO
@MetaDefinition("persistence.postgres.OrganizationRequestPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationRequestDAO"])
public val _KSP_PersistenceDaoOrganizationRequestDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.OrganizationRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationRequestSyncDAO"])
public class _KSP_PersistencePostgresOrganizationRequestSyncPostgresDAO
@MetaDefinition("persistence.postgres.OrganizationRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationRequestSyncDAO"])
public val _KSP_PersistenceDaoOrganizationRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.OrganizationPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationDAO"])
public class _KSP_PersistencePostgresOrganizationPostgresDAO
@MetaDefinition("persistence.postgres.OrganizationPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationDAO"])
public val _KSP_PersistenceDaoOrganizationDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.MemberInvitationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberInvitationSyncDAO"])
public class _KSP_PersistencePostgresMemberInvitationSyncPostgresDAO
@MetaDefinition("persistence.postgres.MemberInvitationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberInvitationSyncDAO"])
public val _KSP_PersistenceDaoMemberInvitationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ContractSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ContractSyncDAO"])
public class _KSP_PersistencePostgresContractSyncPostgresDAO
@MetaDefinition("persistence.postgres.ContractSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ContractSyncDAO"])
public val _KSP_PersistenceDaoContractSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ProducerAccountSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerAccountSyncDAO"])
public class _KSP_PersistencePostgresProducerAccountSyncPostgresDAO
@MetaDefinition("persistence.postgres.ProducerAccountSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerAccountSyncDAO"])
public val _KSP_PersistenceDaoProducerAccountSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ServerPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ServerDAO"])
public class _KSP_PersistencePostgresServerPostgresDAO
@MetaDefinition("persistence.postgres.ServerPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ServerDAO"])
public val _KSP_PersistenceDaoServerDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.OrganizationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationSyncDAO"])
public class _KSP_PersistencePostgresOrganizationSyncPostgresDAO
@MetaDefinition("persistence.postgres.OrganizationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OrganizationSyncDAO"])
public val _KSP_PersistenceDaoOrganizationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.OwnerSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OwnerSyncDAO"])
public class _KSP_PersistencePostgresOwnerSyncPostgresDAO
@MetaDefinition("persistence.postgres.OwnerSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.OwnerSyncDAO"])
public val _KSP_PersistenceDaoOwnerSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ErrorReportSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ErrorReportSyncDAO"])
public class _KSP_PersistencePostgresErrorReportSyncPostgresDAO
@MetaDefinition("persistence.postgres.ErrorReportSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ErrorReportSyncDAO"])
public val _KSP_PersistenceDaoErrorReportSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.DeliveryTemplateSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.DeliveryTemplateSyncDAO"])
public class _KSP_PersistencePostgresDeliveryTemplateSyncPostgresDAO
@MetaDefinition("persistence.postgres.DeliveryTemplateSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.DeliveryTemplateSyncDAO"])
public val _KSP_PersistenceDaoDeliveryTemplateSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ProducerRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerRequestSyncDAO"])
public class _KSP_PersistencePostgresProducerRequestSyncPostgresDAO
@MetaDefinition("persistence.postgres.ProducerRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerRequestSyncDAO"])
public val _KSP_PersistenceDaoProducerRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.MemberJoinRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberJoinRequestSyncDAO"])
public class _KSP_PersistencePostgresMemberJoinRequestSyncPostgresDAO
@MetaDefinition("persistence.postgres.MemberJoinRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberJoinRequestSyncDAO"])
public val _KSP_PersistenceDaoMemberJoinRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.BasketExchangeSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.BasketExchangeSyncDAO"])
public class _KSP_PersistencePostgresBasketExchangeSyncPostgresDAO
@MetaDefinition("persistence.postgres.BasketExchangeSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.BasketExchangeSyncDAO"])
public val _KSP_PersistenceDaoBasketExchangeSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ChangePostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ChangeDAO"])
public class _KSP_PersistencePostgresChangePostgresDAO
@MetaDefinition("persistence.postgres.ChangePostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ChangeDAO"])
public val _KSP_PersistenceDaoChangeDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.AttendanceEmailRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.AttendanceEmailRequestSyncDAO"])
public class _KSP_PersistencePostgresAttendanceEmailRequestSyncPostgresDAO
@MetaDefinition("persistence.postgres.AttendanceEmailRequestSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.AttendanceEmailRequestSyncDAO"])
public val _KSP_PersistenceDaoAttendanceEmailRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.NotificationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.NotificationSyncDAO"])
public class _KSP_PersistencePostgresNotificationSyncPostgresDAO
@MetaDefinition("persistence.postgres.NotificationSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.NotificationSyncDAO"])
public val _KSP_PersistenceDaoNotificationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.AccountDeletionLogPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.AccountDeletionLogDAO"])
public class _KSP_PersistencePostgresAccountDeletionLogPostgresDAO
@MetaDefinition("persistence.postgres.AccountDeletionLogPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.AccountDeletionLogDAO"])
public val _KSP_PersistenceDaoAccountDeletionLogDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.MemberJoinRequestPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberJoinRequestDAO"])
public class _KSP_PersistencePostgresMemberJoinRequestPostgresDAO
@MetaDefinition("persistence.postgres.MemberJoinRequestPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.MemberJoinRequestDAO"])
public val _KSP_PersistenceDaoMemberJoinRequestDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.DeviceTokenSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.DeviceTokenSyncDAO"])
public class _KSP_PersistencePostgresDeviceTokenSyncPostgresDAO
@MetaDefinition("persistence.postgres.DeviceTokenSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.DeviceTokenSyncDAO"])
public val _KSP_PersistenceDaoDeviceTokenSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ProducerSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerSyncDAO"])
public class _KSP_PersistencePostgresProducerSyncPostgresDAO
@MetaDefinition("persistence.postgres.ProducerSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerSyncDAO"])
public val _KSP_PersistenceDaoProducerSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ProducerRequestPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerRequestDAO"])
public class _KSP_PersistencePostgresProducerRequestPostgresDAO
@MetaDefinition("persistence.postgres.ProducerRequestPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProducerRequestDAO"])
public val _KSP_PersistenceDaoProducerRequestDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ActivationTokenPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ActivationTokenDAO"])
public class _KSP_PersistencePostgresActivationTokenPostgresDAO
@MetaDefinition("persistence.postgres.ActivationTokenPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ActivationTokenDAO"])
public val _KSP_PersistenceDaoActivationTokenDAO : Unit get() = Unit
@MetaDefinition("persistence.postgres.ProductTypeSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProductTypeSyncDAO"])
public class _KSP_PersistencePostgresProductTypeSyncPostgresDAO
@MetaDefinition("persistence.postgres.ProductTypeSyncPostgresDAO",moduleTagId="g128ff:PersistencePostgresPostgresModule", dependencies=["client:persistence.postgres.PostgresClient"], binds=["persistence.dao.ProductTypeSyncDAO"])
public val _KSP_PersistenceDaoProductTypeSyncDAO : Unit get() = Unit