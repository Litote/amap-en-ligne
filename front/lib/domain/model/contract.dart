import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract.freezed.dart';
part 'contract.g.dart';

enum ContractStatus {
  @JsonValue('IN_PREPARATION')
  inPreparation,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('ENDED')
  ended,
}

enum ContractMemberStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('SUSPENDED')
  suspended,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('NOT_PRESENT')
  notPresent,
}

@freezed
abstract class MemberSubscription with _$MemberSubscription {
  const factory MemberSubscription({
    @JsonKey(name: 'product_type_id') required String productTypeId,
    @JsonKey(name: 'basket_size') BasketSize? basketSize,
  }) = _MemberSubscription;

  factory MemberSubscription.fromJson(Map<String, Object?> json) =>
      _$MemberSubscriptionFromJson(json);
}

@freezed
abstract class ProductPrice with _$ProductPrice {
  const factory ProductPrice({
    @JsonKey(name: 'product_type_id') required String productTypeId,
    @JsonKey(name: 'basket_size') BasketSize? basketSize,
    double? price,
  }) = _ProductPrice;

  factory ProductPrice.fromJson(Map<String, Object?> json) =>
      _$ProductPriceFromJson(json);
}

@freezed
abstract class ContractMember with _$ContractMember {
  const factory ContractMember({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'subscription_instant') required String subscriptionInstant,
    required ContractMemberStatus status,
    @Default([]) List<MemberSubscription> subscriptions,
  }) = _ContractMember;

  factory ContractMember.fromJson(Map<String, Object?> json) =>
      _$ContractMemberFromJson(json);
}

/// A shared basket: several members ([memberIds]) share a single physical basket on a contract,
/// picking it up in round-robin alternation across the contract's deliveries.
///
/// Overlay structure: the members keep their individual [ContractMember] subscriptions; this entry
/// only marks that they alternate on one basket. Alternation is anchored on [anchorDeliveryId]
/// (a stable identity, not a positional index) — see `shared_basket_view.dart`.
@freezed
abstract class SharedBasket with _$SharedBasket {
  const factory SharedBasket({
    @JsonKey(name: 'shared_basket_id') required String sharedBasketId,
    @JsonKey(name: 'member_ids') @Default([]) List<String> memberIds,
    @JsonKey(name: 'anchor_delivery_id') String? anchorDeliveryId,
  }) = _SharedBasket;

  factory SharedBasket.fromJson(Map<String, Object?> json) =>
      _$SharedBasketFromJson(json);
}

@freezed
abstract class Contract with _$Contract {
  const factory Contract({
    @JsonKey(name: 'contract_id') required String contractId,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'organization_id') required String organizationId,
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    @JsonKey(name: 'min_delivery_date') required String minDeliveryDate,
    @JsonKey(name: 'max_delivery_date') required String maxDeliveryDate,
    @JsonKey(name: 'delivery_count') required int deliveryCount,
    @JsonKey(name: 'season_year') required int seasonYear,
    @JsonKey(name: 'product_prices')
    @Default([])
    List<ProductPrice> productPrices,
    @Default([]) List<String> coordinators,
    @Default([]) List<ContractMember> members,
    @Default(ContractStatus.inPreparation) ContractStatus status,
    @JsonKey(name: 'delivery_template_id') String? deliveryTemplateId,
    @JsonKey(name: 'shared_baskets')
    @Default([])
    List<SharedBasket> sharedBaskets,
    @JsonKey(name: 'is_main_contract') @Default(false) bool isMainContract,
  }) = _Contract;

  factory Contract.fromJson(Map<String, Object?> json) =>
      _$ContractFromJson(json);
}
