package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("produceraccount.ProducerAccountModule",id="5guh9o", includes=["core.CoreModule"])
public class _KSP_ProduceraccountProducerAccountModule
@MetaDefinition("produceraccount.ProducerAccountLifecycleService",moduleTagId="5guh9o:ProduceraccountProducerAccountModule", dependencies=["producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","userProvisioningPort:core.UserProvisioningPort","accountLifecycleEmailPort:email.AccountLifecycleEmailPort","accountDeletionLogDAO:persistence.dao.AccountDeletionLogDAO","changeFactory:produceraccount.ProducerAccountChangeFactory"])
public class _KSP_ProduceraccountProducerAccountLifecycleService
@MetaDefinition("produceraccount.ProducerAccountChangeFactory",moduleTagId="5guh9o:ProduceraccountProducerAccountModule")
public class _KSP_ProduceraccountProducerAccountChangeFactory
@MetaDefinition("produceraccount.ProducerAccountService",moduleTagId="5guh9o:ProduceraccountProducerAccountModule", dependencies=["producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","upsertNormalizer:produceraccount.ProducerAccountUpsertNormalizer","changeFactory:produceraccount.ProducerAccountChangeFactory","lifecycleService:produceraccount.ProducerAccountLifecycleService"], binds=["core.EntityTypeService"])
public class _KSP_ProduceraccountProducerAccountService
@MetaDefinition("produceraccount.ProducerAccountService",moduleTagId="5guh9o:ProduceraccountProducerAccountModule", dependencies=["producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","upsertNormalizer:produceraccount.ProducerAccountUpsertNormalizer","changeFactory:produceraccount.ProducerAccountChangeFactory","lifecycleService:produceraccount.ProducerAccountLifecycleService"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit
@MetaDefinition("produceraccount.ProducerAccountUpsertNormalizer",moduleTagId="5guh9o:ProduceraccountProducerAccountModule", dependencies=["producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO"])
public class _KSP_ProduceraccountProducerAccountUpsertNormalizer