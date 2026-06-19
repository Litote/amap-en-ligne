@Tags(['acceptance'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tenant = 'producer-1';
  const producerScope = 'producer-account:producer-1';
  final bootstrapStory = _loadStory('bootstrap-empty');
  final createStory = _loadStory('create-product-type');
  final incrementalStory = _loadStory('incremental-sync');
  final reconnectStory = _loadStory('offline-reconnect-create-product-type');
  final remapStory = _loadStory('contract-weekly-deliveries-tmp-id-remap');

  late AppDatabase db;
  late SyncRepository syncRepo;
  late _ScriptedSyncApi api;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  test('${bootstrapStory.title} [${bootstrapStory.id}]', () async {
    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: bootstrapStory.id,
        request: const SyncRequest(),
        response: const SyncResponse(
          authorizedScopes: [producerScope],
          results: {
            producerScope: BootstrapScopeSyncResult(
              items: [],
              nextCursor: 'c1',
            ),
          },
        ),
      ),
    ]);
    syncRepo = SyncRepository(db: db, api: api);

    final outcome = await syncRepo.sync(tenantId: tenant);

    expect(outcome, isA<SyncSuccess>());
    expect(await db.watchProductTypes(tenant).first, isEmpty);
    expect(await db.readCursor(producerScope), 'c1');
    expect(await db.readPendingMutations(), isEmpty);
  });

  test('${createStory.title} [${createStory.id}]', () async {
    final productRepo = ProductTypeRepository(
      db: db,
      idGenerator: _SequenceIdGenerator(['entity-1', 'op-1']),
    );
    syncRepo = SyncRepository(db: db, api: api = _ScriptedSyncApi([]));

    final optimistic = await productRepo.create(
      tenantId: tenant,
      name: 'Vegetables',
      supportedBasketSizes: const [BasketSize(name: 'small')],
    );
    final pending = await db.readPendingMutations();
    api.enqueue(
      _ExpectedSyncCall.response(
        label: createStory.id,
        request: SyncRequest(cursors: const {}, mutations: pending),
        response: const SyncResponse(
          authorizedScopes: [producerScope],
          results: {
            producerScope: BootstrapScopeSyncResult(
              items: [
                ProductTypePayload(
                  productType: ProductType(
                    productTypeId: 'pt-1',
                    producerAccountId: tenant,
                    supportedBasketSizes: [BasketSize(name: 'small')],
                    name: 'Vegetables',
                  ),
                ),
              ],
              nextCursor: 'c1',
            ),
          },
          mutations: [
            MutationOutcome(
              clientOpId: 'op-1',
              status: MutationStatus.applied,
              serverEntityId: 'pt-1',
            ),
          ],
        ),
      ),
    );

    expect(optimistic.productTypeId, 'tmp_entity-1');

    final outcome = await syncRepo.sync(tenantId: tenant);

    expect(outcome, isA<SyncSuccess>());
    final rows = await db.watchProductTypes(tenant).first;
    expect(rows, const [
      ProductType(
        productTypeId: 'pt-1',
        producerAccountId: tenant,
        supportedBasketSizes: [BasketSize(name: 'small')],
        name: 'Vegetables',
      ),
    ]);
    expect(await db.readCursor(producerScope), 'c1');
    expect(await db.readPendingMutations(), isEmpty);
  });

  test('${incrementalStory.title} [${incrementalStory.id}]', () async {
    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: '${incrementalStory.id} bootstrap',
        request: const SyncRequest(),
        response: const SyncResponse(
          authorizedScopes: [producerScope],
          results: {
            producerScope: BootstrapScopeSyncResult(
              items: [
                ProductTypePayload(
                  productType: ProductType(
                    productTypeId: 'pt-1',
                    producerAccountId: tenant,
                    supportedBasketSizes: [BasketSize(name: 'small')],
                    name: 'Vegetables',
                  ),
                ),
              ],
              nextCursor: 'c1',
            ),
          },
        ),
      ),
      _ExpectedSyncCall.response(
        label: '${incrementalStory.id} incremental',
        request: const SyncRequest(cursors: {producerScope: 'c1'}),
        response: const SyncResponse(
          authorizedScopes: [producerScope],
          results: {
            producerScope: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.productType,
                  entityId: 'pt-2',
                  op: ChangeOp.upsert,
                  payload: ProductTypePayload(
                    productType: ProductType(
                      productTypeId: 'pt-2',
                      producerAccountId: tenant,
                      supportedBasketSizes: [BasketSize(name: 'small')],
                      name: 'Fruits',
                    ),
                  ),
                  producedAt: 1,
                ),
              ],
              nextCursor: 'c2',
            ),
          },
        ),
      ),
    ]);
    syncRepo = SyncRepository(db: db, api: api);

    await syncRepo.sync(tenantId: tenant);
    final outcome = await syncRepo.sync(tenantId: tenant);

    expect(outcome, isA<SyncSuccess>());
    final rows = await db.watchProductTypes(tenant).first;
    expect(rows.map((row) => row.name).toSet(), {'Vegetables', 'Fruits'});
    expect(await db.readCursor(producerScope), 'c2');
    expect(await db.readPendingMutations(), isEmpty);
  });

  test('${remapStory.title} [${remapStory.id}]', () async {
    const orgScope = 'organization:org-1';
    const tmpContractId = 'tmp_contract_weekly';
    const realContractId = 'contract-real-1';

    // Seed the local DB: a tmp_ contract and an org whose delivery references it.
    const tmpContract = Contract(
      contractId: tmpContractId,
      name: 'Saison hebdo 2027',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: '2027-01-01',
      maxDeliveryDate: '2027-12-31',
      deliveryCount: 52,
      seasonYear: 2027,
      status: ContractStatus.inPreparation,
    );

    const orgWithTmpRef = Organization(
      organizationId: 'org-1',
      name: 'Test Org',
      contactEmail: 'test@example.com',
      deliveries: [
        Delivery(
          deliveryId: 'delivery-weekly-1',
          organizationId: 'org-1',
          scheduledDate: '2027-01-07T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 1,
          contracts: [
            DeliveryContract(
              contractId: tmpContractId,
              basketQuantity: 0,
              deliveryDescription: 'Saison hebdo 2027',
              status: DeliveryContractStatus.pending,
            ),
          ],
        ),
      ],
    );

    await db.upsertContract('org-1', tmpContract);
    await db.upsertOrganization(orgWithTmpRef);

    await db.enqueuePendingMutation(
      const ClientMutation(
        clientOpId: 'op-contract',
        op: Upsert(payload: ContractPayload(contract: tmpContract)),
      ),
      scopeKey: orgScope,
    );
    await db.enqueuePendingMutation(
      const ClientMutation(
        clientOpId: 'op-org',
        op: Upsert(payload: OrganizationPayload(organization: orgWithTmpRef)),
      ),
      scopeKey: orgScope,
    );

    // Read back the mutations after the serialisation round-trip so the
    // scripted-API equality check matches the actual transmitted request.
    final pending = await db.readPendingMutations();

    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: remapStory.id,
        request: SyncRequest(cursors: const {}, mutations: pending),
        response: SyncResponse(
          authorizedScopes: [orgScope],
          mutations: [
            MutationOutcome(
              clientOpId: pending[0].clientOpId,
              status: MutationStatus.applied,
              serverEntityId: realContractId,
            ),
            MutationOutcome(
              clientOpId: pending[1].clientOpId,
              status: MutationStatus.applied,
            ),
          ],
        ),
      ),
    ]);
    syncRepo = SyncRepository(db: db, api: api);

    await syncRepo.sync(tenantId: tenant);

    // The cached org's delivery must reference the server-allocated contract id.
    final storedOrg = await db.watchOrganization('org-1').first;
    expect(
      storedOrg!.deliveries.single.contracts.single.contractId,
      realContractId,
    );
    // Both mutations were applied — the queue is now empty.
    expect(await db.readPendingMutations(), isEmpty);
  });

  test('${reconnectStory.title} [${reconnectStory.id}]', () async {
    final productRepo = ProductTypeRepository(
      db: db,
      idGenerator: _SequenceIdGenerator(['entity-1', 'op-1']),
    );
    api = _ScriptedSyncApi([
      _ExpectedSyncCall.response(
        label: '${reconnectStory.id} bootstrap',
        request: const SyncRequest(),
        response: const SyncResponse(
          authorizedScopes: [producerScope],
          results: {
            producerScope: BootstrapScopeSyncResult(
              items: [],
              nextCursor: 'c0',
            ),
          },
        ),
      ),
    ]);
    syncRepo = SyncRepository(db: db, api: api);

    await syncRepo.sync(tenantId: tenant);
    final optimistic = await productRepo.create(
      tenantId: tenant,
      name: 'Vegetables',
      supportedBasketSizes: const [BasketSize(name: 'small')],
    );
    final pending = await db.readPendingMutations();

    api
      ..enqueue(
        _ExpectedSyncCall.failure(
          label: '${reconnectStory.id} offline',
          request: SyncRequest(
            cursors: const {producerScope: 'c0'},
            mutations: pending,
          ),
          error: DioException(
            requestOptions: RequestOptions(path: '/v1/sync'),
            message: 'offline',
          ),
        ),
      )
      ..enqueue(
        _ExpectedSyncCall.response(
          label: '${reconnectStory.id} reconnect',
          request: SyncRequest(
            cursors: const {producerScope: 'c0'},
            mutations: pending,
          ),
          response: const SyncResponse(
            authorizedScopes: [producerScope],
            results: {
              producerScope: IncrementalScopeSyncResult(
                changes: [
                  Change(
                    entityType: EntityType.productType,
                    entityId: 'pt-1',
                    op: ChangeOp.upsert,
                    payload: ProductTypePayload(
                      productType: ProductType(
                        productTypeId: 'pt-1',
                        producerAccountId: tenant,
                        supportedBasketSizes: [BasketSize(name: 'small')],
                        name: 'Vegetables',
                      ),
                    ),
                    producedAt: 1,
                  ),
                ],
                nextCursor: 'c1',
              ),
            },
            mutations: [
              MutationOutcome(
                clientOpId: 'op-1',
                status: MutationStatus.applied,
                serverEntityId: 'pt-1',
              ),
            ],
          ),
        ),
      );

    final failure = await syncRepo.sync(tenantId: tenant);
    expect(failure, isA<SyncFailure>());
    expect(
      (await db.watchProductTypes(tenant).first).single.productTypeId,
      optimistic.productTypeId,
    );
    expect(await db.readPendingMutations(), hasLength(1));

    final success = await syncRepo.sync(tenantId: tenant);

    expect(success, isA<SyncSuccess>());
    final rows = await db.watchProductTypes(tenant).first;
    expect(rows.single.productTypeId, 'pt-1');
    expect(rows.single.name, 'Vegetables');
    expect(await db.readCursor(producerScope), 'c1');
    expect(await db.readPendingMutations(), isEmpty);
  });
}

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

  _ExpectedSyncCall.failure({
    required this.label,
    required this.request,
    required this.error,
  }) : response = null;

  final String label;
  final SyncRequest request;
  final SyncResponse? response;
  final Object? error;
}

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
