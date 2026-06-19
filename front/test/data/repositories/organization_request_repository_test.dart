import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AdminOrganizationRequest _buildRequest({
  String requestId = 'req-1',
  OrganizationRequestStatus status =
      OrganizationRequestStatus.pendingValidation,
}) => AdminOrganizationRequest(
  requestId: requestId,
  organizationName: 'AMAP des Collines',
  organizationType: OrganizationType.amap,
  timezone: 'Europe/Paris',
  defaultLanguage: 'fr',
  adminFirstName: 'Alice',
  adminLastName: 'Martin',
  adminEmail: 'alice@collines.fr',
  status: status,
  submittedAt: '2026-05-07T10:00:00Z',
);

void main() {
  late AppDatabase db;
  late OrganizationRequestRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = OrganizationRequestRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('watch() emits from Drift stream', () async {
    final pending = _buildRequest();
    await db.upsertOrganizationRequest(pending);

    final rows = await repo.watch().first;
    expect(rows.length, 1);
    expect(rows.single.requestId, 'req-1');
  });

  test(
    'approve() sets status to approved and enqueues Upsert mutation',
    () async {
      final pending = _buildRequest();
      await db.upsertOrganizationRequest(pending);

      await repo.approve(pending);

      final rows = await db.watchOrganizationRequests().first;
      expect(rows.single.status, OrganizationRequestStatus.approved);
      expect(rows.single.reviewedAt, isNotNull);

      final mutations = await db.readPendingMutations();
      expect(mutations.length, 1);
      expect(mutations.single.op, isA<Upsert>());
      final upsert = mutations.single.op as Upsert;
      expect(upsert.payload, isA<OrganizationRequestPayload>());
      final req =
          (upsert.payload as OrganizationRequestPayload).organizationRequest;
      expect(req.status, OrganizationRequestStatus.approved);
      expect(req.requestId, 'req-1');
      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, instanceOwnerScopeKey);
    },
  );

  test('reject() with comment sets status to rejected and enqueues Upsert '
      'mutation with review comment', () async {
    final pending = _buildRequest();
    await db.upsertOrganizationRequest(pending);

    await repo.reject(pending, reviewComment: 'Dossier incomplet');

    final rows = await db.watchOrganizationRequests().first;
    expect(rows.single.status, OrganizationRequestStatus.rejected);
    expect(rows.single.reviewedAt, isNotNull);
    expect(rows.single.reviewComment, 'Dossier incomplet');

    final mutations = await db.readPendingMutations();
    expect(mutations.length, 1);
    final upsert = mutations.single.op as Upsert;
    final req =
        (upsert.payload as OrganizationRequestPayload).organizationRequest;
    expect(req.status, OrganizationRequestStatus.rejected);
    expect(req.reviewComment, 'Dossier incomplet');
  });

  test(
    'reject() without comment enqueues Upsert with null reviewComment',
    () async {
      final pending = _buildRequest();
      await db.upsertOrganizationRequest(pending);

      await repo.reject(pending);

      final rows = await db.watchOrganizationRequests().first;
      expect(rows.single.reviewComment, isNull);

      final mutations = await db.readPendingMutations();
      final upsert = mutations.single.op as Upsert;
      final req =
          (upsert.payload as OrganizationRequestPayload).organizationRequest;
      expect(req.reviewComment, isNull);
    },
  );

  test(
    'resend() bumps resendRequestedAt and enqueues Upsert on instance-owner scope',
    () async {
      final approved = _buildRequest(
        status: OrganizationRequestStatus.approved,
      );
      await db.upsertOrganizationRequest(approved);

      final before = DateTime.now().toUtc();
      await repo.resend(approved);
      final after = DateTime.now().toUtc();

      final rows = await db.watchOrganizationRequests().first;
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
      final req =
          (upsert.payload as OrganizationRequestPayload).organizationRequest;
      expect(req.resendRequestedAt, isNotNull);
      expect(req.status, OrganizationRequestStatus.approved);

      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, instanceOwnerScopeKey);
    },
  );
}
