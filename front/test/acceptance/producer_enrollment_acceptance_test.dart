@Tags(['acceptance'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
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

/// Client side of `producer-enrollment-account-backed-fans-out`: the admin's
/// enrollment is a plain `Organization` upsert; the producer's account then
/// reaches every device concerned through its own feed (the AMAP admin sees
/// its name, the owner lists it, the producer sees its new AMAP).
void main() {
  const orgId = 'org-1';
  const orgScope = 'organization:org-1';
  const producerId = 'pa-1';

  final story = _loadStory('producer-enrollment-account-backed-fans-out');

  late AppDatabase db;
  late _ScriptedSyncApi api;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    api.assertDrained();
    await db.close();
  });

  const link = OrganizationProducer(
    producerAccountId: producerId,
    associationInstant: '2026-01-01T00:00:00Z',
    status: OrganizationProducerStatus.active,
  );
  const enrolledAccount = ProducerAccount(
    producerAccountId: producerId,
    name: 'Ferme des Collines',
    organizations: [
      ProducerOrganization(
        organizationId: orgId,
        associationInstant: '2026-01-01T00:00:00Z',
        status: OrganizationProducerStatus.active,
      ),
    ],
  );
  const accountChange = Change(
    entityType: EntityType.producerAccount,
    entityId: producerId,
    op: ChangeOp.upsert,
    payload: ProducerAccountPayload(producerAccount: enrolledAccount),
    producedAt: 2,
  );

  Future<List<ProducerAccount>> cachedAccounts() =>
      ProducerAccountRepository(db: db).watchAll().first;

  SyncResponse incremental(String scopeKey, List<Change> changes) =>
      SyncResponse(
        authorizedScopes: [scopeKey],
        results: {
          scopeKey: IncrementalScopeSyncResult(
            changes: changes,
            nextCursor: 'c1',
          ),
        },
      );

  test('${story.title} [${story.id}] — admin enrolls the producer', () async {
    const org = Organization(
      organizationId: orgId,
      name: 'AMAP des Collines',
      contactEmail: 'contact@amap.example.com',
    );
    await db.upsertOrganization(org);
    await db.writeCursor(orgScope, 'c0');

    const products = [
      OrgProduct(
        name: 'Légumes',
        productTypeId: 'pt-vegetables',
        producerAccountId: producerId,
        supportedBasketSizes: [BasketSize(name: 'small')],
      ),
    ];
    await OrganizationRepository(
      db: db,
      idGenerator: _SequenceIdGenerator(['op-enroll']),
    ).enrollProducer(
      currentOrg: org,
      producerAccountId: producerId,
      products: products,
    );

    // Enrolling is an Organization upsert only: no ProducerAccount mutation.
    final pending = await db.readPendingMutations();
    final sentOrg =
        ((pending.single.op as Upsert).payload as OrganizationPayload)
            .organization;
    expect(sentOrg.producers.single.producerAccountId, producerId);
    expect(sentOrg.producers.single.status, OrganizationProducerStatus.active);
    expect(sentOrg.products, products);
    // Before the sync the admin only knows the producer by its id.
    expect(await cachedAccounts(), isEmpty);

    final serverOrg = org.copyWith(producers: [link], products: products);
    api = _ScriptedSyncApi([
      _ExpectedSyncCall(
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
                  payload: OrganizationPayload(organization: serverOrg),
                  producedAt: 1,
                ),
                accountChange,
              ],
              nextCursor: 'c1',
            ),
          },
          mutations: const [
            MutationOutcome(
              clientOpId: 'op-enroll',
              status: MutationStatus.applied,
              serverEntityId: orgId,
            ),
          ],
        ),
      ),
    ]);
    expect(
      await SyncRepository(db: db, api: api).sync(tenantId: orgId),
      isA<SyncSuccess>(),
    );

    expect(await db.readPendingMutations(), isEmpty);
    expect((await db.watchOrganization(orgId).first)!.producers, [link]);
    // The AMAP now resolves the producer's name (not its technical id).
    expect((await cachedAccounts()).single.name, 'Ferme des Collines');
  });

  test('${story.title} [${story.id}] — the owner lists the producer', () async {
    await db.writeCursor('instance-owner', 'c0');
    api = _ScriptedSyncApi([
      _ExpectedSyncCall(
        request: const SyncRequest(cursors: {'instance-owner': 'c0'}),
        response: incremental('instance-owner', const [accountChange]),
      ),
    ]);
    expect(
      await SyncRepository(db: db, api: api).sync(tenantId: 'owner-tenant'),
      isA<SyncSuccess>(),
    );

    expect(await cachedAccounts(), const [enrolledAccount]);
  });

  test(
    '${story.title} [${story.id}] — the producer sees its new AMAP',
    () async {
      const producerScope = 'producer-account:$producerId';
      await db.upsertProducerAccount(
        producerId,
        enrolledAccount.copyWith(organizations: const []),
      );
      await db.writeCursor(producerScope, 'c0');
      api = _ScriptedSyncApi([
        _ExpectedSyncCall(
          request: const SyncRequest(cursors: {producerScope: 'c0'}),
          response: incremental(producerScope, const [accountChange]),
        ),
      ]);
      expect(
        await SyncRepository(db: db, api: api).sync(tenantId: producerId),
        isA<SyncSuccess>(),
      );

      final mine = await ProducerAccountRepository(
        db: db,
      ).watchMine(producerId).first;
      expect(mine!.organizations.map((o) => o.organizationId), [orgId]);
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
    expect(request, call.request);
    return call.response;
  }
}

class _ExpectedSyncCall {
  const _ExpectedSyncCall({required this.request, required this.response});

  final SyncRequest request;
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
