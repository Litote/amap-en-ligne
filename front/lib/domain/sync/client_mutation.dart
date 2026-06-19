import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_mutation.freezed.dart';
part 'client_mutation.g.dart';

@freezed
abstract class ClientMutation with _$ClientMutation {
  const factory ClientMutation({
    @JsonKey(name: 'client_op_id') required String clientOpId,
    required MutationOp op,
  }) = _ClientMutation;

  factory ClientMutation.fromJson(Map<String, Object?> json) =>
      _$ClientMutationFromJson(json);

  /// Prefix for client-side temporary entity ids. The server detects this
  /// prefix and allocates a real id, returning the mapping in
  /// `MutationOutcome.serverEntityId`.
  static const String tmpIdPrefix = 'tmp_';
}
