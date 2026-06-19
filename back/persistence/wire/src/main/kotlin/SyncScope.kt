package persistence.changes

import persistence.model.EntityType

sealed interface SyncScope {
    val key: String
    val entityTypes: List<EntityType>

    data class ProducerAccount(
        val producerAccountId: String,
    ) : SyncScope {
        override val key: String = "producer-account:$producerAccountId"

        // Producers' private feed also carries their notifications and device tokens (ADR-005).
        override val entityTypes: List<EntityType> =
            listOf(EntityType.ProductType, EntityType.Notification, EntityType.DeviceToken)
    }

    data class Organization(
        val organizationId: String,
    ) : SyncScope {
        override val key: String = "organization:$organizationId"
        override val entityTypes: List<EntityType> =
            listOf(
                EntityType.Organization,
                EntityType.ProducerAccount,
                EntityType.Member,
                EntityType.MemberJoinRequest,
                EntityType.MemberInvitation,
                EntityType.Contract,
                EntityType.DeliveryTemplate,
                EntityType.BasketExchange,
            )
    }

    /**
     * Private per-recipient scope carrying an AMAP member's personal notification feed
     * (see ADR-005). Keyed by the auth **subject** (`sub`), the only stable per-user id
     * available both when granting the scope (from the JWT) and when a server-side
     * producer addresses a recipient. (`Member.memberId` is a separate generated id and
     * must NOT be used here.) One member of the "private recipient scope" family.
     */
    data class Member(
        val subject: String,
    ) : SyncScope {
        override val key: String = "member:$subject"
        override val entityTypes: List<EntityType> = listOf(EntityType.Notification, EntityType.DeviceToken)
    }

    /**
     * Private per-recipient scope carrying an OWNER's personal notification feed
     * (see ADR-005). Keyed by the auth subject — distinct from the shared
     * [InstanceOwner] scope (which is visible to every owner).
     */
    data class Owner(
        val subject: String,
    ) : SyncScope {
        override val key: String = "owner:$subject"
        override val entityTypes: List<EntityType> = listOf(EntityType.Notification, EntityType.DeviceToken)
    }

    data object InstanceOwner : SyncScope {
        override val key: String = INSTANCE_OWNER_SCOPE_KEY
        override val entityTypes: List<EntityType> =
            listOf(
                EntityType.Organization,
                EntityType.OrganizationRequest,
                EntityType.ProducerRequest,
                EntityType.Owner,
                EntityType.OwnerInvitation,
                EntityType.Member,
                EntityType.ProducerAccount,
                EntityType.ErrorReport,
            )
    }

    companion object {
        fun fromKey(key: String): SyncScope? =
            when {
                key.startsWith("producer-account:") -> ProducerAccount(key.removePrefix("producer-account:"))
                key.startsWith("organization:") -> Organization(key.removePrefix("organization:"))
                key.startsWith("member:") -> Member(key.removePrefix("member:"))
                key.startsWith("owner:") -> Owner(key.removePrefix("owner:"))
                key == INSTANCE_OWNER_SCOPE_KEY -> InstanceOwner
                else -> null
            }
    }
}

const val INSTANCE_OWNER_SCOPE_KEY: String = "instance-owner"
