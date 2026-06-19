package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val sync_SyncModule : Module get() = module {
	includes(activation.ActivationModule().module,
		attendance.AttendanceModule().module,
		contract.ContractModule().module,
		core.CoreModule().module,
		deliverytemplate.DeliveryTemplateModule().module,
		errorreport.ErrorReportModule().module,
		exchange.ExchangeModule().module,
		member.MemberModule().module,
		memberinvitation.MemberInvitationModule().module,
		memberjoinrequest.MemberJoinRequestModule().module,
		notification.NotificationModule().module,
		onboarding.OnboardingModule().module,
		organization.OrganizationModule().module,
		organizationrequest.OrganizationRequestModule().module,
		owner.OwnerModule().module,
		producer.ProducerModule().module,
		produceraccount.ProducerAccountModule().module,
		producerrequest.ProducerRequestModule().module,
		producttype.ProductTypeModule().module)
	single(createdAtStart=true) { _ -> sync.DataService(services=getAll(),changeDAO=get(),memberSyncDAO=get(),authorizedScopeResolver=get())} 
	single(createdAtStart=true) { _ -> sync.ExportService(dataService=get(),organizationSyncDAO=get(),producerAccountSyncDAO=get(),productTypeDAO=get(),memberSyncDAO=get())} 
	single(createdAtStart=true) { _ -> sync.ImportService(organizationSyncDAO=get(),producerAccountSyncDAO=get(),memberSyncDAO=get(),contractSyncDAO=get(),deliveryTemplateSyncDAO=get(),basketExchangeSyncDAO=get(),memberInvitationDAO=get(),memberJoinRequestSyncDAO=get(),productTypeDAO=get())} 
}
public val sync.SyncModule.module : org.koin.core.module.Module get() = sync_SyncModule
