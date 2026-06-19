package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("email.delivery.EmailDeliveryModule",id="s63r2k")
public class _KSP_EmailDeliveryEmailDeliveryModule
@MetaDefinition("email.delivery.AccountLifecycleEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","ownerDAO:persistence.dao.OwnerSyncDAO"], binds=["email.AccountLifecycleEmailPort"])
public class _KSP_EmailDeliveryAccountLifecycleEmailAdapter
@MetaDefinition("email.delivery.AccountLifecycleEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","ownerDAO:persistence.dao.OwnerSyncDAO"], binds=["email.AccountLifecycleEmailPort"])
public val _KSP_EmailAccountLifecycleEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.OwnerActivationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.OwnerActivationEmailPort"])
public class _KSP_EmailDeliveryOwnerActivationEmailAdapter
@MetaDefinition("email.delivery.OwnerActivationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.OwnerActivationEmailPort"])
public val _KSP_EmailOwnerActivationEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.MemberJoinRequestNotificationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","memberSyncDAO:persistence.dao.MemberSyncDAO"], binds=["email.MemberJoinRequestNotificationEmailPort"])
public class _KSP_EmailDeliveryMemberJoinRequestNotificationEmailAdapter
@MetaDefinition("email.delivery.MemberJoinRequestNotificationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","memberSyncDAO:persistence.dao.MemberSyncDAO"], binds=["email.MemberJoinRequestNotificationEmailPort"])
public val _KSP_EmailMemberJoinRequestNotificationEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.OrganizationRequestNotificationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","ownerDAO:persistence.dao.OwnerSyncDAO"], binds=["email.OrganizationRequestNotificationEmailPort"])
public class _KSP_EmailDeliveryOrganizationRequestNotificationEmailAdapter
@MetaDefinition("email.delivery.OrganizationRequestNotificationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","ownerDAO:persistence.dao.OwnerSyncDAO"], binds=["email.OrganizationRequestNotificationEmailPort"])
public val _KSP_EmailOrganizationRequestNotificationEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.MemberJoinRequestRejectionEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.MemberJoinRequestRejectionEmailPort"])
public class _KSP_EmailDeliveryMemberJoinRequestRejectionEmailAdapter
@MetaDefinition("email.delivery.MemberJoinRequestRejectionEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.MemberJoinRequestRejectionEmailPort"])
public val _KSP_EmailMemberJoinRequestRejectionEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.EmailNotificationChannelSender",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["notificationpublisher.NotificationChannelSender"])
public class _KSP_EmailDeliveryEmailNotificationChannelSender
@MetaDefinition("email.delivery.EmailNotificationChannelSender",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["notificationpublisher.NotificationChannelSender"])
public val _KSP_NotificationpublisherNotificationChannelSender : Unit get() = Unit
@MetaDefinition("email.delivery.BasketExchangeRequestReceivedEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.BasketExchangeRequestReceivedEmailPort"])
public class _KSP_EmailDeliveryBasketExchangeRequestReceivedEmailAdapter
@MetaDefinition("email.delivery.BasketExchangeRequestReceivedEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.BasketExchangeRequestReceivedEmailPort"])
public val _KSP_EmailBasketExchangeRequestReceivedEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.BasketExchangeAcceptedEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.BasketExchangeAcceptedEmailPort"])
public class _KSP_EmailDeliveryBasketExchangeAcceptedEmailAdapter
@MetaDefinition("email.delivery.BasketExchangeAcceptedEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.BasketExchangeAcceptedEmailPort"])
public val _KSP_EmailBasketExchangeAcceptedEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.BasketExchangeRejectedEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.BasketExchangeRejectedEmailPort"])
public class _KSP_EmailDeliveryBasketExchangeRejectedEmailAdapter
@MetaDefinition("email.delivery.BasketExchangeRejectedEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.BasketExchangeRejectedEmailPort"])
public val _KSP_EmailBasketExchangeRejectedEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.ProducerRequestRejectionEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.ProducerRequestRejectionEmailPort"])
public class _KSP_EmailDeliveryProducerRequestRejectionEmailAdapter
@MetaDefinition("email.delivery.ProducerRequestRejectionEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.ProducerRequestRejectionEmailPort"])
public val _KSP_EmailProducerRequestRejectionEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.AttendanceEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.AttendanceEmailPort"])
public class _KSP_EmailDeliveryAttendanceEmailAdapter
@MetaDefinition("email.delivery.AttendanceEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.AttendanceEmailPort"])
public val _KSP_EmailAttendanceEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.OrganizationRequestRejectionEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.RejectionEmailPort"])
public class _KSP_EmailDeliveryOrganizationRequestRejectionEmailAdapter
@MetaDefinition("email.delivery.OrganizationRequestRejectionEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.RejectionEmailPort"])
public val _KSP_EmailRejectionEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.ProducerActivationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.ProducerActivationEmailPort"])
public class _KSP_EmailDeliveryProducerActivationEmailAdapter
@MetaDefinition("email.delivery.ProducerActivationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.ProducerActivationEmailPort"])
public val _KSP_EmailProducerActivationEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.MemberInvitationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.MemberInvitationEmailPort"])
public class _KSP_EmailDeliveryMemberInvitationEmailAdapter
@MetaDefinition("email.delivery.MemberInvitationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway"], binds=["email.MemberInvitationEmailPort"])
public val _KSP_EmailMemberInvitationEmailPort : Unit get() = Unit
@MetaDefinition("email.delivery.ProducerRequestNotificationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","ownerDAO:persistence.dao.OwnerSyncDAO"], binds=["email.ProducerRequestNotificationEmailPort"])
public class _KSP_EmailDeliveryProducerRequestNotificationEmailAdapter
@MetaDefinition("email.delivery.ProducerRequestNotificationEmailAdapter",moduleTagId="s63r2k:EmailDeliveryEmailDeliveryModule", dependencies=["gateway:email.delivery.EmailGateway","ownerDAO:persistence.dao.OwnerSyncDAO"], binds=["email.ProducerRequestNotificationEmailPort"])
public val _KSP_EmailProducerRequestNotificationEmailPort : Unit get() = Unit