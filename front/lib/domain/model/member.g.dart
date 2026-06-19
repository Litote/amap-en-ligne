// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberContract _$MemberContractFromJson(Map<String, dynamic> json) =>
    _MemberContract(
      contractId: json['contract_id'] as String,
      subscriptionInstant: json['subscription_instant'] as String,
      status: $enumDecode(_$MemberContractStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$MemberContractToJson(_MemberContract instance) =>
    <String, dynamic>{
      'contract_id': instance.contractId,
      'subscription_instant': instance.subscriptionInstant,
      'status': _$MemberContractStatusEnumMap[instance.status]!,
    };

const _$MemberContractStatusEnumMap = {
  MemberContractStatus.active: 'ACTIVE',
  MemberContractStatus.suspended: 'SUSPENDED',
  MemberContractStatus.completed: 'COMPLETED',
  MemberContractStatus.cancelled: 'CANCELLED',
  MemberContractStatus.notPresent: 'NOT_PRESENT',
};

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  memberId: json['member_id'] as String,
  organizationId: json['organization_id'] as String,
  roles:
      (json['roles'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$RoleEnumMap, e))
          .toSet() ??
      const {Role.volunteer},
  activeStatus: json['active_status'] as bool? ?? true,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  accountStatus: $enumDecodeNullable(
    _$MemberAccountStatusEnumMap,
    json['account_status'],
  ),
  contracts:
      (json['contracts'] as List<dynamic>?)
          ?.map((e) => MemberContract.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  memberSettings: json['member_settings'] as Map<String, dynamic>?,
  memberPreferences: json['member_preferences'] == null
      ? null
      : MemberPreferences.fromJson(
          json['member_preferences'] as Map<String, dynamic>,
        ),
  userPreferences: json['user_preferences'] == null
      ? null
      : UserPreferences.fromJson(
          json['user_preferences'] as Map<String, dynamic>,
        ),
  userSettings: json['user_settings'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'member_id': instance.memberId,
  'organization_id': instance.organizationId,
  'roles': instance.roles.map((e) => _$RoleEnumMap[e]!).toList(),
  'active_status': instance.activeStatus,
  'first_name': ?instance.firstName,
  'last_name': ?instance.lastName,
  'email': ?instance.email,
  'phone': ?instance.phone,
  'account_status': ?_$MemberAccountStatusEnumMap[instance.accountStatus],
  'contracts': instance.contracts,
  'member_settings': ?instance.memberSettings,
  'member_preferences': ?instance.memberPreferences,
  'user_preferences': ?instance.userPreferences,
  'user_settings': ?instance.userSettings,
};

const _$RoleEnumMap = {
  Role.owner: 'OWNER',
  Role.admin: 'ADMIN',
  Role.producer: 'PRODUCER',
  Role.coordinator: 'COORDINATOR',
  Role.volunteer: 'VOLUNTEER',
};

const _$MemberAccountStatusEnumMap = {
  MemberAccountStatus.active: 'ACTIVE',
  MemberAccountStatus.suspended: 'SUSPENDED',
};
