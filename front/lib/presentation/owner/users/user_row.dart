import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:flutter/foundation.dart';

/// A denormalized, view-level aggregate that represents one user
/// (identified by [identityKey]) as displayed in the instance user list.
///
/// Built from [Owner] + [Member] + [Organization] data available locally.
@immutable
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserMembership &&
          other.memberId == memberId &&
          other.organizationId == organizationId &&
          other.organizationName == organizationName &&
          setEquals(other.roles, roles));

  @override
  int get hashCode => Object.hash(
    memberId,
    organizationId,
    organizationName,
    Object.hashAllUnordered(roles),
  );
}

enum UserDisplayStatus { active, pendingInvitation, suspended }

/// View-model for a single row in the user list screen.
@immutable
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
    this.isInvitation = false,
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

  /// ISO-8601 instant string, or null when unknown (members created before
  /// `Member.registered_at` existed, owner seeded at deployment).
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

  /// True for a pending [OwnerInvitation] / [MemberInvitation]: no account
  /// exists yet, so no lifecycle or membership action applies.
  final bool isInvitation;

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

  // Value equality: bloc states holding rows must differ whenever a row's
  // content does (late organization name, role or status change), otherwise
  // the bloc drops the new state as a duplicate.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.identityKey == identityKey &&
          other.ownerId == ownerId &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.email == email &&
          other.phone == phone &&
          other.registeredAt == registeredAt &&
          other.displayStatus == displayStatus &&
          listEquals(other.memberships, memberships) &&
          other.isOwner == isOwner &&
          other.isProducer == isProducer &&
          other.producerAccountId == producerAccountId &&
          other.producerAccountName == producerAccountName &&
          other.isInvitation == isInvitation);

  @override
  int get hashCode => Object.hash(
    identityKey,
    firstName,
    lastName,
    email,
    phone,
    registeredAt,
    displayStatus,
    Object.hashAll(memberships),
    isOwner,
    isProducer,
    producerAccountName,
    isInvitation,
  );
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
  registeredAt: _knownInstant(owner.registeredAt),
  displayStatus: owner.accountStatus == AccountStatus.suspended
      ? UserDisplayStatus.suspended
      : UserDisplayStatus.active,
  memberships: const [],
  isOwner: true,
  isProducer: false,
);

/// [instant], or null when it is missing or the Unix epoch — the placeholder
/// registration date of the owner seeded at deployment.
String? _knownInstant(String? instant) {
  final parsed = instant == null ? null : DateTime.tryParse(instant);
  if (parsed == null || parsed.millisecondsSinceEpoch <= 0) return null;
  return instant;
}

/// Builds an invited-owner [UserRow] for a pending [OwnerInvitation].
UserRow userRowFromOwnerInvitation(OwnerInvitation invitation) => UserRow(
  identityKey: 'owner-invitation:${invitation.invitationId}',
  ownerId: invitation.invitationId,
  firstName: invitation.firstName,
  lastName: invitation.lastName,
  email: invitation.email,
  displayStatus: UserDisplayStatus.pendingInvitation,
  memberships: const [],
  isOwner: true,
  isProducer: false,
  isInvitation: true,
);

/// Builds an invited-member [UserRow] for a pending [MemberInvitation].
UserRow userRowFromMemberInvitation(
  MemberInvitation invitation,
  Map<String, String> organizationNamesById,
) => UserRow(
  identityKey: 'member-invitation:${invitation.invitationId}',
  ownerId: invitation.invitationId,
  firstName: invitation.firstName,
  lastName: invitation.lastName,
  email: invitation.email,
  displayStatus: UserDisplayStatus.pendingInvitation,
  memberships: [
    UserMembership(
      memberId: invitation.invitationId,
      organizationId: invitation.organizationId,
      organizationName:
          organizationNamesById[invitation.organizationId] ??
          invitation.organizationId,
      roles: invitation.roles,
    ),
  ],
  isOwner: false,
  isProducer: false,
  isInvitation: true,
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
    displayStatus: _producerDisplayStatus(pa),
    memberships: const [],
    isOwner: false,
    isProducer: true,
    producerAccountId: pa.producerAccountId,
    producerAccountName: pa.name,
  );
}

UserDisplayStatus _producerDisplayStatus(ProducerAccount pa) {
  if (!pa.activeStatus) return UserDisplayStatus.suspended;
  if (pa.pendingActivation) return UserDisplayStatus.pendingInvitation;
  return UserDisplayStatus.active;
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
    ),
    lastName: _resolveMemberField(members, direct: (member) => member.lastName),
    email: _resolveMemberField(members, direct: (member) => member.email),
    phone: _resolveOptionalMemberField(
      members,
      direct: (member) => member.phone,
    ),
    registeredAt: _earliestRegistration(members),
    displayStatus: _aggregateMemberStatus(members),
    memberships: memberships,
    isOwner: false,
    isProducer: false,
  );
}

/// The earliest known registration date among the user's memberships.
String? _earliestRegistration(List<Member> members) {
  String? earliest;
  DateTime? earliestAt;
  for (final member in members) {
    final instant = _knownInstant(member.registeredAt);
    final at = instant == null ? null : DateTime.parse(instant);
    if (at != null && (earliestAt == null || at.isBefore(earliestAt))) {
      earliest = instant;
      earliestAt = at;
    }
  }
  return earliest;
}

String _resolveMemberField(
  List<Member> members, {
  required String? Function(Member member) direct,
}) => _resolveOptionalMemberField(members, direct: direct) ?? '';

String? _resolveOptionalMemberField(
  List<Member> members, {
  required String? Function(Member member) direct,
}) {
  for (final member in members) {
    final value = direct(member)?.trim();
    if (value != null && value.isNotEmpty) return value;
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

UserDisplayStatus _displayStatusFromMember(Member member) =>
    switch (member.accountStatus) {
      MemberAccountStatus.suspended => UserDisplayStatus.suspended,
      MemberAccountStatus.active => UserDisplayStatus.active,
    };

/// Every user of the instance as displayed by the OWNER user list, sorted by
/// last then first name:
/// - owners, then account-backed producers (a no-account producer has no
///   login, so it is not a user), then members grouped by identity;
/// - pending owner / member invitations as « Invité » rows, unless an
///   account already carries the same email.
List<UserRow> buildInstanceUserRows({
  required List<Owner> owners,
  required List<Member> members,
  required List<Organization> organizations,
  required List<ProducerAccount> producerAccounts,
  required List<OwnerInvitation> ownerInvitations,
  required List<MemberInvitation> memberInvitations,
}) {
  final organizationNamesById = {
    for (final organization in organizations)
      organization.organizationId: organization.name,
  };
  final accountRows = _accountRowsByIdentity(
    owners: owners,
    members: members,
    producerAccounts: producerAccounts,
    organizationNamesById: organizationNamesById,
  );
  final invitationRows = _pendingInvitationRows(
    ownerInvitations: ownerInvitations,
    memberInvitations: memberInvitations,
    organizationNamesById: organizationNamesById,
    accountEmails: {
      for (final row in accountRows.values)
        if (row.email.trim().isNotEmpty) _emailKey(row.email),
    },
  );
  return [...accountRows.values, ...invitationRows]..sort(_byName);
}

/// Owners, then account-backed producers, then members grouped by identity.
Map<String, UserRow> _accountRowsByIdentity({
  required List<Owner> owners,
  required List<Member> members,
  required List<ProducerAccount> producerAccounts,
  required Map<String, String> organizationNamesById,
}) {
  final byIdentity = <String, UserRow>{
    for (final owner in owners) owner.ownerId: userRowFromOwner(owner),
  };
  for (final pa in producerAccounts) {
    if (pa.managementMode == ProducerManagementMode.noAccount) continue;
    byIdentity.putIfAbsent(
      pa.producerAccountId,
      () => userRowFromProducerAccount(pa),
    );
  }
  final membersByIdentity = <String, List<Member>>{};
  for (final member in members) {
    membersByIdentity.putIfAbsent(member.memberId, () => []).add(member);
  }
  for (final entry in membersByIdentity.entries) {
    if (byIdentity.containsKey(entry.key)) continue;
    final row = userRowFromMembers(entry.value, organizationNamesById);
    if (row != null) byIdentity[entry.key] = row;
  }
  return byIdentity;
}

/// Pending owner / member invitations whose email has no account yet.
List<UserRow> _pendingInvitationRows({
  required List<OwnerInvitation> ownerInvitations,
  required List<MemberInvitation> memberInvitations,
  required Map<String, String> organizationNamesById,
  required Set<String> accountEmails,
}) {
  bool invited(InvitationStatus status, String email) =>
      status == InvitationStatus.pendingActivation &&
      !accountEmails.contains(_emailKey(email));
  return [
    for (final invitation in ownerInvitations)
      if (invited(invitation.status, invitation.email))
        userRowFromOwnerInvitation(invitation),
    for (final invitation in memberInvitations)
      if (invited(invitation.status, invitation.email))
        userRowFromMemberInvitation(invitation, organizationNamesById),
  ];
}

String _emailKey(String email) => email.trim().toLowerCase();

int _byName(UserRow a, UserRow b) {
  final lastCmp = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
  if (lastCmp != 0) return lastCmp;
  return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
}
