import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_snapshot.freezed.dart';
part 'entity_snapshot.g.dart';

@freezed
abstract class EntitySnapshot with _$EntitySnapshot {
  const factory EntitySnapshot({
    @Default(<EntityPayload>[]) List<EntityPayload> items,
    required String cursor,
  }) = _EntitySnapshot;

  factory EntitySnapshot.fromJson(Map<String, Object?> json) =>
      _$EntitySnapshotFromJson(json);
}
