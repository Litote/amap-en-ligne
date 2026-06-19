package sync

import activation.ActivationModule
import attendance.AttendanceModule
import contract.ContractModule
import core.CoreModule
import deliverytemplate.DeliveryTemplateModule
import errorreport.ErrorReportModule
import exchange.ExchangeModule
import member.MemberModule
import memberinvitation.MemberInvitationModule
import memberjoinrequest.MemberJoinRequestModule
import notification.NotificationModule
import onboarding.OnboardingModule
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import organization.OrganizationModule
import organizationrequest.OrganizationRequestModule
import owner.OwnerModule
import producer.ProducerModule
import produceraccount.ProducerAccountModule
import producerrequest.ProducerRequestModule
import producttype.ProductTypeModule

@Module(
    includes = [
        CoreModule::class,
        OnboardingModule::class,
        OwnerModule::class,
        ErrorReportModule::class,
        OrganizationModule::class,
        ContractModule::class,
        DeliveryTemplateModule::class,
        ProducerAccountModule::class,
        ProducerModule::class,
        ProductTypeModule::class,
        MemberModule::class,
        MemberJoinRequestModule::class,
        MemberInvitationModule::class,
        OrganizationRequestModule::class,
        ProducerRequestModule::class,
        AttendanceModule::class,
        ExchangeModule::class,
        NotificationModule::class,
        ActivationModule::class,
    ],
)
@ComponentScan
class SyncModule
