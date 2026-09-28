// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producer_request_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProducerRequestResponse _$ProducerRequestResponseFromJson(
  Map<String, dynamic> json,
) => _ProducerRequestResponse(
  requestId: json['request_id'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$ProducerRequestResponseToJson(
  _ProducerRequestResponse instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'status': instance.status,
};
