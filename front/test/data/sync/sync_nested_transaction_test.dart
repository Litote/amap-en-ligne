import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/data/sync/handlers/owner_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncApi extends Mock implements SyncApi {}

class _FakeSyncRequest extends Fake implements SyncRequest {}

/// Counts transactions opened while another transaction is already active.
///
/// On web with cross-origin isolation (COOP/COEP), drift runs on the OPFS
/// locks storage, where a nested transaction never commits: the enclosing
/// sync transaction hangs forever. The `tmp_*` remap helpers run inside the
/// sync transaction, so they must never open one of their own.
class _NestedTransactionCounter extends QueryInterceptor {
  int nested = 0;

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    if (parent is TransactionExecutor) nested++;
    return super.beginTransaction(parent);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSyncRequest());
  });

  late _NestedTransactionCounter counter;
  late AppDatabase db;

  setUp(() {
    counter = _NestedTransactionCounter();
    db = AppDatabase(NativeDatabase.memory().interceptWith(counter));
  });

  tearDown(() async {
    await db.close();
  });

  test('tmp id remap helpers do not open nested transactions', () async {
    await db.transaction(() async {
      await db.remapProductTypeId(
        producerAccountId: 'pa',
        oldId: 'tmp_1',
        newId: 'real',
      );
      await db.remapProducerAccountId(oldId: 'tmp_1', newId: 'real');
      await db.remapOwnerInvitationId(oldId: 'tmp_1', newId: 'real');
      await db.remapBasketExchangeId(oldId: 'tmp_1', newId: 'real');
      await db.remapMemberId(
        organizationId: 'org',
        oldId: 'tmp_1',
        newId: 'real',
      );
      await db.remapMemberInvitationId(
        organizationId: 'org',
        oldId: 'tmp_1',
        newId: 'real',
      );
      await db.remapContractId(
        organizationId: 'org',
        oldId: 'tmp_1',
        newId: 'real',
      );
      await db.remapDeliveryTemplateId(
        organizationId: 'org',
        oldId: 'tmp_1',
        newId: 'real',
      );
      await db.remapDeviceTokenId(
        recipientScope: 'member:sub',
        oldId: 'tmp_1',
        newId: 'real',
      );
      await db.remapAttendanceEmailRequestId(oldId: 'tmp_1', newId: 'real');
      await db.remapErrorReportId(oldId: 'tmp_1', newId: 'real');
    });

    expect(counter.nested, 0);
  });

  test('owner tmp id remap does not open a nested transaction', () async {
    const owner = Owner(
      ownerId: 'tmp_owner',
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@example.com',
      registeredAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );
    await db.upsertOwner(owner);

    await db.transaction(
      () => const OwnerSyncHandler().remapTmpId(
        db,
        payload: const OwnerPayload(owner: owner),
        serverEntityId: 'real-owner',
      ),
    );

    expect(counter.nested, 0);
    expect(await db.findOwnerById('real-owner'), isNotNull);
  });

  test(
    'owner invitation creation syncs without opening a nested transaction',
    () async {
      final api = _MockSyncApi();
      final repo = SyncRepository(db: db, api: api);
      final clientOpId = await OwnerInvitationRepository(
        db: db,
      ).create(firstName: 'Jane', lastName: 'Doe', email: 'jane@example.com');
      when(() => api.sync(any())).thenAnswer(
        (_) async => SyncResponse(
          authorizedScopes: const [instanceOwnerScopeKey],
          results: const {
            instanceOwnerScopeKey: IncrementalScopeSyncResult(
              changes: [],
              nextCursor: 'c1',
            ),
          },
          mutations: [
            MutationOutcome(
              clientOpId: clientOpId,
              status: MutationStatus.applied,
              serverEntityId: 'real-invitation',
            ),
          ],
        ),
      );

      final outcome = await repo.sync(tenantId: '');

      expect(outcome, isA<SyncSuccess>());
      expect(counter.nested, 0);
      final invitations = await db.getOwnerInvitations();
      expect(invitations.single.invitationId, 'real-invitation');
    },
  );
}
