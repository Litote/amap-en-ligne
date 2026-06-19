// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberSubscription _$MemberSubscriptionFromJson(Map<String, dynamic> json) =>
    _MemberSubscription(
      productTypeId: json['product_type_id'] as String,
      basketSize: json['basket_size'] == null
          ? null
          : BasketSize.fromJson(json['basket_size'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MemberSubscriptionToJson(_MemberSubscription instance) =>
    <String, dynamic>{
      'product_type_id': instance.productTypeId,
      'basket_size': ?instance.basketSize,
    };

_ProductPrice _$ProductPriceFromJson(Map<String, dynamic> json) =>
    _ProductPrice(
      productTypeId: json['product_type_id'] as String,
      basketSize: json['basket_size'] == null
          ? null
          : BasketSize.fromJson(json['basket_size'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ProductPriceToJson(_ProductPrice instance) =>
    <String, dynamic>{
      'product_type_id': instance.productTypeId,
      'basket_size': ?instance.basketSize,
      'price': ?instance.price,
    };

_ContractMember _$ContractMemberFromJson(Map<String, dynamic> json) =>
    _ContractMember(
      memberId: json['member_id'] as String,
      subscriptionInstant: json['subscription_instant'] as String,
      status: $enumDecode(_$ContractMemberStatusEnumMap, json['status']),
      subscriptions:
          (json['subscriptions'] as List<dynamic>?)
              ?.map(
                (e) => MemberSubscription.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ContractMemberToJson(_ContractMember instance) =>
    <String, dynamic>{
      'member_id': instance.memberId,
      'subscription_instant': instance.subscriptionInstant,
      'status': _$ContractMemberStatusEnumMap[instance.status]!,
      'subscriptions': instance.subscriptions,
    };

const _$ContractMemberStatusEnumMap = {
  ContractMemberStatus.active: 'ACTIVE',
  ContractMemberStatus.suspended: 'SUSPENDED',
  ContractMemberStatus.completed: 'COMPLETED',
  ContractMemberStatus.cancelled: 'CANCELLED',
  ContractMemberStatus.notPresent: 'NOT_PRESENT',
};

_SharedBasket _$SharedBasketFromJson(Map<String, dynamic> json) =>
    _SharedBasket(
      sharedBasketId: json['shared_basket_id'] as String,
      memberIds:
          (json['member_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      anchorDeliveryId: json['anchor_delivery_id'] as String?,
    );

Map<String, dynamic> _$SharedBasketToJson(_SharedBasket instance) =>
    <String, dynamic>{
      'shared_basket_id': instance.sharedBasketId,
      'member_ids': instance.memberIds,
      'anchor_delivery_id': ?instance.anchorDeliveryId,
    };

_Contract _$ContractFromJson(Map<String, dynamic> json) => _Contract(
  contractId: json['contract_id'] as String,
  name: json['name'] as String,
  organizationId: json['organization_id'] as String,
  producerAccountId: json['producer_account_id'] as String,
  minDeliveryDate: json['min_delivery_date'] as String,
  maxDeliveryDate: json['max_delivery_date'] as String,
  deliveryCount: (json['delivery_count'] as num).toInt(),
  seasonYear: (json['season_year'] as num).toInt(),
  productPrices:
      (json['product_prices'] as List<dynamic>?)
          ?.map((e) => ProductPrice.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  coordinators:
      (json['coordinators'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  members:
      (json['members'] as List<dynamic>?)
          ?.map((e) => ContractMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  status:
      $enumDecodeNullable(_$ContractStatusEnumMap, json['status']) ??
      ContractStatus.inPreparation,
  deliveryTemplateId: json['delivery_template_id'] as String?,
  sharedBaskets:
      (json['shared_baskets'] as List<dynamic>?)
          ?.map((e) => SharedBasket.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ContractToJson(_Contract instance) => <String, dynamic>{
  'contract_id': instance.contractId,
  'name': instance.name,
  'organization_id': instance.organizationId,
  'producer_account_id': instance.producerAccountId,
  'min_delivery_date': instance.minDeliveryDate,
  'max_delivery_date': instance.maxDeliveryDate,
  'delivery_count': instance.deliveryCount,
  'season_year': instance.seasonYear,
  'product_prices': instance.productPrices,
  'coordinators': instance.coordinators,
  'members': instance.members,
  'status': _$ContractStatusEnumMap[instance.status]!,
  'delivery_template_id': ?instance.deliveryTemplateId,
  'shared_baskets': instance.sharedBaskets,
};

const _$ContractStatusEnumMap = {
  ContractStatus.inPreparation: 'IN_PREPARATION',
  ContractStatus.active: 'ACTIVE',
  ContractStatus.ended: 'ENDED',
};
