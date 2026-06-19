import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _orgId = 'org-1';

DeliveryTemplate _buildTemplate({
  String templateId = 'dt-1',
  EarlySlot? earlySlot,
}) => DeliveryTemplate(
  deliveryTemplateId: templateId,
  organizationId: _orgId,
  name: 'Livraison standard',
  standardStartTime: '18:00',
  standardEndTime: '20:00',
  earlySlot: earlySlot,
);

void main() {
  late AppDatabase db;
  late DeliveryTemplateRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DeliveryTemplateRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('create writes a tmp_ id locally and enqueues Upsert', () async {
    final template = _buildTemplate();
    final created = await repo.create(template);

    final rows = await db.watchDeliveryTemplates(_orgId).first;
    expect(rows.length, 1);
    expect(rows.single.deliveryTemplateId, startsWith('tmp_'));
    expect(rows.single.name, 'Livraison standard');
    expect(created.deliveryTemplateId, rows.single.deliveryTemplateId);

    final pending = await db.readPendingMutations();
    expect(pending.length, 1);
    expect(pending.single.op, isA<Upsert>());
    final upsert = pending.single.op as Upsert;
    expect(upsert.payload, isA<DeliveryTemplatePayload>());
    final dt = (upsert.payload as DeliveryTemplatePayload).deliveryTemplate;
    expect(dt.deliveryTemplateId, startsWith('tmp_'));
    final entries = await db.readPendingMutationEntries();
    expect(entries.single.scopeKey, organizationScopeKey(_orgId));
  });

  test('update writes the template and enqueues Upsert with real id', () async {
    final template = _buildTemplate();
    await db.upsertDeliveryTemplate(_orgId, template);

    await repo.update(template.copyWith(name: 'Updated name'));

    final rows = await db.watchDeliveryTemplates(_orgId).first;
    expect(rows.single.name, 'Updated name');

    final pending = await db.readPendingMutations();
    expect(pending.length, 1);
    expect(pending.single.op, isA<Upsert>());
    final upsert = pending.single.op as Upsert;
    final dt = (upsert.payload as DeliveryTemplatePayload).deliveryTemplate;
    expect(dt.name, 'Updated name');
  });

  test(
    'create preserves early_slot and round-trips through the pending queue',
    () async {
      final template = _buildTemplate(
        earlySlot: const EarlySlot(
          arrivalTime: '17:00',
          explanation: 'Réception des légumes',
          maxVolunteers: 2,
        ),
      );
      await repo.create(template);

      final pending = await db.readPendingMutations();
      final upsert = pending.single.op as Upsert;
      final dt = (upsert.payload as DeliveryTemplatePayload).deliveryTemplate;
      expect(dt.earlySlot?.arrivalTime, '17:00');
      expect(dt.earlySlot?.maxVolunteers, 2);
    },
  );

  test('delete removes the row and enqueues a Delete mutation', () async {
    final template = _buildTemplate();
    await db.upsertDeliveryTemplate(_orgId, template);

    await repo.delete('dt-1', _orgId);

    expect(await db.watchDeliveryTemplates(_orgId).first, isEmpty);

    final pending = await db.readPendingMutations();
    expect(pending.length, 1);
    expect(pending.single.op, isA<Delete>());
    final delete = pending.single.op as Delete;
    expect(delete.entityType, EntityType.deliveryTemplate);
    expect(delete.entityId, 'dt-1');
    final entries = await db.readPendingMutationEntries();
    expect(entries.single.scopeKey, organizationScopeKey(_orgId));
  });

  test('watch is reactive to upserts', () async {
    final stream = repo.watch(_orgId);
    final emitted = <List<DeliveryTemplate>>[];
    final sub = stream.listen(emitted.add);

    await db.upsertDeliveryTemplate(_orgId, _buildTemplate());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(emitted.last.length, 1);
    expect(emitted.last.single.deliveryTemplateId, 'dt-1');
  });
}
