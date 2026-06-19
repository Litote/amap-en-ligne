package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val persistence_dynamo_DynamoModule : Module get() = module {
	val moduleInstance = persistence.dynamo.DynamoModule()
	includes(properties.PropertiesModule().module)
	single(createdAtStart=true) { _ -> persistence.dynamo.AccountDeletionLogDynamoDAO(client=get())} bind(persistence.dao.AccountDeletionLogDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ActivationTokenDynamoDAO(client=get())} bind(persistence.dao.ActivationTokenDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.AttendanceEmailRequestSyncDynamoDAO(client=get())} bind(persistence.dao.AttendanceEmailRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.BasketExchangeSyncDynamoDAO(client=get())} bind(persistence.dao.BasketExchangeSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ChangeDynamoDAO(client=get())} bind(persistence.dao.ChangeDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ContractSyncDynamoDAO(client=get())} bind(persistence.dao.ContractSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.DeliveryTemplateSyncDynamoDAO(client=get())} bind(persistence.dao.DeliveryTemplateSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.DeviceTokenSyncDynamoDAO(client=get())} bind(persistence.dao.DeviceTokenSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ErrorReportSyncDynamoDAO(client=get())} bind(persistence.dao.ErrorReportSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.MemberInvitationSyncDynamoDAO(client=get())} bind(persistence.dao.MemberInvitationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.MemberJoinRequestDynamoDAO(client=get())} bind(persistence.dao.MemberJoinRequestDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.MemberJoinRequestSyncDynamoDAO(client=get())} bind(persistence.dao.MemberJoinRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.MemberSyncDynamoDAO(client=get())} bind(persistence.dao.MemberSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.NotificationSyncDynamoDAO(client=get())} bind(persistence.dao.NotificationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.OrganizationDynamoDAO(client=get())} bind(persistence.dao.OrganizationDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.OrganizationRequestDynamoDAO(client=get())} bind(persistence.dao.OrganizationRequestDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.OrganizationRequestSyncDynamoDAO(client=get())} bind(persistence.dao.OrganizationRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.OrganizationSyncDynamoDAO(client=get())} bind(persistence.dao.OrganizationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.OwnerInvitationSyncDynamoDAO(client=get())} bind(persistence.dao.OwnerInvitationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.OwnerSyncDynamoDAO(client=get())} bind(persistence.dao.OwnerSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ProducerAccountSyncDynamoDAO(client=get())} bind(persistence.dao.ProducerAccountSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ProducerRequestDynamoDAO(client=get())} bind(persistence.dao.ProducerRequestDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ProducerRequestSyncDynamoDAO(client=get())} bind(persistence.dao.ProducerRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ProducerSyncDynamoDAO(client=get())} bind(persistence.dao.ProducerSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ProductTypeSyncDynamoDAO(client=get())} bind(persistence.dao.ProductTypeSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.dynamo.ServerDynamoDAO(client=get())} bind(persistence.dao.ServerDAO::class)
	single(createdAtStart=true) { _ -> moduleInstance.dynamoClient(properties=get())} bind(persistence.dynamo.DynamoClient::class)
}
public val persistence.dynamo.DynamoModule.module : org.koin.core.module.Module get() = persistence_dynamo_DynamoModule
