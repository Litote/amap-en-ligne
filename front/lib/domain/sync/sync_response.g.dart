// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) =>
    _SyncResponse(
      authorizedScopes:
          (json['authorized_scopes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      results:
          (json['results'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              ScopeSyncResult.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const <String, ScopeSyncResult>{},
      mutations:
          (json['mutations'] as List<dynamic>?)
              ?.map((e) => MutationOutcome.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MutationOutcome>[],
    );

Map<String, dynamic> _$SyncResponseToJson(_SyncResponse instance) =>
    <String, dynamic>{
      'authorized_scopes': instance.authorizedScopes,
      'results': instance.results,
      'mutations': instance.mutations,
    };
