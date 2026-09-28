@Tags(['acceptance'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Client side of the `contract-lifecycle` stories: the coordinator's contract
/// edit goes through [ContractRepository] (optimistic write + pending
/// mutation); a late server refusal must restore the server state of the
/// organization scope (cursor reset + bootstrap round-trip) and surface the
/// error code to the UI.
void main() {
  const orgId = 'org-1';
  const orgScope = 'organization:org-1';

  final endedStory = _loadStory('contract-ended-rejects-new-subscription');
  final manualEndedStory = _loadStory(
    'contract-manual-ended-rejects-new-subscription',
  );
  final invalidSubscriptionStory = _loadStory(
    'contract-subscription-invalid-rejected',
  );
  final invalidSharedBasketStory = _loadStory(
    'contract-shared-basket-invalid-rejected',
  );
  final sharedBasketCreatedStory = _loadStory('contract-shared-basket-created');

  late AppDatabase db;
  late _ScriptedSyncApi api;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _ScriptedSyncApi();
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  ContractMember subscriber(String memberId, String productTypeId) =>
      ContractMember(
        memberId: memberId,
        subscriptionInstant: '2025-01-01T00:00:00Z',
        status: ContractMemberStatus.active,
        subscriptions: [MemberSubscription(productTypeId: productTypeId)],
      );

  Contract contract({
    required String contractId,
    String minDeliveryDate = '2025-01-01',
    String maxDeliveryDate = '2025-12-31',
    ContractStatus status = ContractStatus.active,
    List<String> productTypeIds = const ['pt-tomato'],
    List<ContractMember> members = const [],
    List<SharedBasket> sharedBaskets = const [],
  }) => Contract(
    contractId: contractId,
    name: 'Saison',
    organizationId: orgId,
    producerAccountId: 'producer-1',
    minDeliveryDate: minDeliveryDate,
    maxDeliveryDate: maxDeliveryDate,
    deliveryCount: 26,
    seasonYear: int.parse(minDeliveryDate.substring(0, 4)),
    productPrices: [
      for (final id in productTypeIds) ProductPrice(productTypeId: id),
    ],
    status: status,
    members: members,
    sharedBaskets: sharedBaskets,
  );

  /// Scripts the two round-trips of a refused contract upsert: the REJECTED
  /// outcome (which resets the org cursor), then the bootstrap that brings
  /// back [serverContracts].
  void scriptRejection({
    required String label,
    required List<Contract> serverContracts,
    required MutationErrorCode code,
  }) {
    api
      ..enqueue(
        label: '$label (mutation)',
        request: (pending) =>
            SyncRequest(cursors: const {orgScope: 'c0'}, mutations: pending),
        response: SyncResponse(
          authorizedScopes: const [orgScope],
          results: const {
            orgScope: IncrementalScopeSyncResult(changes: [], nextCursor: 'c1'),
          },
          mutations: [
            MutationOutcome(
              clientOpId: 'op-1',
              status: MutationStatus.rejected,
              error: MutationError(code: code, message: 'refused'),
            ),
          ],
        ),
      )
      ..enqueue(
        label: '$label (restore)',
        request: (_) => const SyncRequest(cursors: {orgScope: null}),
        response: SyncResponse(
          authorizedScopes: const [orgScope],
          results: {
            orgScope: BootstrapScopeSyncResult(
              items: [
                for (final c in serverContracts) ContractPayload(contract: c),
              ],
              nextCursor: 'c2',
            ),
          },
        ),
      );
  }

  Future<List<Contract>> localContracts() => db.watchContracts(orgId).first;

  Future<SyncSuccess> sync() async {
    final outcome = await SyncRepository(
      db: db,
      api: api,
    ).sync(tenantId: orgId);
    expect(outcome, isA<SyncSuccess>());
    return outcome as SyncSuccess;
  }

  // ---------------------------------------------------------------------------
  // contract-ended-rejects-new-subscription
  // ---------------------------------------------------------------------------
  test('${endedStory.title} [${endedStory.id}]', () async {
    final serverContract = contract(
      contractId: 'contract-1',
      minDeliveryDate: '2020-01-01',
      maxDeliveryDate: '2020-06-30',
      productTypeIds: const ['pt-tomato', 'pt-eggs'],
      members: [subscriber('member-1', 'pt-tomato')],
    );
    // The form pre-check: a contract past its last delivery is ended.
    expect(isContractEffectivelyEnded(serverContract), isTrue);
    await db.upsertContract(orgId, serverContract);
    await db.writeCursor(orgScope, 'c0');

    final repo = ContractRepository(
      db: db,
      idGenerator: _SequenceIdGenerator(['op-1']),
    );
    await repo.update(
      serverContract.copyWith(
        members: [...serverContract.members, subscriber('member-2', 'pt-eggs')],
      ),
    );
    expect((await localContracts()).single.members, hasLength(2));

    scriptRejection(
      label: endedStory.id,
      serverContracts: [serverContract],
      code: MutationErrorCode.contractEnded,
    );
    final outcome = await sync();

    expect(
      outcome.rejectedMutations.single.error?.code,
      MutationErrorCode.contractEnded,
    );
    expect(await db.readPendingMutations(), isEmpty);
    expect((await localContracts()).single.members.map((m) => m.memberId), [
      'member-1',
    ]);
    expect(await db.readCursor(orgScope), 'c2');
  });

  // ---------------------------------------------------------------------------
  // contract-manual-ended-rejects-new-subscription
  // ---------------------------------------------------------------------------
  test('${manualEndedStory.title} [${manualEndedStory.id}]', () async {
    final serverContract = contract(
      contractId: 'contract-3',
      minDeliveryDate: '2027-01-01',
      maxDeliveryDate: '2027-12-31',
      status: ContractStatus.ended,
    );
    // Manually ENDED: ended even though its dates are still in the future.
    expect(
      isContractEffectivelyEnded(serverContract, now: DateTime(2026, 9, 29)),
      isTrue,
    );
    await db.upsertContract(orgId, serverContract);
    await db.writeCursor(orgScope, 'c0');

    final repo = ContractRepository(
      db: db,
      idGenerator: _SequenceIdGenerator(['op-1']),
    );
    await repo.update(
      serverContract.copyWith(members: [subscriber('member-2', 'pt-tomato')]),
    );

    scriptRejection(
      label: manualEndedStory.id,
      serverContracts: [serverContract],
      code: MutationErrorCode.contractEnded,
    );
    final outcome = await sync();

    expect(
      outcome.rejectedMutations.single.error?.code,
      MutationErrorCode.contractEnded,
    );
    expect((await localContracts()).single.members, isEmpty);
  });

  // ---------------------------------------------------------------------------
  // contract-subscription-invalid-rejected
  // ---------------------------------------------------------------------------
  test(
    '${invalidSubscriptionStory.title} [${invalidSubscriptionStory.id}]',
    () async {
      await db.writeCursor(orgScope, 'c0');
      final repo = ContractRepository(
        db: db,
        idGenerator: _SequenceIdGenerator(['op-1']),
      );
      await repo.update(
        contract(
          contractId: 'contract-2',
          productTypeIds: const ['pt-tomato', 'pt-eggs'],
          members: [subscriber('member-1', 'pt-unknown')],
        ),
      );
      expect(await localContracts(), hasLength(1));

      scriptRejection(
        label: invalidSubscriptionStory.id,
        serverContracts: const [],
        code: MutationErrorCode.invalidSubscription,
      );
      final outcome = await sync();

      expect(
        outcome.rejectedMutations.single.error?.code,
        MutationErrorCode.invalidSubscription,
      );
      // The refused contract never existed server-side: it leaves the cache.
      expect(await localContracts(), isEmpty);
      expect(await db.readPendingMutations(), isEmpty);
    },
  );

  // ---------------------------------------------------------------------------
  // contract-shared-basket-invalid-rejected
  // ---------------------------------------------------------------------------
  test(
    '${invalidSharedBasketStory.title} [${invalidSharedBasketStory.id}]',
    () async {
      final serverContract = contract(
        contractId: 'contract-shared-bad',
        members: [subscriber('member-1', 'pt-tomato')],
      );
      await db.upsertContract(orgId, serverContract);
      await db.writeCursor(orgScope, 'c0');

      final repo = ContractRepository(
        db: db,
        idGenerator: _SequenceIdGenerator(['op-1']),
      );
      await repo.update(
        serverContract.copyWith(
          sharedBaskets: const [
            SharedBasket(sharedBasketId: 'tmp_sb-1', memberIds: ['member-1']),
          ],
        ),
      );

      scriptRejection(
        label: invalidSharedBasketStory.id,
        serverContracts: [serverContract],
        code: MutationErrorCode.invalidSharedBasket,
      );
      final outcome = await sync();

      expect(
        outcome.rejectedMutations.single.error?.code,
        MutationErrorCode.invalidSharedBasket,
      );
      expect((await localContracts()).single.sharedBaskets, isEmpty);
    },
  );

  // ---------------------------------------------------------------------------
  // contract-shared-basket-created: the nested tmp_ shared basket id is never
  // echoed through serverEntityId (reserved for the contract root); the front
  // recovers the real id from the authoritative contract of the same sync.
  // ---------------------------------------------------------------------------
  test(
    '${sharedBasketCreatedStory.title} [${sharedBasketCreatedStory.id}]',
    () async {
      final members = [
        subscriber('member-1', 'pt-tomato'),
        subscriber('member-2', 'pt-tomato'),
      ];
      final serverContract = contract(
        contractId: 'contract-shared',
        members: members,
      );
      await db.upsertContract(orgId, serverContract);
      await db.writeCursor(orgScope, 'c0');

      final repo = ContractRepository(
        db: db,
        idGenerator: _SequenceIdGenerator(['op-1']),
      );
      await repo.update(
        serverContract.copyWith(
          sharedBaskets: const [
            SharedBasket(
              sharedBasketId: 'tmp_sb-1',
              memberIds: ['member-1', 'member-2'],
            ),
          ],
        ),
      );

      final persisted = serverContract.copyWith(
        sharedBaskets: const [
          SharedBasket(
            sharedBasketId: 'sb-real-1',
            memberIds: ['member-1', 'member-2'],
          ),
        ],
      );
      api.enqueue(
        label: sharedBasketCreatedStory.id,
        request: (pending) =>
            SyncRequest(cursors: const {orgScope: 'c0'}, mutations: pending),
        response: SyncResponse(
          authorizedScopes: const [orgScope],
          results: {
            orgScope: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.contract,
                  entityId: 'contract-shared',
                  op: ChangeOp.upsert,
                  payload: ContractPayload(contract: persisted),
                  producedAt: 1,
                ),
              ],
              nextCursor: 'c1',
            ),
          },
          mutations: const [
            MutationOutcome(
              clientOpId: 'op-1',
              status: MutationStatus.applied,
              serverEntityId: 'contract-shared',
            ),
          ],
        ),
      );
      final outcome = await sync();

      expect(outcome.rejectedMutations, isEmpty);
      expect(await db.readPendingMutations(), isEmpty);
      final local = (await localContracts()).single;
      expect(local.contractId, 'contract-shared');
      expect(local.sharedBaskets.single.sharedBasketId, 'sb-real-1');
      expect(local.sharedBaskets.single.memberIds, ['member-1', 'member-2']);
    },
  );
}

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
// Scripted SyncApi — the expected request may depend on the pending mutations
// the client actually sends.
// ---------------------------------------------------------------------------

class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi() : super(Dio());

  final Queue<_ExpectedSyncCall> _calls = Queue();

  void enqueue({
    required String label,
    required SyncRequest Function(List<ClientMutation> pending) request,
    required SyncResponse response,
  }) => _calls.add(
    _ExpectedSyncCall(label: label, request: request, response: response),
  );

  void assertDrained() {
    expect(_calls, isEmpty, reason: 'Unconsumed scripted sync calls.');
  }

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    if (_calls.isEmpty) fail('Unexpected sync request: $request');
    final call = _calls.removeFirst();
    expect(
      request,
      call.request(request.mutations),
      reason: 'Unexpected sync request for ${call.label}',
    );
    return call.response;
  }
}

class _ExpectedSyncCall {
  const _ExpectedSyncCall({
    required this.label,
    required this.request,
    required this.response,
  });

  final String label;
  final SyncRequest Function(List<ClientMutation> pending) request;
  final SyncResponse response;
}

// ---------------------------------------------------------------------------
// Deterministic ID generator
// ---------------------------------------------------------------------------

class _SequenceIdGenerator extends IdGenerator {
  _SequenceIdGenerator(Iterable<String> ids) : _ids = Queue.of(ids);

  final Queue<String> _ids;

  @override
  String next() {
    if (_ids.isEmpty) throw StateError('No ids left in _SequenceIdGenerator.');
    return _ids.removeFirst();
  }
}
