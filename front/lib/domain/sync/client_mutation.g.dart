// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_mutation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClientMutation _$ClientMutationFromJson(Map<String, dynamic> json) =>
    _ClientMutation(
      clientOpId: json['client_op_id'] as String,
      op: MutationOp.fromJson(json['op'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClientMutationToJson(_ClientMutation instance) =>
    <String, dynamic>{'client_op_id': instance.clientOpId, 'op': instance.op};
