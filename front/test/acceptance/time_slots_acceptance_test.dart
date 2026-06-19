@Tags(['acceptance'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const orgId = 'org-1';
  const orgScope = 'organization:org-1';
  const deliveryId = 'delivery-1';
  const contractId = 'contract-1';
  const slotId = 'slot-1';

  final cancelStory = _loadStory('time-slot-cancel');
  final deleteConflictStory = _loadStory('time-slot-delete-conflict');
  final rescheduleStory = _loadStory('time-slot-reschedule');

  late AppDatabase db;
  late _ScriptedSyncApi api;

  const regAlice = MemberRegistration(
    memberId: 'member-1',
    displayName: 'Alice Volunteer',
    memberEmail: 'member-1@example.com',
    registrationInstant: '2099-06-01T10:00:00Z',
    status: RegistrationStatus.registered,
  );
  const regBob = MemberRegistration(
    memberId: 'member-2',
    displayName: 'Bob Volunteer',
    memberEmail: 'member-2@example.com',
    registrationInstant: '2099-06-01T11:00:00Z',
    status: RegistrationStatus.registered,
  );

  /// Builds the base Organization with one future PLANNED delivery + one
  /// STANDARD slot (`slot-1`) carrying the given [slot] state.
  Organization buildOrg({required MemberSlot slot}) {
    return Organization(
      organizationId: orgId,
      name: 'AMAP des Collines',
      contactEmail: 'contact@amap.example.com',
      activeStatus: true,
      timezone: 'Europe/Paris',
      defaultLanguage: 'fr',
      createdInstant: '2025-01-01T00:00:00Z',
      lastUpdatedInstant: '2025-01-01T00:00:00Z',
      deliveries: [
        Delivery(
          deliveryId: deliveryId,
          organizationId: orgId,
          scheduledDate: '2099-06-15T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 2,
          contracts: [
            DeliveryContract(
              contractId: contractId,
              coordinators: const ['coordinator-1'],
              basketQuantity: 10,
              deliveryDescription: 'Weekly basket',
              status: DeliveryContractStatus.pending,
              slots: [slot],
            ),
          ],
        ),
      ],
    );
  }

  MemberSlot buildOpenSlot({
    List<MemberRegistration> registrations = const [regAlice, regBob],
    String startTime = '2099-06-15T18:00:00',
    String endTime = '2099-06-15T20:00:00',
  }) => MemberSlot(
    slotId: slotId,
    startTime: startTime,
    endTime: endTime,
    activityType: ActivityType.reception,
    requiredVolunteers: 2,
    currentRegistrations: registrations.length,
    status: SlotStatus.open,
    slotKind: SlotKind.standard,
    registrations: registrations,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  // --------------------------------------------------------------------------
  // Scenario 1 — time-slot-cancel
  // --------------------------------------------------------------------------
  test('${cancelStory.title} [${cancelStory.id}]', () async {
    final idGen = _SequenceIdGenerator(['op-cancel-slot']);
    final orgRepo = OrganizationRepository(db: db, idGenerator: idGen);

    final initialOrg = buildOrg(slot: buildOpenSlot());
    await db.upsertOrganization(initialOrg);
    await db.writeCursor(orgScope, 'c0');

    // Act: the coordinator cancels the slot with the optimistic local cascade
    // (mirrors TimeSlotsBloc.slotCancelRequested).
    final cancelledLocally = buildOpenSlot().copyWith(
      status: SlotStatus.cancelled,
      currentRegistrations: 0,
      registrations: [
        regAlice.copyWith(status: RegistrationStatus.cancelled),
        regBob.copyWith(status: RegistrationStatus.cancelled),
      ],
    );
    await orgRepo.updateDelivery(
      currentOrg: initialOrg,
      delivery: buildOrg(slot: cancelledLocally).deliveries.single,
    );

    // The local cache reflects the optimistic cascade immediately.
    final localOrg = await db.watchOrganization(orgId).first;
    final localSlot = _findSlot(localOrg!);
    expect(localSlot.status, SlotStatus.cancelled);
    expect(
      localSlot.registrations.every(
        (r) => r.status == RegistrationStatus.cancelled,
      ),
      isTrue,
    );

    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));

    // Server response: APPLIED + authoritative cascade reflected in the diff.
    final orgAfterSync = buildOrg(slot: cancelledLocally);
    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: cancelStory.id,
        request: SyncRequest(
          cursors: const {orgScope: 'c0'},
          mutations: pending,
        ),
        response: SyncResponse(
          authorizedScopes: const [orgScope],
          results: {
            orgScope: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.organization,
                  entityId: orgId,
                  op: ChangeOp.upsert,
                  payload: OrganizationPayload(organization: orgAfterSync),
                  producedAt: 1,
                ),
              ],
              nextCursor: 'c1',
            ),
          },
          mutations: const [
            MutationOutcome(
              clientOpId: 'op-cancel-slot',
              status: MutationStatus.applied,
              serverEntityId: orgId,
            ),
          ],
        ),
      ),
    ]);

    final syncRepo = SyncRepository(db: db, api: api);
    final outcome = await syncRepo.sync(tenantId: orgId);

    expect(outcome, isA<SyncSuccess>());
    final syncedOrg = await db.watchOrganization(orgId).first;
    final syncedSlot = _findSlot(syncedOrg!);
    expect(syncedSlot.status, SlotStatus.cancelled);
    expect(syncedSlot.currentRegistrations, 0);
    expect(
      syncedSlot.registrations.every(
        (r) => r.status == RegistrationStatus.cancelled,
      ),
      isTrue,
    );
    expect(await db.readPendingMutations(), isEmpty);
    expect(await db.readCursor(orgScope), 'c1');
  });

  // --------------------------------------------------------------------------
  // Scenario 2 — time-slot-delete-conflict
  // --------------------------------------------------------------------------
  test('${deleteConflictStory.title} [${deleteConflictStory.id}]', () async {
    // An offline race bypasses the local "no active registration" guard: the
    // slot deletion reaches the server while members are still registered.
    final idGen = _SequenceIdGenerator(['op-delete-slot']);
    final orgRepo = OrganizationRepository(db: db, idGenerator: idGen);

    final initialOrg = buildOrg(slot: buildOpenSlot());
    await db.upsertOrganization(initialOrg);
    await db.writeCursor(orgScope, 'c0');

    final deliveryWithoutSlot = initialOrg.deliveries.single.copyWith(
      contracts: [
        initialOrg.deliveries.single.contracts.single.copyWith(slots: const []),
      ],
    );
    await orgRepo.updateDelivery(
      currentOrg: initialOrg,
      delivery: deliveryWithoutSlot,
    );

    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));

    // Server rejects with CONFLICT and re-sends the authoritative org state.
    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: deleteConflictStory.id,
        request: SyncRequest(
          cursors: const {orgScope: 'c0'},
          mutations: pending,
        ),
        response: SyncResponse(
          authorizedScopes: const [orgScope],
          results: {
            orgScope: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.organization,
                  entityId: orgId,
                  op: ChangeOp.upsert,
                  payload: OrganizationPayload(organization: initialOrg),
                  producedAt: 2,
                ),
              ],
              nextCursor: 'c1',
            ),
          },
          mutations: const [
            MutationOutcome(
              clientOpId: 'op-delete-slot',
              status: MutationStatus.rejected,
              error: MutationError(
                code: MutationErrorCode.conflict,
                message: 'slot cannot be deleted: 2 active registration(s)',
              ),
            ),
          ],
        ),
      ),
    ]);

    final syncRepo = SyncRepository(db: db, api: api);
    final outcome = await syncRepo.sync(tenantId: orgId);

    expect(outcome, isA<SyncSuccess>());
    final syncSuccess = outcome as SyncSuccess;
    expect(syncSuccess.rejectedMutations, hasLength(1));
    expect(
      syncSuccess.rejectedMutations.first.error?.code,
      MutationErrorCode.conflict,
    );

    // The pending queue is drained and the authoritative state restored the
    // slot with its registrations.
    expect(await db.readPendingMutations(), isEmpty);
    final syncedOrg = await db.watchOrganization(orgId).first;
    final syncedSlot = _findSlot(syncedOrg!);
    expect(syncedSlot.status, SlotStatus.open);
    expect(syncedSlot.registrations, hasLength(2));
  });

  // --------------------------------------------------------------------------
  // Scenario 3 — time-slot-reschedule
  // --------------------------------------------------------------------------
  test('${rescheduleStory.title} [${rescheduleStory.id}]', () async {
    final idGen = _SequenceIdGenerator(['op-reschedule-slot']);
    final orgRepo = OrganizationRepository(db: db, idGenerator: idGen);

    final initialOrg = buildOrg(slot: buildOpenSlot());
    await db.upsertOrganization(initialOrg);
    await db.writeCursor(orgScope, 'c0');

    final rescheduledSlot = buildOpenSlot(
      startTime: '2099-06-15T19:00:00',
      endTime: '2099-06-15T21:00:00',
    );
    await orgRepo.updateDelivery(
      currentOrg: initialOrg,
      delivery: buildOrg(slot: rescheduledSlot).deliveries.single,
    );

    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));

    final orgAfterSync = buildOrg(slot: rescheduledSlot);
    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: rescheduleStory.id,
        request: SyncRequest(
          cursors: const {orgScope: 'c0'},
          mutations: pending,
        ),
        response: SyncResponse(
          authorizedScopes: const [orgScope],
          results: {
            orgScope: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.organization,
                  entityId: orgId,
                  op: ChangeOp.upsert,
                  payload: OrganizationPayload(organization: orgAfterSync),
                  producedAt: 3,
                ),
              ],
              nextCursor: 'c1',
            ),
          },
          mutations: const [
            MutationOutcome(
              clientOpId: 'op-reschedule-slot',
              status: MutationStatus.applied,
              serverEntityId: orgId,
            ),
          ],
        ),
      ),
    ]);

    final syncRepo = SyncRepository(db: db, api: api);
    final outcome = await syncRepo.sync(tenantId: orgId);

    expect(outcome, isA<SyncSuccess>());
    final syncedOrg = await db.watchOrganization(orgId).first;
    final syncedSlot = _findSlot(syncedOrg!);
    // Registrations are preserved through the reschedule.
    expect(syncedSlot.startTime, '2099-06-15T19:00:00');
    expect(syncedSlot.registrations, hasLength(2));
    expect(
      syncedSlot.registrations.every(
        (r) => r.status == RegistrationStatus.registered,
      ),
      isTrue,
    );
    expect(await db.readPendingMutations(), isEmpty);
    expect(await db.readCursor(orgScope), 'c1');
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MemberSlot _findSlot(Organization org) {
  final delivery = org.deliveries.first;
  final contract = delivery.contracts.first;
  return contract.slots.first;
}

// ---------------------------------------------------------------------------
// Scenario story loader (reads scenario JSON title/id from acceptance/scenarios/)
// ---------------------------------------------------------------------------

class _AcceptanceStory {
  const _AcceptanceStory({required this.id, required this.title});

  final String id;
  final String title;
}

_AcceptanceStory _loadStory(String id) {
  final uri = Directory.current.uri.resolve('../acceptance/scenarios/$id.json');
  final content = File.fromUri(uri).readAsStringSync();
  final json = jsonDecode(content) as Map<String, Object?>;
  return _AcceptanceStory(
    id: json['id']! as String,
    title: json['title']! as String,
  );
}

// ---------------------------------------------------------------------------
// Scripted SyncApi
// ---------------------------------------------------------------------------

class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi(Iterable<_ExpectedSyncCall> calls)
    : _calls = Queue.of(calls),
      super(Dio());

  final Queue<_ExpectedSyncCall> _calls;

  void assertDrained() {
    expect(_calls, isEmpty, reason: 'Unconsumed scripted sync calls remain.');
  }

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    expect(_calls, isNotEmpty, reason: 'Unexpected sync request: $request');
    final call = _calls.removeFirst();
    expect(
      request,
      call.request,
      reason: 'Unexpected sync request for ${call.label}',
    );
    return call.response!;
  }
}

class _ExpectedSyncCall {
  _ExpectedSyncCall.response({
    required this.label,
    required this.request,
    required this.response,
  });

  final String label;
  final SyncRequest request;
  final SyncResponse? response;
}

// ---------------------------------------------------------------------------
// Deterministic ID generator
// ---------------------------------------------------------------------------

class _SequenceIdGenerator extends IdGenerator {
  _SequenceIdGenerator(Iterable<String> ids) : _ids = Queue.of(ids);

  final Queue<String> _ids;

  @override
  String next() {
    if (_ids.isEmpty) {
      throw StateError('No ids left in _SequenceIdGenerator.');
    }
    return _ids.removeFirst();
  }
}
