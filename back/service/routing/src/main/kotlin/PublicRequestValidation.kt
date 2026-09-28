package routing

import core.InputRules
import persistence.model.CreateMemberJoinRequestBody
import persistence.model.CreateOrganizationRequestBody
import persistence.model.CreateProducerRequestBody

/**
 * Server-side validation of the unauthenticated onboarding submissions, built on the
 * shared [InputRules]. Returns a human-readable reason for the first invalid field,
 * or `null` when valid.
 */
internal fun CreateOrganizationRequestBody.validationError(): String? =
    InputRules.requireName("organization_name", organizationName)
        ?: InputRules.requireName("admin_first_name", adminFirstName)
        ?: InputRules.requireName("admin_last_name", adminLastName)
        ?: InputRules.requireEmail("admin_email", adminEmail)
        ?: InputRules.optionalComment("submitter_comment", submitterComment)

internal fun CreateProducerRequestBody.validationError(): String? =
    InputRules.requireName("producer_name", producerName)
        ?: InputRules.requireName("admin_first_name", adminFirstName)
        ?: InputRules.requireName("admin_last_name", adminLastName)
        ?: InputRules.requireEmail("admin_email", adminEmail)
        ?: InputRules.optionalComment("submitter_comment", submitterComment)

internal fun CreateMemberJoinRequestBody.validationError(): String? =
    InputRules.requireName("organization_id", organizationId)
        ?: InputRules.requireName("first_name", firstName)
        ?: InputRules.requireName("last_name", lastName)
        ?: InputRules.requireEmail("email", email)
