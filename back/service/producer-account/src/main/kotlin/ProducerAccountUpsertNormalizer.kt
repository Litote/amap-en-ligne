package produceraccount

import id.Id
import id.generateId
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.LinkedProducerAccount
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization

internal sealed class ProducerAccountUpsertNormalization {
    data class Success(
        val producerAccount: ProducerAccount,
    ) : ProducerAccountUpsertNormalization()

    data class Rejected(
        val code: MutationErrorCode,
        val message: String,
    ) : ProducerAccountUpsertNormalization()
}

internal sealed class ProducerAccountLinkResolution {
    data class Success(
        val linkedProducerAccount: LinkedProducerAccount?,
    ) : ProducerAccountLinkResolution()

    data class Rejected(
        val code: MutationErrorCode,
        val message: String,
    ) : ProducerAccountLinkResolution()
}

/**
 * Validates and normalises incoming [ProducerAccount] upsert payloads before persistence.
 *
 * Responsibilities:
 *  - id allocation for `tmp_*` creations
 *  - management-mode immutability enforcement ([validateCreationInvariants])
 *  - organisation-association normalisation:
 *      NO_ACCOUNT → single-org pin enforced ([enforcedNoAccountOrganization]);
 *      ACCOUNT_BACKED → caller org auto-added if missing ([ensureOrganizationAssociation])
 *  - linked-account resolution and uniqueness check ([resolveLinkedProducerAccount])
 */
@Single
class ProducerAccountUpsertNormalizer(
    private val producerAccountSyncDAO: ProducerAccountSyncDAO,
) {
    internal suspend fun normalizeAdminUpsert(
        organizationId: String,
        incoming: ProducerAccount,
    ): ProducerAccountUpsertNormalization {
        val isTmpId = incoming.producerAccountId.id.startsWith(ClientMutation.TMP_ID_PREFIX)
        val existing =
            if (isTmpId) {
                null
            } else {
                producerAccountSyncDAO.findById(incoming.producerAccountId)
            }

        validateCreationInvariants(isTmpId, existing, incoming)?.let { return it }

        val resolvedId =
            if (isTmpId) {
                generateId()
            } else {
                incoming.producerAccountId
            }

        val normalizedOrganizations =
            when (incoming.managementMode) {
                ProducerManagementMode.ACCOUNT_BACKED -> {
                    ensureOrganizationAssociation(
                        producer = incoming,
                        organizationId = organizationId,
                    )
                }

                ProducerManagementMode.NO_ACCOUNT -> {
                    val enforcedOrganization = enforcedNoAccountOrganization(organizationId, incoming, existing)
                    noAccountOrganizationRejection(organizationId, incoming, enforcedOrganization)?.let { return it }
                    listOf(enforcedOrganization)
                }
            }

        if (incoming.managementMode == ProducerManagementMode.NO_ACCOUNT && incoming.users.isNotEmpty()) {
            return rejectUpsert(MutationErrorCode.INVALID_PAYLOAD, "no-account producers cannot declare producer users")
        }

        if (incoming.managementMode == ProducerManagementMode.ACCOUNT_BACKED && incoming.linkedProducerAccount != null) {
            return rejectUpsert(
                MutationErrorCode.INVALID_PAYLOAD,
                "account-backed producers cannot point to a linked producer account",
            )
        }

        val normalizedLinkedProducerAccount =
            when (val link = normalizedLinkedAccountFor(organizationId, resolvedId, incoming, existing)) {
                is ProducerAccountLinkResolution.Rejected -> {
                    return ProducerAccountUpsertNormalization.Rejected(link.code, link.message)
                }

                is ProducerAccountLinkResolution.Success -> {
                    link.linkedProducerAccount
                }
            }

        return ProducerAccountUpsertNormalization.Success(
            incoming.copy(
                producerAccountId = resolvedId,
                organizations = normalizedOrganizations,
                managementMode = incoming.managementMode,
                linkedProducerAccount = normalizedLinkedProducerAccount,
            ),
        )
    }

    /** Mode/identity invariants checked before any normalisation. */
    private fun validateCreationInvariants(
        isTmpId: Boolean,
        existing: ProducerAccount?,
        incoming: ProducerAccount,
    ): ProducerAccountUpsertNormalization.Rejected? {
        if (!isTmpId && existing == null) {
            return rejectUpsert(
                MutationErrorCode.NOT_FOUND,
                "producer account not found: ${incoming.producerAccountId.id}",
            )
        }
        if (existing != null && existing.managementMode != incoming.managementMode) {
            return rejectUpsert(MutationErrorCode.INVALID_PAYLOAD, "producer management_mode is immutable")
        }
        if (isTmpId && incoming.managementMode != ProducerManagementMode.NO_ACCOUNT) {
            return rejectUpsert(
                MutationErrorCode.INVALID_PAYLOAD,
                "only no-account producers can be created through organization sync",
            )
        }
        return null
    }

    /** The single organisation a NO_ACCOUNT producer is pinned to (existing link wins, else incoming, else the caller org). */
    private fun enforcedNoAccountOrganization(
        organizationId: String,
        incoming: ProducerAccount,
        existing: ProducerAccount?,
    ): ProducerOrganization =
        existing?.organizations?.singleOrNull()
            ?: incoming.organizations.singleOrNull()
            ?: ProducerOrganization(
                organizationId = organizationId.toId(),
                associationInstant = incoming.createdInstant,
                status = OrganizationProducerStatus.ACTIVE,
            )

    private fun noAccountOrganizationRejection(
        organizationId: String,
        incoming: ProducerAccount,
        enforcedOrganization: ProducerOrganization,
    ): ProducerAccountUpsertNormalization.Rejected? {
        if (enforcedOrganization.organizationId.id != organizationId) {
            return rejectUpsert(
                MutationErrorCode.INVALID_PAYLOAD,
                "no-account producers must belong to the caller organization",
            )
        }
        if (incoming.organizations.size > 1) {
            return rejectUpsert(
                MutationErrorCode.INVALID_PAYLOAD,
                "no-account producers cannot be linked to multiple organizations",
            )
        }
        return null
    }

    /** Resolves the linked producer account for NO_ACCOUNT producers; account-backed producers never carry a link. */
    private suspend fun normalizedLinkedAccountFor(
        organizationId: String,
        resolvedId: Id<ProducerAccount>,
        incoming: ProducerAccount,
        existing: ProducerAccount?,
    ): ProducerAccountLinkResolution =
        if (incoming.managementMode == ProducerManagementMode.NO_ACCOUNT) {
            resolveLinkedProducerAccount(
                organizationId = organizationId,
                sourceProducerAccountId = resolvedId.id,
                requestedLink = incoming.linkedProducerAccount,
                existingLink = existing?.linkedProducerAccount,
            )
        } else {
            ProducerAccountLinkResolution.Success(null)
        }

    private suspend fun resolveLinkedProducerAccount(
        organizationId: String,
        sourceProducerAccountId: String,
        requestedLink: LinkedProducerAccount?,
        existingLink: LinkedProducerAccount?,
    ): ProducerAccountLinkResolution {
        val targetProducerAccountId = requestedLink?.producerAccountId ?: existingLink?.producerAccountId
        if (targetProducerAccountId == null) {
            return ProducerAccountLinkResolution.Success(null)
        }
        if (targetProducerAccountId.id == sourceProducerAccountId) {
            return rejectLink(MutationErrorCode.INVALID_PAYLOAD, "a producer cannot link to itself")
        }

        val target =
            producerAccountSyncDAO.findById(targetProducerAccountId)
                ?: return rejectLink(
                    MutationErrorCode.NOT_FOUND,
                    "linked account-backed producer not found: ${targetProducerAccountId.id}",
                )
        if (target.managementMode != ProducerManagementMode.ACCOUNT_BACKED) {
            return rejectLink(MutationErrorCode.INVALID_PAYLOAD, "linked producer target must be account-backed")
        }

        val conflictingLink =
            producerAccountSyncDAO
                .getByOrganizationId(organizationId.toId())
                .firstOrNull {
                    it.producerAccountId.id != sourceProducerAccountId &&
                        it.managementMode == ProducerManagementMode.NO_ACCOUNT &&
                        it.linkedProducerAccount?.producerAccountId == targetProducerAccountId
                }
        if (conflictingLink != null) {
            return rejectLink(
                MutationErrorCode.CONFLICT,
                "linked account-backed producer already used by ${conflictingLink.producerAccountId.id}",
            )
        }
        return LinkedProducerAccount(
            producerAccountId = target.producerAccountId,
            name = target.name,
        ).let(ProducerAccountLinkResolution::Success)
    }

    private fun ensureOrganizationAssociation(
        producer: ProducerAccount,
        organizationId: String,
    ): List<ProducerOrganization> {
        val existingAssociation = producer.organizations.firstOrNull { it.organizationId.id == organizationId }
        return if (existingAssociation != null) {
            producer.organizations
        } else {
            producer.organizations +
                ProducerOrganization(
                    organizationId = organizationId.toId(),
                    associationInstant = producer.lastUpdatedInstant,
                    status = OrganizationProducerStatus.ACTIVE,
                )
        }
    }

    private fun rejectUpsert(
        code: MutationErrorCode,
        message: String,
    ) = ProducerAccountUpsertNormalization.Rejected(code, message)

    private fun rejectLink(
        code: MutationErrorCode,
        message: String,
    ) = ProducerAccountLinkResolution.Rejected(code, message)
}
