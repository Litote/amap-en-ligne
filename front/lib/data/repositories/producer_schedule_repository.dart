import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Access to the producer's AMAP schedules ([ProducerSchedule]),
/// server-derived projections synced on its `producer-account:{id}` feed.
///
/// The only write is the basket composition of the producer's own products
/// ([updateBasketDescriptions]): the back writes it back into the AMAP.
class ProducerScheduleRepository {
  ProducerScheduleRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<ProducerSchedule>> watch(String producerAccountId) =>
      _db.watchProducerSchedules(producerAccountId);

  /// Replaces the composition of [deliveryId] in [schedule] with
  /// [basketDescriptions] (the producer's products only): optimistic local
  /// write + a `ProducerSchedule` upsert on the producer's scope. The next
  /// sync brings back the server's version of the schedule.
  Future<void> updateBasketDescriptions({
    required ProducerSchedule schedule,
    required String deliveryId,
    required List<BasketDeliveryDescription> basketDescriptions,
  }) {
    final updated = schedule.copyWith(
      deliveries: [
        for (final delivery in schedule.deliveries)
          if (delivery.deliveryId == deliveryId)
            delivery.copyWith(basketDescriptions: basketDescriptions)
          else
            delivery,
      ],
    );
    return _db.transaction(() async {
      await _db.upsertProducerSchedule(updated);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(
            payload: ProducerSchedulePayload(producerSchedule: updated),
          ),
        ),
        scopeKey: producerAccountScopeKey(updated.producerAccountId),
      );
    });
  }
}
