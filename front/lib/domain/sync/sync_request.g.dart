// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncRequest _$SyncRequestFromJson(Map<String, dynamic> json) => _SyncRequest(
  cursors:
      (json['cursors'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String?),
      ) ??
      const <String, String?>{},
  mutations:
      (json['mutations'] as List<dynamic>?)
          ?.map((e) => ClientMutation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ClientMutation>[],
);

Map<String, dynamic> _$SyncRequestToJson(_SyncRequest instance) =>
    <String, dynamic>{
      'cursors': instance.cursors,
      'mutations': instance.mutations,
    };
