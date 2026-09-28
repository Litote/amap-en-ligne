import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/producer_schedule_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProducerScheduleRepository repo;

  const schedule = ProducerSchedule(
    organizationId: 'org-1',
    producerAccountId: 'pa-1',
    organizationName: 'AMAP',
    deliveries: [
      ProducerScheduleDelivery(
        deliveryId: 'd-1',
        scheduledDate: '2099-10-01T18:00',
        status: DeliveryStatus.planned,
      ),
      ProducerScheduleDelivery(
        deliveryId: 'd-2',
        scheduledDate: '2099-10-08T18:00',
        status: DeliveryStatus.planned,
      ),
    ],
  );
  const composition = [
    BasketDeliveryDescription(
      productTypeId: 'pt-1',
      basketSizeName: 'Petit',
      items: [DeliveryItem(itemTypeId: 'it-1', name: 'Brie')],
      itemsUpdatedAt: '2099-01-01T00:00:00.000Z',
    ),
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProducerScheduleRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
    await db.upsertProducerSchedule(schedule);
  });

  tearDown(() => db.close());

  test('updateBasketDescriptions rewrites the delivery locally and enqueues '
      'the schedule on the producer scope', () async {
    await repo.updateBasketDescriptions(
      schedule: schedule,
      deliveryId: 'd-2',
      basketDescriptions: composition,
    );

    final expected = schedule.copyWith(
      deliveries: [
        schedule.deliveries.first,
        schedule.deliveries.last.copyWith(basketDescriptions: composition),
      ],
    );
    expect((await repo.watch('pa-1').first).single, expected);
    final pending = await db.readPendingMutations();
    final upsert = pending.single.op as Upsert;
    expect(
      (upsert.payload as ProducerSchedulePayload).producerSchedule,
      expected,
    );
    expect(
      (await db.readPendingMutationEntries()).single.scopeKey,
      producerAccountScopeKey('pa-1'),
    );
  });
}
