import 'dart:convert';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/product_type_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('product_type CRUD', () {
    final pt = buildProductType(
      supportedBasketSizes: const [smallBasketSize, largeBasketSize],
      description: 'Seasonal',
    );

    test(
      'upsert + read round-trip preserves all fields including jsonb basket sizes',
      () async {
        await db.upsertProductType(pt);
        final rows = await db.watchProductTypes(testTenantId).first;
        expect(rows, [pt]);
      },
    );

    test('upsert is idempotent (replaces previous row)', () async {
      await db.upsertProductType(pt);
      await db.upsertProductType(pt.copyWith(name: 'Renamed'));
      final rows = await db.watchProductTypes(testTenantId).first;
      expect(rows.single.name, 'Renamed');
    });

    test('delete removes the row', () async {
      await db.upsertProductType(pt);
      await db.deleteProductType(
        producerAccountId: testTenantId,
        productTypeId: 'pt-1',
      );
      final rows = await db.watchProductTypes(testTenantId).first;
      expect(rows, isEmpty);
    });

    test(
      'producer isolation: rows under another tenant are not visible',
      () async {
        await db.upsertProductType(pt);
        await db.upsertProductType(
          pt.copyWith(producerAccountId: 'producer-2'),
        );
        expect(
          (await db.watchProductTypes(testTenantId).first)
              .single
              .producerAccountId,
          testTenantId,
        );
        expect(
          (await db.watchProductTypes('producer-2').first)
              .single
              .producerAccountId,
          'producer-2',
        );
      },
    );

    test(
      'remapProductTypeId migrates the row from tmp_ to a real id',
      () async {
        final tmp = buildProductType(
          productTypeId: 'tmp_abc',
          supportedBasketSizes: const [smallBasketSize],
        );
        await db.upsertProductType(tmp);
        await db.remapProductTypeId(
          producerAccountId: testTenantId,
          oldId: 'tmp_abc',
          newId: 'pt-real-1',
        );
        final rows = await db.watchProductTypes(testTenantId).first;
        expect(rows.single.productTypeId, 'pt-real-1');
        expect(rows.single.name, 'Vegetables');
      },
    );

    test(
      'remapProductTypeId is a no-op when the source row does not exist',
      () async {
        await db.remapProductTypeId(
          producerAccountId: testTenantId,
          oldId: 'tmp_missing',
          newId: 'pt-1',
        );
        expect(await db.watchProductTypes(testTenantId).first, isEmpty);
      },
    );

    test(
      'corrupted supported_basket_sizes returns row with empty basket sizes',
      () async {
        await db.customStatement(
          'INSERT INTO product_types '
          '(producer_account_id, product_type_id, name, description, supported_basket_sizes) '
          'VALUES (?, ?, ?, NULL, ?)',
          [testTenantId, 'pt-corrupt', 'Corrupt', 'not-json'],
        );

        final rows = await db.watchProductTypes(testTenantId).first;
        expect(rows.single.productTypeId, 'pt-corrupt');
        expect(rows.single.supportedBasketSizes, isEmpty);
      },
    );
  });

  group('sync_cursors', () {
    test(
      'readCursor returns null when no row exists (bootstrap signal)',
      () async {
        expect(await db.readCursor(testProducerScopeKey), isNull);
      },
    );

    test('writeCursor + readCursor round-trip', () async {
      await db.writeCursor(testProducerScopeKey, 'cursor-1');
      expect(await db.readCursor(testProducerScopeKey), 'cursor-1');
    });

    test('writeCursor overwrites previous value', () async {
      await db.writeCursor(testProducerScopeKey, 'cursor-1');
      await db.writeCursor(testProducerScopeKey, 'cursor-2');
      expect(await db.readCursor(testProducerScopeKey), 'cursor-2');
    });

    test('writeCursor with null preserves the bootstrap signal', () async {
      await db.writeCursor(testProducerScopeKey, 'cursor-1');
      await db.writeCursor(testProducerScopeKey, null);
      expect(await db.readCursor(testProducerScopeKey), isNull);
    });

    test('resetAllCursors sets every existing cursor to null', () async {
      const orgKey = 'organization:org-1';
      await db.writeCursor(testProducerScopeKey, 'cursor-a');
      await db.writeCursor(orgKey, 'cursor-b');
      await db.resetAllCursors();
      expect(await db.readCursor(testProducerScopeKey), isNull);
      expect(await db.readCursor(orgKey), isNull);
    });

    test('resetAllCursors on empty table is a no-op', () async {
      await db.resetAllCursors();
      expect(await db.readAllScopeCursors(), isEmpty);
    });
  });

  group('pending_mutations queue', () {
    final upsertMutation = buildProductTypeUpsertMutation();
    final deleteMutation = buildProductTypeDeleteMutation(
      clientOpId: 'op-2',
      entityId: 'pt-1',
    );

    test('enqueue + read returns mutations in createdAt order', () async {
      await db.enqueuePendingMutation(
        upsertMutation,
        scopeKey: testProducerScopeKey,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.enqueuePendingMutation(
        deleteMutation,
        scopeKey: testProducerScopeKey,
      );
      final pending = await db.readPendingMutations();
      expect(pending.map((m) => m.clientOpId), ['op-1', 'op-2']);
    });

    test('round-trip preserves polymorphic op (Upsert/Delete)', () async {
      await db.enqueuePendingMutation(
        upsertMutation,
        scopeKey: testProducerScopeKey,
      );
      await db.enqueuePendingMutation(
        deleteMutation,
        scopeKey: testProducerScopeKey,
      );
      final pending = await db.readPendingMutations();
      expect(pending[0].op, isA<Upsert>());
      expect(pending[1].op, isA<Delete>());
      final delete = pending[1].op as Delete;
      expect(delete.entityId, 'pt-1');
    });

    test('drainPendingMutations removes only the listed ids', () async {
      await db.enqueuePendingMutation(
        upsertMutation,
        scopeKey: testProducerScopeKey,
      );
      await db.enqueuePendingMutation(
        deleteMutation,
        scopeKey: testProducerScopeKey,
      );
      await db.drainPendingMutations(['op-1']);
      final pending = await db.readPendingMutations();
      expect(pending.single.clientOpId, 'op-2');
    });

    test('drainPendingMutations with empty list is a no-op', () async {
      await db.enqueuePendingMutation(
        upsertMutation,
        scopeKey: testProducerScopeKey,
      );
      await db.drainPendingMutations(<String>[]);
      expect((await db.readPendingMutations()).length, 1);
    });

    test(
      'legacy upsert without scope is backfilled from its payload scope',
      () async {
        await db.customStatement(
          'INSERT INTO pending_mutations (client_op_id, scope_key, payload_json, created_at) '
          'VALUES (?, NULL, ?, ?)',
          [upsertMutation.clientOpId, jsonEncode(upsertMutation), 1],
        );

        final pending = await db.readPendingMutationEntries();

        expect(pending.single.scopeKey, testProducerScopeKey);
        final stored =
            await (db.select(
                  db.pendingMutations,
                )..where((t) => t.clientOpId.equals(upsertMutation.clientOpId)))
                .getSingle();
        expect(stored.scopeKey, testProducerScopeKey);
      },
    );

    test(
      'legacy delete without scope resolves from a matching queued upsert',
      () async {
        const member = Member(memberId: 'tmp_member', organizationId: 'org-1');
        const upsertMutation = ClientMutation(
          clientOpId: 'op-upsert',
          op: Upsert(payload: MemberPayload(member: member)),
        );
        const deleteMutation = ClientMutation(
          clientOpId: 'op-delete',
          op: Delete(entityType: EntityType.member, entityId: 'tmp_member'),
        );

        await db.customStatement(
          'INSERT INTO pending_mutations (client_op_id, scope_key, payload_json, created_at) '
          'VALUES (?, NULL, ?, ?)',
          [upsertMutation.clientOpId, jsonEncode(upsertMutation), 1],
        );
        await db.customStatement(
          'INSERT INTO pending_mutations (client_op_id, scope_key, payload_json, created_at) '
          'VALUES (?, NULL, ?, ?)',
          [deleteMutation.clientOpId, jsonEncode(deleteMutation), 2],
        );

        final pending = await db.readPendingMutationEntries();

        expect(pending.map((entry) => entry.scopeKey), [
          organizationScopeKey('org-1'),
          organizationScopeKey('org-1'),
        ]);
      },
    );
  });

  group('members CRUD', () {
    const orgId = 'org-1';

    Member buildMember({String memberId = 'm-1'}) =>
        Member(memberId: memberId, organizationId: orgId);

    test('upsert + watch round-trip', () async {
      final m = buildMember();
      await db.upsertMember(orgId, m);
      final rows = await db.watchMembers(orgId).first;
      expect(rows.length, 1);
      expect(rows.single.memberId, 'm-1');
    });

    test('upsert is idempotent', () async {
      final m = buildMember();
      await db.upsertMember(orgId, m);
      await db.upsertMember(orgId, m.copyWith(activeStatus: false));
      final rows = await db.watchMembers(orgId).first;
      expect(rows.single.activeStatus, false);
    });

    test('delete removes the row', () async {
      await db.upsertMember(orgId, buildMember());
      await db.deleteMember(orgId, 'm-1');
      expect(await db.watchMembers(orgId).first, isEmpty);
    });

    test('clearMembersForOrganization removes all rows for the org', () async {
      await db.upsertMember(orgId, buildMember(memberId: 'm-1'));
      await db.upsertMember(orgId, buildMember(memberId: 'm-2'));
      await db.clearMembersForOrganization(orgId);
      expect(await db.watchMembers(orgId).first, isEmpty);
    });

    test('org isolation: rows under another org are not visible', () async {
      await db.upsertMember(orgId, buildMember());
      await db.upsertMember(
        'org-2',
        Member(memberId: 'm-1', organizationId: 'org-2'),
      );
      expect((await db.watchMembers(orgId).first).length, 1);
      expect((await db.watchMembers('org-2').first).length, 1);
    });

    // Regression: ORGANIZATION_ADMIN users have tenantId == sub (not orgId).
    // watchMembersForTenant must fall back to the sync cursor to resolve the
    // real orgId when the exact-match fails.
    test(
      'GIVEN member stored under orgId AND cursor written for organization:orgId '
      'WHEN watchMembersForTenant is called with sub (not orgId) '
      'THEN the member is returned via cursor fallback',
      () async {
        final m = buildMember();
        await db.upsertMember(orgId, m);
        await db.writeCursor('organization:$orgId', 'cursor-1');

        const sub = 'user-sub-not-org-id';
        final rows = await db.watchMembersForTenant(sub).first;
        expect(rows, [m]);
      },
    );

    test(
      'GIVEN member invitations stored under orgId AND cursor written for organization:orgId '
      'WHEN watchMemberInvitationsForTenant is called with sub (not orgId) '
      'THEN the invitation is returned via cursor fallback',
      () async {
        const inv = MemberInvitation(
          invitationId: 'inv-1',
          organizationId: orgId,
          email: 'test@test.com',
          firstName: 'Test',
          lastName: 'User',
          roles: {},
          status: InvitationStatus.pendingActivation,
          createdAt: '2026-01-01T00:00:00.000Z',
          expiresAt: '2026-01-08T00:00:00.000Z',
        );
        await db.upsertMemberInvitation(orgId, inv);
        await db.writeCursor('organization:$orgId', 'cursor-1');

        const sub = 'user-sub-not-org-id';
        final rows = await db.watchMemberInvitationsForTenant(sub).first;
        expect(rows, [inv]);
      },
    );
  });

  group('contracts CRUD', () {
    const orgId = 'org-1';

    Contract buildContract({String contractId = 'c-1'}) => Contract(
      contractId: contractId,
      name: 'Contrat test',
      organizationId: orgId,
      producerAccountId: 'pa-1',
      minDeliveryDate: '2025-01-01',
      maxDeliveryDate: '2025-12-31',
      deliveryCount: 12,
      seasonYear: 2025,
      productPrices: const [ProductPrice(productTypeId: 'pt-1', price: 240.0)],
    );

    test('upsert + watch round-trip', () async {
      final c = buildContract();
      await db.upsertContract(orgId, c);
      final rows = await db.watchContracts(orgId).first;
      expect(rows.length, 1);
      expect(rows.single.contractId, 'c-1');
    });

    test('upsert is idempotent', () async {
      final c = buildContract();
      await db.upsertContract(orgId, c);
      await db.upsertContract(
        orgId,
        c.copyWith(
          productPrices: const [
            ProductPrice(productTypeId: 'pt-1', price: 300.0),
          ],
        ),
      );
      final rows = await db.watchContracts(orgId).first;
      expect(rows.single.productPrices.first.price, 300.0);
    });

    test('delete removes the row', () async {
      await db.upsertContract(orgId, buildContract());
      await db.deleteContract(orgId, 'c-1');
      expect(await db.watchContracts(orgId).first, isEmpty);
    });

    test('clearContractsForOrganization removes all rows', () async {
      await db.upsertContract(orgId, buildContract(contractId: 'c-1'));
      await db.upsertContract(orgId, buildContract(contractId: 'c-2'));
      await db.clearContractsForOrganization(orgId);
      expect(await db.watchContracts(orgId).first, isEmpty);
    });
  });

  group('delivery_templates CRUD', () {
    const orgId = 'org-1';

    DeliveryTemplate buildTemplate({
      String templateId = 'dt-1',
      EarlySlot? earlySlot,
    }) => DeliveryTemplate(
      deliveryTemplateId: templateId,
      organizationId: orgId,
      name: 'Livraison standard',
      standardStartTime: '18:00',
      standardEndTime: '20:00',
      earlySlot: earlySlot,
    );

    test('upsert + watch round-trip without early slot', () async {
      final t = buildTemplate();
      await db.upsertDeliveryTemplate(orgId, t);
      final rows = await db.watchDeliveryTemplates(orgId).first;
      expect(rows.length, 1);
      expect(rows.single.deliveryTemplateId, 'dt-1');
      expect(rows.single.earlySlot, isNull);
    });

    test('upsert + watch round-trip with early slot', () async {
      final t = buildTemplate(
        earlySlot: const EarlySlot(
          arrivalTime: '17:00',
          explanation: 'Réception des légumes',
          maxVolunteers: 2,
        ),
      );
      await db.upsertDeliveryTemplate(orgId, t);
      final rows = await db.watchDeliveryTemplates(orgId).first;
      expect(rows.single.earlySlot?.arrivalTime, '17:00');
      expect(rows.single.earlySlot?.maxVolunteers, 2);
    });

    test('upsert is idempotent', () async {
      final t = buildTemplate();
      await db.upsertDeliveryTemplate(orgId, t);
      await db.upsertDeliveryTemplate(orgId, t.copyWith(name: 'Updated'));
      final rows = await db.watchDeliveryTemplates(orgId).first;
      expect(rows.single.name, 'Updated');
    });

    test('delete removes the row', () async {
      await db.upsertDeliveryTemplate(orgId, buildTemplate());
      await db.deleteDeliveryTemplate(orgId, 'dt-1');
      expect(await db.watchDeliveryTemplates(orgId).first, isEmpty);
    });

    test('clearDeliveryTemplatesForOrganization removes all rows', () async {
      await db.upsertDeliveryTemplate(orgId, buildTemplate(templateId: 'dt-1'));
      await db.upsertDeliveryTemplate(orgId, buildTemplate(templateId: 'dt-2'));
      await db.clearDeliveryTemplatesForOrganization(orgId);
      expect(await db.watchDeliveryTemplates(orgId).first, isEmpty);
    });

    test('org isolation: rows under another org are not visible', () async {
      await db.upsertDeliveryTemplate(orgId, buildTemplate());
      await db.upsertDeliveryTemplate(
        'org-2',
        DeliveryTemplate(
          deliveryTemplateId: 'dt-1',
          organizationId: 'org-2',
          name: 'Other',
          standardStartTime: '09:00',
          standardEndTime: '11:00',
        ),
      );
      expect((await db.watchDeliveryTemplates(orgId).first).length, 1);
      expect((await db.watchDeliveryTemplates('org-2').first).length, 1);
    });
  });

  group('OrganizationRequests CRUD', () {
    AdminOrganizationRequest buildRequest({
      String requestId = 'req-1',
      OrganizationRequestStatus status =
          OrganizationRequestStatus.pendingValidation,
    }) => AdminOrganizationRequest(
      requestId: requestId,
      organizationName: 'AMAP des Collines',
      organizationType: OrganizationType.amap,
      timezone: 'Europe/Paris',
      defaultLanguage: 'fr',
      adminFirstName: 'Alice',
      adminLastName: 'Martin',
      adminEmail: 'alice@collines.fr',
      status: status,
      submittedAt: '2026-05-07T10:00:00Z',
    );

    test('upsert + watch round-trip', () async {
      final r = buildRequest();
      await db.upsertOrganizationRequest(r);
      final rows = await db.watchOrganizationRequests().first;
      expect(rows.length, 1);
      expect(rows.single.requestId, 'req-1');
      expect(rows.single.organizationType, OrganizationType.amap);
    });

    group('ProducerRequests CRUD', () {
      AdminProducerRequest buildRequest({
        String requestId = 'req-1',
        ProducerRequestStatus status = ProducerRequestStatus.pendingValidation,
      }) => AdminProducerRequest(
        requestId: requestId,
        producerName: 'Ferme des Collines',
        adminFirstName: 'Alice',
        adminLastName: 'Martin',
        adminEmail: 'alice@collines.fr',
        status: status,
        submittedAt: '2026-05-07T10:00:00Z',
      );

      test('upsert + watch round-trip', () async {
        await db.upsertProducerRequest(buildRequest());
        final rows = await db.watchProducerRequests().first;
        expect(rows.single.requestId, 'req-1');
        expect(rows.single.producerName, 'Ferme des Collines');
      });

      test('delete removes the row', () async {
        await db.upsertProducerRequest(buildRequest());
        await db.deleteProducerRequest('req-1');
        expect(await db.watchProducerRequests().first, isEmpty);
      });

      test('clearProducerRequests removes all rows', () async {
        await db.upsertProducerRequest(buildRequest(requestId: 'req-1'));
        await db.upsertProducerRequest(buildRequest(requestId: 'req-2'));
        await db.clearProducerRequests();
        expect(await db.watchProducerRequests().first, isEmpty);
      });
    });

    test('upsert is idempotent (replaces previous row)', () async {
      final r = buildRequest();
      await db.upsertOrganizationRequest(r);
      await db.upsertOrganizationRequest(
        r.copyWith(status: OrganizationRequestStatus.approved),
      );
      final rows = await db.watchOrganizationRequests().first;
      expect(rows.single.status, OrganizationRequestStatus.approved);
    });

    test('delete removes the row', () async {
      await db.upsertOrganizationRequest(buildRequest());
      await db.deleteOrganizationRequest('req-1');
      expect(await db.watchOrganizationRequests().first, isEmpty);
    });

    test('clearOrganizationRequests removes all rows', () async {
      await db.upsertOrganizationRequest(buildRequest(requestId: 'req-1'));
      await db.upsertOrganizationRequest(buildRequest(requestId: 'req-2'));
      await db.clearOrganizationRequests();
      expect(await db.watchOrganizationRequests().first, isEmpty);
    });

    test('watch emits updated list after upsert', () async {
      final stream = db.watchOrganizationRequests();
      final emitted = <List<AdminOrganizationRequest>>[];
      final sub = stream.listen(emitted.add);

      await db.upsertOrganizationRequest(buildRequest());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(emitted.last.length, 1);
      expect(emitted.last.single.requestId, 'req-1');
    });
  });

  group('owners CRUD', () {
    Owner buildOwner({
      String ownerId = 'o-1',
      AccountStatus accountStatus = AccountStatus.active,
      String? phone,
    }) => Owner(
      ownerId: ownerId,
      firstName: 'Alice',
      lastName: 'Martin',
      email: 'alice@example.com',
      phone: phone,
      accountStatus: accountStatus,
      registeredAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );

    test('upsert + watch round-trip preserves all fields', () async {
      final o = buildOwner();
      await db.upsertOwner(o);
      final rows = await db.watchOwners().first;
      expect(rows.length, 1);
      expect(rows.single.ownerId, 'o-1');
      expect(rows.single.firstName, 'Alice');
      expect(rows.single.accountStatus, AccountStatus.active);
      expect(rows.single.phone, isNull);
    });

    test('upsert round-trip with phone and SUSPENDED status', () async {
      final o = buildOwner(
        accountStatus: AccountStatus.suspended,
        phone: '+33612345678',
      );
      await db.upsertOwner(o);
      final rows = await db.watchOwners().first;
      expect(rows.single.accountStatus, AccountStatus.suspended);
      expect(rows.single.phone, '+33612345678');
    });

    test('upsert is idempotent (replaces previous row)', () async {
      final o = buildOwner();
      await db.upsertOwner(o);
      await db.upsertOwner(o.copyWith(accountStatus: AccountStatus.suspended));
      final rows = await db.watchOwners().first;
      expect(rows.single.accountStatus, AccountStatus.suspended);
    });

    test('delete removes the row', () async {
      await db.upsertOwner(buildOwner());
      await db.deleteOwner('o-1');
      expect(await db.watchOwners().first, isEmpty);
    });

    test('clearOwners removes all rows', () async {
      await db.upsertOwner(buildOwner(ownerId: 'o-1'));
      await db.upsertOwner(buildOwner(ownerId: 'o-2'));
      await db.clearOwners();
      expect(await db.watchOwners().first, isEmpty);
    });

    test('findOwnerById returns null when missing', () async {
      expect(await db.findOwnerById('o-missing'), isNull);
    });

    test('findOwnerById returns correct owner when present', () async {
      await db.upsertOwner(buildOwner(ownerId: 'o-1'));
      await db.upsertOwner(buildOwner(ownerId: 'o-2'));
      final found = await db.findOwnerById('o-1');
      expect(found?.ownerId, 'o-1');
    });

    test('watch emits updated list after upsert', () async {
      final stream = db.watchOwners();
      final emitted = <List<Owner>>[];
      final sub = stream.listen(emitted.add);

      await db.upsertOwner(buildOwner());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(emitted.last.length, 1);
      expect(emitted.last.single.ownerId, 'o-1');
    });
  });

  group('basket_exchanges CRUD', () {
    const orgId = 'org-1';

    BasketExchange buildBasketExchange({
      String id = 'be-1',
      BasketExchangeStatus status = BasketExchangeStatus.open,
      List<BasketExchangeRequest> requests = const [],
    }) => BasketExchange(
      basketExchangeId: id,
      organizationId: orgId,
      deliveryId: 'd-1',
      contractId: 'c-1',
      offeringMemberId: 'm-1',
      status: status,
      createdAt: '2026-05-20T10:00:00Z',
      requests: requests,
    );

    test('upsert + watchBasketExchangesByOrg round-trips all fields', () async {
      final exchange = buildBasketExchange(
        requests: [
          const BasketExchangeRequest(
            requestId: 'req-1',
            requesterMemberId: 'm-2',
            createdAt: '2026-05-21T09:00:00Z',
            status: BasketExchangeRequestStatus.pending,
          ),
        ],
      );
      await db.upsertBasketExchange(exchange);

      final rows = await db.watchBasketExchangesByOrg(orgId).first;
      expect(rows.length, 1);
      final row = rows.single;
      expect(row.basketExchangeId, 'be-1');
      expect(row.status, BasketExchangeStatus.open);
      expect(row.requests.length, 1);
      expect(row.requests.single.requestId, 'req-1');
      expect(row.requests.single.status, BasketExchangeRequestStatus.pending);
    });

    test('upsert is idempotent (replaces previous row)', () async {
      final exchange = buildBasketExchange();
      await db.upsertBasketExchange(exchange);
      await db.upsertBasketExchange(
        exchange.copyWith(status: BasketExchangeStatus.cancelled),
      );

      final rows = await db.watchBasketExchangesByOrg(orgId).first;
      expect(rows.length, 1);
      expect(rows.single.status, BasketExchangeStatus.cancelled);
    });

    test('deleteBasketExchange removes the row', () async {
      await db.upsertBasketExchange(buildBasketExchange());
      await db.deleteBasketExchange('be-1');

      final rows = await db.watchBasketExchangesByOrg(orgId).first;
      expect(rows, isEmpty);
    });

    test('clearBasketExchangesForOrg removes only rows for that org', () async {
      await db.upsertBasketExchange(buildBasketExchange(id: 'be-1'));
      await db.upsertBasketExchange(
        buildBasketExchange(id: 'be-2').copyWith(organizationId: 'org-2'),
      );

      await db.clearBasketExchangesForOrg(orgId);

      final orgRows = await db.watchBasketExchangesByOrg(orgId).first;
      expect(orgRows, isEmpty);
      final org2Rows = await db.watchBasketExchangesByOrg('org-2').first;
      expect(org2Rows.length, 1);
    });

    test(
      'watchBasketExchangesByOrg does not return rows from other orgs',
      () async {
        await db.upsertBasketExchange(buildBasketExchange(id: 'be-org1'));
        await db.upsertBasketExchange(
          buildBasketExchange(id: 'be-org2').copyWith(organizationId: 'org-2'),
        );

        final rows = await db.watchBasketExchangesByOrg(orgId).first;
        expect(rows.length, 1);
        expect(rows.single.basketExchangeId, 'be-org1');
      },
    );

    test('remapBasketExchangeId migrates from tmp_ to real id', () async {
      await db.upsertBasketExchange(buildBasketExchange(id: 'tmp_abc'));
      await db.remapBasketExchangeId(oldId: 'tmp_abc', newId: 'be-real-1');

      final rows = await db.watchBasketExchangesByOrg(orgId).first;
      expect(rows.single.basketExchangeId, 'be-real-1');
    });
  });

  group('error_reports CRUD', () {
    test('upsert + watchAllErrorReports round-trips all fields', () async {
      const report = ErrorReport(
        errorReportId: 'er-1',
        errorMessage: 'Sync timeout',
        reportedAt: '2026-06-09T12:00:00Z',
      );
      await db.upsertErrorReport(report);

      final rows = await db.watchAllErrorReports().first;
      expect(rows.length, 1);
      expect(rows.single.errorReportId, 'er-1');
      expect(rows.single.errorMessage, 'Sync timeout');
      expect(rows.single.reportedAt, '2026-06-09T12:00:00Z');
    });

    test('upsert is idempotent (replaces previous row)', () async {
      const report = ErrorReport(
        errorReportId: 'er-1',
        errorMessage: 'Original error',
        reportedAt: '2026-06-09T12:00:00Z',
      );
      await db.upsertErrorReport(report);
      await db.upsertErrorReport(
        report.copyWith(errorMessage: 'Updated error'),
      );

      final rows = await db.watchAllErrorReports().first;
      expect(rows.length, 1);
      expect(rows.single.errorMessage, 'Updated error');
    });

    test('deleteErrorReport removes the row', () async {
      await db.upsertErrorReport(
        const ErrorReport(
          errorReportId: 'er-1',
          errorMessage: 'Error',
          reportedAt: '2026-06-09T12:00:00Z',
        ),
      );
      await db.deleteErrorReport('er-1');

      expect(await db.watchAllErrorReports().first, isEmpty);
    });

    test('clearAllErrorReports removes all rows', () async {
      await db.upsertErrorReport(
        const ErrorReport(
          errorReportId: 'er-1',
          errorMessage: 'Error 1',
          reportedAt: '2026-06-09T12:00:00Z',
        ),
      );
      await db.upsertErrorReport(
        const ErrorReport(
          errorReportId: 'er-2',
          errorMessage: 'Error 2',
          reportedAt: '2026-06-09T13:00:00Z',
        ),
      );
      await db.clearAllErrorReports();

      expect(await db.watchAllErrorReports().first, isEmpty);
    });

    test('remapErrorReportId migrates from tmp_ to real id', () async {
      await db.upsertErrorReport(
        const ErrorReport(
          errorReportId: 'tmp_abc',
          errorMessage: 'Error',
          reportedAt: '2026-06-09T12:00:00Z',
        ),
      );
      await db.remapErrorReportId(oldId: 'tmp_abc', newId: 'er-real-1');

      final rows = await db.watchAllErrorReports().first;
      expect(rows.single.errorReportId, 'er-real-1');
      expect(rows.single.errorMessage, 'Error');
    });
  });
}
