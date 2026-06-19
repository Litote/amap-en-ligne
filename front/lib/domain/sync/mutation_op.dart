import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutation_op.freezed.dart';

/// Discriminated union for client-submitted mutations.
/// Wire `type` is `Upsert` or `Delete` (matches back `@SerialName`).
sealed class MutationOp {
  const MutationOp();

  Map<String, dynamic> toJson();

  factory MutationOp.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'Upsert' => Upsert.fromJson(json),
        'Delete' => Delete.fromJson(json),
        final t => throw FormatException('Unknown MutationOp type: $t'),
      };
}

@Freezed(toJson: false, fromJson: false)
abstract class Upsert extends MutationOp with _$Upsert {
  const Upsert._() : super();
  const factory Upsert({required EntityPayload payload}) = _Upsert;

  factory Upsert.fromJson(Map<String, dynamic> json) => Upsert(
    payload: EntityPayload.fromJson(json['payload'] as Map<String, dynamic>),
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Upsert',
    'payload': payload.toJson(),
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class Delete extends MutationOp with _$Delete {
  const Delete._() : super();
  const factory Delete({
    required EntityType entityType,
    required String entityId,
  }) = _Delete;

  factory Delete.fromJson(Map<String, dynamic> json) => Delete(
    entityType: entityTypeFromWire(json['entity_type'] as String),
    entityId: json['entity_id'] as String,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Delete',
    'entity_type': entityTypeWireNames[entityType]!,
    'entity_id': entityId,
  };
}
