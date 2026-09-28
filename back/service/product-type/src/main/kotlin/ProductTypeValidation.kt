package producttype

import core.InputRules
import persistence.model.ProductType

/**
 * Mirrors the producer forms: required product name (`product_type_form_screen.dart`),
 * required component names and small SVG-only component images (`item_types_screen.dart`,
 * `optionalSvgImageError`). Returns the first violation, or `null`.
 */
internal fun ProductType.validationError(): String? {
    InputRules.requireName("name", name)?.let { return it }
    InputRules.basketSizesError("supported_basket_sizes", supportedBasketSizes.map { it.name })?.let { return it }
    itemTypes.forEach { itemType ->
        InputRules.requireName("item_types.name", itemType.name)?.let { return it }
        InputRules.optionalSvg("item_types.image_svg", itemType.imageSvg)?.let { return it }
    }
    return null
}
