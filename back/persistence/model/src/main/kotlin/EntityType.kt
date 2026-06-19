package persistence.model

import kotlinx.serialization.Serializable

/**
 * Closed enumeration of domain entity types eligible to the offline-first sync
 * protocol. Acts as the discriminator for [EntityPayload], for [Change.entityType],
 * and as the key type for `cursors` / `changes` / `data` maps in `SyncRequest` /
 * `SyncResponse`.
 *
 * Adding a new synced entity is a deliberate four-step move:
 *  1. add a constant here,
 *  2. add a sealed subclass of [EntityPayload] that wraps the entity,
 *  3. add a sealed subclass of `EntityTypeService` to handle upsert/delete for it,
 *  4. extend the front contract.
 */
@Serializable
enum class EntityType {
    ProductType,
    Organization,
    ProducerAccount,
    Member,
    MemberJoinRequest,
    MemberInvitation,
    Contract,
    DeliveryTemplate,
    OrganizationRequest,
    ProducerRequest,
    Owner,
    OwnerInvitation,
    BasketExchange,
    Notification,
    DeviceToken,
    AttendanceEmailRequest,
    Producer,
    ErrorReport,
}

/** All synced entity types (union). */
val entityTypes: List<EntityType> = EntityType.entries
