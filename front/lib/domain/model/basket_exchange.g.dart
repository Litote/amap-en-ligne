// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basket_exchange.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BasketExchangeRequest _$BasketExchangeRequestFromJson(
  Map<String, dynamic> json,
) => _BasketExchangeRequest(
  requestId: json['request_id'] as String,
  requesterMemberId: json['requester_member_id'] as String,
  createdAt: json['created_at'] as String,
  status: $enumDecode(_$BasketExchangeRequestStatusEnumMap, json['status']),
  decidedAt: json['decided_at'] as String?,
  proposedDeliveryId: json['proposed_delivery_id'] as String?,
  proposedContractId: json['proposed_contract_id'] as String?,
);

Map<String, dynamic> _$BasketExchangeRequestToJson(
  _BasketExchangeRequest instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'requester_member_id': instance.requesterMemberId,
  'created_at': instance.createdAt,
  'status': _$BasketExchangeRequestStatusEnumMap[instance.status]!,
  'decided_at': ?instance.decidedAt,
  'proposed_delivery_id': ?instance.proposedDeliveryId,
  'proposed_contract_id': ?instance.proposedContractId,
};

const _$BasketExchangeRequestStatusEnumMap = {
  BasketExchangeRequestStatus.pending: 'PENDING',
  BasketExchangeRequestStatus.accepted: 'ACCEPTED',
  BasketExchangeRequestStatus.rejected: 'REJECTED',
  BasketExchangeRequestStatus.withdrawn: 'WITHDRAWN',
};

_BasketExchange _$BasketExchangeFromJson(Map<String, dynamic> json) =>
    _BasketExchange(
      basketExchangeId: json['basket_exchange_id'] as String,
      organizationId: json['organization_id'] as String,
      deliveryId: json['delivery_id'] as String,
      contractId: json['contract_id'] as String,
      offeringMemberId: json['offering_member_id'] as String,
      motive: json['motive'] as String?,
      status: $enumDecode(_$BasketExchangeStatusEnumMap, json['status']),
      createdAt: json['created_at'] as String,
      decidedAt: json['decided_at'] as String?,
      acceptedRequestId: json['accepted_request_id'] as String?,
      requests:
          (json['requests'] as List<dynamic>?)
              ?.map(
                (e) =>
                    BasketExchangeRequest.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BasketExchangeToJson(_BasketExchange instance) =>
    <String, dynamic>{
      'basket_exchange_id': instance.basketExchangeId,
      'organization_id': instance.organizationId,
      'delivery_id': instance.deliveryId,
      'contract_id': instance.contractId,
      'offering_member_id': instance.offeringMemberId,
      'motive': ?instance.motive,
      'status': _$BasketExchangeStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt,
      'decided_at': ?instance.decidedAt,
      'accepted_request_id': ?instance.acceptedRequestId,
      'requests': instance.requests,
    };

const _$BasketExchangeStatusEnumMap = {
  BasketExchangeStatus.open: 'OPEN',
  BasketExchangeStatus.accepted: 'ACCEPTED',
  BasketExchangeStatus.cancelled: 'CANCELLED',
};
