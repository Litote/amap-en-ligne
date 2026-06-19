import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AdminProducerRequest _buildRequest({
  String requestId = 'req-1',
  ProducerRequestStatus status = ProducerRequestStatus.pendingValidation,
}) => AdminProducerRequest(
  requestId: requestId,
  producerName: 'Ferme des Collines',
  adminFirstName: 'Alice',
  adminLastName: 'Martin',
  adminEmail: 'alice@collines.fr',
  status: status,
  submittedAt: '2026-05-07T10:00:00Z',
);

void main() {
  late AppDatabase db;
  late ProducerRequestRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProducerRequestRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('watch() emits from Drift stream', () async {
    await db.upsertProducerRequest(_buildRequest());
    final rows = await repo.watch().first;
    expect(rows.single.requestId, 'req-1');
  });

  test('approve() updates local cache and enqueues Upsert mutation', () async {
    final pending = _buildRequest();
    await db.upsertProducerRequest(pending);

    await repo.approve(pending);

    final rows = await db.watchProducerRequests().first;
    expect(rows.single.status, ProducerRequestStatus.approved);
    expect(rows.single.reviewedAt, isNotNull);

    final mutations = await db.readPendingMutations();
    final upsert = mutations.single.op as Upsert;
    final request = (upsert.payload as ProducerRequestPayload).producerRequest;
    expect(request.status, ProducerRequestStatus.approved);

    final entries = await db.readPendingMutationEntries();
    expect(entries.single.scopeKey, instanceOwnerScopeKey);
  });

  test('reject() writes review comment into mutation payload', () async {
    final pending = _buildRequest();
    await db.upsertProducerRequest(pending);

    await repo.reject(pending, reviewComment: 'Dossier incomplet');

    final rows = await db.watchProducerRequests().first;
    expect(rows.single.status, ProducerRequestStatus.rejected);
    expect(rows.single.reviewComment, 'Dossier incomplet');

    final mutations = await db.readPendingMutations();
    final upsert = mutations.single.op as Upsert;
    final request = (upsert.payload as ProducerRequestPayload).producerRequest;
    expect(request.reviewComment, 'Dossier incomplet');
  });

  test(
    'resend() bumps resendRequestedAt and enqueues Upsert on instance-owner scope',
    () async {
      final approved = _buildRequest(status: ProducerRequestStatus.approved);
      await db.upsertProducerRequest(approved);

      final before = DateTime.now().toUtc();
      await repo.resend(approved);
      final after = DateTime.now().toUtc();

      final rows = await db.watchProducerRequests().first;
      expect(rows.single.resendRequestedAt, isNotNull);
      final resendAt = DateTime.parse(rows.single.resendRequestedAt!);
      expect(
        resendAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(resendAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);

      final mutations = await db.readPendingMutations();
      expect(mutations.length, 1);
      final upsert = mutations.single.op as Upsert;
      final request =
          (upsert.payload as ProducerRequestPayload).producerRequest;
      expect(request.resendRequestedAt, isNotNull);
      expect(request.status, ProducerRequestStatus.approved);

      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, instanceOwnerScopeKey);
    },
  );
}
