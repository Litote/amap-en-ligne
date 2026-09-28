// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EntitySnapshot _$EntitySnapshotFromJson(Map<String, dynamic> json) =>
    _EntitySnapshot(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => EntityPayload.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <EntityPayload>[],
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$EntitySnapshotToJson(_EntitySnapshot instance) =>
    <String, dynamic>{'items': instance.items, 'cursor': instance.cursor};
