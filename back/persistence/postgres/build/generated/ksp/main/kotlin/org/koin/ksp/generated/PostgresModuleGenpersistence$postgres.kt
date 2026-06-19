package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val persistence_postgres_PostgresModule : Module get() = module {
	val moduleInstance = persistence.postgres.PostgresModule()
	includes(properties.PropertiesModule().module)
	single(createdAtStart=true) { _ -> persistence.postgres.AccountDeletionLogPostgresDAO(client=get())} bind(persistence.dao.AccountDeletionLogDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ActivationTokenPostgresDAO(client=get())} bind(persistence.dao.ActivationTokenDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.AttendanceEmailRequestSyncPostgresDAO(client=get())} bind(persistence.dao.AttendanceEmailRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.BasketExchangeSyncPostgresDAO(client=get())} bind(persistence.dao.BasketExchangeSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ChangePostgresDAO(client=get())} bind(persistence.dao.ChangeDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ContractSyncPostgresDAO(client=get())} bind(persistence.dao.ContractSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.DeliveryTemplateSyncPostgresDAO(client=get())} bind(persistence.dao.DeliveryTemplateSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.DeviceTokenSyncPostgresDAO(client=get())} bind(persistence.dao.DeviceTokenSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ErrorReportSyncPostgresDAO(client=get())} bind(persistence.dao.ErrorReportSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.MemberInvitationSyncPostgresDAO(client=get())} bind(persistence.dao.MemberInvitationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.MemberJoinRequestPostgresDAO(client=get())} bind(persistence.dao.MemberJoinRequestDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.MemberJoinRequestSyncPostgresDAO(client=get())} bind(persistence.dao.MemberJoinRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.MemberSyncPostgresDAO(client=get())} bind(persistence.dao.MemberSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.NotificationSyncPostgresDAO(client=get())} bind(persistence.dao.NotificationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.OrganizationPostgresDAO(client=get())} bind(persistence.dao.OrganizationDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.OrganizationRequestPostgresDAO(client=get())} bind(persistence.dao.OrganizationRequestDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.OrganizationRequestSyncPostgresDAO(client=get())} bind(persistence.dao.OrganizationRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.OrganizationSyncPostgresDAO(client=get())} bind(persistence.dao.OrganizationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.OwnerInvitationSyncPostgresDAO(client=get())} bind(persistence.dao.OwnerInvitationSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.OwnerSyncPostgresDAO(client=get())} bind(persistence.dao.OwnerSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ProducerAccountSyncPostgresDAO(client=get())} bind(persistence.dao.ProducerAccountSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ProducerRequestPostgresDAO(client=get())} bind(persistence.dao.ProducerRequestDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ProducerRequestSyncPostgresDAO(client=get())} bind(persistence.dao.ProducerRequestSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ProducerSyncPostgresDAO(client=get())} bind(persistence.dao.ProducerSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ProductTypeSyncPostgresDAO(client=get())} bind(persistence.dao.ProductTypeSyncDAO::class)
	single(createdAtStart=true) { _ -> persistence.postgres.ServerPostgresDAO(client=get())} bind(persistence.dao.ServerDAO::class)
	single(createdAtStart=true) { _ -> moduleInstance.dataSource(postgresClient=get())} bind(javax.sql.DataSource::class)
	single(createdAtStart=true) { _ -> moduleInstance.postgresClient(properties=get())} bind(persistence.postgres.PostgresClient::class)
}
public val persistence.postgres.PostgresModule.module : org.koin.core.module.Module get() = persistence_postgres_PostgresModule
