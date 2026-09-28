package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("exchange.ExchangeModule",id="6ozp6u", includes=["core.CoreModule"])
public class _KSP_ExchangeExchangeModule
@MetaDefinition("exchange.BasketExchangeService",moduleTagId="6ozp6u:ExchangeExchangeModule", dependencies=["basketExchangeSyncDAO:persistence.dao.BasketExchangeSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","requestReceivedEmailPort:email.BasketExchangeRequestReceivedEmailPort","acceptedEmailPort:email.BasketExchangeAcceptedEmailPort","rejectedEmailPort:email.BasketExchangeRejectedEmailPort","notifier:exchange.BasketExchangeNotifier","commitmentValidator:exchange.BasketExchangeCommitmentValidator"], binds=["core.EntityTypeService"])
public class _KSP_ExchangeBasketExchangeService
@MetaDefinition("exchange.BasketExchangeService",moduleTagId="6ozp6u:ExchangeExchangeModule", dependencies=["basketExchangeSyncDAO:persistence.dao.BasketExchangeSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","requestReceivedEmailPort:email.BasketExchangeRequestReceivedEmailPort","acceptedEmailPort:email.BasketExchangeAcceptedEmailPort","rejectedEmailPort:email.BasketExchangeRejectedEmailPort","notifier:exchange.BasketExchangeNotifier","commitmentValidator:exchange.BasketExchangeCommitmentValidator"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit
@MetaDefinition("exchange.BasketExchangeNotifier",moduleTagId="6ozp6u:ExchangeExchangeModule", dependencies=["notificationPublisher:notificationpublisher.NotificationPublisher"])
public class _KSP_ExchangeBasketExchangeNotifier
@MetaDefinition("exchange.BasketExchangeCommitmentValidator",moduleTagId="6ozp6u:ExchangeExchangeModule", dependencies=["contractSyncDAO:persistence.dao.ContractSyncDAO"])
public class _KSP_ExchangeBasketExchangeCommitmentValidator