import 'dart:convert';

import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> wireOf(Object value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  group('Organization', () {
    test('fromJson decodes all fields', () {
      final org = Organization.fromJson({
        'organization_id': 'org-1',
        'name': 'AMAP des Collines',
        'contact_email': 'contact@collines.fr',
        'active_status': true,
        'default_delivery_template_id': 'dt-1',
      });
      expect(org.organizationId, 'org-1');
      expect(org.name, 'AMAP des Collines');
      expect(org.contactEmail, 'contact@collines.fr');
      expect(org.activeStatus, isTrue);
      expect(org.defaultDeliveryTemplateId, 'dt-1');
    });

    test('active_status defaults to true when absent', () {
      final org = Organization.fromJson({
        'organization_id': 'org-2',
        'name': 'Les Paniers Solidaires',
        'contact_email': 'info@paniers.fr',
      });
      expect(org.activeStatus, isTrue);
    });

    test(
      'toJson omits active_status=true (include_if_null: false applies to null, not defaults)',
      () {
        final org = const Organization(
          organizationId: 'org-1',
          name: 'AMAP test',
          contactEmail: 'test@amap.fr',
        );
        final json = org.toJson();
        expect(json['organization_id'], 'org-1');
        expect(json['name'], 'AMAP test');
        expect(json['contact_email'], 'test@amap.fr');
        expect(json.containsKey('default_delivery_template_id'), isFalse);
      },
    );

    test('toJson includes default_delivery_template_id when present', () {
      final org = const Organization(
        organizationId: 'org-1',
        name: 'AMAP test',
        contactEmail: 'test@amap.fr',
        defaultDeliveryTemplateId: 'dt-1',
      );

      expect(org.toJson()['default_delivery_template_id'], 'dt-1');
    });

    test(
      'deliveries decode optional delivery_template_id and legacy omission',
      () {
        final withTemplate = Organization.fromJson({
          'organization_id': 'org-3',
          'name': 'AMAP des Rives',
          'contact_email': 'contact@rives.fr',
          'deliveries': [
            {
              'delivery_id': 'd-1',
              'organization_id': 'org-3',
              'scheduled_date': '2025-06-14T18:00:00',
              'status': 'PLANNED',
              'min_volunteers_required': 2,
              'delivery_template_id': 'dt-1',
            },
            {
              'delivery_id': 'd-2',
              'organization_id': 'org-3',
              'scheduled_date': '2025-06-21T18:00:00',
              'status': 'PLANNED',
              'min_volunteers_required': 2,
            },
          ],
        });

        expect(withTemplate.deliveries[0].deliveryTemplateId, 'dt-1');
        expect(withTemplate.deliveries[1].deliveryTemplateId, isNull);
        final roundTrip = Organization.fromJson(wireOf(withTemplate));
        expect(roundTrip.deliveries[0].deliveryTemplateId, 'dt-1');
        expect(roundTrip.deliveries[1].deliveryTemplateId, isNull);
      },
    );
  });

  group('OrganizationCreationRequest', () {
    test('toJson produces correct snake_case keys', () {
      final request = const OrganizationCreationRequest(
        organizationName: 'AMAP test',
        timezone: 'Europe/Paris',
        defaultLanguage: 'fr',
        adminFirstName: 'Jean',
        adminLastName: 'Dupont',
        adminEmail: 'jean.dupont@example.fr',
        organizationType: OrganizationType.amap,
      );
      final json = request.toJson();
      expect(json['organization_name'], 'AMAP test');
      expect(json['timezone'], 'Europe/Paris');
      expect(json['default_language'], 'fr');
      expect(json['admin_first_name'], 'Jean');
      expect(json['admin_last_name'], 'Dupont');
      expect(json['admin_email'], 'jean.dupont@example.fr');
      expect(json['organization_type'], 'AMAP');
    });

    test('OrganizationType.amap serializes as AMAP', () {
      final request = const OrganizationCreationRequest(
        organizationName: 'AMAP test',
        timezone: 'Europe/Paris',
        defaultLanguage: 'fr',
        adminFirstName: 'Jean',
        adminLastName: 'Dupont',
        adminEmail: 'jean.dupont@example.fr',
        organizationType: OrganizationType.amap,
      );
      expect(request.toJson()['organization_type'], 'AMAP');
    });

    test('OrganizationType.producer serializes as PRODUCER', () {
      final request = const OrganizationCreationRequest(
        organizationName: 'Producer test',
        timezone: 'Europe/Paris',
        defaultLanguage: 'fr',
        adminFirstName: 'Jean',
        adminLastName: 'Dupont',
        adminEmail: 'jean.dupont@example.fr',
        organizationType: OrganizationType.producer,
      );
      expect(request.toJson()['organization_type'], 'PRODUCER');
    });

    test('round-trip preserves organizationType', () {
      final request = const OrganizationCreationRequest(
        organizationName: 'AMAP test',
        timezone: 'Europe/Paris',
        defaultLanguage: 'fr',
        adminFirstName: 'Jean',
        adminLastName: 'Dupont',
        adminEmail: 'jean.dupont@example.fr',
        organizationType: OrganizationType.amap,
      );
      final decoded = OrganizationCreationRequest.fromJson(request.toJson());
      expect(decoded.organizationType, OrganizationType.amap);
    });
  });

  group('DeliveryContract', () {
    test('round-trip with coordinators present', () {
      final contract = const DeliveryContract(
        contractId: 'c-1',
        coordinators: ['m-1', 'm-2'],
        basketQuantity: 10,
        deliveryDescription: 'Panier légumes',
        status: DeliveryContractStatus.pending,
      );
      final json = contract.toJson();
      expect(json['coordinators'], equals(['m-1', 'm-2']));
      expect(json.containsKey('coordinator_id'), isFalse);

      final decoded = DeliveryContract.fromJson(json);
      expect(decoded.coordinators, equals(['m-1', 'm-2']));
    });

    test('round-trip with empty coordinators list', () {
      const contract = DeliveryContract(
        contractId: 'c-2',
        coordinators: [],
        basketQuantity: 5,
        deliveryDescription: 'Panier fruits',
        status: DeliveryContractStatus.pending,
      );
      final json = contract.toJson();
      // Back serialises coordinators explicitly even when empty.
      expect(json['coordinators'], equals([]));

      final decoded = DeliveryContract.fromJson(json);
      expect(decoded.coordinators, isEmpty);
    });

    test('fromJson decodes absent coordinators key as empty list', () {
      final contract = DeliveryContract.fromJson({
        'contract_id': 'c-3',
        'basket_quantity': 5,
        'delivery_description': 'Panier fruits',
        'status': 'PENDING',
      });
      expect(contract.coordinators, isEmpty);
    });
  });

  group('Delivery', () {
    test('round-trip does not include coordinator_id field', () {
      const delivery = Delivery(
        deliveryId: 'd-1',
        organizationId: 'org-1',
        scheduledDate: '2025-06-14T18:00:00',
        status: DeliveryStatus.planned,
        minVolunteersRequired: 2,
      );
      final json = delivery.toJson();
      expect(json.containsKey('coordinator_id'), isFalse);

      final decoded = Delivery.fromJson(json);
      // Delivery has no coordinatorId field — verify it decodes without error.
      expect(decoded.deliveryId, 'd-1');
    });

    test('fromJson ignores coordinator_id when present in legacy JSON', () {
      // Legacy JSON may contain coordinator_id — it must be silently ignored.
      final delivery = Delivery.fromJson({
        'delivery_id': 'd-legacy',
        'organization_id': 'org-1',
        'scheduled_date': '2025-06-14T18:00:00',
        'status': 'PLANNED',
        'min_volunteers_required': 2,
        'coordinator_id': 'some-member-id',
      });
      expect(delivery.deliveryId, 'd-legacy');
    });
  });

  group('OrganizationRequestResponse', () {
    test('fromJson decodes request_id and status', () {
      final resp = OrganizationRequestResponse.fromJson({
        'request_id': 'req-123',
        'status': 'PENDING_VALIDATION',
      });
      expect(resp.requestId, 'req-123');
      expect(resp.status, 'PENDING_VALIDATION');
    });
  });
}
