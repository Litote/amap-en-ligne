package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("exchange.ExchangeModule",id="6ozp6u", includes=["core.CoreModule"])
public class _KSP_ExchangeExchangeModule
@MetaDefinition("exchange.BasketExchangeService",moduleTagId="6ozp6u:ExchangeExchangeModule", dependencies=["basketExchangeSyncDAO:persistence.dao.BasketExchangeSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","contractSyncDAO:persistence.dao.ContractSyncDAO","requestReceivedEmailPort:email.BasketExchangeRequestReceivedEmailPort","acceptedEmailPort:email.BasketExchangeAcceptedEmailPort","rejectedEmailPort:email.BasketExchangeRejectedEmailPort","notificationPublisher:notificationpublisher.NotificationPublisher"], binds=["core.EntityTypeService"])
public class _KSP_ExchangeBasketExchangeService
@MetaDefinition("exchange.BasketExchangeService",moduleTagId="6ozp6u:ExchangeExchangeModule", dependencies=["basketExchangeSyncDAO:persistence.dao.BasketExchangeSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","contractSyncDAO:persistence.dao.ContractSyncDAO","requestReceivedEmailPort:email.BasketExchangeRequestReceivedEmailPort","acceptedEmailPort:email.BasketExchangeAcceptedEmailPort","rejectedEmailPort:email.BasketExchangeRejectedEmailPort","notificationPublisher:notificationpublisher.NotificationPublisher"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit