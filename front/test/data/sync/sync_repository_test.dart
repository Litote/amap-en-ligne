import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/product_type_fixtures.dart';

class _MockSyncApi extends Mock implements SyncApi {}

class _FakeSyncRequest extends Fake implements SyncRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSyncRequest());
  });

  late AppDatabase db;
  late _MockSyncApi api;
  late SyncRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _MockSyncApi();
    repo = SyncRepository(db: db, api: api);
  });

  tearDown(() async {
    await db.close();
  });

  group('scope bootstrap', () {
    test(
      'replaces local rows with the bootstrap and stores the scope cursor',
      () async {
        await db.upsertProductType(
          buildProductType(productTypeId: 'pt-old', name: 'Stale'),
        );

        final fresh = buildProductType(
          supportedBasketSizes: const [smallBasketSize],
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => SyncResponse(
            authorizedScopes: const [testProducerScopeKey],
            results: {
              testProducerScopeKey: BootstrapScopeSyncResult(
                items: [ProductTypePayload(productType: fresh)],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        expect(await db.watchProductTypes(testTenantId).first, [fresh]);
        expect(await db.readCursor(testProducerScopeKey), 'c1');
      },
    );

    test(
      'bootstrap returned after incremental clears stale local scope data',
      () async {
        await db.writeCursor(testProducerScopeKey, 'c0');
        await db.upsertProductType(buildProductType(productTypeId: 'pt-stale'));

        when(() => api.sync(any())).thenAnswer(
          (_) async => SyncResponse(
            authorizedScopes: const [testProducerScopeKey],
            results: {
              testProducerScopeKey: BootstrapScopeSyncResult(
                items: [
                  ProductTypePayload(
                    productType: buildProductType(productTypeId: 'pt-fresh'),
                  ),
                ],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        await repo.sync(tenantId: testTenantId);

        final rows = await db.watchProductTypes(testTenantId).first;
        expect(rows.map((row) => row.productTypeId), ['pt-fresh']);
        expect(await db.readCursor(testProducerScopeKey), 'c1');
      },
    );

    test(
      'organization bootstrap stores synced member join requests locally',
      () async {
        const scopeKey = 'organization:org-1';
        const request = AdminMemberJoinRequest(
          requestId: 'req-1',
          organizationId: 'org-1',
          email: 'alice@example.org',
          firstName: 'Alice',
          lastName: 'Martin',
          status: MemberJoinRequestStatus.pending,
          submittedAt: '2026-01-01T00:00:00Z',
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [scopeKey],
            results: {
              scopeKey: BootstrapScopeSyncResult(
                items: [MemberJoinRequestPayload(memberJoinRequest: request)],
                nextCursor: 'c-join-1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        expect(await db.watchMemberJoinRequests('org-1').first, [request]);
        expect(await db.readCursor(scopeKey), 'c-join-1');
      },
    );

    test(
      'instance-owner bootstrap stores synced producer requests locally',
      () async {
        const request = AdminProducerRequest(
          requestId: 'producer-req-1',
          producerName: 'Ferme des Collines',
          adminFirstName: 'Alice',
          adminLastName: 'Martin',
          adminEmail: 'alice@example.org',
          status: ProducerRequestStatus.pendingValidation,
          submittedAt: '2026-01-01T00:00:00Z',
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [instanceOwnerScopeKey],
            results: {
              instanceOwnerScopeKey: BootstrapScopeSyncResult(
                items: [ProducerRequestPayload(producerRequest: request)],
                nextCursor: 'c-producer-request-1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        expect(await db.watchProducerRequests().first, [request]);
        expect(
          await db.readCursor(instanceOwnerScopeKey),
          'c-producer-request-1',
        );
      },
    );
  });

  group('scope incremental', () {
    test('UPSERT change applies and advances the scope cursor', () async {
      await db.writeCursor(testProducerScopeKey, 'c0');

      final updated = buildProductType(name: 'New name');

      when(() => api.sync(any())).thenAnswer(
        (_) async => SyncResponse(
          authorizedScopes: const [testProducerScopeKey],
          results: {
            testProducerScopeKey: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.productType,
                  entityId: 'pt-1',
                  op: ChangeOp.upsert,
                  payload: ProductTypePayload(productType: updated),
                  producedAt: 1,
                ),
              ],
              nextCursor: 'c1',
            ),
          },
        ),
      );

      await repo.sync(tenantId: testTenantId);

      final rows = await db.watchProductTypes(testTenantId).first;
      expect(rows.single.name, 'New name');
      expect(await db.readCursor(testProducerScopeKey), 'c1');
    });

    test('DELETE change removes the local row', () async {
      await db.upsertProductType(buildProductType(name: 'X'));
      await db.writeCursor(testProducerScopeKey, 'c0');

      when(() => api.sync(any())).thenAnswer(
        (_) async => const SyncResponse(
          authorizedScopes: [testProducerScopeKey],
          results: {
            testProducerScopeKey: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.productType,
                  entityId: 'pt-1',
                  op: ChangeOp.delete,
                  producedAt: 1,
                ),
              ],
              nextCursor: 'c1',
            ),
          },
        ),
      );

      await repo.sync(tenantId: testTenantId);

      expect(await db.watchProductTypes(testTenantId).first, isEmpty);
    });
  });

  group('authorized scopes', () {
    test('request uses stored scope cursors only', () async {
      await db.writeCursor(testProducerScopeKey, 'cX');
      final mutation = buildProductTypeDeleteMutation();
      await db.enqueuePendingMutation(mutation, scopeKey: testProducerScopeKey);

      when(() => api.sync(any())).thenAnswer(
        (_) async => const SyncResponse(
          authorizedScopes: [testProducerScopeKey],
          mutations: [
            MutationOutcome(
              clientOpId: 'op-1',
              status: MutationStatus.applied,
              serverEntityId: 'pt-1',
            ),
          ],
        ),
      );

      await repo.sync(tenantId: testTenantId);

      final captured =
          verify(() => api.sync(captureAny())).captured.single as SyncRequest;
      expect(captured.cursors, {'producer-account:producer-1': 'cX'});
      expect(captured.mutations.single.clientOpId, 'op-1');
    });

    test(
      'scope disappearance clears only that scope data and pending queue',
      () async {
        const org1Scope = 'organization:org-1';
        const org2Scope = 'organization:org-2';

        await db.writeCursor(org1Scope, 'c-org-1');
        await db.writeCursor(org2Scope, 'c-org-2');
        await db.upsertMember(
          'org-1',
          const Member(memberId: 'm-1', organizationId: 'org-1'),
        );
        await db.upsertMember(
          'org-2',
          const Member(memberId: 'm-2', organizationId: 'org-2'),
        );
        await db.enqueuePendingMutation(
          const ClientMutation(
            clientOpId: 'op-org-1',
            op: Delete(entityType: EntityType.member, entityId: 'm-1'),
          ),
          scopeKey: org1Scope,
        );
        await db.enqueuePendingMutation(
          const ClientMutation(
            clientOpId: 'op-org-2',
            op: Delete(entityType: EntityType.member, entityId: 'm-2'),
          ),
          scopeKey: org2Scope,
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [org1Scope],
            results: {
              org1Scope: IncrementalScopeSyncResult(nextCursor: 'c-org-1b'),
            },
          ),
        );

        await repo.sync(tenantId: testTenantId);

        expect(await db.watchMembers('org-1').first, hasLength(1));
        expect(await db.watchMembers('org-2').first, isEmpty);
        expect(await db.readCursor(org1Scope), 'c-org-1b');
        expect(await db.readCursor(org2Scope), isNull);
        expect((await db.readPendingMutations()).map((m) => m.clientOpId), [
          'op-org-1',
        ]);
      },
    );

    test(
      'successful sync drops legacy pending rows that still have no scope',
      () async {
        await db.customStatement(
          'INSERT INTO pending_mutations (client_op_id, scope_key, payload_json, created_at) '
          'VALUES (?, NULL, ?, ?)',
          [
            'op-legacy',
            '{"client_op_id":"op-legacy","op":{"type":"Delete","entity_type":"Member","entity_id":"member-missing"}}',
            1,
          ],
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [testProducerScopeKey],
            results: {
              testProducerScopeKey: IncrementalScopeSyncResult(
                nextCursor: 'c1',
              ),
            },
          ),
        );

        await repo.sync(tenantId: testTenantId);

        final captured =
            verify(() => api.sync(captureAny())).captured.single as SyncRequest;
        expect(captured.mutations, isEmpty);
        expect(await db.readPendingMutations(), isEmpty);
      },
    );
  });

  group('mutation reconciliation', () {
    test(
      'APPLIED with serverEntityId remaps tmp_ id and drains pending',
      () async {
        final tmp = buildProductType(productTypeId: 'tmp_abc');
        await db.upsertProductType(tmp);
        final mutation = buildProductTypeUpsertMutation(productType: tmp);
        await db.enqueuePendingMutation(
          mutation,
          scopeKey: testProducerScopeKey,
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [testProducerScopeKey],
            mutations: [
              MutationOutcome(
                clientOpId: 'op-1',
                status: MutationStatus.applied,
                serverEntityId: 'pt-real-1',
              ),
            ],
          ),
        );

        await repo.sync(tenantId: testTenantId);

        final rows = await db.watchProductTypes(testTenantId).first;
        expect(rows.single.productTypeId, 'pt-real-1');
        expect(await db.readPendingMutations(), isEmpty);
      },
    );

    test(
      'rewrites still-pending queued mutations that reference a remapped tmp id',
      () async {
        final tmp = buildProductType(productTypeId: 'tmp_abc', name: 'Draft');
        await db.upsertProductType(tmp);
        await db.enqueuePendingMutation(
          buildProductTypeUpsertMutation(productType: tmp),
          scopeKey: testProducerScopeKey,
        );

        when(() => api.sync(any())).thenAnswer((_) async {
          await db.enqueuePendingMutation(
            ClientMutation(
              clientOpId: 'op-2',
              op: Upsert(
                payload: ProductTypePayload(
                  productType: tmp.copyWith(name: 'Draft updated'),
                ),
              ),
            ),
            scopeKey: testProducerScopeKey,
          );
          return const SyncResponse(
            authorizedScopes: [testProducerScopeKey],
            mutations: [
              MutationOutcome(
                clientOpId: 'op-1',
                status: MutationStatus.applied,
                serverEntityId: 'pt-real-1',
              ),
            ],
          );
        });

        await repo.sync(tenantId: testTenantId);

        final pending = await db.readPendingMutations();
        expect(pending, hasLength(1));
        final op = pending.single.op as Upsert;
        final payload = op.payload as ProductTypePayload;
        expect(payload.productType.productTypeId, 'pt-real-1');
      },
    );

    test(
      'member tmp id is remapped locally when the outcome returns serverEntityId',
      () async {
        const orgScope = 'organization:org-1';
        const tmpMember = Member(
          memberId: 'tmp_member',
          organizationId: 'org-1',
        );
        await db.upsertMember('org-1', tmpMember);
        await db.enqueuePendingMutation(
          const ClientMutation(
            clientOpId: 'op-member',
            op: Upsert(payload: MemberPayload(member: tmpMember)),
          ),
          scopeKey: orgScope,
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [orgScope],
            mutations: [
              MutationOutcome(
                clientOpId: 'op-member',
                status: MutationStatus.applied,
                serverEntityId: 'member-1',
              ),
            ],
          ),
        );

        await repo.sync(tenantId: testTenantId);

        final members = await db.watchMembers('org-1').first;
        expect(members.single.memberId, 'member-1');
      },
    );

    test(
      'producer tmp id remaps local rows and queued organization references',
      () async {
        const orgScope = 'organization:org-1';
        const tmpProducer = ProducerAccount(
          producerAccountId: 'tmp_producer-1',
          name: 'Ferme locale',
          managementMode: ProducerManagementMode.noAccount,
        );
        const organization = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'contact@amap.fr',
          producers: [
            OrganizationProducer(
              producerAccountId: 'tmp_producer-1',
              associationInstant: '2025-01-01T00:00:00Z',
              status: OrganizationProducerStatus.active,
            ),
          ],
          products: [
            OrgProduct(
              name: 'Tomates',
              productTypeId: 'tmp_pt-1',
              producerAccountId: 'tmp_producer-1',
            ),
          ],
        );

        await db.upsertProducerAccount(
          tmpProducer.producerAccountId,
          tmpProducer,
        );
        await db.upsertOrganization(organization);
        await db.enqueuePendingMutation(
          const ClientMutation(
            clientOpId: 'op-producer',
            op: Upsert(
              payload: ProducerAccountPayload(producerAccount: tmpProducer),
            ),
          ),
          scopeKey: orgScope,
        );

        when(() => api.sync(any())).thenAnswer((_) async {
          await db.enqueuePendingMutation(
            const ClientMutation(
              clientOpId: 'op-org',
              op: Upsert(
                payload: OrganizationPayload(organization: organization),
              ),
            ),
            scopeKey: orgScope,
          );
          return const SyncResponse(
            authorizedScopes: [orgScope],
            mutations: [
              MutationOutcome(
                clientOpId: 'op-producer',
                status: MutationStatus.applied,
                serverEntityId: 'pa-real-1',
              ),
            ],
          );
        });

        await repo.sync(tenantId: testTenantId);

        final storedProducer = await db
            .watchProducerAccountById('pa-real-1')
            .first;
        expect(storedProducer, isNotNull);
        final storedOrg = await db.watchOrganization('org-1').first;
        expect(storedOrg!.producers.single.producerAccountId, 'pa-real-1');
        expect(storedOrg.products.single.producerAccountId, 'pa-real-1');

        final pending = await db.readPendingMutations();
        expect(pending, hasLength(1));
        final payload =
            (pending.single.op as Upsert).payload as OrganizationPayload;
        expect(
          payload.organization.producers.single.producerAccountId,
          'pa-real-1',
        );
      },
    );

    test(
      'contract tmp id is remapped in pending OrganizationPayload mutations',
      () async {
        const orgScope = 'organization:org-1';
        const tmpContractId = 'tmp_contract-1';
        const tmpContract = Contract(
          contractId: tmpContractId,
          name: 'Contrat test',
          organizationId: 'org-1',
          producerAccountId: 'pa-1',
          minDeliveryDate: '2026-01-05',
          maxDeliveryDate: '2026-01-26',
          deliveryCount: 4,
          seasonYear: 2026,
        );

        // An organization mutation that references the tmp contract id in
        // a delivery's contracts list — queued after the contract mutation.
        const orgWithTmpRef = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'contact@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: 'del-1',
              organizationId: 'org-1',
              scheduledDate: '2026-01-05T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 1,
              contracts: [
                DeliveryContract(
                  contractId: tmpContractId,
                  basketQuantity: 0,
                  deliveryDescription: 'Contrat test',
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

        when(() => api.sync(any())).thenAnswer((_) async {
          // Simulate the org mutation being queued during sync (as in the
          // real flow where it is sent immediately after the contract).
          await db.enqueuePendingMutation(
            const ClientMutation(
              clientOpId: 'op-org',
              op: Upsert(
                payload: OrganizationPayload(organization: orgWithTmpRef),
              ),
            ),
            scopeKey: orgScope,
          );
          return const SyncResponse(
            authorizedScopes: [orgScope],
            mutations: [
              MutationOutcome(
                clientOpId: 'op-contract',
                status: MutationStatus.applied,
                serverEntityId: 'contract-real-1',
              ),
            ],
          );
        });

        await repo.sync(tenantId: testTenantId);

        // The pending org mutation should now reference the real contract id.
        final pending = await db.readPendingMutations();
        expect(pending, hasLength(1));
        final payload =
            (pending.single.op as Upsert).payload as OrganizationPayload;
        final deliveryContract =
            payload.organization.deliveries.single.contracts.single;
        expect(deliveryContract.contractId, 'contract-real-1');

        // The stored organization should also reference the real contract id.
        final storedOrg = await db.watchOrganization('org-1').first;
        expect(
          storedOrg!.deliveries.single.contracts.single.contractId,
          'contract-real-1',
        );
      },
    );

    test(
      'legacy delete without scope inherits scope and rewritten id after tmp remap',
      () async {
        const orgScope = 'organization:org-1';
        const tmpMember = Member(
          memberId: 'tmp_member',
          organizationId: 'org-1',
        );
        await db.upsertMember('org-1', tmpMember);
        await db.customStatement(
          'INSERT INTO pending_mutations (client_op_id, scope_key, payload_json, created_at) '
          'VALUES (?, NULL, ?, ?)',
          [
            'op-member-upsert',
            jsonEncode(
              const ClientMutation(
                clientOpId: 'op-member-upsert',
                op: Upsert(payload: MemberPayload(member: tmpMember)),
              ),
            ),
            1,
          ],
        );
        await db.customStatement(
          'INSERT INTO pending_mutations (client_op_id, scope_key, payload_json, created_at) '
          'VALUES (?, NULL, ?, ?)',
          [
            'op-member-delete',
            jsonEncode(
              const ClientMutation(
                clientOpId: 'op-member-delete',
                op: Delete(
                  entityType: EntityType.member,
                  entityId: 'tmp_member',
                ),
              ),
            ),
            2,
          ],
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [orgScope],
            mutations: [
              MutationOutcome(
                clientOpId: 'op-member-upsert',
                status: MutationStatus.applied,
                serverEntityId: 'member-1',
              ),
            ],
          ),
        );

        await repo.sync(tenantId: testTenantId);

        final pending = await db.readPendingMutationEntries();
        expect(pending, hasLength(1));
        expect(pending.single.scopeKey, orgScope);
        final delete = pending.single.mutation.op as Delete;
        expect(delete.entityId, 'member-1');
      },
    );

    test('REJECTED is surfaced and pending entry is still drained', () async {
      final mutation = buildProductTypeDeleteMutation(
        clientOpId: 'op-bad',
        entityId: 'tmp_xxx',
      );
      await db.enqueuePendingMutation(mutation, scopeKey: testProducerScopeKey);

      when(() => api.sync(any())).thenAnswer(
        (_) async => const SyncResponse(
          authorizedScopes: [testProducerScopeKey],
          mutations: [
            MutationOutcome(
              clientOpId: 'op-bad',
              status: MutationStatus.rejected,
              error: MutationError(
                code: MutationErrorCode.invalidPayload,
                message: 'cannot delete a temporary id',
              ),
            ),
          ],
        ),
      );

      final outcome = await repo.sync(tenantId: testTenantId);

      expect(outcome, isA<SyncSuccess>());
      final success = outcome as SyncSuccess;
      expect(success.rejectedMutations.single.clientOpId, 'op-bad');
      expect(await db.readPendingMutations(), isEmpty);
    });
  });

  group('failure modes', () {
    test('returns SyncFailure when the API throws DioException', () async {
      when(() => api.sync(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/sync'),
          message: 'boom',
        ),
      );
      final outcome = await repo.sync(tenantId: testTenantId);
      expect(outcome, isA<SyncFailure>());
      expect((outcome as SyncFailure).message, 'boom');
    });

    test(
      'returns SyncNetworkFailure when the connection fails (server unreachable)',
      () async {
        when(() => api.sync(any())).thenThrow(
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/v1/sync'),
            reason: 'connection refused',
          ),
        );
        final outcome = await repo.sync(tenantId: testTenantId);
        expect(outcome, isA<SyncNetworkFailure>());
      },
    );

    test('returns SyncNetworkFailure on connection timeout', () async {
      when(() => api.sync(any())).thenThrow(
        DioException.connectionTimeout(
          requestOptions: RequestOptions(path: '/v1/sync'),
          timeout: const Duration(seconds: 5),
        ),
      );
      final outcome = await repo.sync(tenantId: testTenantId);
      expect(outcome, isA<SyncNetworkFailure>());
    });

    test(
      'returns SyncNetworkFailure when an unknown DioException wraps a SocketException',
      () async {
        when(() => api.sync(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/sync'),
            error: const SocketException('Network is unreachable'),
          ),
        );
        final outcome = await repo.sync(tenantId: testTenantId);
        expect(outcome, isA<SyncNetworkFailure>());
      },
    );

    test(
      'returns SyncFailure (not SyncNetworkFailure) on an HTTP error response',
      () async {
        final requestOptions = RequestOptions(path: '/v1/sync');
        when(() => api.sync(any())).thenThrow(
          DioException.badResponse(
            statusCode: 500,
            requestOptions: requestOptions,
            response: Response(requestOptions: requestOptions, statusCode: 500),
          ),
        );
        final outcome = await repo.sync(tenantId: testTenantId);
        expect(outcome, isA<SyncFailure>());
      },
    );

    test('pending mutations stay queued after a network failure', () async {
      final mutation = buildProductTypeUpsertMutation(clientOpId: 'op-offline');
      await db.enqueuePendingMutation(mutation, scopeKey: testProducerScopeKey);
      when(() => api.sync(any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/v1/sync'),
          reason: 'connection refused',
        ),
      );

      await repo.sync(tenantId: testTenantId);

      expect(await db.readPendingMutations(), hasLength(1));
    });

    test(
      'StateError from missing entity handler returns SyncFailure not a crash',
      () async {
        final repoNoHandlers = SyncRepository(db: db, api: api, handlers: {});
        when(() => api.sync(any())).thenAnswer(
          (_) async => SyncResponse(
            authorizedScopes: const [testProducerScopeKey],
            results: {
              testProducerScopeKey: BootstrapScopeSyncResult(
                items: [ProductTypePayload(productType: buildProductType())],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        final outcome = await repoNoHandlers.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncFailure>());
      },
    );
  });

  group('other entities', () {
    const orgScope = 'organization:org-1';

    final template = DeliveryTemplate(
      deliveryTemplateId: 'dt-1',
      organizationId: 'org-1',
      name: 'Livraison standard',
      standardStartTime: '18:00',
      standardEndTime: '20:00',
    );

    final owner = Owner(
      ownerId: 'o-1',
      firstName: 'Alice',
      lastName: 'Martin',
      email: 'alice@example.com',
      accountStatus: AccountStatus.active,
      registeredAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );

    test('organization-scoped bootstrap inserts delivery templates', () async {
      when(() => api.sync(any())).thenAnswer(
        (_) async => SyncResponse(
          authorizedScopes: const [orgScope],
          results: {
            orgScope: BootstrapScopeSyncResult(
              items: [DeliveryTemplatePayload(deliveryTemplate: template)],
              nextCursor: 'c-dt-1',
            ),
          },
        ),
      );

      await repo.sync(tenantId: testTenantId);

      final rows = await db.watchDeliveryTemplates('org-1').first;
      expect(rows.single.deliveryTemplateId, 'dt-1');
      expect(await db.readCursor(orgScope), 'c-dt-1');
    });

    test('instance-owner incremental applies owner delete', () async {
      await db.upsertOwner(owner);

      when(() => api.sync(any())).thenAnswer(
        (_) async => const SyncResponse(
          authorizedScopes: [instanceOwnerScopeKey],
          results: {
            instanceOwnerScopeKey: IncrementalScopeSyncResult(
              changes: [
                Change(
                  entityType: EntityType.owner,
                  entityId: 'o-1',
                  op: ChangeOp.delete,
                  producedAt: 1,
                ),
              ],
              nextCursor: 'c-owner-1',
            ),
          },
        ),
      );

      await repo.sync(tenantId: testTenantId);

      expect(await db.watchOwners().first, isEmpty);
    });

    test(
      'instance-owner incremental applies producer request delete',
      () async {
        await db.upsertProducerRequest(
          const AdminProducerRequest(
            requestId: 'producer-req-1',
            producerName: 'Ferme des Collines',
            adminFirstName: 'Alice',
            adminLastName: 'Martin',
            adminEmail: 'alice@example.org',
            status: ProducerRequestStatus.pendingValidation,
            submittedAt: '2026-01-01T00:00:00Z',
          ),
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [instanceOwnerScopeKey],
            results: {
              instanceOwnerScopeKey: IncrementalScopeSyncResult(
                changes: [
                  Change(
                    entityType: EntityType.producerRequest,
                    entityId: 'producer-req-1',
                    op: ChangeOp.delete,
                    producedAt: 1,
                  ),
                ],
                nextCursor: 'c-producer-request-1',
              ),
            },
          ),
        );

        await repo.sync(tenantId: testTenantId);

        expect(await db.watchProducerRequests().first, isEmpty);
      },
    );

    test('organization bootstrap stores BasketExchange rows locally', () async {
      const orgScopeKey = 'organization:org-1';
      const exchange = BasketExchange(
        basketExchangeId: 'be-1',
        organizationId: 'org-1',
        deliveryId: 'd-1',
        contractId: 'c-1',
        offeringMemberId: 'm-1',
        status: BasketExchangeStatus.open,
        createdAt: '2026-05-20T10:00:00Z',
      );

      when(() => api.sync(any())).thenAnswer(
        (_) async => const SyncResponse(
          authorizedScopes: [orgScopeKey],
          results: {
            orgScopeKey: BootstrapScopeSyncResult(
              items: [BasketExchangePayload(basketExchange: exchange)],
              nextCursor: 'c-be-1',
            ),
          },
        ),
      );

      final outcome = await repo.sync(tenantId: testTenantId);

      expect(outcome, isA<SyncSuccess>());
      final rows = await db.watchBasketExchangesByOrg('org-1').first;
      expect(rows.length, 1);
      expect(rows.single.basketExchangeId, 'be-1');
      expect(rows.single.status, BasketExchangeStatus.open);
      expect(await db.readCursor(orgScopeKey), 'c-be-1');
    });

    test(
      'organization incremental UPSERT applies BasketExchange change',
      () async {
        const orgScopeKey = 'organization:org-1';
        await db.writeCursor(orgScopeKey, 'c0');

        const exchange = BasketExchange(
          basketExchangeId: 'be-2',
          organizationId: 'org-1',
          deliveryId: 'd-2',
          contractId: 'c-2',
          offeringMemberId: 'm-2',
          status: BasketExchangeStatus.open,
          createdAt: '2026-05-21T10:00:00Z',
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [orgScopeKey],
            results: {
              orgScopeKey: IncrementalScopeSyncResult(
                changes: [
                  Change(
                    entityType: EntityType.basketExchange,
                    entityId: 'be-2',
                    op: ChangeOp.upsert,
                    payload: BasketExchangePayload(basketExchange: exchange),
                    producedAt: 1,
                  ),
                ],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        await repo.sync(tenantId: testTenantId);

        final rows = await db.watchBasketExchangesByOrg('org-1').first;
        expect(rows.single.basketExchangeId, 'be-2');
        expect(await db.readCursor(orgScopeKey), 'c1');
      },
    );
  });

  group('role refresh detection', () {
    const orgScopeKey = 'organization:org-1';

    test(
      'memberOrOwnerUpdated is false when sync contains no Member or Owner payloads',
      () async {
        when(() => api.sync(any())).thenAnswer(
          (_) async => SyncResponse(
            authorizedScopes: const [testProducerScopeKey],
            results: {
              testProducerScopeKey: BootstrapScopeSyncResult(
                items: [ProductTypePayload(productType: buildProductType())],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        expect((outcome as SyncSuccess).memberOrOwnerUpdated, isFalse);
      },
    );

    test(
      'memberOrOwnerUpdated is true when bootstrap contains a Member payload',
      () async {
        when(() => api.sync(any())).thenAnswer(
          (_) async => SyncResponse(
            authorizedScopes: const [orgScopeKey],
            results: {
              orgScopeKey: BootstrapScopeSyncResult(
                items: const [
                  MemberPayload(
                    member: Member(memberId: 'm-1', organizationId: 'org-1'),
                  ),
                ],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        expect((outcome as SyncSuccess).memberOrOwnerUpdated, isTrue);
      },
    );

    test(
      'memberOrOwnerUpdated is true when incremental contains a Member UPSERT change',
      () async {
        await db.writeCursor(orgScopeKey, 'c0');

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [orgScopeKey],
            results: {
              orgScopeKey: IncrementalScopeSyncResult(
                changes: [
                  Change(
                    entityType: EntityType.member,
                    entityId: 'm-1',
                    op: ChangeOp.upsert,
                    payload: MemberPayload(
                      member: Member(memberId: 'm-1', organizationId: 'org-1'),
                    ),
                    producedAt: 1,
                  ),
                ],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        expect((outcome as SyncSuccess).memberOrOwnerUpdated, isTrue);
      },
    );

    test(
      'memberOrOwnerUpdated is true when bootstrap contains an Owner payload',
      () async {
        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [instanceOwnerScopeKey],
            results: {
              instanceOwnerScopeKey: BootstrapScopeSyncResult(
                items: [
                  OwnerPayload(
                    owner: Owner(
                      ownerId: 'o-1',
                      firstName: 'Alice',
                      lastName: 'Martin',
                      email: 'alice@example.org',
                      accountStatus: AccountStatus.active,
                      registeredAt: '2026-01-01T00:00:00Z',
                      updatedAt: '2026-01-01T00:00:00Z',
                    ),
                  ),
                ],
                nextCursor: 'c-owner-1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        expect((outcome as SyncSuccess).memberOrOwnerUpdated, isTrue);
      },
    );

    test(
      'memberOrOwnerUpdated is false when incremental contains only a Member DELETE',
      () async {
        await db.writeCursor(orgScopeKey, 'c0');
        await db.upsertMember(
          'org-1',
          const Member(memberId: 'm-1', organizationId: 'org-1'),
        );

        when(() => api.sync(any())).thenAnswer(
          (_) async => const SyncResponse(
            authorizedScopes: [orgScopeKey],
            results: {
              orgScopeKey: IncrementalScopeSyncResult(
                changes: [
                  Change(
                    entityType: EntityType.member,
                    entityId: 'm-1',
                    op: ChangeOp.delete,
                    producedAt: 1,
                  ),
                ],
                nextCursor: 'c1',
              ),
            },
          ),
        );

        final outcome = await repo.sync(tenantId: testTenantId);

        expect(outcome, isA<SyncSuccess>());
        // DELETE does not indicate a role change — only UPSERT payloads do.
        expect((outcome as SyncSuccess).memberOrOwnerUpdated, isFalse);
      },
    );
  });
}
