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
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
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
  const volunteerId = 'volunteer-1';
  const otherMemberId = 'other-member';

  final registrationStory = _loadStory('volunteer-self-registration');
  final unregisterStory = _loadStory('volunteer-self-unregister');
  final forbiddenStory = _loadStory('volunteer-register-other-forbidden');

  late AppDatabase db;
  late _ScriptedSyncApi api;

  /// Builds the base Organization with one future CONFIRMED delivery + one
  /// STANDARD slot having the given [registrations].
  Organization buildOrg({List<MemberRegistration> registrations = const []}) {
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
          status: DeliveryStatus.confirmed,
          minVolunteersRequired: 2,
          contracts: [
            DeliveryContract(
              contractId: contractId,
              coordinators: const ['coordinator-1'],
              basketQuantity: 10,
              deliveryDescription: 'Weekly basket',
              status: DeliveryContractStatus.pending,
              slots: [
                MemberSlot(
                  startTime: '2099-06-15T18:00:00',
                  endTime: '2099-06-15T20:00:00',
                  activityType: ActivityType.reception,
                  requiredVolunteers: 2,
                  currentRegistrations: registrations.length,
                  status: SlotStatus.open,
                  slotKind: SlotKind.standard,
                  registrations: registrations,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Member buildVolunteer() => const Member(
    memberId: volunteerId,
    organizationId: orgId,
    roles: {Role.volunteer},
    firstName: 'Alice',
    lastName: 'Volunteer',
    email: 'volunteer@example.com',
    activeStatus: true,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  // --------------------------------------------------------------------------
  // Scenario 1 — volunteer-self-registration
  // --------------------------------------------------------------------------
  test('${registrationStory.title} [${registrationStory.id}]', () async {
    final idGen = _SequenceIdGenerator(['op-register']);
    final orgRepo = OrganizationRepository(db: db, idGenerator: idGen);

    // Populate the DB with the org in its initial empty-slot state.
    final initialOrg = buildOrg();
    await db.upsertOrganization(initialOrg);
    await db.writeCursor(orgScope, 'c0');

    final volunteer = buildVolunteer();
    await db.upsertMember(orgId, volunteer);

    // Act: register the volunteer optimistically.
    await orgRepo.registerToSlot(
      currentOrg: initialOrg,
      deliveryId: deliveryId,
      contractId: contractId,
      slotKind: SlotKind.standard,
      me: volunteer,
    );

    // The local org cache must now contain the registration.
    final localOrg = await db.watchOrganization(orgId).first;
    expect(localOrg, isNotNull, reason: 'org not found in local cache');
    final localSlot = _findSlot(localOrg!);
    expect(localSlot.registrations, hasLength(1));
    expect(localSlot.registrations.first.memberId, volunteerId);

    // A pending mutation must be enqueued.
    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));
    final mut = pending.first;
    expect(mut.op, isA<Upsert>());
    final upsert = mut.op as Upsert;
    expect(upsert.payload, isA<OrganizationPayload>());

    // Prepare the scripted sync response: APPLIED + incremental with updated org.
    final orgAfterSync = buildOrg(
      registrations: [
        MemberRegistration(
          memberId: volunteerId,
          displayName: 'Alice Volunteer',
          memberEmail: 'volunteer@example.com',
          registrationInstant: '2099-06-01T10:00:00Z',
          status: RegistrationStatus.registered,
        ),
      ],
    );

    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: registrationStory.id,
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
              clientOpId: 'op-register',
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
    expect(syncedOrg, isNotNull);
    final syncedSlot = _findSlot(syncedOrg!);
    expect(syncedSlot.registrations, hasLength(1));
    expect(syncedSlot.registrations.first.memberId, volunteerId);
    expect(await db.readPendingMutations(), isEmpty);
    expect(await db.readCursor(orgScope), 'c1');
  });

  // --------------------------------------------------------------------------
  // Scenario 2 — volunteer-self-unregister
  // --------------------------------------------------------------------------
  test('${unregisterStory.title} [${unregisterStory.id}]', () async {
    final idGen = _SequenceIdGenerator(['op-unregister']);
    final orgRepo = OrganizationRepository(db: db, idGenerator: idGen);

    // Populate with an existing registration for the volunteer.
    final existingRegistration = MemberRegistration(
      memberId: volunteerId,
      displayName: 'Alice Volunteer',
      memberEmail: 'volunteer@example.com',
      registrationInstant: '2099-05-20T10:00:00Z',
      status: RegistrationStatus.registered,
    );
    final initialOrg = buildOrg(registrations: [existingRegistration]);
    await db.upsertOrganization(initialOrg);
    await db.writeCursor(orgScope, 'c0');

    final volunteer = buildVolunteer();
    await db.upsertMember(orgId, volunteer);

    // Act: unregister the volunteer optimistically.
    await orgRepo.unregisterFromSlot(
      currentOrg: initialOrg,
      deliveryId: deliveryId,
      contractId: contractId,
      slotKind: SlotKind.standard,
      memberId: volunteerId,
    );

    // Local slot must now have no registrations.
    final localOrg = await db.watchOrganization(orgId).first;
    expect(localOrg, isNotNull);
    final localSlot = _findSlot(localOrg!);
    expect(localSlot.registrations, isEmpty);

    // A pending mutation must be enqueued.
    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));

    final orgAfterSync = buildOrg();

    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: unregisterStory.id,
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
                  producedAt: 2,
                ),
              ],
              nextCursor: 'c2',
            ),
          },
          mutations: const [
            MutationOutcome(
              clientOpId: 'op-unregister',
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
    expect(syncedOrg, isNotNull);
    final syncedSlot = _findSlot(syncedOrg!);
    expect(syncedSlot.registrations, isEmpty);
    expect(await db.readPendingMutations(), isEmpty);
    expect(await db.readCursor(orgScope), 'c2');
  });

  // --------------------------------------------------------------------------
  // Scenario 3 — volunteer-register-other-forbidden
  // --------------------------------------------------------------------------
  test('${forbiddenStory.title} [${forbiddenStory.id}]', () async {
    // This scenario validates that a REJECTED outcome is surfaced correctly.
    // The front does not prevent submitting the mutation (it is the back that
    // rejects it). We simulate the attempt by building a modified org that
    // contains another member's registration and submitting it directly via
    // the SyncRepository, then verifying the pending mutation is drained and
    // the org state is not altered.

    final initialOrg = buildOrg();
    await db.upsertOrganization(initialOrg);
    await db.writeCursor(orgScope, 'c0');

    final volunteer = buildVolunteer();
    await db.upsertMember(orgId, volunteer);

    // Enqueue the forbidden mutation directly (simulates a client bug or
    // a front unit that does not guard ownership).
    final otherRegistration = MemberRegistration(
      memberId: otherMemberId,
      displayName: 'Other Member',
      memberEmail: 'other@example.com',
      registrationInstant: '2099-06-01T10:00:00Z',
      status: RegistrationStatus.registered,
    );
    final orgWithOtherRegistration = buildOrg(
      registrations: [otherRegistration],
    );
    final forbidden = ClientMutation(
      clientOpId: 'op-register-other',
      op: Upsert(
        payload: OrganizationPayload(organization: orgWithOtherRegistration),
      ),
    );
    await db.enqueuePendingMutation(forbidden, scopeKey: orgScope);

    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));

    // Scripted API returns REJECTED.
    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: forbiddenStory.id,
        request: SyncRequest(
          cursors: const {orgScope: 'c0'},
          mutations: pending,
        ),
        response: const SyncResponse(
          authorizedScopes: [orgScope],
          results: {
            orgScope: IncrementalScopeSyncResult(changes: [], nextCursor: 'c0'),
          },
          mutations: [
            MutationOutcome(
              clientOpId: 'op-register-other',
              status: MutationStatus.rejected,
              error: MutationError(
                code: MutationErrorCode.forbidden,
                message: 'Volunteer cannot modify other members registrations',
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
    expect(syncSuccess.rejectedMutations.first.clientOpId, 'op-register-other');

    // Pending mutations must be drained (REJECTED = acknowledged by server).
    expect(await db.readPendingMutations(), isEmpty);

    // The org state must NOT contain the other member's registration.
    final localOrg = await db.watchOrganization(orgId).first;
    expect(localOrg, isNotNull);
    final localSlot = _findSlot(localOrg!);
    expect(localSlot.registrations, isEmpty);
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

  void enqueue(_ExpectedSyncCall call) => _calls.add(call);

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
    if (call.error != null) throw call.error!;
    return call.response!;
  }
}

class _ExpectedSyncCall {
  _ExpectedSyncCall.response({
    required this.label,
    required this.request,
    required this.response,
  }) : error = null;

  final String label;
  final SyncRequest request;
  final SyncResponse? response;
  final Object? error;
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
