import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/error_report_repository.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scopeKey = 'organization:org-1';
  late AppDatabase db;
  late ErrorReportRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ErrorReportRepository(db: db, idGenerator: IdGenerator(Random(0)));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create writes a tmp_ row locally and enqueues an Upsert on the provided scope',
    () async {
      await repo.create(
        errorMessage: 'Échec de la synchronisation : timeout',
        scopeKey: scopeKey,
      );

      final rows = await db.watchAllErrorReports().first;
      expect(rows.length, 1);
      final row = rows.single;
      expect(row.errorReportId.startsWith(ClientMutation.tmpIdPrefix), isTrue);
      expect(row.errorMessage, 'Échec de la synchronisation : timeout');
      expect(row.reportedAt.isNotEmpty, isTrue);

      final pending = await db.readPendingMutations();
      expect(pending.length, 1);
      final upsert = pending.single.op as Upsert;
      final payload = upsert.payload as ErrorReportPayload;
      expect(
        payload.errorReport.errorMessage,
        'Échec de la synchronisation : timeout',
      );
      expect(payload.errorReport.errorReportId, row.errorReportId);

      final entries = await db.readPendingMutationEntries();
      expect(entries.single.scopeKey, scopeKey);
    },
  );

  test('create generates a unique tmp_ id each time', () async {
    await repo.create(errorMessage: 'Error 1', scopeKey: scopeKey);
    await repo.create(errorMessage: 'Error 2', scopeKey: scopeKey);

    final rows = await db.watchAllErrorReports().first;
    expect(rows.length, 2);
    final ids = rows.map((r) => r.errorReportId).toSet();
    expect(ids.length, 2);

    final pending = await db.readPendingMutations();
    expect(pending.length, 2);
  });
}
