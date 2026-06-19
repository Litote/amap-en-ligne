package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("produceraccount.ProducerAccountModule",id="5guh9o", includes=["core.CoreModule"])
public class _KSP_ProduceraccountProducerAccountModule
@MetaDefinition("produceraccount.ProducerAccountService",moduleTagId="5guh9o:ProduceraccountProducerAccountModule", dependencies=["producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","userProvisioningPort:core.UserProvisioningPort","accountLifecycleEmailPort:email.AccountLifecycleEmailPort","accountDeletionLogDAO:persistence.dao.AccountDeletionLogDAO"], binds=["core.EntityTypeService"])
public class _KSP_ProduceraccountProducerAccountService
@MetaDefinition("produceraccount.ProducerAccountService",moduleTagId="5guh9o:ProduceraccountProducerAccountModule", dependencies=["producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","userProvisioningPort:core.UserProvisioningPort","accountLifecycleEmailPort:email.AccountLifecycleEmailPort","accountDeletionLogDAO:persistence.dao.AccountDeletionLogDAO"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit