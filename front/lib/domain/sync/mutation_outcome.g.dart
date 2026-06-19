// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutation_outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MutationOutcome _$MutationOutcomeFromJson(Map<String, dynamic> json) =>
    _MutationOutcome(
      clientOpId: json['client_op_id'] as String,
      status: $enumDecode(_$MutationStatusEnumMap, json['status']),
      serverEntityId: json['server_entity_id'] as String?,
      error: json['error'] == null
          ? null
          : MutationError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MutationOutcomeToJson(_MutationOutcome instance) =>
    <String, dynamic>{
      'client_op_id': instance.clientOpId,
      'status': _$MutationStatusEnumMap[instance.status]!,
      'server_entity_id': ?instance.serverEntityId,
      'error': ?instance.error,
    };

const _$MutationStatusEnumMap = {
  MutationStatus.applied: 'APPLIED',
  MutationStatus.rejected: 'REJECTED',
};

_MutationError _$MutationErrorFromJson(Map<String, dynamic> json) =>
    _MutationError(
      code: $enumDecode(_$MutationErrorCodeEnumMap, json['code']),
      message: json['message'] as String,
    );

Map<String, dynamic> _$MutationErrorToJson(_MutationError instance) =>
    <String, dynamic>{
      'code': _$MutationErrorCodeEnumMap[instance.code]!,
      'message': instance.message,
    };

const _$MutationErrorCodeEnumMap = {
  MutationErrorCode.notFound: 'NOT_FOUND',
  MutationErrorCode.forbidden: 'FORBIDDEN',
  MutationErrorCode.invalidPayload: 'INVALID_PAYLOAD',
  MutationErrorCode.uniqueViolation: 'UNIQUE_VIOLATION',
  MutationErrorCode.conflict: 'CONFLICT',
  MutationErrorCode.ownerExclusive: 'OWNER_EXCLUSIVE',
  MutationErrorCode.producerExclusive: 'PRODUCER_EXCLUSIVE',
  MutationErrorCode.mixedRoles: 'MIXED_ROLES',
  MutationErrorCode.lastAdmin: 'LAST_ADMIN',
  MutationErrorCode.lastOwner: 'LAST_OWNER',
  MutationErrorCode.lastProducer: 'LAST_PRODUCER',
  MutationErrorCode.selfActionForbidden: 'SELF_ACTION_FORBIDDEN',
  MutationErrorCode.missingCoordinator: 'MISSING_COORDINATOR',
  MutationErrorCode.contractEnded: 'CONTRACT_ENDED',
  MutationErrorCode.invalidSubscription: 'INVALID_SUBSCRIPTION',
  MutationErrorCode.invalidSharedBasket: 'INVALID_SHARED_BASKET',
};
