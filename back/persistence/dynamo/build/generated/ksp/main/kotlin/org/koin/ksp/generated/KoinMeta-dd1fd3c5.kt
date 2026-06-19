package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("persistence.dynamo.DynamoModule",id="b06v5h", includes=["properties.PropertiesModule"])
public class _KSP_PersistenceDynamoDynamoModule
@MetaDefinition("persistence.dynamo.dynamoClient",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["properties:properties.Properties"], binds=["persistence.dynamo.DynamoClient"])
public class _KSP_PersistenceDynamoDynamoClient
@MetaDefinition("persistence.dynamo.ActivationTokenDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ActivationTokenDAO"])
public class _KSP_PersistenceDynamoActivationTokenDynamoDAO
@MetaDefinition("persistence.dynamo.ActivationTokenDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ActivationTokenDAO"])
public val _KSP_PersistenceDaoActivationTokenDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.NotificationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.NotificationSyncDAO"])
public class _KSP_PersistenceDynamoNotificationSyncDynamoDAO
@MetaDefinition("persistence.dynamo.NotificationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.NotificationSyncDAO"])
public val _KSP_PersistenceDaoNotificationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ProducerRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerRequestSyncDAO"])
public class _KSP_PersistenceDynamoProducerRequestSyncDynamoDAO
@MetaDefinition("persistence.dynamo.ProducerRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerRequestSyncDAO"])
public val _KSP_PersistenceDaoProducerRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ProductTypeSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProductTypeSyncDAO"])
public class _KSP_PersistenceDynamoProductTypeSyncDynamoDAO
@MetaDefinition("persistence.dynamo.ProductTypeSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProductTypeSyncDAO"])
public val _KSP_PersistenceDaoProductTypeSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.AccountDeletionLogDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.AccountDeletionLogDAO"])
public class _KSP_PersistenceDynamoAccountDeletionLogDynamoDAO
@MetaDefinition("persistence.dynamo.AccountDeletionLogDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.AccountDeletionLogDAO"])
public val _KSP_PersistenceDaoAccountDeletionLogDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.OrganizationRequestDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationRequestDAO"])
public class _KSP_PersistenceDynamoOrganizationRequestDynamoDAO
@MetaDefinition("persistence.dynamo.OrganizationRequestDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationRequestDAO"])
public val _KSP_PersistenceDaoOrganizationRequestDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.MemberInvitationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberInvitationSyncDAO"])
public class _KSP_PersistenceDynamoMemberInvitationSyncDynamoDAO
@MetaDefinition("persistence.dynamo.MemberInvitationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberInvitationSyncDAO"])
public val _KSP_PersistenceDaoMemberInvitationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ProducerRequestDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerRequestDAO"])
public class _KSP_PersistenceDynamoProducerRequestDynamoDAO
@MetaDefinition("persistence.dynamo.ProducerRequestDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerRequestDAO"])
public val _KSP_PersistenceDaoProducerRequestDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.OwnerInvitationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OwnerInvitationSyncDAO"])
public class _KSP_PersistenceDynamoOwnerInvitationSyncDynamoDAO
@MetaDefinition("persistence.dynamo.OwnerInvitationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OwnerInvitationSyncDAO"])
public val _KSP_PersistenceDaoOwnerInvitationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.DeliveryTemplateSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.DeliveryTemplateSyncDAO"])
public class _KSP_PersistenceDynamoDeliveryTemplateSyncDynamoDAO
@MetaDefinition("persistence.dynamo.DeliveryTemplateSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.DeliveryTemplateSyncDAO"])
public val _KSP_PersistenceDaoDeliveryTemplateSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.MemberJoinRequestDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberJoinRequestDAO"])
public class _KSP_PersistenceDynamoMemberJoinRequestDynamoDAO
@MetaDefinition("persistence.dynamo.MemberJoinRequestDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberJoinRequestDAO"])
public val _KSP_PersistenceDaoMemberJoinRequestDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ProducerSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerSyncDAO"])
public class _KSP_PersistenceDynamoProducerSyncDynamoDAO
@MetaDefinition("persistence.dynamo.ProducerSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerSyncDAO"])
public val _KSP_PersistenceDaoProducerSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.MemberSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberSyncDAO"])
public class _KSP_PersistenceDynamoMemberSyncDynamoDAO
@MetaDefinition("persistence.dynamo.MemberSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberSyncDAO"])
public val _KSP_PersistenceDaoMemberSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.OrganizationRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationRequestSyncDAO"])
public class _KSP_PersistenceDynamoOrganizationRequestSyncDynamoDAO
@MetaDefinition("persistence.dynamo.OrganizationRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationRequestSyncDAO"])
public val _KSP_PersistenceDaoOrganizationRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ContractSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ContractSyncDAO"])
public class _KSP_PersistenceDynamoContractSyncDynamoDAO
@MetaDefinition("persistence.dynamo.ContractSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ContractSyncDAO"])
public val _KSP_PersistenceDaoContractSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.OwnerSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OwnerSyncDAO"])
public class _KSP_PersistenceDynamoOwnerSyncDynamoDAO
@MetaDefinition("persistence.dynamo.OwnerSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OwnerSyncDAO"])
public val _KSP_PersistenceDaoOwnerSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.OrganizationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationSyncDAO"])
public class _KSP_PersistenceDynamoOrganizationSyncDynamoDAO
@MetaDefinition("persistence.dynamo.OrganizationSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationSyncDAO"])
public val _KSP_PersistenceDaoOrganizationSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.BasketExchangeSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.BasketExchangeSyncDAO"])
public class _KSP_PersistenceDynamoBasketExchangeSyncDynamoDAO
@MetaDefinition("persistence.dynamo.BasketExchangeSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.BasketExchangeSyncDAO"])
public val _KSP_PersistenceDaoBasketExchangeSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.AttendanceEmailRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.AttendanceEmailRequestSyncDAO"])
public class _KSP_PersistenceDynamoAttendanceEmailRequestSyncDynamoDAO
@MetaDefinition("persistence.dynamo.AttendanceEmailRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.AttendanceEmailRequestSyncDAO"])
public val _KSP_PersistenceDaoAttendanceEmailRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ChangeDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ChangeDAO"])
public class _KSP_PersistenceDynamoChangeDynamoDAO
@MetaDefinition("persistence.dynamo.ChangeDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ChangeDAO"])
public val _KSP_PersistenceDaoChangeDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ServerDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ServerDAO"])
public class _KSP_PersistenceDynamoServerDynamoDAO
@MetaDefinition("persistence.dynamo.ServerDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ServerDAO"])
public val _KSP_PersistenceDaoServerDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.OrganizationDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationDAO"])
public class _KSP_PersistenceDynamoOrganizationDynamoDAO
@MetaDefinition("persistence.dynamo.OrganizationDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.OrganizationDAO"])
public val _KSP_PersistenceDaoOrganizationDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.DeviceTokenSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.DeviceTokenSyncDAO"])
public class _KSP_PersistenceDynamoDeviceTokenSyncDynamoDAO
@MetaDefinition("persistence.dynamo.DeviceTokenSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.DeviceTokenSyncDAO"])
public val _KSP_PersistenceDaoDeviceTokenSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ProducerAccountSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerAccountSyncDAO"])
public class _KSP_PersistenceDynamoProducerAccountSyncDynamoDAO
@MetaDefinition("persistence.dynamo.ProducerAccountSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ProducerAccountSyncDAO"])
public val _KSP_PersistenceDaoProducerAccountSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.MemberJoinRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberJoinRequestSyncDAO"])
public class _KSP_PersistenceDynamoMemberJoinRequestSyncDynamoDAO
@MetaDefinition("persistence.dynamo.MemberJoinRequestSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.MemberJoinRequestSyncDAO"])
public val _KSP_PersistenceDaoMemberJoinRequestSyncDAO : Unit get() = Unit
@MetaDefinition("persistence.dynamo.ErrorReportSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ErrorReportSyncDAO"])
public class _KSP_PersistenceDynamoErrorReportSyncDynamoDAO
@MetaDefinition("persistence.dynamo.ErrorReportSyncDynamoDAO",moduleTagId="b06v5h:PersistenceDynamoDynamoModule", dependencies=["client:persistence.dynamo.DynamoClient"], binds=["persistence.dao.ErrorReportSyncDAO"])
public val _KSP_PersistenceDaoErrorReportSyncDAO : Unit get() = Unit