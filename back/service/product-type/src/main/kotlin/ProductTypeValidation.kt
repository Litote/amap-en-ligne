package producttype

import core.InputRules
import persistence.model.ProductType

/**
 * Mirrors the producer forms: required product name (`product_type_form_screen.dart`),
 * required component names and SVG-only component images (`item_types_screen.dart`,
 * `_looksLikeSvg`). Returns the first violation, or `null`.
 */
internal fun ProductType.validationError(): String? {
    InputRules.requireName("name", name)?.let { return it }
    itemTypes.forEach { itemType ->
        InputRules.requireName("item_types.name", itemType.name)?.let { return it }
        val svg = itemType.imageSvg?.trimStart()
        if (!svg.isNullOrEmpty() && !svg.startsWith("<svg") && !svg.startsWith("<?xml")) {
            return "item_types.image_svg must be inline SVG markup"
        }
    }
    return null
}
