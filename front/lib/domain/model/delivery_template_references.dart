import 'package:amap_en_ligne/domain/model/organization.dart';

/// Returns [organization] with every reference to the delivery template
/// [oldId] — the organization default and each delivery's template — replaced
/// by [newId], or [organization] itself when it references no such template.
///
/// Used when the server allocates the real id of a `tmp_*` template.
Organization remapDeliveryTemplateReferences(
  Organization organization, {
  required String oldId,
  required String newId,
}) {
  final defaultMatches = organization.defaultDeliveryTemplateId == oldId;
  final deliveryMatches = organization.deliveries.any(
    (d) => d.deliveryTemplateId == oldId,
  );
  if (!defaultMatches && !deliveryMatches) return organization;
  return organization.copyWith(
    defaultDeliveryTemplateId: defaultMatches
        ? newId
        : organization.defaultDeliveryTemplateId,
    deliveries: organization.deliveries
        .map(
          (d) => d.deliveryTemplateId == oldId
              ? d.copyWith(deliveryTemplateId: newId)
              : d,
        )
        .toList(),
  );
}
