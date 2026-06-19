import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';

/// A denormalized, view-level aggregate that represents one user
/// (identified by [identityKey]) as displayed in the instance user list.
///
/// Built from [Owner] + [Member] + [Organization] data available locally.
class UserMembership {
  const UserMembership({
    required this.memberId,
    required this.organizationId,
    required this.organizationName,
    required this.roles,
  });

  /// The [Member.memberId] identifying this membership row.
  final String memberId;

  final String organizationId;
  final String organizationName;
  final Set<Role> roles;
}

enum UserDisplayStatus { active, pendingInvitation, suspended }

/// View-model for a single row in the user list screen.
class UserRow {
  const UserRow({
    required this.identityKey,
    required this.ownerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.registeredAt,
    required this.displayStatus,
    required this.memberships,
    required this.isOwner,
    required this.isProducer,
    this.producerAccountId,
    this.producerAccountName,
  });

  /// Stable user identity key for UI deduplication.
  final String identityKey;

  /// Database identifier of the [Owner] row when [isOwner] is true,
  /// or the memberId of the first [Member] row otherwise. Used for navigation.
  final String ownerId;

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  /// ISO-8601 instant string, or null when not available (Member-only users
  /// do not expose a registration date in Phase 4/5).
  final String? registeredAt;

  final UserDisplayStatus displayStatus;

  /// AMAP memberships across all organisations. Empty for OWNER users.
  final List<UserMembership> memberships;

  final bool isOwner;
  final bool isProducer;

  /// `ProducerAccount.producerAccountId` when [isProducer] is true.
  final String? producerAccountId;

  /// `ProducerAccount.name` when [isProducer] is true — shown in the
  /// "Producteur" column of the user list.
  final String? producerAccountName;

  String get displayName {
    final fullName = [
      firstName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
    if (email.trim().isNotEmpty) return email.trim();
    final normalizedPhone = phone?.trim();
    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      return normalizedPhone;
    }
    final producerName = producerAccountName?.trim();
    if (producerName != null && producerName.isNotEmpty) return producerName;
    return 'Utilisateur sans nom';
  }

  Set<Role> get badgeRoles {
    if (isOwner) return {Role.owner};
    if (isProducer) return {Role.producer};
    return memberships.expand((membership) => membership.roles).toSet();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow && other.identityKey == identityKey);

  @override
  int get hashCode => identityKey.hashCode;
}

/// Role filter values for the user list.
enum UserListRoleFilter { owner, admin, coordinator, volunteer, producer }

/// Builds a [UserRow] for an [Owner].
UserRow userRowFromOwner(Owner owner) => UserRow(
  identityKey: owner.ownerId,
  ownerId: owner.ownerId,
  firstName: owner.firstName,
  lastName: owner.lastName,
  email: owner.email,
  phone: owner.phone,
  registeredAt: owner.registeredAt,
  displayStatus: owner.accountStatus == AccountStatus.suspended
      ? UserDisplayStatus.suspended
      : UserDisplayStatus.active,
  memberships: const [],
  isOwner: true,
  isProducer: false,
);

/// Builds a [UserRow] for a [ProducerAccount].
///
/// The wire `ProducerAccount` payload has no user-level identity field today; we
/// use `producerAccountId` as the row identity so the list
/// dedupes on it and the detail screen can route to `/owner/users/<id>`.
/// First/last name are derived by splitting `name` on the first whitespace —
/// best-effort until a dedicated identity field arrives on the wire.
UserRow userRowFromProducerAccount(ProducerAccount pa) {
  final trimmed = pa.name.trim();
  final spaceAt = trimmed.indexOf(' ');
  final firstName = spaceAt < 0 ? trimmed : trimmed.substring(0, spaceAt);
  final lastName = spaceAt < 0 ? '' : trimmed.substring(spaceAt + 1);
  return UserRow(
    identityKey: pa.producerAccountId,
    ownerId: pa.producerAccountId,
    firstName: firstName,
    lastName: lastName,
    email: pa.contactEmail ?? '',
    displayStatus: pa.activeStatus
        ? UserDisplayStatus.active
        : UserDisplayStatus.suspended,
    memberships: const [],
    isOwner: false,
    isProducer: true,
    producerAccountId: pa.producerAccountId,
    producerAccountName: pa.name,
  );
}

UserRow? userRowFromMembers(
  List<Member> members,
  Map<String, String> organizationNamesById,
) {
  if (members.isEmpty) return null;
  final identityKey = members.first.memberId;

  final memberships =
      members
          .map(
            (member) => UserMembership(
              memberId: member.memberId,
              organizationId: member.organizationId,
              organizationName:
                  organizationNamesById[member.organizationId] ??
                  member.organizationId,
              roles: member.roles,
            ),
          )
          .toList()
        ..sort(
          (a, b) => a.organizationName.toLowerCase().compareTo(
            b.organizationName.toLowerCase(),
          ),
        );

  final first = members.first;
  return UserRow(
    identityKey: identityKey,
    ownerId: first.memberId,
    firstName: _resolveMemberField(
      members,
      direct: (member) => member.firstName,
      legacyKey: 'first_name',
    ),
    lastName: _resolveMemberField(
      members,
      direct: (member) => member.lastName,
      legacyKey: 'last_name',
    ),
    email: _resolveMemberField(
      members,
      direct: (member) => member.email,
      legacyKey: 'email',
    ),
    phone: _resolveOptionalMemberField(
      members,
      direct: (member) => member.phone,
      legacyKey: 'phone',
    ),
    registeredAt: null,
    displayStatus: _aggregateMemberStatus(members),
    memberships: memberships,
    isOwner: false,
    isProducer: false,
  );
}

String _resolveMemberField(
  List<Member> members, {
  required String? Function(Member member) direct,
  required String legacyKey,
}) =>
    _resolveOptionalMemberField(
      members,
      direct: direct,
      legacyKey: legacyKey,
    ) ??
    '';

String? _resolveOptionalMemberField(
  List<Member> members, {
  required String? Function(Member member) direct,
  required String legacyKey,
}) {
  for (final member in members) {
    final value = direct(member)?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  for (final member in members) {
    final settingsValue = (member.memberSettings?[legacyKey] as String?)
        ?.trim();
    if (settingsValue != null && settingsValue.isNotEmpty) return settingsValue;
    final userSettingsValue = (member.userSettings?[legacyKey] as String?)
        ?.trim();
    if (userSettingsValue != null && userSettingsValue.isNotEmpty) {
      return userSettingsValue;
    }
  }
  return null;
}

UserDisplayStatus _aggregateMemberStatus(List<Member> members) {
  final statuses = members.map(_displayStatusFromMember).toSet();
  if (statuses.contains(UserDisplayStatus.suspended)) {
    return UserDisplayStatus.suspended;
  }
  if (statuses.contains(UserDisplayStatus.pendingInvitation)) {
    return UserDisplayStatus.pendingInvitation;
  }
  return UserDisplayStatus.active;
}

UserDisplayStatus _displayStatusFromMember(Member member) {
  switch (member.accountStatus) {
    case MemberAccountStatus.suspended:
      return UserDisplayStatus.suspended;
    case MemberAccountStatus.active:
      return UserDisplayStatus.active;
    case null:
      return member.activeStatus
          ? UserDisplayStatus.active
          : UserDisplayStatus.suspended;
  }
}
