// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChangePage _$ChangePageFromJson(Map<String, dynamic> json) => _ChangePage(
  changes:
      (json['changes'] as List<dynamic>?)
          ?.map((e) => Change.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Change>[],
  nextCursor: json['next_cursor'] as String?,
  hasMore: json['has_more'] as bool,
);

Map<String, dynamic> _$ChangePageToJson(_ChangePage instance) =>
    <String, dynamic>{
      'changes': instance.changes,
      'next_cursor': ?instance.nextCursor,
      'has_more': instance.hasMore,
    };
