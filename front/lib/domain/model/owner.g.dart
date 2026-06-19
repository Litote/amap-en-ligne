// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Owner _$OwnerFromJson(Map<String, dynamic> json) => _Owner(
  ownerId: json['owner_id'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  accountStatus:
      $enumDecodeNullable(_$AccountStatusEnumMap, json['account_status']) ??
      AccountStatus.active,
  registeredAt: json['registered_at'] as String,
  updatedAt: json['updated_at'] as String,
  userPreferences: json['user_preferences'] == null
      ? null
      : UserPreferences.fromJson(
          json['user_preferences'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$OwnerToJson(_Owner instance) => <String, dynamic>{
  'owner_id': instance.ownerId,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'email': instance.email,
  'phone': ?instance.phone,
  'account_status': _$AccountStatusEnumMap[instance.accountStatus]!,
  'registered_at': instance.registeredAt,
  'updated_at': instance.updatedAt,
  'user_preferences': ?instance.userPreferences,
};

const _$AccountStatusEnumMap = {
  AccountStatus.active: 'ACTIVE',
  AccountStatus.suspended: 'SUSPENDED',
};
