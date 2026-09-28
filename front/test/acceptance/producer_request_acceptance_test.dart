@Tags(['acceptance'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_state.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_bloc.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_event.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_state.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final story = _loadStory('producer-request-approval');

  test('${story.title} [${story.id}]', () async {
    final publicApi = _ScriptedPublicApi([
      const ProducerRequestResponse(
        requestId: 'req-1',
        status: 'PENDING_VALIDATION',
      ),
    ]);

    final creationBloc = ProducerRequestBloc(publicApi: publicApi);
    final successFuture = creationBloc.stream
        .where((s) => s is ProducerRequestSuccess)
        .cast<ProducerRequestSuccess>()
        .first;

    creationBloc.add(
      const ProducerRequestSubmitted(
        producerName: 'Ferme des Collines',
        adminFirstName: 'Alice',
        adminLastName: 'Martin',
        adminEmail: 'alice@collines.fr',
      ),
    );

    final success = await successFuture;
    expect(success.response.requestId, 'req-1');
    await creationBloc.close();
    publicApi.assertDrained();

    final db = AppDatabase(NativeDatabase.memory());
    final repo = ProducerRequestRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
    await db.upsertProducerRequest(
      const AdminProducerRequest(
        requestId: 'req-1',
        producerName: 'Ferme des Collines',
        adminFirstName: 'Alice',
        adminLastName: 'Martin',
        adminEmail: 'alice@collines.fr',
        status: ProducerRequestStatus.pendingValidation,
        submittedAt: '2026-05-07T10:00:00Z',
      ),
    );

    final reviewBloc = ProducerRequestsBloc(producerRequestRepository: repo);
    final loadedFuture = reviewBloc.stream
        .where((s) => s is ProducerRequestsLoaded)
        .cast<ProducerRequestsLoaded>()
        .first;
    reviewBloc.add(const ProducerRequestsEvent.loadRequested());
    final loaded = await loadedFuture;
    expect(
      loaded.requests.single.status,
      ProducerRequestStatus.pendingValidation,
    );

    final approvedFuture = reviewBloc.stream
        .where((s) => s is ProducerRequestsLoaded)
        .cast<ProducerRequestsLoaded>()
        .where(
          (s) => s.requests.single.status == ProducerRequestStatus.approved,
        )
        .first;
    reviewBloc.add(
      ProducerRequestsEvent.approveRequested(request: loaded.requests.single),
    );
    await approvedFuture;

    final pendingMutations = await db.readPendingMutations();
    expect(pendingMutations.length, 1);

    // The owner sync applies the approval: the server answers with the
    // approved request and the new
    // account-backed producer, still pending activation, on instance-owner.
    await db.writeCursor(instanceOwnerScopeKey, 'c0');
    const producerAccount = ProducerAccount(
      producerAccountId: 'pa-1',
      name: 'Ferme des Collines',
      contactEmail: 'alice@collines.fr',
      pendingActivation: true,
    );
    final syncApi = _ScriptedSyncApi(
      request: SyncRequest(
        cursors: const {instanceOwnerScopeKey: 'c0'},
        mutations: pendingMutations,
      ),
      response: SyncResponse(
        authorizedScopes: const [instanceOwnerScopeKey],
        results: {
          instanceOwnerScopeKey: IncrementalScopeSyncResult(
            changes: [
              Change(
                entityType: EntityType.producerRequest,
                entityId: 'req-1',
                op: ChangeOp.upsert,
                payload: ProducerRequestPayload(
                  producerRequest: loaded.requests.single.copyWith(
                    status: ProducerRequestStatus.approved,
                  ),
                ),
                producedAt: 1,
              ),
              const Change(
                entityType: EntityType.producerAccount,
                entityId: 'pa-1',
                op: ChangeOp.upsert,
                payload: ProducerAccountPayload(
                  producerAccount: producerAccount,
                ),
                producedAt: 2,
              ),
            ],
            nextCursor: 'c1',
          ),
        },
        mutations: [
          MutationOutcome(
            clientOpId: pendingMutations.single.clientOpId,
            status: MutationStatus.applied,
            serverEntityId: 'req-1',
          ),
        ],
      ),
    );

    final outcome = await SyncRepository(
      db: db,
      api: syncApi,
    ).sync(tenantId: 'owner-tenant');

    expect(outcome, isA<SyncSuccess>());
    syncApi.assertDrained();
    expect(await db.readPendingMutations(), isEmpty);
    final syncedRequest = (await db.watchProducerRequests().first).single;
    expect(syncedRequest.status, ProducerRequestStatus.approved);
    final accounts = await db.watchAllProducerAccounts().first;
    expect(accounts.single.pendingActivation, isTrue);
    expect(await db.readCursor(instanceOwnerScopeKey), 'c1');

    await reviewBloc.close();
    await db.close();
  });
}

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

/// Answers exactly one expected sync request.
class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi({
    required SyncRequest request,
    required SyncResponse response,
  }) : _request = request,
       _response = response,
       super(Dio());

  final SyncRequest _request;
  final SyncResponse _response;
  var _calls = 0;

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    _calls++;
    expect(_calls, 1, reason: 'Unexpected extra sync request: $request');
    expect(request, _request);
    return _response;
  }

  void assertDrained() {
    expect(_calls, 1, reason: 'The scripted sync request was not sent.');
  }
}

class _ScriptedPublicApi extends PublicApi {
  _ScriptedPublicApi(Iterable<ProducerRequestResponse> responses)
    : _responses = responses.toList(),
      super(Dio());

  final List<ProducerRequestResponse> _responses;

  @override
  Future<ProducerRequestResponse> createProducerRequest(
    ProducerCreationRequest request,
  ) async {
    expect(
      _responses,
      isNotEmpty,
      reason: 'Unexpected createProducerRequest call',
    );
    return _responses.removeAt(0);
  }

  void assertDrained() {
    expect(_responses, isEmpty);
  }
}
