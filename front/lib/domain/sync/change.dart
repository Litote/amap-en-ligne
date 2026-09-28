import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'change.freezed.dart';
part 'change.g.dart';

@freezed
abstract class Change with _$Change {
  const factory Change({
    String? cursor,
    @JsonKey(name: 'entity_type') required EntityType entityType,
    @JsonKey(name: 'entity_id') required String entityId,
    @JsonKey(name: 'producer_account_id') String? producerAccountId,
    required ChangeOp op,
    EntityPayload? payload,
    @JsonKey(name: 'produced_at') required int producedAt,
  }) = _Change;

  factory Change.fromJson(Map<String, Object?> json) => _$ChangeFromJson(json);
}

enum ChangeOp {
  @JsonValue('UPSERT')
  upsert,
  @JsonValue('DELETE')
  delete,
}
