package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ItemType(
    val id: Id<ItemType>,
    val name: String,
    // Inline SVG markup of the component icon (SVG only); null when no image is defined.
    @SerialName("image_svg") val imageSvg: String? = null,
)

@Serializable
data class ProductType(
    @SerialName("product_type_id")
    val productTypeId: Id<ProductType>,
    @SerialName("producer_account_id")
    val producerAccountId: Id<ProducerAccount>,
    @SerialName("supported_basket_sizes")
    val supportedBasketSizes: List<BasketSize> = emptyList(),
    val name: String,
    val description: String? = null,
    @SerialName("item_types") val itemTypes: List<ItemType> = emptyList(),
)
