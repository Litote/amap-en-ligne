import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_account.freezed.dart';
part 'producer_account.g.dart';

enum ProducerManagementMode {
  @JsonValue('ACCOUNT_BACKED')
  accountBacked,
  @JsonValue('NO_ACCOUNT')
  noAccount,
}

/// Producer-side embedding: one entry per `Organization` the producer is
/// linked to. Mirrors the back `ProducerOrganization` data class (note: the
/// reverse `OrganizationProducer` in `organization.dart` has `producer_account_id`
/// — these are intentionally distinct wire shapes).
@freezed
abstract class ProducerOrganization with _$ProducerOrganization {
  const factory ProducerOrganization({
    @JsonKey(name: 'organization_id') required String organizationId,
    // ISO-8601 instant string, e.g. "2026-05-18T22:23:25.095Z".
    @JsonKey(name: 'association_instant') required String associationInstant,
    required OrganizationProducerStatus status,
  }) = _ProducerOrganization;

  factory ProducerOrganization.fromJson(Map<String, Object?> json) =>
      _$ProducerOrganizationFromJson(json);
}

@freezed
abstract class ProducerProduct with _$ProducerProduct {
  const factory ProducerProduct({
    required String name,
    @JsonKey(name: 'product_type_id') required String productTypeId,
    @JsonKey(name: 'supported_basket_sizes')
    @Default([])
    List<BasketSize> supportedBasketSizes,
    String? description,
  }) = _ProducerProduct;

  factory ProducerProduct.fromJson(Map<String, Object?> json) =>
      _$ProducerProductFromJson(json);
}

@freezed
abstract class ProducerAccount with _$ProducerAccount {
  const factory ProducerAccount({
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    required String name,
    @JsonKey(name: 'contact_email') String? contactEmail,
    String? address,
    String? website,
    @JsonKey(name: 'active_status') @Default(true) bool activeStatus,
    // ISO-8601 instant strings (e.g. "2026-05-18T22:23:25.093Z") — matches
    // the back's kotlin.time.Instant default serialization.
    @JsonKey(name: 'created_instant') String? createdInstant,
    @JsonKey(name: 'last_updated_instant') String? lastUpdatedInstant,
    @JsonKey(name: 'management_mode')
    @Default(ProducerManagementMode.accountBacked)
    ProducerManagementMode managementMode,
    @JsonKey(name: 'linked_producer_account')
    LinkedProducerAccount? linkedProducerAccount,
    @Default([]) List<ProducerProduct> products,
    @Default([]) List<ProducerOrganization> organizations,
    @JsonKey(name: 'user_preferences') UserPreferences? userPreferences,
  }) = _ProducerAccount;

  factory ProducerAccount.fromJson(Map<String, Object?> json) =>
      _$ProducerAccountFromJson(json);
}

@freezed
abstract class LinkedProducerAccount with _$LinkedProducerAccount {
  const factory LinkedProducerAccount({
    @JsonKey(name: 'producer_account_id') required String producerAccountId,
    required String name,
  }) = _LinkedProducerAccount;

  factory LinkedProducerAccount.fromJson(Map<String, Object?> json) =>
      _$LinkedProducerAccountFromJson(json);
}
