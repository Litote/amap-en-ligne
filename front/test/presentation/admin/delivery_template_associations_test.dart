import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_associations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'computeDeliveryTemplateAssociations counts only matching deliveries',
    () {
      final organization = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
        deliveries: const [
          Delivery(
            deliveryId: 'd-1',
            organizationId: 'org-1',
            scheduledDate: '2030-06-14T18:00:00Z',
            status: DeliveryStatus.planned,
            minVolunteersRequired: 2,
            deliveryTemplateId: 'dt-1',
          ),
          Delivery(
            deliveryId: 'd-2',
            organizationId: 'org-1',
            scheduledDate: '2024-06-14T18:00:00Z',
            status: DeliveryStatus.completed,
            minVolunteersRequired: 2,
            deliveryTemplateId: 'dt-1',
          ),
          Delivery(
            deliveryId: 'd-3',
            organizationId: 'org-1',
            scheduledDate: '2030-06-14T18:00:00Z',
            status: DeliveryStatus.planned,
            minVolunteersRequired: 2,
          ),
        ],
      );

      final associations = computeDeliveryTemplateAssociations(
        organization,
        'dt-1',
        now: DateTime.parse('2025-01-01T00:00:00Z'),
      );

      expect(associations.associationCount, 2);
      expect(
        associations.futureAssociatedDeliveries.map(
          (delivery) => delivery.deliveryId,
        ),
        ['d-1'],
      );
    },
  );
}
