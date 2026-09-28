@file:OptIn(ExperimentalTime::class)

package core

import persistence.model.BasketDeliveryDescription
import persistence.model.Delivery
import persistence.model.ItemType
import persistence.model.Organization
import persistence.model.ProductType
import kotlin.time.ExperimentalTime

/**
 * Rules shared by the two writers of a delivery's basket composition
 * ([Delivery.basketDescriptions]): coordinators (whole `Organization` upserts) and producers
 * (their `ProducerSchedule`, restricted to their own products).
 */
object BasketComposition {
    /**
     * Mirrors the composition editor: a component needs a name (the free-entry form; catalog
     * components carry their catalog name) and a bounded optional weight. Only components that
     * are new or edited are checked, so legacy components (e.g. an empty name snapshot) never
     * block the delivery.
     */
    fun itemsError(
        persisted: List<BasketDeliveryDescription>,
        incoming: List<BasketDeliveryDescription>,
        label: String,
    ): String? {
        val persistedItems = persisted.flatMap { it.items }.toSet()
        incoming
            .flatMap { it.items }
            .filterNot { it in persistedItems }
            .forEach { item ->
                InputRules.requireName("$label basket item name", item.name)?.let { return it }
                val weight = item.weight
                if (weight != null && weight.length > InputRules.MAX_NAME_LENGTH) {
                    return "$label basket item weight must be at most ${InputRules.MAX_NAME_LENGTH} characters"
                }
            }
        return null
    }

    /**
     * Protects compositions against stale copies: coordinators always upsert the whole
     * organization, so a device whose cache predates a composition edit (e.g. one made by the
     * producer) would otherwise write the old items back. For each (delivery, product, basket
     * size) present on both sides, the stored items are kept when they carry a newer
     * [BasketDeliveryDescription.itemsUpdatedAt] than the incoming ones (no timestamp = oldest;
     * when neither side has one, the incoming items win — legacy behaviour).
     *
     * Adding or removing a description (the products present in the delivery) is left to the
     * incoming write. The organization component catalog ([Organization.itemTypes]) is only ever
     * extended by editors, so stored entries missing from the incoming write are kept too.
     */
    fun keepNewestItems(
        persisted: Organization?,
        incoming: Organization,
    ): Organization {
        if (persisted == null) return incoming
        val persistedDeliveries = persisted.deliveries.associateBy { it.deliveryId }
        return incoming.copy(
            itemTypes = (persisted.itemTypes.associateBy { it.id } + incoming.itemTypes.associateBy { it.id }).values.toList(),
            deliveries =
                incoming.deliveries.map { delivery ->
                    persistedDeliveries[delivery.deliveryId]?.let { keepNewestItems(it, delivery) } ?: delivery
                },
        )
    }

    private fun keepNewestItems(
        persisted: Delivery,
        incoming: Delivery,
    ): Delivery {
        val stored = persisted.basketDescriptions.associateBy { it.key }
        return incoming.copy(
            basketDescriptions =
                incoming.basketDescriptions.map { description ->
                    val current = stored[description.key]
                    if (current != null && current.isNewerThan(description)) current else description
                },
        )
    }

    /** Stored items win when they have a timestamp and the incoming ones an older or none. */
    private fun BasketDeliveryDescription.isNewerThan(other: BasketDeliveryDescription): Boolean {
        val mine = itemsUpdatedAt ?: return false
        val theirs = other.itemsUpdatedAt ?: return true
        return mine > theirs
    }

    private val BasketDeliveryDescription.key get() = productTypeId to basketSizeName

    /**
     * [catalog] (the organization-level component catalog) updated with the latest definition,
     * taken from [productTypes], of every component used by [descriptions]. Keyed by id so each
     * icon is stored once; entries used by other deliveries are kept.
     */
    fun mergedItemTypes(
        catalog: List<ItemType>,
        descriptions: List<BasketDeliveryDescription>,
        productTypes: List<ProductType>,
    ): List<ItemType> {
        val used = descriptions.flatMap { it.items }.map { it.itemTypeId }.toSet()
        val latest = productTypes.flatMap { it.itemTypes }.filter { it.id in used }
        return (catalog.associateBy { it.id } + latest.associateBy { it.id }).values.toList()
    }
}
