// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producer_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProducerOrganization _$ProducerOrganizationFromJson(
  Map<String, dynamic> json,
) => _ProducerOrganization(
  organizationId: json['organization_id'] as String,
  associationInstant: json['association_instant'] as String,
  status: $enumDecode(_$OrganizationProducerStatusEnumMap, json['status']),
);

Map<String, dynamic> _$ProducerOrganizationToJson(
  _ProducerOrganization instance,
) => <String, dynamic>{
  'organization_id': instance.organizationId,
  'association_instant': instance.associationInstant,
  'status': _$OrganizationProducerStatusEnumMap[instance.status]!,
};

const _$OrganizationProducerStatusEnumMap = {
  OrganizationProducerStatus.active: 'ACTIVE',
  OrganizationProducerStatus.suspended: 'SUSPENDED',
  OrganizationProducerStatus.terminated: 'TERMINATED',
};

_ProducerProduct _$ProducerProductFromJson(Map<String, dynamic> json) =>
    _ProducerProduct(
      name: json['name'] as String,
      productTypeId: json['product_type_id'] as String,
      supportedBasketSizes:
          (json['supported_basket_sizes'] as List<dynamic>?)
              ?.map((e) => BasketSize.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ProducerProductToJson(_ProducerProduct instance) =>
    <String, dynamic>{
      'name': instance.name,
      'product_type_id': instance.productTypeId,
      'supported_basket_sizes': instance.supportedBasketSizes,
      'description': ?instance.description,
    };

_ProducerAccount _$ProducerAccountFromJson(Map<String, dynamic> json) =>
    _ProducerAccount(
      producerAccountId: json['producer_account_id'] as String,
      name: json['name'] as String,
      contactEmail: json['contact_email'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
      activeStatus: json['active_status'] as bool? ?? true,
      createdInstant: json['created_instant'] as String?,
      lastUpdatedInstant: json['last_updated_instant'] as String?,
      managementMode:
          $enumDecodeNullable(
            _$ProducerManagementModeEnumMap,
            json['management_mode'],
          ) ??
          ProducerManagementMode.accountBacked,
      linkedProducerAccount: json['linked_producer_account'] == null
          ? null
          : LinkedProducerAccount.fromJson(
              json['linked_producer_account'] as Map<String, dynamic>,
            ),
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => ProducerProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      organizations:
          (json['organizations'] as List<dynamic>?)
              ?.map(
                (e) => ProducerOrganization.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      userPreferences: json['user_preferences'] == null
          ? null
          : UserPreferences.fromJson(
              json['user_preferences'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ProducerAccountToJson(
  _ProducerAccount instance,
) => <String, dynamic>{
  'producer_account_id': instance.producerAccountId,
  'name': instance.name,
  'contact_email': ?instance.contactEmail,
  'address': ?instance.address,
  'website': ?instance.website,
  'active_status': instance.activeStatus,
  'created_instant': ?instance.createdInstant,
  'last_updated_instant': ?instance.lastUpdatedInstant,
  'management_mode': _$ProducerManagementModeEnumMap[instance.managementMode]!,
  'linked_producer_account': ?instance.linkedProducerAccount,
  'products': instance.products,
  'organizations': instance.organizations,
  'user_preferences': ?instance.userPreferences,
};

const _$ProducerManagementModeEnumMap = {
  ProducerManagementMode.accountBacked: 'ACCOUNT_BACKED',
  ProducerManagementMode.noAccount: 'NO_ACCOUNT',
};

_LinkedProducerAccount _$LinkedProducerAccountFromJson(
  Map<String, dynamic> json,
) => _LinkedProducerAccount(
  producerAccountId: json['producer_account_id'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$LinkedProducerAccountToJson(
  _LinkedProducerAccount instance,
) => <String, dynamic>{
  'producer_account_id': instance.producerAccountId,
  'name': instance.name,
};
