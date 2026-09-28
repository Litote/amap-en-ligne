import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'change_page.freezed.dart';
part 'change_page.g.dart';

@freezed
abstract class ChangePage with _$ChangePage {
  const factory ChangePage({
    @Default(<Change>[]) List<Change> changes,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'has_more') required bool hasMore,
  }) = _ChangePage;

  factory ChangePage.fromJson(Map<String, Object?> json) =>
      _$ChangePageFromJson(json);
}
