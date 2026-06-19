import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scope_sync_result.freezed.dart';

sealed class ScopeSyncResult {
  const ScopeSyncResult();

  String? get nextCursor;

  Map<String, dynamic> toJson();

  factory ScopeSyncResult.fromJson(Map<String, dynamic> json) =>
      switch (json['mode']) {
        'bootstrap' => BootstrapScopeSyncResult.fromJson(json),
        'incremental' => IncrementalScopeSyncResult.fromJson(json),
        final mode => throw FormatException(
          'Unknown ScopeSyncResult mode: $mode',
        ),
      };
}

@Freezed(toJson: false, fromJson: false)
abstract class BootstrapScopeSyncResult extends ScopeSyncResult
    with _$BootstrapScopeSyncResult {
  const BootstrapScopeSyncResult._() : super();

  const factory BootstrapScopeSyncResult({
    @Default(<EntityPayload>[]) List<EntityPayload> items,
    @JsonKey(name: 'next_cursor') String? nextCursor,
  }) = _BootstrapScopeSyncResult;

  factory BootstrapScopeSyncResult.fromJson(Map<String, dynamic> json) =>
      BootstrapScopeSyncResult(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => EntityPayload.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'mode': 'bootstrap',
    'items': items.map((item) => item.toJson()).toList(),
    'next_cursor': nextCursor,
  };
}

@Freezed(toJson: false, fromJson: false)
abstract class IncrementalScopeSyncResult extends ScopeSyncResult
    with _$IncrementalScopeSyncResult {
  const IncrementalScopeSyncResult._() : super();

  const factory IncrementalScopeSyncResult({
    @Default(<Change>[]) List<Change> changes,
    @JsonKey(name: 'next_cursor') String? nextCursor,
  }) = _IncrementalScopeSyncResult;

  factory IncrementalScopeSyncResult.fromJson(Map<String, dynamic> json) =>
      IncrementalScopeSyncResult(
        changes: (json['changes'] as List<dynamic>? ?? const [])
            .map((change) => Change.fromJson(change as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'mode': 'incremental',
    'changes': changes.map((change) => change.toJson()).toList(),
    'next_cursor': nextCursor,
  };
}
