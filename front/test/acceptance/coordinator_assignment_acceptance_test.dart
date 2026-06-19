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
  const coordinatorId = 'coordinator-1';
  const adminId = 'admin-1';
  const contractDescription = 'Weekly basket';

  final selfAssignStory = _loadStory('coordinator-self-assign');
  final missingCoordinatorStory = _loadStory(
    'coordinator-confirm-requires-coordinator',
  );

  late AppDatabase db;
  late _ScriptedSyncApi api;

  /// Builds a base [Organization] with one future PLANNED delivery and one
  /// [DeliveryContract] with the given [coordinators].
  Organization buildOrg({List<String> coordinators = const []}) {
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
              coordinators: coordinators,
              basketQuantity: 10,
              deliveryDescription: contractDescription,
              status: DeliveryContractStatus.pending,
              slots: const [],
            ),
          ],
        ),
      ],
    );
  }

  Member buildCoordinator() => const Member(
    memberId: coordinatorId,
    organizationId: orgId,
    roles: {Role.coordinator},
    firstName: 'Alice',
    lastName: 'Coordinator',
    email: 'coordinator@example.com',
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
  // Scenario 1 — coordinator-self-assign
  // --------------------------------------------------------------------------
  test('${selfAssignStory.title} [${selfAssignStory.id}]', () async {
    final idGen = _SequenceIdGenerator(['op-self-assign']);
    final orgRepo = OrganizationRepository(db: db, idGenerator: idGen);

    // Populate the DB with the org: empty coordinators list.
    final initialOrg = buildOrg();
    await db.upsertOrganization(initialOrg);
    await db.writeCursor(orgScope, 'c0');

    final coordinator = buildCoordinator();
    await db.upsertMember(orgId, coordinator);

    // Act: coordinator self-assigns.
    await orgRepo.assignCoordinator(
      currentOrg: initialOrg,
      deliveryId: deliveryId,
      contractId: contractId,
      memberId: coordinatorId,
    );

    // Optimistic write: coordinator must be in the local cache.
    final localOrg = await db.watchOrganization(orgId).first;
    expect(localOrg, isNotNull, reason: 'org not found in local cache');
    final localContract = localOrg!.deliveries.first.contracts.first;
    expect(localContract.coordinators, contains(coordinatorId));

    // A pending mutation must be enqueued.
    final pending = await db.readPendingMutations();
    expect(pending, hasLength(1));
    final mut = pending.first;
    expect(mut.op, isA<Upsert>());
    final upsert = mut.op as Upsert;
    expect(upsert.payload, isA<OrganizationPayload>());

    // Scripted response: APPLIED + incremental with updated org.
    final orgAfterSync = buildOrg(coordinators: [coordinatorId]);

    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: selfAssignStory.id,
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
              clientOpId: 'op-self-assign',
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
    final syncedContract = syncedOrg!.deliveries.first.contracts.first;
    expect(syncedContract.coordinators, contains(coordinatorId));
    expect(await db.readPendingMutations(), isEmpty);
    expect(await db.readCursor(orgScope), 'c1');
  });

  // --------------------------------------------------------------------------
  // Scenario 2 — coordinator-confirm-requires-coordinator
  // --------------------------------------------------------------------------
  test(
    '${missingCoordinatorStory.title} [${missingCoordinatorStory.id}]',
    () async {
      // Populate the DB: PLANNED delivery, empty coordinators.
      final initialOrg = buildOrg();
      await db.upsertOrganization(initialOrg);
      await db.writeCursor(orgScope, 'c0');

      final admin = const Member(
        memberId: adminId,
        organizationId: orgId,
        roles: {Role.admin},
        firstName: 'Bob',
        lastName: 'Admin',
        activeStatus: true,
      );
      await db.upsertMember(orgId, admin);

      // Simulate the admin transitioning the delivery to CONFIRMED with an
      // empty coordinators list — this is what a future "Confirm" button would
      // enqueue. We build the mutation directly to match the scenario JSON
      // without needing a dedicated repository method.
      final confirmedDelivery = initialOrg.deliveries.first.copyWith(
        status: DeliveryStatus.confirmed,
      );
      final confirmedOrg = initialOrg.copyWith(deliveries: [confirmedDelivery]);
      final forbiddenMutation = ClientMutation(
        clientOpId: 'op-confirm',
        op: Upsert(payload: OrganizationPayload(organization: confirmedOrg)),
      );
      await db.enqueuePendingMutation(forbiddenMutation, scopeKey: orgScope);

      final pending = await db.readPendingMutations();
      expect(pending, hasLength(1));

      // Scripted response: REJECTED with MISSING_COORDINATOR.
      api = _ScriptedSyncApi([
        _ExpectedSyncCall.response(
          label: missingCoordinatorStory.id,
          request: SyncRequest(
            cursors: const {orgScope: 'c0'},
            mutations: pending,
          ),
          response: const SyncResponse(
            authorizedScopes: [orgScope],
            results: {
              orgScope: IncrementalScopeSyncResult(
                changes: [],
                nextCursor: 'c0',
              ),
            },
            mutations: [
              MutationOutcome(
                clientOpId: 'op-confirm',
                status: MutationStatus.rejected,
                error: MutationError(
                  code: MutationErrorCode.missingCoordinator,
                  message:
                      'Cannot confirm delivery: contract contract-1 has no coordinator',
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
      // The rejected mutation must be surfaced.
      expect(syncSuccess.rejectedMutations, hasLength(1));
      expect(
        syncSuccess.rejectedMutations.first.error?.code,
        MutationErrorCode.missingCoordinator,
      );

      // Pending queue is drained (REJECTED = acknowledged by server).
      expect(await db.readPendingMutations(), isEmpty);
    },
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Scenario story loader
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
