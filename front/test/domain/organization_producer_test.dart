import 'dart:convert';

import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> wireOf(Object value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  group('OrganizationProducer', () {
    test('fromJson decodes all fields', () {
      final json = {
        'producer_account_id': 'pa-1',
        'association_instant': '2023-11-14T22:13:20Z',
        'status': 'ACTIVE',
      };
      final p = OrganizationProducer.fromJson(json);
      expect(p.producerAccountId, 'pa-1');
      expect(p.associationInstant, '2023-11-14T22:13:20Z');
      expect(p.status, OrganizationProducerStatus.active);
    });

    test('toJson produces snake_case keys', () {
      const p = OrganizationProducer(
        producerAccountId: 'pa-1',
        associationInstant: '2023-11-14T22:13:20Z',
        status: OrganizationProducerStatus.suspended,
      );
      final json = wireOf(p);
      expect(json['producer_account_id'], 'pa-1');
      expect(json['association_instant'], '2023-11-14T22:13:20Z');
      expect(json['status'], 'SUSPENDED');
    });

    test('round-trip for all statuses', () {
      for (final status in OrganizationProducerStatus.values) {
        final p = OrganizationProducer(
          producerAccountId: 'pa-1',
          associationInstant: '1970-01-01T00:00:01Z',
          status: status,
        );
        final decoded = OrganizationProducer.fromJson(wireOf(p));
        expect(decoded.status, status);
      }
    });
  });

  group('OrgProduct', () {
    test('fromJson decodes all fields', () {
      final json = {
        'name': 'Vegetables',
        'product_type_id': 'pt-1',
        'producer_account_id': 'pa-1',
        'supported_basket_sizes': [
          {'name': 'small'},
        ],
        'description': 'Seasonal',
      };
      final p = OrgProduct.fromJson(json);
      expect(p.name, 'Vegetables');
      expect(p.productTypeId, 'pt-1');
      expect(p.producerAccountId, 'pa-1');
      expect(p.supportedBasketSizes, [const BasketSize(name: 'small')]);
      expect(p.description, 'Seasonal');
    });

    test('toJson produces snake_case keys', () {
      const p = OrgProduct(
        name: 'Fruits',
        productTypeId: 'pt-2',
        producerAccountId: 'pa-2',
      );
      final json = wireOf(p);
      expect(json['name'], 'Fruits');
      expect(json['product_type_id'], 'pt-2');
      expect(json['producer_account_id'], 'pa-2');
    });

    test('supported_basket_sizes defaults to empty list when absent', () {
      final json = {
        'name': 'Fruits',
        'product_type_id': 'pt-1',
        'producer_account_id': 'pa-1',
      };
      final p = OrgProduct.fromJson(json);
      expect(p.supportedBasketSizes, isEmpty);
    });
  });

  group('Organization (extended)', () {
    test('fromJson decodes producers and products', () {
      final json = {
        'organization_id': 'org-1',
        'name': 'AMAP Test',
        'contact_email': 'test@amap.fr',
        'producers': [
          {
            'producer_account_id': 'pa-1',
            'association_instant': '2023-11-14T22:13:20Z',
            'status': 'ACTIVE',
          },
        ],
        'products': [
          {
            'name': 'Vegetables',
            'product_type_id': 'pt-1',
            'producer_account_id': 'pa-1',
            'supported_basket_sizes': [],
          },
        ],
      };
      final org = Organization.fromJson(json);
      expect(org.producers.length, 1);
      expect(org.producers.first.producerAccountId, 'pa-1');
      expect(org.products.length, 1);
      expect(org.products.first.name, 'Vegetables');
    });

    test('producers and products default to empty when absent', () {
      final json = {
        'organization_id': 'org-1',
        'name': 'AMAP Test',
        'contact_email': 'test@amap.fr',
      };
      final org = Organization.fromJson(json);
      expect(org.producers, isEmpty);
      expect(org.products, isEmpty);
    });

    test('round-trip preserves all extended fields', () {
      const org = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
        timezone: 'Europe/Paris',
        producers: [
          OrganizationProducer(
            producerAccountId: 'pa-1',
            associationInstant: '1970-01-01T00:00:01Z',
            status: OrganizationProducerStatus.active,
          ),
        ],
      );
      final decoded = Organization.fromJson(wireOf(org));
      expect(decoded.organizationId, 'org-1');
      expect(decoded.timezone, 'Europe/Paris');
      expect(decoded.producers.first.producerAccountId, 'pa-1');
    });
  });

  group('OrganizationPayload', () {
    test('discriminator round-trip', () {
      const org = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
      );
      final payload = OrganizationPayload(organization: org);
      final json = payload.toJson();
      expect(json['type'], 'Organization');

      final decoded = OrganizationPayload.fromJson(json);
      expect(decoded.organization.organizationId, 'org-1');
      expect(decoded.entityType.name, 'organization');
    });

    test('EntityPayload.fromJson dispatches to OrganizationPayload', () {
      const org = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
      );
      final payload = OrganizationPayload(organization: org);
      final json = payload.toJson();
      final decoded = EntityPayload.fromJson(json);
      expect(decoded, isA<OrganizationPayload>());
    });
  });

  group('ProducerProduct', () {
    test('fromJson decodes all fields', () {
      final json = {
        'name': 'Honey',
        'product_type_id': 'pt-3',
        'supported_basket_sizes': [
          {'name': 'large'},
        ],
        'description': 'Organic honey',
      };
      final p = ProducerProduct.fromJson(json);
      expect(p.name, 'Honey');
      expect(p.productTypeId, 'pt-3');
      expect(p.supportedBasketSizes, [const BasketSize(name: 'large')]);
      expect(p.description, 'Organic honey');
    });

    test('toJson produces snake_case keys', () {
      const p = ProducerProduct(name: 'Honey', productTypeId: 'pt-3');
      final json = wireOf(p);
      expect(json['name'], 'Honey');
      expect(json['product_type_id'], 'pt-3');
    });
  });

  group('ProducerAccount', () {
    test('fromJson decodes all fields', () {
      final json = {
        'producer_account_id': 'pa-1',
        'name': 'Jean Dupont',
        'contact_email': 'jean@farm.fr',
        'address': '1 rue des Champs',
        'website': 'https://farm.fr',
        'active_status': true,
        'products': [
          {
            'name': 'Vegetables',
            'product_type_id': 'pt-1',
            'supported_basket_sizes': [],
          },
        ],
      };
      final pa = ProducerAccount.fromJson(json);
      expect(pa.producerAccountId, 'pa-1');
      expect(pa.name, 'Jean Dupont');
      expect(pa.contactEmail, 'jean@farm.fr');
      expect(pa.address, '1 rue des Champs');
      expect(pa.website, 'https://farm.fr');
      expect(pa.activeStatus, isTrue);
      expect(pa.managementMode, ProducerManagementMode.accountBacked);
      expect(pa.products.length, 1);
    });

    test('products default to empty when absent', () {
      final json = {'producer_account_id': 'pa-1', 'name': 'Jean Dupont'};
      final pa = ProducerAccount.fromJson(json);
      expect(pa.products, isEmpty);
    });

    test('round-trip preserves all fields', () {
      const pa = ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Jean Dupont',
        contactEmail: 'jean@farm.fr',
        products: [ProducerProduct(name: 'Vegetables', productTypeId: 'pt-1')],
      );
      final decoded = ProducerAccount.fromJson(wireOf(pa));
      expect(decoded.producerAccountId, 'pa-1');
      expect(decoded.name, 'Jean Dupont');
      expect(decoded.products.first.name, 'Vegetables');
    });

    test('decodes management mode and linked producer account', () {
      final pa = ProducerAccount.fromJson({
        'producer_account_id': 'pa-1',
        'name': 'Ferme locale',
        'management_mode': 'NO_ACCOUNT',
        'linked_producer_account': {
          'producer_account_id': 'pa-2',
          'name': 'Ferme liée',
        },
      });
      expect(pa.managementMode, ProducerManagementMode.noAccount);
      expect(pa.linkedProducerAccount?.producerAccountId, 'pa-2');
    });
  });

  group('ProducerAccountPayload', () {
    test('discriminator round-trip', () {
      const pa = ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Jean Dupont',
      );
      final payload = ProducerAccountPayload(producerAccount: pa);
      final json = payload.toJson();
      expect(json['type'], 'ProducerAccount');

      final decoded = ProducerAccountPayload.fromJson(json);
      expect(decoded.producerAccount.producerAccountId, 'pa-1');
      expect(decoded.entityType.name, 'producerAccount');
    });

    test('EntityPayload.fromJson dispatches to ProducerAccountPayload', () {
      const pa = ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Jean Dupont',
      );
      final payload = ProducerAccountPayload(producerAccount: pa);
      final json = payload.toJson();
      final decoded = EntityPayload.fromJson(json);
      expect(decoded, isA<ProducerAccountPayload>());
    });
  });
}
