import 'dart:io';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/error_report.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
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

  group('watchEffectiveProducerAccountId', () {
    test('is null before any producer-account scope was synced', () async {
      expect(await db.watchEffectiveProducerAccountId().first, isNull);
    });

    test('returns the id of the synced producer-account scope (the account id, '
        'which may differ from the auth sub)', () async {
      await db.writeCursor('organization:org-1', 'c-0');
      await db.writeCursor('producer-account:pa-real', 'c-1');

      expect(await db.watchEffectiveProducerAccountId().first, 'pa-real');
    });
  });

  group('product types synced on an organization scope', () {
    const orgId = 'org-1';

    test(
      'deleteProductTypeById removes the row whatever its producer',
      () async {
        await db.upsertProductType(
          buildProductType(productTypeId: 'pt-9', producerAccountId: 'pa-9'),
        );

        await db.deleteProductTypeById('pt-9');

        expect(await db.watchProductTypes('pa-9').first, isEmpty);
      },
    );

    test('clearScopeData(organization) drops the catalogs of the organization '
        'producers so a re-bootstrap does not keep stale ones', () async {
      await db.upsertOrganization(
        const Organization(
          organizationId: orgId,
          name: 'AMAP',
          contactEmail: 'amap@example.com',
          producers: [
            OrganizationProducer(
              producerAccountId: 'pa-9',
              associationInstant: '2026-01-01T00:00:00Z',
              status: OrganizationProducerStatus.active,
            ),
          ],
        ),
      );
      await db.upsertProductType(
        buildProductType(productTypeId: 'pt-9', producerAccountId: 'pa-9'),
      );
      await db.upsertProductType(
        buildProductType(productTypeId: 'pt-other', producerAccountId: 'pa-x'),
      );

      await db.clearScopeData('organization:$orgId');

      expect(await db.watchProductTypes('pa-9').first, isEmpty);
      expect(await db.watchProductTypes('pa-x').first, hasLength(1));
    });
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

    test('upsert + read round-trip preserves the component catalog', () async {
      final withCatalog = pt.copyWith(
        itemTypes: const [
          ItemType(id: 'it-1', name: 'Comté', imageSvg: '<svg/>'),
          ItemType(id: 'it-2', name: 'Morbier'),
        ],
      );
      await db.upsertProductType(withCatalog);

      final rows = await db.watchProductTypes(testTenantId).first;
      expect(rows.single.itemTypes, withCatalog.itemTypes);
    });

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
  });

  group('member invitations on the instance-owner scope', () {
    MemberInvitation buildInvitation(String id, String orgId) =>
        MemberInvitation(
          invitationId: id,
          organizationId: orgId,
          email: '$id@example.com',
          firstName: 'Alice',
          lastName: 'Martin',
          roles: const {},
          status: InvitationStatus.pendingActivation,
          createdAt: '2026-09-01T00:00:00Z',
          expiresAt: '2026-09-08T00:00:00Z',
        );

    test('watchAllMemberInvitations lists the invitations of every '
        'organization', () async {
      await db.upsertMemberInvitation('org-1', buildInvitation('i-1', 'org-1'));
      await db.upsertMemberInvitation('org-2', buildInvitation('i-2', 'org-2'));

      final all = await db.watchAllMemberInvitations().first;

      expect(all.map((i) => i.invitationId), unorderedEquals(['i-1', 'i-2']));
    });

    test(
      'clearScopeData(instance-owner) drops the member invitations',
      () async {
        await db.upsertMemberInvitation(
          'org-1',
          buildInvitation('i-1', 'org-1'),
        );

        await db.clearScopeData('instance-owner');

        expect(await db.watchAllMemberInvitations().first, isEmpty);
      },
    );

    test('deleteMemberInvitationById removes the invitation whatever its '
        'organization', () async {
      await db.upsertMemberInvitation('org-1', buildInvitation('i-1', 'org-1'));
      await db.upsertMemberInvitation('org-2', buildInvitation('i-2', 'org-2'));

      await db.deleteMemberInvitationById('i-1');

      final all = await db.watchAllMemberInvitations().first;
      expect(all.map((i) => i.invitationId), ['i-2']);
    });
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
      await db.upsertMember(
        orgId,
        m.copyWith(accountStatus: MemberAccountStatus.suspended),
      );
      final rows = await db.watchMembers(orgId).first;
      expect(rows.single.accountStatus, MemberAccountStatus.suspended);
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
        const Member(memberId: 'm-1', organizationId: 'org-2'),
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
      productPrices: const [ProductPrice(productTypeId: 'pt-1', price: 240)],
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
            ProductPrice(productTypeId: 'pt-1', price: 300),
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

    test('remapDeliveryTemplateId rewrites the organization default template '
        'and delivery references', () async {
      await db.upsertDeliveryTemplate(
        orgId,
        buildTemplate(templateId: 'tmp_1'),
      );
      await db.upsertOrganization(
        const Organization(
          organizationId: orgId,
          name: 'AMAP',
          contactEmail: 'amap@example.com',
          defaultDeliveryTemplateId: 'tmp_1',
          deliveries: [
            Delivery(
              deliveryId: 'd-1',
              organizationId: orgId,
              scheduledDate: '2026-10-01T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 1,
              deliveryTemplateId: 'tmp_1',
            ),
          ],
        ),
      );

      await db.remapDeliveryTemplateId(
        organizationId: orgId,
        oldId: 'tmp_1',
        newId: 'dt-real',
      );

      final org = await db.watchOrganizationForTenant(orgId).first;
      expect(org?.defaultDeliveryTemplateId, 'dt-real');
      expect(org?.deliveries.single.deliveryTemplateId, 'dt-real');
      final templates = await db.watchDeliveryTemplates(orgId).first;
      expect(templates.single.deliveryTemplateId, 'dt-real');
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
        const DeliveryTemplate(
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

  group('schema version mismatch', () {
    Future<AppDatabase> openLegacy(int userVersion) async {
      final legacy = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // Pre-squash layout: an obsolete table plus a current table with
            // an incompatible shape, stamped with a foreign schema version.
            raw
              ..execute('CREATE TABLE legacy_table (id TEXT)')
              ..execute('CREATE TABLE sync_cursors (legacy TEXT)')
              ..execute("INSERT INTO sync_cursors VALUES ('stale')")
              ..execute('PRAGMA user_version = $userVersion');
          },
        ),
      );
      addTearDown(legacy.close);
      return legacy;
    }

    Future<List<String>> tableNames(AppDatabase database) async {
      final rows = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      return rows.map((row) => row.read<String>('name')).toList();
    }

    test(
      'upgrading from v3 adds cache_owners and keeps queued mutations',
      () async {
        final dir = Directory.systemTemp.createTempSync('amap_db_v3');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = File('${dir.path}/app.sqlite');

        final v3 = AppDatabase(NativeDatabase(file));
        final productType = buildProductType();
        await v3.enqueuePendingMutation(
          buildProductTypeUpsertMutation(productType: productType),
          scopeKey: testProducerScopeKey,
        );
        await v3.customStatement('DROP TABLE cache_owners');
        await v3.customStatement('PRAGMA user_version = 3');
        await v3.close();

        final upgraded = AppDatabase(NativeDatabase(file));
        addTearDown(upgraded.close);

        expect(await upgraded.readPendingMutations(), hasLength(1));
        expect(await upgraded.readCacheOwner(), isNull);
        await upgraded.writeCacheOwner('user-a');
        expect(await upgraded.readCacheOwner(), 'user-a');
      },
    );

    test(
      'upgrading from v4 drops the organization cursors only, keeping the '
      'queue (re-bootstrap without the other members contact details)',
      () async {
        final dir = Directory.systemTemp.createTempSync('amap_db_v4');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = File('${dir.path}/app.sqlite');

        final v4 = AppDatabase(NativeDatabase(file));
        await v4.writeCursor('organization:org-1', 'cursor-org');
        await v4.writeCursor(testProducerScopeKey, 'cursor-producer');
        await v4.enqueuePendingMutation(
          buildProductTypeUpsertMutation(productType: buildProductType()),
          scopeKey: testProducerScopeKey,
        );
        await v4.customStatement('PRAGMA user_version = 4');
        await v4.close();

        final upgraded = AppDatabase(NativeDatabase(file));
        addTearDown(upgraded.close);

        expect(await upgraded.readCursor('organization:org-1'), isNull);
        expect(
          await upgraded.readCursor(testProducerScopeKey),
          'cursor-producer',
        );
        expect(await upgraded.readPendingMutations(), hasLength(1));
      },
    );

    for (final userVersion in [6, 42]) {
      test(
        'user_version $userVersion rebuilds the cache instead of throwing',
        () async {
          final legacy = await openLegacy(userVersion);

          expect(await legacy.readAllScopeCursors(), isEmpty);
          await legacy.writeCursor(testProducerScopeKey, 'cursor-1');
          expect(await legacy.readCursor(testProducerScopeKey), 'cursor-1');

          final names = await tableNames(legacy);
          expect(names, isNot(contains('legacy_table')));
          expect(
            names.toSet(),
            legacy.allTables.map((table) => table.actualTableName).toSet(),
          );
          final version = await legacy
              .customSelect('PRAGMA user_version')
              .getSingle();
          expect(version.read<int>('user_version'), legacy.schemaVersion);
        },
      );
    }
  });
}
