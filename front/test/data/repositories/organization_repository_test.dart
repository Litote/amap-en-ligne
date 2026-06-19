import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/notification_copy_override.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _testOrgId = 'org-1';
const _producerAccountId = 'pa-1';

Organization _buildOrg({
  List<OrganizationProducer> producers = const [],
  List<OrgProduct> products = const [],
}) => Organization(
  organizationId: _testOrgId,
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  producers: producers,
  products: products,
);

/// Builds an [Organization] with a single delivery containing one contract
/// with two slots: one STANDARD and one EARLY, both initially empty.
Organization _buildOrgWithSlots() {
  const standardSlot = MemberSlot(
    startTime: '2025-06-14T18:00:00',
    endTime: '2025-06-14T20:00:00',
    activityType: ActivityType.preparation,
    requiredVolunteers: 2,
    currentRegistrations: 0,
    status: SlotStatus.open,
    slotKind: SlotKind.standard,
  );
  const earlySlot = MemberSlot(
    startTime: '2025-06-14T17:00:00',
    endTime: '2025-06-14T18:00:00',
    activityType: ActivityType.reception,
    requiredVolunteers: 1,
    currentRegistrations: 0,
    status: SlotStatus.open,
    slotKind: SlotKind.early,
  );
  const contract = DeliveryContract(
    contractId: 'c-1',
    coordinators: ['coord-1'],
    basketQuantity: 5,
    deliveryDescription: 'Panier légumes',
    status: DeliveryContractStatus.pending,
    slots: [standardSlot, earlySlot],
  );
  const delivery = Delivery(
    deliveryId: 'd-1',
    organizationId: _testOrgId,
    scheduledDate: '2025-06-14T18:00:00',
    status: DeliveryStatus.confirmed,
    minVolunteersRequired: 2,
    contracts: [contract],
  );
  return _buildOrg().copyWith(deliveries: [delivery]);
}

const _testMember = Member(
  memberId: 'member-42',
  organizationId: _testOrgId,
  firstName: 'Alice',
  lastName: 'Martin',
  email: 'alice@example.fr',
);

void main() {
  late AppDatabase db;
  late OrganizationRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = OrganizationRepository(db: db, idGenerator: IdGenerator(Random(0)));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'updateNotificationOverrides stores overrides and drops blank entries',
    () async {
      final baseOrg = _buildOrg();
      await db.upsertOrganization(baseOrg);

      await repo.updateNotificationOverrides(
        currentOrg: baseOrg,
        overrides: const {
          NotificationCategory.slotCancelled: NotificationCopyOverride(
            title: 'Annulé',
            body: 'Le créneau est annulé.',
          ),
          // Blank entry must be dropped.
          NotificationCategory.slotRescheduled: NotificationCopyOverride(
            title: '   ',
            body: '',
          ),
        },
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      expect(stored!.notificationOverrides.keys, [
        NotificationCategory.slotCancelled,
      ]);
      expect(
        stored.notificationOverrides[NotificationCategory.slotCancelled]!.title,
        'Annulé',
      );

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      final upsert = pending.single.op as Upsert;
      final payload = upsert.payload as OrganizationPayload;
      expect(
        payload.organization.notificationOverrides.containsKey(
          NotificationCategory.slotRescheduled,
        ),
        isFalse,
      );
    },
  );

  test(
    'enrollProducer writes updated org and enqueues an Upsert mutation',
    () async {
      final baseOrg = _buildOrg();
      await db.upsertOrganization(baseOrg);

      await repo.enrollProducer(
        currentOrg: baseOrg,
        producerAccountId: _producerAccountId,
        products: const [
          OrgProduct(
            name: 'Vegetables',
            productTypeId: 'pt-1',
            producerAccountId: _producerAccountId,
          ),
        ],
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      expect(stored, isNotNull);
      expect(stored!.producers.length, 1);
      expect(stored.producers.first.producerAccountId, _producerAccountId);
      expect(stored.producers.first.status, OrganizationProducerStatus.active);
      expect(stored.products.length, 1);
      expect(stored.products.first.name, 'Vegetables');

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      expect(upsert.payload, isA<OrganizationPayload>());
      final org = (upsert.payload as OrganizationPayload).organization;
      expect(org.producers.length, 1);
      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, organizationScopeKey(_testOrgId));
    },
  );

  test(
    'updateProducerStatus updates producer status and enqueues Upsert mutation',
    () async {
      final baseOrg = _buildOrg(
        producers: const [
          OrganizationProducer(
            producerAccountId: _producerAccountId,
            associationInstant: '1970-01-01T00:00:01Z',
            status: OrganizationProducerStatus.active,
          ),
        ],
      );
      await db.upsertOrganization(baseOrg);

      await repo.updateProducerStatus(
        currentOrg: baseOrg,
        producerAccountId: _producerAccountId,
        newStatus: OrganizationProducerStatus.suspended,
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      expect(
        stored!.producers.first.status,
        OrganizationProducerStatus.suspended,
      );

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      expect(pending.single.op, isA<Upsert>());
    },
  );

  test(
    'updateProducerProducts replaces producer products and enqueues Upsert mutation',
    () async {
      final baseOrg = _buildOrg(
        producers: const [
          OrganizationProducer(
            producerAccountId: _producerAccountId,
            associationInstant: '1970-01-01T00:00:01Z',
            status: OrganizationProducerStatus.active,
          ),
        ],
        products: const [
          OrgProduct(
            name: 'Old product',
            productTypeId: 'pt-old',
            producerAccountId: _producerAccountId,
          ),
        ],
      );
      await db.upsertOrganization(baseOrg);

      await repo.updateProducerProducts(
        currentOrg: baseOrg,
        producerAccountId: _producerAccountId,
        products: const [
          OrgProduct(
            name: 'New product',
            productTypeId: 'pt-new',
            producerAccountId: _producerAccountId,
          ),
        ],
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      expect(stored!.products.length, 1);
      expect(stored.products.first.name, 'New product');
      expect(
        stored.products.where((p) => p.productTypeId == 'pt-old').isEmpty,
        isTrue,
      );

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
    },
  );

  test(
    'updateDefaultDeliveryTemplateId updates the org and enqueues Upsert mutation',
    () async {
      final baseOrg = _buildOrg();
      await db.upsertOrganization(baseOrg);

      await repo.updateDefaultDeliveryTemplateId(
        currentOrg: baseOrg,
        defaultDeliveryTemplateId: 'dt-1',
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      expect(stored, isNotNull);
      expect(stored!.defaultDeliveryTemplateId, 'dt-1');

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      final org = (upsert.payload as OrganizationPayload).organization;
      expect(org.defaultDeliveryTemplateId, 'dt-1');
    },
  );

  test(
    'createNoAccountProducer writes producer and org updates in organization scope',
    () async {
      final baseOrg = _buildOrg();
      await db.upsertOrganization(baseOrg);

      final created = await repo.createNoAccountProducer(
        currentOrg: baseOrg,
        name: 'Ferme locale',
        contactEmail: 'contact@locale.fr',
        products: const [
          ProducerProduct(name: 'Tomates', productTypeId: 'tmp_pt-1'),
        ],
      );

      expect(created.producerAccountId, startsWith('tmp_'));
      expect(created.managementMode, ProducerManagementMode.noAccount);
      final storedProducer = await db
          .watchProducerAccountById(created.producerAccountId)
          .first;
      expect(storedProducer, isNotNull);
      expect(storedProducer!.products.single.name, 'Tomates');

      // The local org cache is updated optimistically with full products for
      // responsive UI, even though the network mutation excludes them.
      final storedOrg = await db.watchOrganization(_testOrgId).first;
      expect(
        storedOrg!.producers.single.producerAccountId,
        created.producerAccountId,
      );
      expect(
        storedOrg.products.single.producerAccountId,
        created.producerAccountId,
      );

      final entries = await db.readPendingMutationEntries();
      expect(entries, hasLength(2));
      expect(
        entries.every(
          (entry) => entry.scopeKey == organizationScopeKey(_testOrgId),
        ),
        isTrue,
      );
      expect(entries.first.mutation.op, isA<Upsert>());
      expect(entries.last.mutation.op, isA<Upsert>());

      // The OrganizationPayload mutation must carry only the updated producers
      // list — NOT the new NO_ACCOUNT products (those are in ProducerAccountPayload).
      final orgEntry = entries.last;
      final orgUpsert = orgEntry.mutation.op as Upsert;
      final orgPayload = orgUpsert.payload as OrganizationPayload;
      expect(
        orgPayload.organization.producers.single.producerAccountId,
        created.producerAccountId,
      );
      expect(orgPayload.organization.products, isEmpty);
    },
  );

  // Regression guard: the back-end rejects sync with MissingFieldException
  // when ProducerAccount.created_instant / last_updated_instant are absent.
  // This test pins that createNoAccountProducer always stamps both fields.
  test('createNoAccountProducer stamps created_instant and last_updated_instant '
      'on the enqueued ProducerAccountPayload', () async {
    final baseOrg = _buildOrg();
    await db.upsertOrganization(baseOrg);

    final created = await repo.createNoAccountProducer(
      currentOrg: baseOrg,
      name: 'Ferme sans compte',
      products: const [
        ProducerProduct(name: 'Légumes', productTypeId: 'pt-veg'),
      ],
    );

    // The returned domain object must carry both instant fields.
    expect(created.createdInstant, isNotNull);
    expect(created.lastUpdatedInstant, isNotNull);

    // The enqueued ProducerAccountPayload must also carry both fields so the
    // back-end sync endpoint never receives null for required instant columns.
    final entries = await db.readPendingMutationEntries();
    final producerEntry = entries.first; // ProducerAccountPayload is first
    final upsert = producerEntry.mutation.op as Upsert;
    final payload = upsert.payload as ProducerAccountPayload;
    expect(payload.producerAccount.createdInstant, isNotNull);
    expect(payload.producerAccount.lastUpdatedInstant, isNotNull);

    // Both instants must be ISO-8601 UTC strings (non-empty).
    expect(payload.producerAccount.createdInstant, isNotEmpty);
    expect(payload.producerAccount.lastUpdatedInstant, isNotEmpty);
  });

  test(
    'updateNoAccountProducerProducts updates producer cache and org cache, enqueues only PA mutation',
    () async {
      const producer = ProducerAccount(
        producerAccountId: 'tmp_pa-1',
        name: 'Ferme locale',
        managementMode: ProducerManagementMode.noAccount,
        products: [ProducerProduct(name: 'Ancien', productTypeId: 'pt-old')],
      );
      final baseOrg = _buildOrg(
        producers: const [
          OrganizationProducer(
            producerAccountId: 'tmp_pa-1',
            associationInstant: '1970-01-01T00:00:01Z',
            status: OrganizationProducerStatus.active,
          ),
        ],
        products: const [
          OrgProduct(
            name: 'Ancien',
            productTypeId: 'pt-old',
            producerAccountId: 'tmp_pa-1',
          ),
        ],
      );
      await db.upsertOrganization(baseOrg);
      await db.upsertProducerAccount(producer.producerAccountId, producer);

      await repo.updateNoAccountProducerProducts(
        currentOrg: baseOrg,
        producerAccount: producer,
        products: const [
          ProducerProduct(name: 'Nouveau', productTypeId: 'pt-new'),
        ],
      );

      // Both local caches are updated for responsive UI.
      final storedProducer = await db
          .watchProducerAccountById('tmp_pa-1')
          .first;
      expect(storedProducer!.products.single.name, 'Nouveau');
      final storedOrg = await db.watchOrganization(_testOrgId).first;
      expect(storedOrg!.products.single.name, 'Nouveau');
      expect(storedOrg.products.single.producerAccountId, 'tmp_pa-1');

      // Only one mutation is enqueued: ProducerAccountPayload (no OrganizationPayload).
      // PA.products is the single source of truth for NO_ACCOUNT products.
      final entries = await db.readPendingMutationEntries();
      expect(entries, hasLength(1));
      final upsert = entries.single.mutation.op as Upsert;
      expect(upsert.payload, isA<ProducerAccountPayload>());
      final paPayload = upsert.payload as ProducerAccountPayload;
      expect(paPayload.producerAccount.products.single.name, 'Nouveau');
    },
  );

  test(
    'linkNoAccountProducer migrates org references to the linked producer',
    () async {
      const noAccountProducer = ProducerAccount(
        producerAccountId: 'tmp_pa-1',
        name: 'Ferme locale',
        managementMode: ProducerManagementMode.noAccount,
        products: [ProducerProduct(name: 'Tomates', productTypeId: 'pt-1')],
      );
      const linkedProducer = ProducerAccount(
        producerAccountId: 'pa-2',
        name: 'Ferme avec compte',
      );
      final baseOrg = _buildOrg(
        producers: const [
          OrganizationProducer(
            producerAccountId: 'tmp_pa-1',
            associationInstant: '1970-01-01T00:00:01Z',
            status: OrganizationProducerStatus.active,
          ),
        ],
        products: const [
          OrgProduct(
            name: 'Tomates',
            productTypeId: 'pt-1',
            producerAccountId: 'tmp_pa-1',
          ),
        ],
      );
      await db.upsertOrganization(baseOrg);
      await db.upsertProducerAccount(
        noAccountProducer.producerAccountId,
        noAccountProducer,
      );

      await repo.linkNoAccountProducer(
        currentOrg: baseOrg,
        noAccountProducer: noAccountProducer,
        linkedProducer: linkedProducer,
      );

      final storedProducer = await db
          .watchProducerAccountById('tmp_pa-1')
          .first;
      expect(
        storedProducer!.linkedProducerAccount?.producerAccountId,
        linkedProducer.producerAccountId,
      );
      final storedOrg = await db.watchOrganization(_testOrgId).first;
      expect(storedOrg!.producers.single.producerAccountId, 'pa-2');
      expect(storedOrg.products.single.producerAccountId, 'pa-2');
    },
  );

  test(
    'updateRegistrationStatus updates nested registration status and enqueues Upsert',
    () async {
      const deliveryId = 'd-1';
      const contractId = 'c-1';
      const memberId = 'member-1';

      final registration = const MemberRegistration(
        memberId: memberId,
        displayName: 'Jean Dupont',
        memberEmail: 'jean@example.fr',
        registrationInstant: '2026-01-15T18:00:00Z',
        status: RegistrationStatus.registered,
      );
      final slot = MemberSlot(
        startTime: '2025-06-14T18:00:00',
        endTime: '2025-06-14T20:00:00',
        activityType: ActivityType.preparation,
        requiredVolunteers: 1,
        currentRegistrations: 1,
        status: SlotStatus.open,
        registrations: [registration],
      );
      final contract = DeliveryContract(
        contractId: contractId,
        coordinators: const ['coord-1'],
        basketQuantity: 5,
        deliveryDescription: 'Panier légumes',
        status: DeliveryContractStatus.pending,
        slots: [slot],
      );
      final delivery = Delivery(
        deliveryId: deliveryId,
        organizationId: _testOrgId,
        scheduledDate: '2025-06-14T18:00:00',
        status: DeliveryStatus.inProgress,
        minVolunteersRequired: 1,
        contracts: [contract],
      );
      final baseOrg = _buildOrg().copyWith(deliveries: [delivery]);
      await db.upsertOrganization(baseOrg);

      await repo.updateRegistrationStatus(
        currentOrg: baseOrg,
        deliveryId: deliveryId,
        contractId: contractId,
        memberId: memberId,
        newStatus: RegistrationStatus.confirmed,
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      expect(stored, isNotNull);
      final storedReg = stored!
          .deliveries
          .single
          .contracts
          .single
          .slots
          .single
          .registrations
          .single;
      expect(storedReg.status, RegistrationStatus.confirmed);

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      expect(upsert.payload, isA<OrganizationPayload>());
      final org = (upsert.payload as OrganizationPayload).organization;
      expect(
        org
            .deliveries
            .single
            .contracts
            .single
            .slots
            .single
            .registrations
            .single
            .status,
        RegistrationStatus.confirmed,
      );
    },
  );

  test(
    'updateDeliveryContractStatus updates contract status and enqueues Upsert',
    () async {
      const deliveryId = 'd-1';
      const contractId = 'c-1';

      final contract = DeliveryContract(
        contractId: contractId,
        coordinators: const ['coord-1'],
        basketQuantity: 5,
        deliveryDescription: 'Panier légumes',
        status: DeliveryContractStatus.pending,
      );
      final delivery = Delivery(
        deliveryId: deliveryId,
        organizationId: _testOrgId,
        scheduledDate: '2025-06-14T18:00:00',
        status: DeliveryStatus.inProgress,
        minVolunteersRequired: 1,
        contracts: [contract],
      );
      final baseOrg = _buildOrg().copyWith(deliveries: [delivery]);
      await db.upsertOrganization(baseOrg);

      await repo.updateDeliveryContractStatus(
        currentOrg: baseOrg,
        deliveryId: deliveryId,
        contractId: contractId,
        newStatus: DeliveryContractStatus.distributed,
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      expect(stored, isNotNull);
      expect(
        stored!.deliveries.single.contracts.single.status,
        DeliveryContractStatus.distributed,
      );

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      expect(upsert.payload, isA<OrganizationPayload>());
      final org = (upsert.payload as OrganizationPayload).organization;
      expect(
        org.deliveries.single.contracts.single.status,
        DeliveryContractStatus.distributed,
      );
    },
  );

  test('watch is reactive to upserts', () async {
    final stream = repo.watch(_testOrgId);
    final emitted = <Organization?>[];
    final sub = stream.listen(emitted.add);

    final org = _buildOrg();
    await db.upsertOrganization(org);

    // Wait for stream to settle.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(emitted.last, isNotNull);
    expect(emitted.last!.organizationId, _testOrgId);
  });

  test('addDelivery appends delivery and enqueues Upsert mutation', () async {
    final baseOrg = _buildOrg();
    await db.upsertOrganization(baseOrg);

    const delivery = Delivery(
      deliveryId: 'd-1',
      organizationId: _testOrgId,
      scheduledDate: '2025-06-14T09:00:00',
      status: DeliveryStatus.planned,
      minVolunteersRequired: 2,
    );

    await repo.addDelivery(currentOrg: baseOrg, delivery: delivery);

    final stored = await db.watchOrganization(_testOrgId).first;
    expect(stored, isNotNull);
    expect(stored!.deliveries.length, 1);
    expect(stored.deliveries.first.deliveryId, 'd-1');

    final pending = await db.readPendingMutations();
    expect(pending.length, 1);
    expect(pending.single.op, isA<Upsert>());
    final upsert = pending.single.op as Upsert;
    expect(upsert.payload, isA<OrganizationPayload>());
    final org = (upsert.payload as OrganizationPayload).organization;
    expect(org.deliveries.single.deliveryId, 'd-1');
  });

  test('updateDelivery replaces delivery by id and enqueues Upsert', () async {
    const delivery = Delivery(
      deliveryId: 'd-1',
      organizationId: _testOrgId,
      scheduledDate: '2025-06-14T09:00:00',
      status: DeliveryStatus.planned,
      minVolunteersRequired: 2,
    );
    final baseOrg = _buildOrg().copyWith(deliveries: [delivery]);
    await db.upsertOrganization(baseOrg);

    const updated = Delivery(
      deliveryId: 'd-1',
      organizationId: _testOrgId,
      scheduledDate: '2025-07-01T10:00:00',
      status: DeliveryStatus.confirmed,
      minVolunteersRequired: 3,
    );

    await repo.updateDelivery(currentOrg: baseOrg, delivery: updated);

    final stored = await db.watchOrganization(_testOrgId).first;
    expect(stored, isNotNull);
    expect(stored!.deliveries.single.scheduledDate, '2025-07-01T10:00:00');
    expect(stored.deliveries.single.status, DeliveryStatus.confirmed);

    final pending = await db.readPendingMutations();
    expect(pending.length, 1);
    expect(pending.single.op, isA<Upsert>());
  });

  test('deleteDelivery removes delivery by id and enqueues Upsert', () async {
    const delivery = Delivery(
      deliveryId: 'd-1',
      organizationId: _testOrgId,
      scheduledDate: '2025-06-14T09:00:00',
      status: DeliveryStatus.planned,
      minVolunteersRequired: 2,
    );
    final baseOrg = _buildOrg().copyWith(deliveries: [delivery]);
    await db.upsertOrganization(baseOrg);

    await repo.deleteDelivery(currentOrg: baseOrg, deliveryId: 'd-1');

    final stored = await db.watchOrganization(_testOrgId).first;
    expect(stored, isNotNull);
    expect(stored!.deliveries, isEmpty);

    final pending = await db.readPendingMutations();
    expect(pending.length, 1);
    expect(pending.single.op, isA<Upsert>());
  });

  // ─── registerToSlot / unregisterFromSlot ────────────────────────────────────

  test(
    'registerToSlot on STANDARD slot adds registration and enqueues Upsert',
    () async {
      final baseOrg = _buildOrgWithSlots();
      await db.upsertOrganization(baseOrg);

      await repo.registerToSlot(
        currentOrg: baseOrg,
        deliveryId: 'd-1',
        contractId: 'c-1',
        slotKind: SlotKind.standard,
        me: _testMember,
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      final standardSlot = stored!.deliveries.single.contracts.single.slots
          .firstWhere((s) => s.slotKind == SlotKind.standard);
      expect(standardSlot.registrations, hasLength(1));
      expect(standardSlot.registrations.single.memberId, 'member-42');
      expect(standardSlot.registrations.single.displayName, 'Alice Martin');
      expect(
        standardSlot.registrations.single.status,
        RegistrationStatus.registered,
      );

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      expect(upsert.payload, isA<OrganizationPayload>());
      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, organizationScopeKey(_testOrgId));
    },
  );

  test(
    'registerToSlot increments currentRegistrations on the target slot',
    () async {
      final baseOrg = _buildOrgWithSlots();
      await db.upsertOrganization(baseOrg);

      await repo.registerToSlot(
        currentOrg: baseOrg,
        deliveryId: 'd-1',
        contractId: 'c-1',
        slotKind: SlotKind.standard,
        me: _testMember,
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      final standardSlot = stored!.deliveries.single.contracts.single.slots
          .firstWhere((s) => s.slotKind == SlotKind.standard);
      expect(standardSlot.currentRegistrations, 1);
    },
  );

  test(
    'registerToSlot on EARLY slot adds registration to the EARLY slot only',
    () async {
      final baseOrg = _buildOrgWithSlots();
      await db.upsertOrganization(baseOrg);

      await repo.registerToSlot(
        currentOrg: baseOrg,
        deliveryId: 'd-1',
        contractId: 'c-1',
        slotKind: SlotKind.early,
        me: _testMember,
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      final slots = stored!.deliveries.single.contracts.single.slots;
      final earlySlot = slots.firstWhere((s) => s.slotKind == SlotKind.early);
      final standardSlot = slots.firstWhere(
        (s) => s.slotKind == SlotKind.standard,
      );

      expect(earlySlot.registrations, hasLength(1));
      expect(earlySlot.registrations.single.memberId, 'member-42');
      // STANDARD slot must be untouched.
      expect(standardSlot.registrations, isEmpty);

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
    },
  );

  test('registerToSlot is a no-op when member is already registered', () async {
    const registration = MemberRegistration(
      memberId: 'member-42',
      displayName: 'Alice Martin',
      memberEmail: 'alice@example.fr',
      registrationInstant: '2026-01-15T18:00:00Z',
      status: RegistrationStatus.registered,
    );
    final baseOrg = _buildOrg().copyWith(
      deliveries: [
        const Delivery(
          deliveryId: 'd-1',
          organizationId: _testOrgId,
          scheduledDate: '2025-06-14T18:00:00',
          status: DeliveryStatus.confirmed,
          minVolunteersRequired: 2,
          contracts: [
            DeliveryContract(
              contractId: 'c-1',
              coordinators: ['coord-1'],
              basketQuantity: 5,
              deliveryDescription: 'Panier légumes',
              status: DeliveryContractStatus.pending,
              slots: [
                MemberSlot(
                  startTime: '2025-06-14T18:00:00',
                  endTime: '2025-06-14T20:00:00',
                  activityType: ActivityType.preparation,
                  requiredVolunteers: 2,
                  currentRegistrations: 1,
                  status: SlotStatus.open,
                  slotKind: SlotKind.standard,
                  registrations: [registration],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await db.upsertOrganization(baseOrg);

    await repo.registerToSlot(
      currentOrg: baseOrg,
      deliveryId: 'd-1',
      contractId: 'c-1',
      slotKind: SlotKind.standard,
      me: _testMember,
    );

    // Nothing enqueued (idempotent).
    final pending = await db.readPendingMutations();
    expect(pending, isEmpty);
  });

  test(
    'unregisterFromSlot removes the member registration and enqueues Upsert',
    () async {
      const registration = MemberRegistration(
        memberId: 'member-42',
        displayName: 'Alice Martin',
        memberEmail: 'alice@example.fr',
        registrationInstant: '2026-01-15T18:00:00Z',
        status: RegistrationStatus.registered,
      );
      final baseOrg = _buildOrg().copyWith(
        deliveries: [
          const Delivery(
            deliveryId: 'd-1',
            organizationId: _testOrgId,
            scheduledDate: '2025-06-14T18:00:00',
            status: DeliveryStatus.confirmed,
            minVolunteersRequired: 2,
            contracts: [
              DeliveryContract(
                contractId: 'c-1',
                coordinators: ['coord-1'],
                basketQuantity: 5,
                deliveryDescription: 'Panier légumes',
                status: DeliveryContractStatus.pending,
                slots: [
                  MemberSlot(
                    startTime: '2025-06-14T18:00:00',
                    endTime: '2025-06-14T20:00:00',
                    activityType: ActivityType.preparation,
                    requiredVolunteers: 2,
                    currentRegistrations: 1,
                    status: SlotStatus.open,
                    slotKind: SlotKind.standard,
                    registrations: [registration],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await db.upsertOrganization(baseOrg);

      await repo.unregisterFromSlot(
        currentOrg: baseOrg,
        deliveryId: 'd-1',
        contractId: 'c-1',
        slotKind: SlotKind.standard,
        memberId: 'member-42',
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      final slot = stored!.deliveries.single.contracts.single.slots.single;
      expect(slot.registrations, isEmpty);

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      expect(pending.single.op, isA<Upsert>());
      final upsert = pending.single.op as Upsert;
      expect(upsert.payload, isA<OrganizationPayload>());
    },
  );

  test(
    'unregisterFromSlot decrements currentRegistrations on the target slot',
    () async {
      const registration = MemberRegistration(
        memberId: 'member-42',
        displayName: 'Alice Martin',
        memberEmail: 'alice@example.fr',
        registrationInstant: '2026-01-15T18:00:00Z',
        status: RegistrationStatus.registered,
      );
      final baseOrg = _buildOrg().copyWith(
        deliveries: [
          const Delivery(
            deliveryId: 'd-1',
            organizationId: _testOrgId,
            scheduledDate: '2025-06-14T18:00:00',
            status: DeliveryStatus.confirmed,
            minVolunteersRequired: 2,
            contracts: [
              DeliveryContract(
                contractId: 'c-1',
                coordinators: ['coord-1'],
                basketQuantity: 5,
                deliveryDescription: 'Panier légumes',
                status: DeliveryContractStatus.pending,
                slots: [
                  MemberSlot(
                    startTime: '2025-06-14T18:00:00',
                    endTime: '2025-06-14T20:00:00',
                    activityType: ActivityType.preparation,
                    requiredVolunteers: 2,
                    currentRegistrations: 1,
                    status: SlotStatus.open,
                    slotKind: SlotKind.standard,
                    registrations: [registration],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await db.upsertOrganization(baseOrg);

      await repo.unregisterFromSlot(
        currentOrg: baseOrg,
        deliveryId: 'd-1',
        contractId: 'c-1',
        slotKind: SlotKind.standard,
        memberId: 'member-42',
      );

      final stored = await db.watchOrganization(_testOrgId).first;
      final slot = stored!.deliveries.single.contracts.single.slots.single;
      expect(slot.currentRegistrations, 0);
    },
  );

  test(
    'unregisterFromSlot is a no-op when member has no registration',
    () async {
      final baseOrg = _buildOrgWithSlots();
      await db.upsertOrganization(baseOrg);

      await repo.unregisterFromSlot(
        currentOrg: baseOrg,
        deliveryId: 'd-1',
        contractId: 'c-1',
        slotKind: SlotKind.standard,
        memberId: 'member-99',
      );

      // Nothing enqueued (idempotent).
      final pending = await db.readPendingMutations();
      expect(pending, isEmpty);
    },
  );

  // ─── Coordinator assignment ──────────────────────────────────────────────────

  group('Coordinator assignment', () {
    /// Builds an org with one CONFIRMED delivery containing one contract with
    /// the given [coordinators].
    Organization buildOrgForCoordinator({
      List<String> coordinators = const [],
    }) {
      final contract = DeliveryContract(
        contractId: 'c-1',
        coordinators: coordinators,
        basketQuantity: 5,
        deliveryDescription: 'Panier légumes',
        status: DeliveryContractStatus.pending,
      );
      final delivery = Delivery(
        deliveryId: 'd-1',
        organizationId: _testOrgId,
        scheduledDate: '2025-06-14T18:00:00',
        status: DeliveryStatus.confirmed,
        minVolunteersRequired: 2,
        contracts: [contract],
      );
      return _buildOrg().copyWith(deliveries: [delivery]);
    }

    test(
      'assignCoordinator adds the memberId to the contract and enqueues Upsert',
      () async {
        final baseOrg = buildOrgForCoordinator();
        await db.upsertOrganization(baseOrg);

        await repo.assignCoordinator(
          currentOrg: baseOrg,
          deliveryId: 'd-1',
          contractId: 'c-1',
          memberId: 'coord-1',
        );

        final stored = await db.watchOrganization(_testOrgId).first;
        final contract = stored!.deliveries.single.contracts.single;
        expect(contract.coordinators, contains('coord-1'));

        final pending = await db.readPendingMutations();
        expect(pending.length, 1);
        expect(pending.single.op, isA<Upsert>());
        final upsert = pending.single.op as Upsert;
        expect(upsert.payload, isA<OrganizationPayload>());
        final entries = await db.readPendingMutationEntries();
        expect(entries.single.scopeKey, organizationScopeKey(_testOrgId));
      },
    );

    test(
      'assignCoordinator is a no-op when the member is already a coordinator',
      () async {
        final baseOrg = buildOrgForCoordinator(coordinators: const ['coord-1']);
        await db.upsertOrganization(baseOrg);

        await repo.assignCoordinator(
          currentOrg: baseOrg,
          deliveryId: 'd-1',
          contractId: 'c-1',
          memberId: 'coord-1',
        );

        final pending = await db.readPendingMutations();
        expect(pending, isEmpty);
      },
    );

    test(
      'unassignCoordinator removes the memberId from the contract and enqueues Upsert',
      () async {
        final baseOrg = buildOrgForCoordinator(
          coordinators: const ['coord-1', 'coord-2'],
        );
        await db.upsertOrganization(baseOrg);

        await repo.unassignCoordinator(
          currentOrg: baseOrg,
          deliveryId: 'd-1',
          contractId: 'c-1',
          memberId: 'coord-1',
        );

        final stored = await db.watchOrganization(_testOrgId).first;
        final contract = stored!.deliveries.single.contracts.single;
        expect(contract.coordinators, isNot(contains('coord-1')));
        expect(contract.coordinators, contains('coord-2'));

        final pending = await db.readPendingMutations();
        expect(pending.length, 1);
        expect(pending.single.op, isA<Upsert>());
      },
    );

    test(
      'unassignCoordinator is a no-op when the member is not a coordinator',
      () async {
        final baseOrg = buildOrgForCoordinator(coordinators: const ['coord-2']);
        await db.upsertOrganization(baseOrg);

        await repo.unassignCoordinator(
          currentOrg: baseOrg,
          deliveryId: 'd-1',
          contractId: 'c-1',
          memberId: 'coord-1',
        );

        final pending = await db.readPendingMutations();
        expect(pending, isEmpty);
      },
    );

    test(
      'assignCoordinator is a no-op when the (deliveryId, contractId) does not exist',
      () async {
        final baseOrg = buildOrgForCoordinator();
        await db.upsertOrganization(baseOrg);

        await repo.assignCoordinator(
          currentOrg: baseOrg,
          deliveryId: 'nonexistent-delivery',
          contractId: 'c-1',
          memberId: 'coord-1',
        );

        final pending = await db.readPendingMutations();
        expect(pending, isEmpty);
      },
    );

    test(
      'assignCoordinatorById fetches fresh org and adds the memberId',
      () async {
        final baseOrg = buildOrgForCoordinator();
        await db.upsertOrganization(baseOrg);

        await repo.assignCoordinatorById(
          organizationId: _testOrgId,
          deliveryId: 'd-1',
          contractId: 'c-1',
          memberId: 'coord-1',
        );

        final stored = await db.watchOrganization(_testOrgId).first;
        final contract = stored!.deliveries.single.contracts.single;
        expect(contract.coordinators, contains('coord-1'));

        final pending = await db.readPendingMutations();
        expect(pending.length, 1);
        expect(pending.single.op, isA<Upsert>());
      },
    );

    test(
      'unassignCoordinatorById fetches fresh org and removes the memberId',
      () async {
        final baseOrg = buildOrgForCoordinator(
          coordinators: const ['coord-1', 'coord-2'],
        );
        await db.upsertOrganization(baseOrg);

        await repo.unassignCoordinatorById(
          organizationId: _testOrgId,
          deliveryId: 'd-1',
          contractId: 'c-1',
          memberId: 'coord-1',
        );

        final stored = await db.watchOrganization(_testOrgId).first;
        final contract = stored!.deliveries.single.contracts.single;
        expect(contract.coordinators, isNot(contains('coord-1')));
        expect(contract.coordinators, contains('coord-2'));

        final pending = await db.readPendingMutations();
        expect(pending.length, 1);
        expect(pending.single.op, isA<Upsert>());
      },
    );
  });
}
