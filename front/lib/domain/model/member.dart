import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

enum MemberContractStatus {
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

/// Lifecycle status of an AMAP member — mirrors back's `MemberAccountStatus`.
///
/// Nullable on legacy rows created before the PII migration; UIs should fall
/// back to [Member.activeStatus] when [Member.accountStatus] is null.
///
/// Note: `PENDING_INVITATION` and `EXPIRED_INVITATION` have been removed from
/// the wire. Those states now live on `MemberInvitation.status`, not on
/// `Member`.
enum MemberAccountStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('SUSPENDED')
  suspended,
}

@freezed
abstract class MemberContract with _$MemberContract {
  const factory MemberContract({
    @JsonKey(name: 'contract_id') required String contractId,
    @JsonKey(name: 'subscription_instant') required String subscriptionInstant,
    required MemberContractStatus status,
  }) = _MemberContract;

  factory MemberContract.fromJson(Map<String, Object?> json) =>
      _$MemberContractFromJson(json);
}

@freezed
abstract class Member with _$Member {
  const factory Member({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'organization_id') required String organizationId,
    @Default({Role.volunteer}) Set<Role> roles,
    @JsonKey(name: 'active_status') @Default(true) bool activeStatus,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    String? email,
    String? phone,
    @JsonKey(name: 'account_status') MemberAccountStatus? accountStatus,
    @Default([]) List<MemberContract> contracts,
    @JsonKey(name: 'member_settings') Map<String, dynamic>? memberSettings,
    @JsonKey(name: 'member_preferences') MemberPreferences? memberPreferences,
    @JsonKey(name: 'user_preferences') UserPreferences? userPreferences,
    @JsonKey(name: 'user_settings') Map<String, dynamic>? userSettings,
  }) = _Member;

  factory Member.fromJson(Map<String, Object?> json) => _$MemberFromJson(json);
}
