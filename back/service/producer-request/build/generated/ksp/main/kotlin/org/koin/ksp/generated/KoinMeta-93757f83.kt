package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("producerrequest.ProducerRequestModule",id="61oca0", includes=["core.CoreModule"])
public class _KSP_ProducerrequestProducerRequestModule
@MetaDefinition("producerrequest.ProducerRequestService",moduleTagId="61oca0:ProducerrequestProducerRequestModule", dependencies=["producerRequestSyncDAO:persistence.dao.ProducerRequestSyncDAO","producerRequestDAO:persistence.dao.ProducerRequestDAO","producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","producerActivationEmailPort:email.ProducerActivationEmailPort","producerRequestRejectionEmailPort:email.ProducerRequestRejectionEmailPort"], binds=["core.EntityTypeService"])
public class _KSP_ProducerrequestProducerRequestService
@MetaDefinition("producerrequest.ProducerRequestService",moduleTagId="61oca0:ProducerrequestProducerRequestModule", dependencies=["producerRequestSyncDAO:persistence.dao.ProducerRequestSyncDAO","producerRequestDAO:persistence.dao.ProducerRequestDAO","producerAccountSyncDAO:persistence.dao.ProducerAccountSyncDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","producerActivationEmailPort:email.ProducerActivationEmailPort","producerRequestRejectionEmailPort:email.ProducerRequestRejectionEmailPort"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit