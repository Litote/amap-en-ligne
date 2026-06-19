import 'package:amap_en_ligne/domain/model/organization.dart';

class DeliveryTemplateAssociations {
  const DeliveryTemplateAssociations({
    required this.associatedDeliveries,
    required this.futureAssociatedDeliveries,
  });

  final List<Delivery> associatedDeliveries;
  final List<Delivery> futureAssociatedDeliveries;

  int get associationCount => associatedDeliveries.length;
}

DeliveryTemplateAssociations computeDeliveryTemplateAssociations(
  Organization? organization,
  String deliveryTemplateId, {
  DateTime? now,
}) {
  final currentInstant = now ?? DateTime.now();
  final deliveries =
      organization?.deliveries
          .where(
            (delivery) => delivery.deliveryTemplateId == deliveryTemplateId,
          )
          .toList() ??
      const <Delivery>[];
  final futureDeliveries = deliveries.where((delivery) {
    final scheduledDate = DateTime.tryParse(delivery.scheduledDate);
    return scheduledDate != null && scheduledDate.isAfter(currentInstant);
  }).toList();
  return DeliveryTemplateAssociations(
    associatedDeliveries: deliveries,
    futureAssociatedDeliveries: futureDeliveries,
  );
}
