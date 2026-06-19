import 'dart:convert';

import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/change_page.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_snapshot.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wire-format compatibility tests against the back's Kotlin serialization.
///
/// Fixtures here are hand-crafted to match exactly what the back produces
/// (snake_case fields, PascalCase sealed-class discriminators, uppercase
/// enum constants). We round-trip through `jsonEncode/jsonDecode` to inspect
/// the actual wire form (raw `.toJson()` does not recurse into nested objects).
void main() {
  Map<String, dynamic> wireOf(Object value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  group('ProductType / BasketSize', () {
    test('round-trip with description and basket sizes', () {
      const json = {
        'product_type_id': 'pt-1',
        'producer_account_id': 'producer-1',
        'supported_basket_sizes': [
          {'name': 'small'},
          {'name': 'large'},
        ],
        'name': 'Vegetables',
        'description': 'Seasonal vegetables',
        'item_types': <Map<String, Object?>>[],
      };
      final pt = ProductType.fromJson(json);
      expect(pt.productTypeId, 'pt-1');
      expect(pt.supportedBasketSizes, [
        const BasketSize(name: 'small'),
        const BasketSize(name: 'large'),
      ]);
      expect(wireOf(pt), json);
    });

    test('decodes when description is omitted', () {
      const json = {
        'product_type_id': 'pt-1',
        'producer_account_id': 'producer-1',
        'supported_basket_sizes': <Map<String, Object?>>[],
        'name': 'Vegetables',
      };
      final pt = ProductType.fromJson(json);
      expect(pt.description, isNull);
    });

    test('ProductType round-trips with itemTypes', () {
      final json = {
        'product_type_id': 'pt-1',
        'producer_account_id': 'pa-1',
        'name': 'Légumes',
        'item_types': [
          {
            'id': 'it-1',
            'name': 'carottes',
            'image_svg': '<svg><circle/></svg>',
          },
          {'id': 'it-2', 'name': 'courgettes'},
        ],
      };
      final pt = ProductType.fromJson(json);
      expect(pt.itemTypes.length, 2);
      expect(pt.itemTypes.first.name, 'carottes');
      expect(pt.itemTypes.first.imageSvg, '<svg><circle/></svg>');
      expect(pt.itemTypes.last.imageSvg, isNull);
      final encoded = pt.toJson();
      expect(encoded['item_types'], isA<List>());
      // Null SVG is omitted on the wire (matches back explicitNulls = false).
      expect(
        (encoded['item_types'] as List).last,
        isNot(contains('image_svg')),
      );
    });

    test('ProductType with no itemTypes field deserializes as empty list', () {
      final json = {
        'product_type_id': 'pt-1',
        'producer_account_id': 'pa-1',
        'name': 'Oeufs',
      };
      final pt = ProductType.fromJson(json);
      expect(pt.itemTypes, isEmpty);
    });
  });

  group('EntityPayload (sealed)', () {
    test('ProductType discriminator round-trip', () {
      const json = {
        'type': 'ProductType',
        'productType': {
          'product_type_id': 'pt-1',
          'producer_account_id': 'producer-1',
          'supported_basket_sizes': <Map<String, Object?>>[],
          'name': 'Vegetables',
          'item_types': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<ProductTypePayload>());
      expect((payload as ProductTypePayload).productType.name, 'Vegetables');
      expect(wireOf(payload), json);
    });

    test('Notification discriminator round-trip (unread)', () {
      const json = {
        'type': 'Notification',
        'notification': {
          'notification_id': 'notif-1',
          'recipient_scope': 'member:m-1',
          'type': 'INFO',
          'category': 'BASKET_EXCHANGE_ACCEPTED',
          'title': 'Demande de panier acceptée',
          'body': 'Votre demande a été acceptée.',
          'related_entity_id': 'bskex-1',
          'created_at': '2026-05-29T10:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<NotificationPayload>());
      final notification = (payload as NotificationPayload).notification;
      expect(notification.recipientScope, 'member:m-1');
      expect(notification.type, NotificationType.info);
      expect(
        notification.category,
        NotificationCategory.basketExchangeAccepted,
      );
      expect(notification.readAt, isNull);
      // null read_at and deep_link are omitted from the wire (include_if_null: false).
      expect(wireOf(payload), json);
    });

    test('Notification discriminator round-trip (read)', () {
      const json = {
        'type': 'Notification',
        'notification': {
          'notification_id': 'notif-2',
          'recipient_scope': 'member:m-1',
          'type': 'REMINDER',
          'category': 'GENERIC',
          'title': 'Rappel',
          'body': 'Livraison demain.',
          'created_at': '2026-05-29T10:00:00Z',
          'read_at': '2026-05-29T11:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json) as NotificationPayload;
      expect(payload.notification.readAt, '2026-05-29T11:00:00Z');
      expect(wireOf(payload), json);
    });

    test('Notification category ORGANIZATION_REQUEST_SUBMITTED round-trip', () {
      const json = {
        'type': 'Notification',
        'notification': {
          'notification_id': 'notif-org-1',
          'recipient_scope': 'owner:sub-1',
          'type': 'INFO',
          'category': 'ORGANIZATION_REQUEST_SUBMITTED',
          'title': "Nouvelle demande de création d'AMAP",
          'body': "Une demande a été soumise.",
          'related_entity_id': 'req-1',
          'created_at': '2026-06-01T10:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json) as NotificationPayload;
      expect(
        payload.notification.category,
        NotificationCategory.organizationRequestSubmitted,
      );
      expect(wireOf(payload), json);
    });

    test('Notification category PRODUCER_REQUEST_SUBMITTED round-trip', () {
      const json = {
        'type': 'Notification',
        'notification': {
          'notification_id': 'notif-prod-1',
          'recipient_scope': 'owner:sub-1',
          'type': 'INFO',
          'category': 'PRODUCER_REQUEST_SUBMITTED',
          'title': 'Nouvelle demande de compte producteur',
          'body': 'Une demande a été soumise.',
          'related_entity_id': 'req-2',
          'created_at': '2026-06-01T10:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json) as NotificationPayload;
      expect(
        payload.notification.category,
        NotificationCategory.producerRequestSubmitted,
      );
      expect(wireOf(payload), json);
    });

    test('Notification category SLOT_CANCELLED round-trip', () {
      const json = {
        'type': 'Notification',
        'notification': {
          'notification_id': 'notif-slot-1',
          'recipient_scope': 'member:m-1',
          'type': 'ALERT',
          'category': 'SLOT_CANCELLED',
          'title': 'Créneau annulé',
          'body': 'Le créneau du 2026-06-15 (18:00–20:00) a été annulé.',
          'related_entity_id': 'delivery-1',
          'created_at': '2026-06-01T10:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json) as NotificationPayload;
      expect(payload.notification.category, NotificationCategory.slotCancelled);
      expect(payload.notification.type, NotificationType.alert);
      expect(wireOf(payload), json);
    });

    test('Notification category SLOT_RESCHEDULED round-trip', () {
      const json = {
        'type': 'Notification',
        'notification': {
          'notification_id': 'notif-slot-2',
          'recipient_scope': 'member:m-1',
          'type': 'ALERT',
          'category': 'SLOT_RESCHEDULED',
          'title': 'Horaire de créneau modifié',
          'body': "L'horaire de votre créneau a été modifié.",
          'related_entity_id': 'delivery-1',
          'created_at': '2026-06-01T10:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json) as NotificationPayload;
      expect(
        payload.notification.category,
        NotificationCategory.slotRescheduled,
      );
      expect(wireOf(payload), json);
    });

    test('DeviceToken discriminator round-trip', () {
      const json = {
        'type': 'DeviceToken',
        'deviceToken': {
          'device_token_id': 'dev-1',
          'recipient_scope': 'member:m-1',
          'platform': 'ANDROID',
          'token': 'fcm-token-xyz',
          'created_at': '2026-05-29T10:00:00Z',
          'last_seen_at': '2026-05-29T10:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<DeviceTokenPayload>());
      final deviceToken = (payload as DeviceTokenPayload).deviceToken;
      expect(deviceToken.recipientScope, 'member:m-1');
      expect(deviceToken.platform, DevicePlatform.android);
      expect(deviceToken.token, 'fcm-token-xyz');
      expect(wireOf(payload), json);
    });

    test('Member discriminator round-trip with Set<Role>', () {
      const json = {
        'type': 'Member',
        'member': {
          'member_id': 'm-1',
          'organization_id': 'org-1',
          'roles': ['COORDINATOR', 'ADMIN'],
          'active_status': true,
          'contracts': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<MemberPayload>());
      final member = (payload as MemberPayload).member;
      expect(member.memberId, 'm-1');
      expect(member.roles, containsAll([Role.coordinator, Role.admin]));
      expect(wireOf(payload), json);
    });

    test('Member discriminator round-trip keeps sub absent on wire', () {
      const json = {
        'type': 'Member',
        'member': {
          'member_id': 'm-2',
          'organization_id': 'org-1',
          'roles': ['VOLUNTEER'],
          'active_status': true,
          'contracts': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<MemberPayload>());
      // `sub` is removed from Member and must stay absent from wire output.
      final member = (payload as MemberPayload).member;
      expect(member.memberId, 'm-2');
      final wire = wireOf(payload);
      final inner = wire['member'] as Map<String, dynamic>;
      expect(inner.containsKey('sub'), isFalse);
    });

    test('Member discriminator round-trip with PII + accountStatus ACTIVE', () {
      const json = {
        'type': 'Member',
        'member': {
          'member_id': 'm-pii',
          'organization_id': 'org-1',
          'roles': ['VOLUNTEER'],
          'active_status': true,
          'first_name': 'Alice',
          'last_name': 'Martin',
          'email': 'alice@example.org',
          'phone': '0612345678',
          'account_status': 'ACTIVE',
          'contracts': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<MemberPayload>());
      final member = (payload as MemberPayload).member;
      expect(member.firstName, 'Alice');
      expect(member.lastName, 'Martin');
      expect(member.email, 'alice@example.org');
      expect(member.phone, '0612345678');
      expect(member.accountStatus, MemberAccountStatus.active);
      expect(wireOf(payload), json);
    });

    test(
      'Member discriminator round-trip with PII + accountStatus SUSPENDED',
      () {
        const json = {
          'type': 'Member',
          'member': {
            'member_id': 'm-suspended',
            'organization_id': 'org-1',
            'roles': ['VOLUNTEER'],
            'active_status': false,
            'first_name': 'Bob',
            'last_name': 'Dupont',
            'email': 'bob@example.org',
            'account_status': 'SUSPENDED',
            'contracts': <Map<String, Object?>>[],
          },
        };
        final payload = EntityPayload.fromJson(json);
        expect(payload, isA<MemberPayload>());
        final member = (payload as MemberPayload).member;
        expect(member.firstName, 'Bob');
        expect(member.accountStatus, MemberAccountStatus.suspended);
        expect(wireOf(payload), json);
      },
    );

    test('MemberJoinRequest discriminator round-trip', () {
      const json = {
        'type': 'MemberJoinRequest',
        'memberJoinRequest': {
          'request_id': 'req-1',
          'organization_id': 'org-1',
          'email': 'alice@example.org',
          'first_name': 'Alice',
          'last_name': 'Martin',
          'status': 'PENDING',
          'submitted_at': '2026-01-01T00:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<MemberJoinRequestPayload>());
      final request = (payload as MemberJoinRequestPayload).memberJoinRequest;
      expect(request.requestId, 'req-1');
      expect(request.status, MemberJoinRequestStatus.pending);
      expect(wireOf(payload), json);
    });

    test(
      'Member discriminator round-trip with all PII fields null (legacy)',
      () {
        const json = {
          'type': 'Member',
          'member': {
            'member_id': 'm-legacy',
            'organization_id': 'org-1',
            'roles': ['VOLUNTEER'],
            'active_status': true,
            'contracts': <Map<String, Object?>>[],
          },
        };
        final payload = EntityPayload.fromJson(json);
        final member = (payload as MemberPayload).member;
        expect(member.firstName, isNull);
        expect(member.lastName, isNull);
        expect(member.email, isNull);
        expect(member.phone, isNull);
        expect(member.accountStatus, isNull);
        // All new fields must be absent from the wire when null
        // (include_if_null: false matches back's explicitNulls = false).
        final inner = (wireOf(payload))['member'] as Map<String, dynamic>;
        expect(inner.containsKey('first_name'), isFalse);
        expect(inner.containsKey('last_name'), isFalse);
        expect(inner.containsKey('email'), isFalse);
        expect(inner.containsKey('phone'), isFalse);
        expect(inner.containsKey('account_status'), isFalse);
      },
    );

    test('Owner discriminator round-trip', () {
      const json = {
        'type': 'Owner',
        'owner': {
          'owner_id': 'o-1',
          'first_name': 'Alice',
          'last_name': 'Martin',
          'email': 'alice@example.com',
          'account_status': 'ACTIVE',
          'registered_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-05-01T00:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<OwnerPayload>());
      final owner = (payload as OwnerPayload).owner;
      expect(owner.ownerId, 'o-1');
      expect(owner.firstName, 'Alice');
      expect(owner.accountStatus, AccountStatus.active);
      expect(owner.phone, isNull);
      // phone is null → absent from wire output.
      final wire = wireOf(payload);
      expect(wire['type'], 'Owner');
      final inner = wire['owner'] as Map<String, dynamic>;
      expect(inner.containsKey('phone'), isFalse);
      expect(inner['account_status'], 'ACTIVE');
    });

    test('Owner discriminator round-trip with phone and SUSPENDED status', () {
      const json = {
        'type': 'Owner',
        'owner': {
          'owner_id': 'o-2',
          'first_name': 'Bob',
          'last_name': 'Dupont',
          'email': 'bob@example.com',
          'phone': '+33612345678',
          'account_status': 'SUSPENDED',
          'registered_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-05-15T00:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<OwnerPayload>());
      final owner = (payload as OwnerPayload).owner;
      expect(owner.phone, '+33612345678');
      expect(owner.accountStatus, AccountStatus.suspended);
      expect(wireOf(payload), json);
    });

    test('MemberInvitation discriminator round-trip', () {
      const json = {
        'type': 'MemberInvitation',
        'memberInvitation': {
          'invitation_id': 'inv-m-1',
          'organization_id': 'org-1',
          'email': 'alice@example.org',
          'first_name': 'Alice',
          'last_name': 'Martin',
          'roles': ['ADMIN', 'VOLUNTEER'],
          'status': 'PENDING_ACTIVATION',
          'created_at': '2026-01-01T00:00:00Z',
          'expires_at': '2026-01-08T00:00:00Z',
          'resend_requested_at': '2026-01-02T00:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<MemberInvitationPayload>());
      final invitation = (payload as MemberInvitationPayload).memberInvitation;
      expect(invitation.organizationId, 'org-1');
      expect(invitation.roles, containsAll([Role.admin, Role.volunteer]));
      expect(invitation.status, InvitationStatus.pendingActivation);
      expect(wireOf(payload), json);
    });

    test('OwnerInvitation discriminator round-trip', () {
      const json = {
        'type': 'OwnerInvitation',
        'ownerInvitation': {
          'invitation_id': 'inv-o-1',
          'first_name': 'Jean',
          'last_name': 'Dupont',
          'email': 'jean@example.fr',
          'status': 'ACTIVATED',
          'submitted_at': '2026-01-01T00:00:00Z',
          'activated_at': '2026-01-03T00:00:00Z',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<OwnerInvitationPayload>());
      final invitation = (payload as OwnerInvitationPayload).ownerInvitation;
      expect(invitation.email, 'jean@example.fr');
      expect(invitation.status, InvitationStatus.activated);
      expect(wireOf(payload), json);
    });

    test('Contract discriminator round-trip (no product prices)', () {
      const json = {
        'type': 'Contract',
        'contract': {
          'contract_id': 'c-1',
          'name': 'Contrat légumes 2026',
          'organization_id': 'org-1',
          'producer_account_id': 'pa-1',
          'min_delivery_date': '2025-01-01',
          'max_delivery_date': '2025-12-31',
          'delivery_count': 12,
          'season_year': 2025,
          'product_prices': <Map<String, Object?>>[],
          'coordinators': <String>[],
          'members': <Map<String, Object?>>[],
          'status': 'IN_PREPARATION',
          'shared_baskets': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<ContractPayload>());
      final contract = (payload as ContractPayload).contract;
      expect(contract.contractId, 'c-1');
      expect(contract.name, 'Contrat légumes 2026');
      expect(contract.producerAccountId, 'pa-1');
      expect(contract.productPrices, isEmpty);
      expect(contract.status, ContractStatus.inPreparation);
      expect(wireOf(payload), json);
    });

    test('Contract discriminator round-trip with product prices', () {
      const json = {
        'type': 'Contract',
        'contract': {
          'contract_id': 'c-2',
          'name': 'Contrat légumes 2026',
          'organization_id': 'org-1',
          'producer_account_id': 'pa-1',
          'min_delivery_date': '2025-01-01',
          'max_delivery_date': '2025-12-31',
          'delivery_count': 12,
          'season_year': 2025,
          'product_prices': [
            {
              'product_type_id': 'pt-1',
              'basket_size': {'name': 'small'},
              'price': 120.0,
            },
            {
              'product_type_id': 'pt-1',
              'basket_size': {'name': 'large'},
            },
            {'product_type_id': 'pt-2'},
          ],
          'coordinators': <String>[],
          'members': <Map<String, Object?>>[],
          'status': 'IN_PREPARATION',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<ContractPayload>());
      final contract = (payload as ContractPayload).contract;
      expect(contract.producerAccountId, 'pa-1');
      expect(contract.productPrices.length, 3);
      expect(contract.productPrices[0].price, 120.0);
      expect(contract.productPrices[0].basketSize?.name, 'small');
      // null price is omitted from wire
      expect(contract.productPrices[1].price, isNull);
      expect(contract.productPrices[2].basketSize, isNull);
      // wire round-trip — null price/basket_size absent (include_if_null: false)
      final wire = wireOf(payload);
      final prices =
          (wire['contract'] as Map<String, dynamic>)['product_prices'] as List;
      expect((prices[1] as Map<String, dynamic>).containsKey('price'), isFalse);
      expect(
        (prices[2] as Map<String, dynamic>).containsKey('basket_size'),
        isFalse,
      );
    });

    test('ContractMember with subscriptions round-trip', () {
      const json = {
        'type': 'Contract',
        'contract': {
          'contract_id': 'c-3',
          'name': 'Contrat légumes 2026',
          'organization_id': 'org-1',
          'producer_account_id': 'pa-1',
          'min_delivery_date': '2025-01-01',
          'max_delivery_date': '2025-12-31',
          'delivery_count': 12,
          'season_year': 2025,
          'product_prices': <Map<String, Object?>>[],
          'coordinators': <String>[],
          'members': [
            {
              'member_id': 'm-1',
              'subscription_instant': '2025-01-01T00:00:00Z',
              'status': 'ACTIVE',
              'subscriptions': [
                {
                  'product_type_id': 'pt-1',
                  'basket_size': {'name': 'small'},
                },
                {'product_type_id': 'pt-2'},
              ],
            },
          ],
          'status': 'IN_PREPARATION',
          'shared_baskets': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<ContractPayload>());
      final contract = (payload as ContractPayload).contract;
      expect(contract.members.length, 1);
      final member = contract.members.first;
      expect(member.memberId, 'm-1');
      expect(member.status, ContractMemberStatus.active);
      expect(member.subscriptions.length, 2);
      expect(member.subscriptions.first.productTypeId, 'pt-1');
      expect(member.subscriptions.first.basketSize?.name, 'small');
      expect(member.subscriptions.last.basketSize, isNull);
      expect(wireOf(payload), json);
    });

    test('Contract with ACTIVE status and delivery_template_id round-trip', () {
      const json = {
        'type': 'Contract',
        'contract': {
          'contract_id': 'c-active',
          'name': 'Contrat actif avec template',
          'organization_id': 'org-1',
          'producer_account_id': 'pa-1',
          'min_delivery_date': '2026-01-01',
          'max_delivery_date': '2026-12-31',
          'delivery_count': 10,
          'season_year': 2026,
          'product_prices': <Map<String, Object?>>[],
          'coordinators': <String>[],
          'members': <Map<String, Object?>>[],
          'status': 'ACTIVE',
          'delivery_template_id': 'tmpl-1',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<ContractPayload>());
      final contract = (payload as ContractPayload).contract;
      expect(contract.status, ContractStatus.active);
      expect(contract.deliveryTemplateId, 'tmpl-1');
      final wire = wireOf(payload);
      final inner = wire['contract'] as Map<String, dynamic>;
      expect(inner['status'], 'ACTIVE');
      expect(inner['delivery_template_id'], 'tmpl-1');
    });

    test('Contract legacy JSON without status defaults to IN_PREPARATION', () {
      // The back may omit 'status' when it equals the default IN_PREPARATION.
      const jsonWithoutStatus = {
        'type': 'Contract',
        'contract': {
          'contract_id': 'c-legacy',
          'name': 'Contrat legacy',
          'organization_id': 'org-1',
          'producer_account_id': 'pa-1',
          'min_delivery_date': '2026-01-01',
          'max_delivery_date': '2026-12-31',
          'delivery_count': 10,
          'season_year': 2026,
          'product_prices': <Map<String, Object?>>[],
          'coordinators': <String>[],
          'members': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(jsonWithoutStatus);
      final contract = (payload as ContractPayload).contract;
      // Defaults to inPreparation when absent.
      expect(contract.status, ContractStatus.inPreparation);
      expect(contract.deliveryTemplateId, isNull);
      // The front always emits 'status' (json_serializable does not omit
      // non-null fields with defaults).
      final wire = wireOf(payload);
      final inner = wire['contract'] as Map<String, dynamic>;
      expect(inner['status'], 'IN_PREPARATION');
      // delivery_template_id is null → absent from wire (include_if_null: false).
      expect(inner.containsKey('delivery_template_id'), isFalse);
    });

    test('Contract with shared_baskets round-trip', () {
      const json = {
        'type': 'Contract',
        'contract': {
          'contract_id': 'c-shared',
          'name': 'Contrat panier partagé',
          'organization_id': 'org-1',
          'producer_account_id': 'pa-1',
          'min_delivery_date': '2026-01-01',
          'max_delivery_date': '2026-12-31',
          'delivery_count': 10,
          'season_year': 2026,
          'product_prices': <Map<String, Object?>>[],
          'coordinators': <String>[],
          'members': <Map<String, Object?>>[],
          'shared_baskets': [
            {
              'shared_basket_id': 'tmp_sb-1',
              'member_ids': ['member-a', 'member-b'],
              'anchor_delivery_id': 'delivery-1',
            },
          ],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<ContractPayload>());
      final contract = (payload as ContractPayload).contract;
      expect(contract.sharedBaskets, hasLength(1));
      final basket = contract.sharedBaskets.first;
      expect(basket.sharedBasketId, 'tmp_sb-1');
      expect(basket.memberIds, ['member-a', 'member-b']);
      expect(basket.anchorDeliveryId, 'delivery-1');
      final wire = wireOf(payload);
      final inner = wire['contract'] as Map<String, dynamic>;
      final baskets = inner['shared_baskets'] as List;
      final wireBasket = baskets.first as Map<String, dynamic>;
      expect(wireBasket['shared_basket_id'], 'tmp_sb-1');
      expect(wireBasket['member_ids'], ['member-a', 'member-b']);
      expect(wireBasket['anchor_delivery_id'], 'delivery-1');
    });

    test(
      'Contract without shared_baskets defaults to empty and omits null anchor',
      () {
        const json = {
          'type': 'Contract',
          'contract': {
            'contract_id': 'c-no-shared',
            'name': 'Contrat sans partage',
            'organization_id': 'org-1',
            'producer_account_id': 'pa-1',
            'min_delivery_date': '2026-01-01',
            'max_delivery_date': '2026-12-31',
            'delivery_count': 10,
            'season_year': 2026,
            'product_prices': <Map<String, Object?>>[],
            'coordinators': <String>[],
            'members': <Map<String, Object?>>[],
            'shared_baskets': [
              {
                'shared_basket_id': 'sb-1',
                'member_ids': ['member-a', 'member-b'],
              },
            ],
          },
        };
        final payload = EntityPayload.fromJson(json) as ContractPayload;
        // Absent shared_baskets defaults to empty.
        final empty =
            EntityPayload.fromJson({
                  'type': 'Contract',
                  'contract': {
                    'contract_id': 'c-empty',
                    'name': 'X',
                    'organization_id': 'org-1',
                    'producer_account_id': 'pa-1',
                    'min_delivery_date': '2026-01-01',
                    'max_delivery_date': '2026-12-31',
                    'delivery_count': 10,
                    'season_year': 2026,
                  },
                })
                as ContractPayload;
        expect(empty.contract.sharedBaskets, isEmpty);
        // null anchor_delivery_id omitted from the wire (include_if_null: false).
        final wire = wireOf(payload);
        final inner = wire['contract'] as Map<String, dynamic>;
        final wireBasket =
            (inner['shared_baskets'] as List).first as Map<String, dynamic>;
        expect(wireBasket.containsKey('anchor_delivery_id'), isFalse);
      },
    );

    test('DeliveryTemplate discriminator round-trip with early slot', () {
      const json = {
        'type': 'DeliveryTemplate',
        'deliveryTemplate': {
          'delivery_template_id': 'dt-1',
          'organization_id': 'org-1',
          'name': 'Livraison avec réception anticipée',
          'standard_start_time': '18:00',
          'standard_end_time': '20:00',
          'volunteer_arrival_time': '17:30',
          'desired_volunteer_count': 4,
          'early_slot': {
            'arrival_time': '17:00',
            'explanation': 'Réception des légumes',
            'max_volunteers': 2,
          },
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<DeliveryTemplatePayload>());
      final dt = (payload as DeliveryTemplatePayload).deliveryTemplate;
      expect(dt.deliveryTemplateId, 'dt-1');
      expect(dt.standardStartTime, '18:00');
      expect(dt.volunteerArrivalTime, '17:30');
      expect(dt.desiredVolunteerCount, 4);
      expect(dt.earlySlot?.arrivalTime, '17:00');
      expect(dt.earlySlot?.maxVolunteers, 2);
      expect(wireOf(payload), json);
    });

    test('DeliveryTemplate early_slot without explanation round-trips', () {
      const json = {
        'type': 'DeliveryTemplate',
        'deliveryTemplate': {
          'delivery_template_id': 'dt-4',
          'organization_id': 'org-1',
          'name': 'Livraison avec créneau sans explication',
          'standard_start_time': '18:00',
          'standard_end_time': '20:00',
          'early_slot': {'arrival_time': '17:00', 'max_volunteers': 2},
        },
      };
      final payload = EntityPayload.fromJson(json);
      final dt = (payload as DeliveryTemplatePayload).deliveryTemplate;
      expect(dt.earlySlot?.arrivalTime, '17:00');
      expect(dt.earlySlot?.maxVolunteers, 2);
      expect(dt.earlySlot?.explanation, isNull);
      // explanation must be absent from wire output when null.
      final earlySlotWire =
          (wireOf(payload)['deliveryTemplate']
                  as Map<String, dynamic>)['early_slot']
              as Map<String, dynamic>;
      expect(earlySlotWire.containsKey('explanation'), isFalse);
    });

    test(
      'DeliveryTemplate volunteer_arrival_time is absent from wire when null',
      () {
        const json = {
          'type': 'DeliveryTemplate',
          'deliveryTemplate': {
            'delivery_template_id': 'dt-3',
            'organization_id': 'org-1',
            'name': 'Livraison sans arrivée bénévole',
            'standard_start_time': '18:00',
            'standard_end_time': '20:00',
          },
        };
        final payload = EntityPayload.fromJson(json);
        final dt = (payload as DeliveryTemplatePayload).deliveryTemplate;
        expect(dt.volunteerArrivalTime, isNull);
        final wire = wireOf(payload);
        expect(
          (wire['deliveryTemplate'] as Map<String, dynamic>).containsKey(
            'volunteer_arrival_time',
          ),
          isFalse,
        );
      },
    );

    test('DeliveryTemplate discriminator defaults new fields when absent', () {
      const json = {
        'type': 'DeliveryTemplate',
        'deliveryTemplate': {
          'delivery_template_id': 'dt-2',
          'organization_id': 'org-1',
          'name': 'Livraison standard',
          'standard_start_time': '18:00',
          'standard_end_time': '20:00',
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<DeliveryTemplatePayload>());
      final dt = (payload as DeliveryTemplatePayload).deliveryTemplate;
      expect(dt.earlySlot, isNull);
      expect(dt.desiredVolunteerCount, 1);
      final wire = wireOf(payload);
      expect(
        (wire['deliveryTemplate']
            as Map<String, dynamic>)['desired_volunteer_count'],
        1,
      );
      // early_slot must be absent from wire output (include_if_null: false).
      expect(
        (wire['deliveryTemplate'] as Map<String, dynamic>).containsKey(
          'early_slot',
        ),
        isFalse,
      );
    });

    group('OrganizationRequest payload', () {
      test('round-trip from server snapshot JSON', () {
        const json = {
          'type': 'OrganizationRequest',
          'organizationRequest': {
            'request_id': 'req-1',
            'organization_name': 'AMAP des Collines',
            'organization_type': 'AMAP',
            'timezone': 'Europe/Paris',
            'default_language': 'fr',
            'admin_first_name': 'Alice',
            'admin_last_name': 'Martin',
            'admin_email': 'alice@collines.fr',
            'status': 'PENDING_VALIDATION',
            'submitted_at': '2026-05-07T10:00:00Z',
          },
        };
        final payload = EntityPayload.fromJson(json);
        expect(payload, isA<OrganizationRequestPayload>());
        final req = (payload as OrganizationRequestPayload).organizationRequest;
        expect(req.requestId, 'req-1');
        expect(req.organizationName, 'AMAP des Collines');
        expect(req.organizationType, OrganizationType.amap);
        expect(req.status, OrganizationRequestStatus.pendingValidation);
        expect(req.reviewedAt, isNull);
        final wire = wireOf(payload);
        expect(wire['type'], 'OrganizationRequest');
        final inner = wire['organizationRequest'] as Map<String, dynamic>;
        expect(inner['request_id'], 'req-1');
        expect(inner['organization_type'], 'AMAP');
        // reviewed_at is null so must be absent (include_if_null: false).
        expect(inner.containsKey('reviewed_at'), isFalse);
      });

      group('ProducerRequest payload', () {
        test('round-trip from server snapshot JSON', () {
          const json = {
            'type': 'ProducerRequest',
            'producerRequest': {
              'request_id': 'req-1',
              'producer_name': 'Ferme des Collines',
              'admin_first_name': 'Alice',
              'admin_last_name': 'Martin',
              'admin_email': 'alice@collines.fr',
              'status': 'PENDING_VALIDATION',
              'submitted_at': '2026-05-07T10:00:00Z',
            },
          };
          final payload = EntityPayload.fromJson(json);
          expect(payload, isA<ProducerRequestPayload>());
          final request = (payload as ProducerRequestPayload).producerRequest;
          expect(request.producerName, 'Ferme des Collines');
          expect(request.status, ProducerRequestStatus.pendingValidation);
          expect(wireOf(payload), json);
        });

        test('mutation write matches expected wire shape', () {
          const request = AdminProducerRequest(
            requestId: 'req-3',
            producerName: 'Ferme test',
            adminFirstName: 'Paul',
            adminLastName: 'Bernard',
            adminEmail: 'paul@test.fr',
            status: ProducerRequestStatus.approved,
            submittedAt: '2026-05-01T08:00:00Z',
            reviewedAt: '2026-05-02T10:00:00Z',
          );
          final payload = ProducerRequestPayload(producerRequest: request);
          final wire = wireOf(payload);
          expect(wire['type'], 'ProducerRequest');
          final inner = wire['producerRequest'] as Map<String, dynamic>;
          expect(inner['status'], 'APPROVED');
          expect(inner['reviewed_at'], '2026-05-02T10:00:00Z');
          // resend_requested_at is null → absent from wire.
          expect(inner.containsKey('resend_requested_at'), isFalse);
        });

        test('resend_requested_at round-trips on ProducerRequest', () {
          const request = AdminProducerRequest(
            requestId: 'req-4',
            producerName: 'Ferme test',
            adminFirstName: 'Paul',
            adminLastName: 'Bernard',
            adminEmail: 'paul@test.fr',
            status: ProducerRequestStatus.approved,
            submittedAt: '2026-05-01T08:00:00Z',
            reviewedAt: '2026-05-02T10:00:00Z',
            resendRequestedAt: '2026-05-03T09:00:00Z',
          );
          final payload = ProducerRequestPayload(producerRequest: request);
          final wire = wireOf(payload);
          final inner = wire['producerRequest'] as Map<String, dynamic>;
          expect(inner['resend_requested_at'], '2026-05-03T09:00:00Z');
          // Round-trip.
          final decoded = EntityPayload.fromJson(wire);
          final decodedRequest =
              (decoded as ProducerRequestPayload).producerRequest;
          expect(decodedRequest.resendRequestedAt, '2026-05-03T09:00:00Z');
        });
      });

      test(
        'round-trip preserves reviewed_at and review_comment when present',
        () {
          const json = {
            'type': 'OrganizationRequest',
            'organizationRequest': {
              'request_id': 'req-2',
              'organization_name': 'Ferme Dupont',
              'organization_type': 'PRODUCER',
              'timezone': 'Europe/Paris',
              'default_language': 'fr',
              'admin_first_name': 'Jean',
              'admin_last_name': 'Dupont',
              'admin_email': 'jean@ferme.fr',
              'status': 'REJECTED',
              'submitted_at': '2026-05-07T10:00:00Z',
              'reviewed_at': '2026-05-08T09:00:00Z',
              'review_comment': 'Dossier incomplet',
            },
          };
          final payload = EntityPayload.fromJson(json);
          final req =
              (payload as OrganizationRequestPayload).organizationRequest;
          expect(req.status, OrganizationRequestStatus.rejected);
          expect(req.organizationType, OrganizationType.producer);
          expect(req.reviewedAt, '2026-05-08T09:00:00Z');
          expect(req.reviewComment, 'Dossier incomplet');
          expect(wireOf(payload), json);
        },
      );

      test('mutation write: toJson matches expected wire shape', () {
        const request = AdminOrganizationRequest(
          requestId: 'req-3',
          organizationName: 'Test AMAP',
          organizationType: OrganizationType.amap,
          timezone: 'Europe/Paris',
          defaultLanguage: 'fr',
          adminFirstName: 'Paul',
          adminLastName: 'Bernard',
          adminEmail: 'paul@test.fr',
          status: OrganizationRequestStatus.approved,
          submittedAt: '2026-05-01T08:00:00Z',
          reviewedAt: '2026-05-02T10:00:00Z',
        );
        final payload = OrganizationRequestPayload(
          organizationRequest: request,
        );
        final wire = wireOf(payload);
        expect(wire['type'], 'OrganizationRequest');
        final inner = wire['organizationRequest'] as Map<String, dynamic>;
        expect(inner['request_id'], 'req-3');
        expect(inner['status'], 'APPROVED');
        expect(inner['organization_type'], 'AMAP');
        expect(inner['reviewed_at'], '2026-05-02T10:00:00Z');
        // resend_requested_at is null → absent from wire.
        expect(inner.containsKey('resend_requested_at'), isFalse);
      });

      test('resend_requested_at round-trips on OrganizationRequest', () {
        const request = AdminOrganizationRequest(
          requestId: 'req-5',
          organizationName: 'Test AMAP',
          organizationType: OrganizationType.amap,
          timezone: 'Europe/Paris',
          defaultLanguage: 'fr',
          adminFirstName: 'Paul',
          adminLastName: 'Bernard',
          adminEmail: 'paul@test.fr',
          status: OrganizationRequestStatus.approved,
          submittedAt: '2026-05-01T08:00:00Z',
          reviewedAt: '2026-05-02T10:00:00Z',
          resendRequestedAt: '2026-05-03T09:00:00Z',
        );
        final payload = OrganizationRequestPayload(
          organizationRequest: request,
        );
        final wire = wireOf(payload);
        final inner = wire['organizationRequest'] as Map<String, dynamic>;
        expect(inner['resend_requested_at'], '2026-05-03T09:00:00Z');
        // Round-trip.
        final decoded = EntityPayload.fromJson(wire);
        final decodedReq =
            (decoded as OrganizationRequestPayload).organizationRequest;
        expect(decodedReq.resendRequestedAt, '2026-05-03T09:00:00Z');
      });
    });

    group('ErrorReport / ErrorReportPayload', () {
      test('round-trip with all fields', () {
        const report = ErrorReport(
          errorReportId: 'er-1',
          errorMessage: 'Échec de la synchronisation : timeout',
          reportedAt: '2026-06-09T12:00:00Z',
        );
        final payload = ErrorReportPayload(errorReport: report);
        final wire = wireOf(payload);

        expect(wire['type'], 'ErrorReport');
        final inner = wire['errorReport'] as Map<String, dynamic>;
        expect(inner['error_report_id'], 'er-1');
        expect(inner['error_message'], 'Échec de la synchronisation : timeout');
        expect(inner['reported_at'], '2026-06-09T12:00:00Z');

        // Round-trip via EntityPayload.fromJson.
        final decoded = EntityPayload.fromJson(wire);
        expect(decoded, isA<ErrorReportPayload>());
        final decodedReport = (decoded as ErrorReportPayload).errorReport;
        expect(decodedReport.errorReportId, 'er-1');
        expect(
          decodedReport.errorMessage,
          'Échec de la synchronisation : timeout',
        );
        expect(decodedReport.reportedAt, '2026-06-09T12:00:00Z');
      });

      test('EntityType wire name is ErrorReport', () {
        expect(EntityType.errorReport.name, 'errorReport');
        expect(entityTypeWireNames[EntityType.errorReport], 'ErrorReport');
      });

      test('Upsert ClientMutation serialises and deserialises correctly', () {
        const report = ErrorReport(
          errorReportId: 'tmp_abc',
          errorMessage: 'Connection failed',
          reportedAt: '2026-06-09T10:00:00Z',
        );
        final mutation = ClientMutation(
          clientOpId: 'op-1',
          op: Upsert(payload: ErrorReportPayload(errorReport: report)),
        );
        final wire = wireOf(mutation);
        final decoded = ClientMutation.fromJson(wire);
        final upsert = decoded.op as Upsert;
        final payload = upsert.payload as ErrorReportPayload;
        expect(payload.errorReport.errorReportId, 'tmp_abc');
        expect(payload.errorReport.errorMessage, 'Connection failed');
      });
    });

    test('rejects unknown discriminator', () {
      expect(
        () => EntityPayload.fromJson({'type': 'Unknown'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Change / ChangeOp', () {
    test('UPSERT with payload', () {
      const json = {
        'cursor': 'c1',
        'entity_type': 'ProductType',
        'entity_id': 'pt-1',
        'producer_account_id': 'producer-1',
        'op': 'UPSERT',
        'payload': {
          'type': 'ProductType',
          'productType': {
            'product_type_id': 'pt-1',
            'producer_account_id': 'producer-1',
            'supported_basket_sizes': <Map<String, Object?>>[],
            'name': 'Vegetables',
            'item_types': <Map<String, Object?>>[],
          },
        },
        'produced_at': 1234,
      };
      final change = Change.fromJson(json);
      expect(change.op, ChangeOp.upsert);
      expect(change.entityType, EntityType.productType);
      expect(change.payload, isA<ProductTypePayload>());
      expect(wireOf(change), json);
    });

    test('DELETE without payload (tombstone)', () {
      const json = {
        'cursor': 'c2',
        'entity_type': 'ProductType',
        'entity_id': 'pt-1',
        'producer_account_id': 'producer-1',
        'op': 'DELETE',
        'produced_at': 1234,
      };
      final change = Change.fromJson(json);
      expect(change.op, ChangeOp.delete);
      expect(change.payload, isNull);
    });
  });

  group('ChangePage / EntitySnapshot', () {
    test('ChangePage with hasMore and nextCursor', () {
      const json = {
        'changes': <Map<String, Object?>>[],
        'next_cursor': 'c5',
        'has_more': true,
      };
      final page = ChangePage.fromJson(json);
      expect(page.nextCursor, 'c5');
      expect(page.hasMore, true);
    });

    group('ScopeSyncResult', () {
      test('bootstrap decodes polymorphic items', () {
        const json = {
          'mode': 'bootstrap',
          'items': [
            {
              'type': 'ProductType',
              'productType': {
                'product_type_id': 'pt-1',
                'producer_account_id': 'producer-1',
                'supported_basket_sizes': <Map<String, Object?>>[],
                'name': 'Vegetables',
                'item_types': <Map<String, Object?>>[],
              },
            },
          ],
          'next_cursor': 'c1',
        };
        final result = ScopeSyncResult.fromJson(json);
        expect(result, isA<BootstrapScopeSyncResult>());
        expect(result.nextCursor, 'c1');
        expect(
          (result as BootstrapScopeSyncResult).items.single,
          isA<ProductTypePayload>(),
        );
        expect(result.toJson(), json);
      });

      test('incremental decodes changes', () {
        const json = {
          'mode': 'incremental',
          'changes': [
            {
              'entity_type': 'ProductType',
              'entity_id': 'pt-1',
              'op': 'DELETE',
              'produced_at': 1234,
            },
          ],
          'next_cursor': 'c2',
        };
        final result = ScopeSyncResult.fromJson(json);
        expect(result, isA<IncrementalScopeSyncResult>());
        expect(result.nextCursor, 'c2');
        expect(
          (result as IncrementalScopeSyncResult).changes.single.op,
          ChangeOp.delete,
        );
        expect(result.toJson(), json);
      });
    });

    test('EntitySnapshot decodes items as polymorphic payloads', () {
      const json = {
        'items': [
          {
            'type': 'ProductType',
            'productType': {
              'product_type_id': 'pt-1',
              'producer_account_id': 'producer-1',
              'supported_basket_sizes': <Map<String, Object?>>[],
              'name': 'Vegetables',
              'item_types': <Map<String, Object?>>[],
            },
          },
        ],
        'cursor': 'c1',
      };
      final snapshot = EntitySnapshot.fromJson(json);
      expect(snapshot.items.single, isA<ProductTypePayload>());
      expect(snapshot.cursor, 'c1');
    });
  });

  group('MutationOp (sealed)', () {
    test('Upsert with payload round-trip', () {
      const json = {
        'type': 'Upsert',
        'payload': {
          'type': 'ProductType',
          'productType': {
            'product_type_id': 'tmp_abc',
            'producer_account_id': 'producer-1',
            'supported_basket_sizes': <Map<String, Object?>>[],
            'name': 'Vegetables',
            'item_types': <Map<String, Object?>>[],
          },
        },
      };
      final op = MutationOp.fromJson(json);
      expect(op, isA<Upsert>());
      expect(wireOf(op), json);
    });

    test('Delete with entity_type and entity_id round-trip', () {
      const json = {
        'type': 'Delete',
        'entity_type': 'ProductType',
        'entity_id': 'pt-1',
      };
      final op = MutationOp.fromJson(json);
      expect(op, isA<Delete>());
      final delete = op as Delete;
      expect(delete.entityType, EntityType.productType);
      expect(delete.entityId, 'pt-1');
      expect(wireOf(op), json);
    });
  });

  group('MutationOutcome', () {
    test('APPLIED with serverEntityId mapping tmp_ → real', () {
      const json = {
        'client_op_id': 'op-1',
        'status': 'APPLIED',
        'server_entity_id': '01HX...real-id',
      };
      final outcome = MutationOutcome.fromJson(json);
      expect(outcome.status, MutationStatus.applied);
      expect(outcome.serverEntityId, '01HX...real-id');
      expect(outcome.error, isNull);
    });

    test('REJECTED with FORBIDDEN error', () {
      const json = {
        'client_op_id': 'op-2',
        'status': 'REJECTED',
        'error': {
          'code': 'FORBIDDEN',
          'message': 'producer_account_id mismatch',
        },
      };
      final outcome = MutationOutcome.fromJson(json);
      expect(outcome.status, MutationStatus.rejected);
      expect(outcome.error?.code, MutationErrorCode.forbidden);
    });

    test('REJECTED with LAST_PRODUCER error code (Phase 0)', () {
      const json = {
        'client_op_id': 'op-3',
        'status': 'REJECTED',
        'error': {
          'code': 'LAST_PRODUCER',
          'message': 'cannot leave producer org without any PRODUCER user',
        },
      };
      final outcome = MutationOutcome.fromJson(json);
      expect(outcome.error?.code, MutationErrorCode.lastProducer);
    });

    test('REJECTED with SELF_ACTION_FORBIDDEN error code (Phase 0)', () {
      const json = {
        'client_op_id': 'op-4',
        'status': 'REJECTED',
        'error': {
          'code': 'SELF_ACTION_FORBIDDEN',
          'message': 'cannot suspend or delete your own account',
        },
      };
      final outcome = MutationOutcome.fromJson(json);
      expect(outcome.error?.code, MutationErrorCode.selfActionForbidden);
    });

    test(
      'REJECTED with CONTRACT_ENDED error code round-trips the exact wire string',
      () {
        const json = {
          'client_op_id': 'op-5',
          'status': 'REJECTED',
          'error': {
            'code': 'CONTRACT_ENDED',
            'message': 'contract season has ended',
          },
        };
        final outcome = MutationOutcome.fromJson(json);
        expect(outcome.status, MutationStatus.rejected);
        expect(outcome.error?.code, MutationErrorCode.contractEnded);
        // Round-trip: the serialised code must match the exact wire string.
        // Use wireOf() to fully serialize through JSON before inspecting.
        final wire = wireOf(outcome);
        expect(
          (wire['error'] as Map<String, dynamic>)['code'],
          'CONTRACT_ENDED',
        );
      },
    );

    test(
      'REJECTED with INVALID_SUBSCRIPTION error code round-trips the exact wire string',
      () {
        const json = {
          'client_op_id': 'op-6',
          'status': 'REJECTED',
          'error': {
            'code': 'INVALID_SUBSCRIPTION',
            'message':
                'member has no subscription or subscription does not match product prices',
          },
        };
        final outcome = MutationOutcome.fromJson(json);
        expect(outcome.status, MutationStatus.rejected);
        expect(outcome.error?.code, MutationErrorCode.invalidSubscription);
        // Round-trip: the serialised code must match the exact wire string.
        final wire = wireOf(outcome);
        expect(
          (wire['error'] as Map<String, dynamic>)['code'],
          'INVALID_SUBSCRIPTION',
        );
      },
    );
  });

  group('SyncRequest', () {
    test('encodes cursors map keyed by scope key', () {
      final request = SyncRequest(
        cursors: {'producer-account:producer-1': 'c1'},
        mutations: const [],
      );
      expect(wireOf(request)['cursors'], {'producer-account:producer-1': 'c1'});
    });

    test('encodes a null cursor (bootstrap signal)', () {
      final request = SyncRequest(cursors: const {'organization:org-1': null});
      expect(wireOf(request)['cursors'], {'organization:org-1': null});
    });

    test('encodes a tmp_ Upsert mutation in full wire form', () {
      const tmp = ProductType(
        productTypeId: 'tmp_abc',
        producerAccountId: 'producer-1',
        supportedBasketSizes: [BasketSize(name: 'small')],
        name: 'Vegetables',
      );
      final request = SyncRequest(
        mutations: [
          ClientMutation(
            clientOpId: 'op-1',
            op: const Upsert(payload: ProductTypePayload(productType: tmp)),
          ),
        ],
      );
      final wire = wireOf(request);
      final mutation =
          (wire['mutations'] as List).single as Map<String, dynamic>;
      expect(mutation['client_op_id'], 'op-1');
      final op = mutation['op']! as Map<String, dynamic>;
      expect(op['type'], 'Upsert');
      final payload = op['payload']! as Map<String, dynamic>;
      expect(payload['type'], 'ProductType');
      final pt = payload['productType']! as Map<String, dynamic>;
      expect(pt['product_type_id'], 'tmp_abc');
      expect(pt['supported_basket_sizes'], [
        {'name': 'small'},
      ]);
    });
  });

  group('SyncResponse', () {
    test('full shape: authorized scopes + scope results + mutations', () {
      const json = {
        'authorized_scopes': ['producer-account:producer-1'],
        'results': {
          'producer-account:producer-1': {
            'mode': 'bootstrap',
            'items': <Map<String, Object?>>[],
            'next_cursor': 'c1',
          },
        },
        'mutations': [
          {
            'client_op_id': 'op-1',
            'status': 'APPLIED',
            'server_entity_id': 'pt-1',
          },
        ],
      };
      final response = SyncResponse.fromJson(json);
      expect(response.authorizedScopes, ['producer-account:producer-1']);
      expect(response.results['producer-account:producer-1']?.nextCursor, 'c1');
      expect(response.mutations.single.serverEntityId, 'pt-1');
      expect(wireOf(response), json);
    });
  });

  group('MemberPreferences', () {
    test('round-trip with all fields present (full shape)', () {
      const json = {
        'delivery_reminders_enabled': true,
        'volunteer_alerts_enabled': false,
        'reminder_24h_enabled': true,
        'reminder_2h_enabled': false,
        'reminder_30min_enabled': true,
        'urgent_need_alerts_enabled': false,
        'incomplete_slot_reminders_enabled': true,
        'planning_changes_alerts_enabled': false,
        'last_updated_instant': '2026-05-20T10:00:00Z',
      };
      final prefs = MemberPreferences.fromJson(json);
      expect(prefs.deliveryRemindersEnabled, isTrue);
      expect(prefs.volunteerAlertsEnabled, isFalse);
      expect(prefs.reminder24hEnabled, isTrue);
      expect(prefs.reminder2hEnabled, isFalse);
      expect(prefs.reminder30minEnabled, isTrue);
      expect(prefs.urgentNeedAlertsEnabled, isFalse);
      expect(prefs.incompleteSlotRemindersEnabled, isTrue);
      expect(prefs.planningChangesAlertsEnabled, isFalse);
      expect(prefs.lastUpdatedInstant, '2026-05-20T10:00:00Z');
      expect(wireOf(prefs), json);
    });

    test('defaults applied when optional boolean fields are absent', () {
      const json = {'last_updated_instant': '2026-05-20T10:00:00Z'};
      final prefs = MemberPreferences.fromJson(json);
      expect(prefs.deliveryRemindersEnabled, isTrue);
      expect(prefs.volunteerAlertsEnabled, isTrue);
      expect(prefs.reminder24hEnabled, isTrue);
      expect(prefs.reminder2hEnabled, isTrue);
      expect(prefs.reminder30minEnabled, isFalse);
      expect(prefs.urgentNeedAlertsEnabled, isTrue);
      expect(prefs.incompleteSlotRemindersEnabled, isFalse);
      expect(prefs.planningChangesAlertsEnabled, isTrue);
    });

    test(
      'Member with memberPreferences present round-trips full prefs block',
      () {
        const json = {
          'type': 'Member',
          'member': {
            'member_id': 'm-pref',
            'organization_id': 'org-1',
            'roles': ['VOLUNTEER'],
            'active_status': true,
            'contracts': <Map<String, Object?>>[],
            'member_preferences': {
              'delivery_reminders_enabled': true,
              'volunteer_alerts_enabled': true,
              'reminder_24h_enabled': true,
              'reminder_2h_enabled': true,
              'reminder_30min_enabled': false,
              'urgent_need_alerts_enabled': true,
              'incomplete_slot_reminders_enabled': false,
              'planning_changes_alerts_enabled': true,
              'last_updated_instant': '2026-05-20T10:00:00Z',
            },
          },
        };
        final payload = EntityPayload.fromJson(json);
        final member = (payload as MemberPayload).member;
        expect(member.memberPreferences, isNotNull);
        expect(member.memberPreferences!.reminder30minEnabled, isFalse);
        expect(
          member.memberPreferences!.lastUpdatedInstant,
          '2026-05-20T10:00:00Z',
        );
        expect(wireOf(payload), json);
      },
    );

    test(
      'Member without memberPreferences has null (absent from wire output)',
      () {
        const json = {
          'type': 'Member',
          'member': {
            'member_id': 'm-no-pref',
            'organization_id': 'org-1',
            'roles': ['VOLUNTEER'],
            'active_status': true,
            'contracts': <Map<String, Object?>>[],
          },
        };
        final payload = EntityPayload.fromJson(json);
        final member = (payload as MemberPayload).member;
        expect(member.memberPreferences, isNull);
        // member_preferences is null → must be absent from wire output.
        final wire = wireOf(payload);
        final inner = wire['member'] as Map<String, dynamic>;
        expect(inner.containsKey('member_preferences'), isFalse);
      },
    );
  });

  group('UserPreferences', () {
    test('round-trip with all fields present (full shape)', () {
      const json = {
        'email_notifications_enabled': true,
        'push_notifications_enabled': false,
        'last_updated_instant': '2026-05-20T11:00:00Z',
      };
      final prefs = UserPreferences.fromJson(json);
      expect(prefs.emailNotificationsEnabled, isTrue);
      expect(prefs.pushNotificationsEnabled, isFalse);
      expect(prefs.lastUpdatedInstant, '2026-05-20T11:00:00Z');
      expect(wireOf(prefs), json);
    });

    test('defaults applied when optional boolean fields are absent', () {
      const json = {'last_updated_instant': '2026-05-20T11:00:00Z'};
      final prefs = UserPreferences.fromJson(json);
      expect(prefs.emailNotificationsEnabled, isTrue);
      expect(prefs.pushNotificationsEnabled, isTrue);
    });

    test(
      'Member with userPreferences present round-trips full prefs block',
      () {
        const json = {
          'type': 'Member',
          'member': {
            'member_id': 'm-uprefs',
            'organization_id': 'org-1',
            'roles': ['VOLUNTEER'],
            'active_status': true,
            'contracts': <Map<String, Object?>>[],
            'user_preferences': {
              'email_notifications_enabled': true,
              'push_notifications_enabled': true,
              'last_updated_instant': '2026-05-20T11:00:00Z',
            },
          },
        };
        final payload = EntityPayload.fromJson(json);
        final member = (payload as MemberPayload).member;
        expect(member.userPreferences, isNotNull);
        expect(member.userPreferences!.pushNotificationsEnabled, isTrue);
        expect(
          member.userPreferences!.lastUpdatedInstant,
          '2026-05-20T11:00:00Z',
        );
        expect(wireOf(payload), json);
      },
    );

    test(
      'Member without userPreferences has null (absent from wire output)',
      () {
        const json = {
          'type': 'Member',
          'member': {
            'member_id': 'm-no-uprefs',
            'organization_id': 'org-1',
            'roles': ['VOLUNTEER'],
            'active_status': true,
            'contracts': <Map<String, Object?>>[],
          },
        };
        final payload = EntityPayload.fromJson(json);
        final member = (payload as MemberPayload).member;
        expect(member.userPreferences, isNull);
        // user_preferences is null → must be absent from wire output.
        final wire = wireOf(payload);
        final inner = wire['member'] as Map<String, dynamic>;
        expect(inner.containsKey('user_preferences'), isFalse);
      },
    );
  });

  group('MemberRegistration', () {
    test(
      'round-trip: registration_instant is an ISO-8601 string, not a number',
      () {
        final json = {
          'member_id': 'm-1',
          'display_name': 'Alice Martin',
          'member_email': 'alice@example.fr',
          'registration_instant': '2026-01-15T18:00:00Z',
          'status': 'REGISTERED',
        };
        final reg = MemberRegistration.fromJson(json);
        expect(reg.registrationInstant, '2026-01-15T18:00:00Z');

        final wire = wireOf(reg);
        // Must re-emit the original ISO-8601 string, not a number.
        expect(wire['registration_instant'], '2026-01-15T18:00:00Z');
        expect(wire['registration_instant'], isA<String>());
        expect(wire['registration_instant'], isNot(isA<int>()));
        expect(wire, json);
      },
    );
  });

  group('BasketExchange', () {
    test('round-trip with no requests and no optional fields', () {
      const json = {
        'type': 'BasketExchange',
        'basketExchange': {
          'basket_exchange_id': 'be-1',
          'organization_id': 'org-1',
          'delivery_id': 'd-1',
          'contract_id': 'c-1',
          'offering_member_id': 'm-1',
          'status': 'OPEN',
          'created_at': '2026-05-26T12:00:00Z',
          'requests': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<BasketExchangePayload>());
      final be = (payload as BasketExchangePayload).basketExchange;
      expect(be.basketExchangeId, 'be-1');
      expect(be.status, BasketExchangeStatus.open);
      expect(be.motive, isNull);
      expect(be.decidedAt, isNull);
      expect(be.acceptedRequestId, isNull);
      expect(be.requests, isEmpty);
      // Null optional fields must be absent from wire output (include_if_null: false).
      final wire = wireOf(payload);
      final inner = wire['basketExchange'] as Map<String, dynamic>;
      expect(inner.containsKey('motive'), isFalse);
      expect(inner.containsKey('decided_at'), isFalse);
      expect(inner.containsKey('accepted_request_id'), isFalse);
    });

    test('round-trip with requests and all optional fields present', () {
      const json = {
        'type': 'BasketExchange',
        'basketExchange': {
          'basket_exchange_id': 'be-2',
          'organization_id': 'org-1',
          'delivery_id': 'd-2',
          'contract_id': 'c-2',
          'offering_member_id': 'm-1',
          'motive': 'Je suis absent ce jour-là',
          'status': 'ACCEPTED',
          'created_at': '2026-05-20T10:00:00Z',
          'decided_at': '2026-05-22T14:00:00Z',
          'accepted_request_id': 'req-1',
          'requests': [
            {
              'request_id': 'req-1',
              'requester_member_id': 'm-2',
              'created_at': '2026-05-21T09:00:00Z',
              'status': 'ACCEPTED',
              'decided_at': '2026-05-22T14:00:00Z',
            },
            {
              'request_id': 'req-2',
              'requester_member_id': 'm-3',
              'created_at': '2026-05-21T11:00:00Z',
              'status': 'REJECTED',
              'decided_at': '2026-05-22T14:00:00Z',
            },
          ],
        },
      };
      final payload = EntityPayload.fromJson(json);
      expect(payload, isA<BasketExchangePayload>());
      final be = (payload as BasketExchangePayload).basketExchange;
      expect(be.basketExchangeId, 'be-2');
      expect(be.status, BasketExchangeStatus.accepted);
      expect(be.motive, 'Je suis absent ce jour-là');
      expect(be.decidedAt, '2026-05-22T14:00:00Z');
      expect(be.acceptedRequestId, 'req-1');
      expect(be.requests.length, 2);
      expect(be.requests.first.requestId, 'req-1');
      expect(be.requests.first.status, BasketExchangeRequestStatus.accepted);
      expect(be.requests.last.requestId, 'req-2');
      expect(be.requests.last.status, BasketExchangeRequestStatus.rejected);
      expect(wireOf(payload), json);
    });

    test('CANCELLED status round-trips', () {
      const json = {
        'type': 'BasketExchange',
        'basketExchange': {
          'basket_exchange_id': 'be-3',
          'organization_id': 'org-1',
          'delivery_id': 'd-3',
          'contract_id': 'c-3',
          'offering_member_id': 'm-1',
          'status': 'CANCELLED',
          'created_at': '2026-05-10T08:00:00Z',
          'decided_at': '2026-05-11T10:00:00Z',
          'requests': <Map<String, Object?>>[],
        },
      };
      final payload = EntityPayload.fromJson(json);
      final be = (payload as BasketExchangePayload).basketExchange;
      expect(be.status, BasketExchangeStatus.cancelled);
      expect(wireOf(payload), json);
    });

    test('BasketExchangeRequest with WITHDRAWN status and no decided_at', () {
      const json = {
        'type': 'BasketExchange',
        'basketExchange': {
          'basket_exchange_id': 'be-4',
          'organization_id': 'org-1',
          'delivery_id': 'd-4',
          'contract_id': 'c-4',
          'offering_member_id': 'm-1',
          'status': 'OPEN',
          'created_at': '2026-05-26T12:00:00Z',
          'requests': [
            {
              'request_id': 'req-3',
              'requester_member_id': 'm-4',
              'created_at': '2026-05-27T09:00:00Z',
              'status': 'WITHDRAWN',
            },
          ],
        },
      };
      final payload = EntityPayload.fromJson(json);
      final be = (payload as BasketExchangePayload).basketExchange;
      final req = be.requests.single;
      expect(req.status, BasketExchangeRequestStatus.withdrawn);
      expect(req.decidedAt, isNull);
      // decided_at absent from wire output when null.
      final wire = wireOf(payload);
      final reqWire =
          ((wire['basketExchange'] as Map<String, dynamic>)['requests'] as List)
                  .first
              as Map<String, dynamic>;
      expect(reqWire.containsKey('decided_at'), isFalse);
    });

    test(
      'BasketExchangeRequest round-trips with proposed counter-delivery',
      () {
        const json = {
          'type': 'BasketExchange',
          'basketExchange': {
            'basket_exchange_id': 'be-5',
            'organization_id': 'org-1',
            'delivery_id': 'd-5',
            'contract_id': 'c-5',
            'offering_member_id': 'm-1',
            'status': 'OPEN',
            'created_at': '2026-05-26T12:00:00Z',
            'requests': [
              {
                'request_id': 'req-5',
                'requester_member_id': 'm-2',
                'created_at': '2026-05-27T09:00:00Z',
                'status': 'PENDING',
                'proposed_delivery_id': 'd-9',
                'proposed_contract_id': 'c-9',
              },
            ],
          },
        };
        final payload = EntityPayload.fromJson(json);
        final be = (payload as BasketExchangePayload).basketExchange;
        final req = be.requests.single;
        expect(req.proposedDeliveryId, 'd-9');
        expect(req.proposedContractId, 'c-9');
        expect(wireOf(payload), json);
      },
    );
  });

  group('Delivery / BasketDeliveryDescription', () {
    test('Delivery round-trips with basketDescriptions', () {
      final json = {
        'delivery_id': 'd-1',
        'organization_id': 'org-1',
        'scheduled_date': '2025-06-14T09:00:00',
        'status': 'PLANNED',
        'min_volunteers_required': 2,
        'basket_descriptions': [
          {
            'product_type_id': 'pt-1',
            'basket_size_name': 'Medium',
            'items': [
              {'item_type_id': 'it-1', 'name': 'Carottes', 'weight': '500g'},
              {'item_type_id': 'it-2'},
            ],
          },
        ],
      };
      final delivery = Delivery.fromJson(json);
      expect(delivery.basketDescriptions.length, 1);
      final desc = delivery.basketDescriptions.first;
      expect(desc.productTypeId, 'pt-1');
      expect(desc.basketSizeName, 'Medium');
      expect(desc.items.first.name, 'Carottes');
      expect(desc.items.first.weight, '500g');
      // Only a tiny label snapshot rides on the item; the SVG never does.
      expect(desc.items.last.name, '');
      expect(desc.items.last.weight, isNull);
      final encodedItem = delivery.basketDescriptions.first.items.first
          .toJson();
      expect(encodedItem, isNot(contains('image_svg')));
    });

    test('Organization round-trips the flat item_types SVG catalog', () {
      final json = {
        'organization_id': 'org-1',
        'name': 'AMAP test',
        'contact_email': 'test@example.com',
        'item_types': [
          {'id': 'it-1', 'name': 'Carottes', 'image_svg': '<svg></svg>'},
          {'id': 'it-2', 'name': 'Courgettes'},
        ],
      };
      final org = Organization.fromJson(json);
      expect(org.itemTypes.length, 2);
      expect(org.itemTypes.first.imageSvg, '<svg></svg>');
      expect(org.itemTypes.last.imageSvg, isNull);
      final encoded = org.toJson();
      expect(encoded['item_types'], isA<List>());
    });

    test('Organization with no item_types deserializes as empty catalog', () {
      final org = Organization.fromJson({
        'organization_id': 'org-1',
        'name': 'AMAP test',
        'contact_email': 'test@example.com',
      });
      expect(org.itemTypes, isEmpty);
    });

    test('Delivery with no basketDescriptions deserializes as empty list', () {
      final json = {
        'delivery_id': 'd-1',
        'organization_id': 'org-1',
        'scheduled_date': '2025-06-14T09:00:00',
        'status': 'PLANNED',
        'min_volunteers_required': 2,
      };
      final delivery = Delivery.fromJson(json);
      expect(delivery.basketDescriptions, isEmpty);
    });

    test('Delivery round-trips per-delivery time overrides', () {
      final json = {
        'delivery_id': 'd-1',
        'organization_id': 'org-1',
        'scheduled_date': '2025-06-14T09:00:00',
        'status': 'PLANNED',
        'min_volunteers_required': 2,
        'standard_end_time': '20:30',
        'volunteer_arrival_time': '17:45',
        'early_slot': {
          'arrival_time': '16:30',
          'explanation': 'Réception',
          'max_volunteers': 3,
        },
      };
      final delivery = Delivery.fromJson(json);
      expect(delivery.standardEndTime, '20:30');
      expect(delivery.volunteerArrivalTime, '17:45');
      expect(delivery.earlySlot?.arrivalTime, '16:30');
      expect(delivery.earlySlot?.maxVolunteers, 3);

      final encoded = wireOf(delivery);
      expect(encoded['standard_end_time'], '20:30');
      expect(encoded['volunteer_arrival_time'], '17:45');
      expect(encoded['early_slot'], {
        'arrival_time': '16:30',
        'explanation': 'Réception',
        'max_volunteers': 3,
      });
    });

    test('Delivery omits null time overrides from the wire', () {
      final json = {
        'delivery_id': 'd-1',
        'organization_id': 'org-1',
        'scheduled_date': '2025-06-14T09:00:00',
        'status': 'PLANNED',
        'min_volunteers_required': 2,
      };
      final delivery = Delivery.fromJson(json);
      expect(delivery.standardEndTime, isNull);
      expect(delivery.volunteerArrivalTime, isNull);
      expect(delivery.earlySlot, isNull);

      final encoded = wireOf(delivery);
      expect(encoded.containsKey('standard_end_time'), isFalse);
      expect(encoded.containsKey('volunteer_arrival_time'), isFalse);
      expect(encoded.containsKey('early_slot'), isFalse);
    });

    test(
      'Delivery early_slot without explanation omits explanation from wire',
      () {
        final json = {
          'delivery_id': 'd-1',
          'organization_id': 'org-1',
          'scheduled_date': '2025-06-14T09:00:00',
          'status': 'PLANNED',
          'min_volunteers_required': 2,
          'early_slot': {'arrival_time': '16:30', 'max_volunteers': 2},
        };
        final delivery = Delivery.fromJson(json);
        expect(delivery.earlySlot?.arrivalTime, '16:30');
        expect(delivery.earlySlot?.maxVolunteers, 2);
        expect(delivery.earlySlot?.explanation, isNull);

        final encoded = wireOf(delivery);
        final earlySlotWire = encoded['early_slot'] as Map<String, dynamic>;
        expect(earlySlotWire.containsKey('explanation'), isFalse);
      },
    );
  });

  group('SlotKind / MemberSlot', () {
    test('MemberSlot without slot_kind defaults to SlotKind.standard', () {
      // Legacy JSON from the back without the slot_kind field — must decode
      // to SlotKind.standard and not throw.
      final json = {
        'start_time': '2025-06-14T18:00:00',
        'end_time': '2025-06-14T20:00:00',
        'activity_type': 'PREPARATION',
        'required_volunteers': 2,
        'current_registrations': 0,
        'status': 'OPEN',
      };
      final slot = MemberSlot.fromJson(json);
      expect(slot.slotKind, SlotKind.standard);
    });

    test('MemberSlot with slot_kind EARLY round-trips correctly', () {
      final json = {
        'start_time': '2025-06-14T17:00:00',
        'end_time': '2025-06-14T18:00:00',
        'activity_type': 'RECEPTION',
        'required_volunteers': 1,
        'current_registrations': 0,
        'status': 'OPEN',
        'slot_kind': 'EARLY',
      };
      final slot = MemberSlot.fromJson(json);
      expect(slot.slotKind, SlotKind.early);
      // Re-encode: slot_kind must be "EARLY" on the wire.
      final wire = wireOf(slot);
      expect(wire['slot_kind'], 'EARLY');
    });

    test(
      'MemberSlot with slot_kind STANDARD round-trips with STANDARD on wire',
      () {
        final json = {
          'start_time': '2025-06-14T18:00:00',
          'end_time': '2025-06-14T20:00:00',
          'activity_type': 'DISTRIBUTION',
          'required_volunteers': 3,
          'current_registrations': 1,
          'status': 'CRITICAL',
          'slot_kind': 'STANDARD',
        };
        final slot = MemberSlot.fromJson(json);
        expect(slot.slotKind, SlotKind.standard);
        final wire = wireOf(slot);
        expect(wire['slot_kind'], 'STANDARD');
      },
    );

    test('MemberSlot with slot_id round-trips and preserves the id', () {
      final json = {
        'slot_id': 'slot-1',
        'start_time': '2025-06-14T18:00:00',
        'end_time': '2025-06-14T20:00:00',
        'activity_type': 'RECEPTION',
        'required_volunteers': 2,
        'current_registrations': 0,
        'status': 'OPEN',
        'slot_kind': 'STANDARD',
      };
      final slot = MemberSlot.fromJson(json);
      expect(slot.slotId, 'slot-1');
      final wire = wireOf(slot);
      expect(wire['slot_id'], 'slot-1');
    });

    test('MemberSlot without slot_id decodes to null and omits it on wire', () {
      // Legacy JSON from the back without the slot_id field — must decode
      // to null, and null slot_id must be omitted on re-encode
      // (include_if_null: false).
      final json = {
        'start_time': '2025-06-14T18:00:00',
        'end_time': '2025-06-14T20:00:00',
        'activity_type': 'PREPARATION',
        'required_volunteers': 2,
        'current_registrations': 0,
        'status': 'OPEN',
      };
      final slot = MemberSlot.fromJson(json);
      expect(slot.slotId, isNull);
      final wire = wireOf(slot);
      expect(wire.containsKey('slot_id'), isFalse);
    });

    test('MemberSlot with status CANCELLED round-trips correctly', () {
      final json = {
        'slot_id': 'slot-1',
        'start_time': '2025-06-14T18:00:00',
        'end_time': '2025-06-14T20:00:00',
        'activity_type': 'RECEPTION',
        'required_volunteers': 2,
        'current_registrations': 0,
        'status': 'CANCELLED',
        'slot_kind': 'STANDARD',
      };
      final slot = MemberSlot.fromJson(json);
      expect(slot.status, SlotStatus.cancelled);
      final wire = wireOf(slot);
      expect(wire['status'], 'CANCELLED');
    });
  });
}
