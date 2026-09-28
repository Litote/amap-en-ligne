package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val email_delivery_EmailDeliveryModule : Module get() = module {
	single(createdAtStart=true) { _ -> email.delivery.AccountLifecycleEmailAdapter(gateway=get(),ownerDAO=get())} bind(email.AccountLifecycleEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.AttendanceEmailAdapter(gateway=get())} bind(email.AttendanceEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.BasketExchangeAcceptedEmailAdapter(gateway=get())} bind(email.BasketExchangeAcceptedEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.BasketExchangeRejectedEmailAdapter(gateway=get())} bind(email.BasketExchangeRejectedEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.BasketExchangeRequestReceivedEmailAdapter(gateway=get())} bind(email.BasketExchangeRequestReceivedEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.EmailNotificationChannelSender(gateway=get())} bind(notificationpublisher.NotificationChannelSender::class)
	single(createdAtStart=true) { _ -> email.delivery.MemberInvitationEmailAdapter(gateway=get())} bind(email.MemberInvitationEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.MemberJoinRequestNotificationEmailAdapter(gateway=get(),memberSyncDAO=get())} bind(email.MemberJoinRequestNotificationEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.MemberJoinRequestRejectionEmailAdapter(gateway=get())} bind(email.MemberJoinRequestRejectionEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.OrganizationRequestNotificationEmailAdapter(gateway=get(),ownerDAO=get())} bind(email.OrganizationRequestNotificationEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.OrganizationRequestRejectionEmailAdapter(gateway=get())} bind(email.RejectionEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.OwnerActivationEmailAdapter(gateway=get())} bind(email.OwnerActivationEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.ProducerActivationEmailAdapter(gateway=get())} bind(email.ProducerActivationEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.ProducerRequestNotificationEmailAdapter(gateway=get(),ownerDAO=get())} bind(email.ProducerRequestNotificationEmailPort::class)
	single(createdAtStart=true) { _ -> email.delivery.ProducerRequestRejectionEmailAdapter(gateway=get())} bind(email.ProducerRequestRejectionEmailPort::class)
}
public val email.delivery.EmailDeliveryModule.module : org.koin.core.module.Module get() = email_delivery_EmailDeliveryModule
