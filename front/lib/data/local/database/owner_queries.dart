part of '../database.dart';

mixin _OwnerQueries on _$AppDatabase {
  Stream<List<AdminOrganizationRequest>> watchOrganizationRequests() =>
      select(organizationRequests).watch().map(
        (rows) => rows
            .map(
              (r) => AdminOrganizationRequest.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertOrganizationRequest(AdminOrganizationRequest request) =>
      into(organizationRequests).insertOnConflictUpdate(
        OrganizationRequestsCompanion.insert(
          requestId: request.requestId,
          dataJson: jsonEncode(request.toJson()),
        ),
      );

  Future<void> deleteOrganizationRequest(String requestId) => (delete(
    organizationRequests,
  )..where((t) => t.requestId.equals(requestId))).go();

  Future<void> clearOrganizationRequests() => delete(organizationRequests).go();

  Stream<List<AdminProducerRequest>> watchProducerRequests() =>
      select(producerRequests).watch().map(
        (rows) => rows
            .map(
              (r) => AdminProducerRequest.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertProducerRequest(AdminProducerRequest request) =>
      into(producerRequests).insertOnConflictUpdate(
        ProducerRequestsCompanion.insert(
          requestId: request.requestId,
          dataJson: jsonEncode(request.toJson()),
        ),
      );

  Future<void> deleteProducerRequest(String requestId) => (delete(
    producerRequests,
  )..where((t) => t.requestId.equals(requestId))).go();

  Future<void> clearProducerRequests() => delete(producerRequests).go();

  Stream<List<Owner>> watchOwners() => select(
    owners,
  ).watch().map((rows) => rows.map(_ownerRowToDomain).toList());

  Future<List<Owner>> getAllOwners() async {
    final rows = await select(owners).get();
    return rows.map(_ownerRowToDomain).toList();
  }

  Future<Owner?> findOwnerById(String ownerId) async {
    final row = await (select(
      owners,
    )..where((t) => t.ownerId.equals(ownerId))).getSingleOrNull();
    return row == null ? null : _ownerRowToDomain(row);
  }

  /// Reactive stream of the [Owner] row whose `ownerId` matches [ownerId].
  /// Emits null when no matching row exists.
  Stream<Owner?> watchOwnerById(String ownerId) =>
      (select(owners)..where((t) => t.ownerId.equals(ownerId)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _ownerRowToDomain(row));

  Future<void> upsertOwner(Owner owner) =>
      into(owners).insertOnConflictUpdate(_ownerDomainToRow(owner));

  Future<void> deleteOwner(String ownerId) =>
      (delete(owners)..where((t) => t.ownerId.equals(ownerId))).go();

  /// Clears all owner rows. Used when applying a bootstrap [EntitySnapshot].
  Future<void> clearOwners() => delete(owners).go();

  /// Optimistically updates the [UserPreferences] for the given [ownerId].
  Future<void> updateOwnerUserPreferences(
    String ownerId,
    UserPreferences userPreferences,
  ) async {
    final existing = await findOwnerById(ownerId);
    if (existing == null) return;
    await upsertOwner(existing.copyWith(userPreferences: userPreferences));
  }

  /// Optimistically updates the profile fields for the given [ownerId].
  /// No-op when the row is not yet in the local cache.
  Future<void> updateOwnerProfile({
    required String ownerId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    final existing = await findOwnerById(ownerId);
    if (existing == null) return;
    await upsertOwner(
      existing.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      ),
    );
  }

  Stream<List<OwnerInvitation>> watchOwnerInvitations() =>
      select(ownerInvitations).watch().map(
        (rows) => rows
            .map(
              (r) => OwnerInvitation.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<OwnerInvitation?> findOwnerInvitationById(String invitationId) async {
    final row = await (select(
      ownerInvitations,
    )..where((t) => t.invitationId.equals(invitationId))).getSingleOrNull();
    if (row == null) return null;
    return OwnerInvitation.fromJson(
      jsonDecode(row.dataJson) as Map<String, dynamic>,
    );
  }

  Future<List<OwnerInvitation>> getOwnerInvitations() async {
    final rows = await select(ownerInvitations).get();
    return rows
        .map(
          (row) => OwnerInvitation.fromJson(
            jsonDecode(row.dataJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> upsertOwnerInvitation(OwnerInvitation invitation) =>
      into(ownerInvitations).insertOnConflictUpdate(
        OwnerInvitationsCompanion.insert(
          invitationId: invitation.invitationId,
          dataJson: jsonEncode(invitation.toJson()),
        ),
      );

  Future<void> deleteOwnerInvitation(String invitationId) => (delete(
    ownerInvitations,
  )..where((t) => t.invitationId.equals(invitationId))).go();

  Future<void> clearOwnerInvitations() => delete(ownerInvitations).go();

  Future<void> remapOwnerInvitationId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing = await (select(
      ownerInvitations,
    )..where((t) => t.invitationId.equals(oldId))).getSingleOrNull();
    if (existing == null) return;
    final invitation = OwnerInvitation.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(invitationId: newId);
    await (delete(
      ownerInvitations,
    )..where((t) => t.invitationId.equals(oldId))).go();
    await upsertOwnerInvitation(invitation);
  });
}

Owner _ownerRowToDomain(OwnerRow row) => Owner(
  ownerId: row.ownerId,
  firstName: row.firstName,
  lastName: row.lastName,
  email: row.email,
  phone: row.phone,
  accountStatus: AccountStatus.values.firstWhere(
    (s) => s.name.toUpperCase() == row.accountStatus,
    orElse: () => AccountStatus.active,
  ),
  registeredAt: row.registeredAt,
  updatedAt: row.updatedAt,
  userPreferences: row.userPreferences == null
      ? null
      : UserPreferences.fromJson(
          jsonDecode(row.userPreferences!) as Map<String, Object?>,
        ),
);

OwnersCompanion _ownerDomainToRow(Owner owner) => OwnersCompanion.insert(
  ownerId: owner.ownerId,
  firstName: owner.firstName,
  lastName: owner.lastName,
  email: owner.email,
  phone: Value(owner.phone),
  accountStatus: owner.accountStatus.name.toUpperCase(),
  registeredAt: owner.registeredAt,
  updatedAt: owner.updatedAt,
  userPreferences: Value(
    owner.userPreferences == null
        ? null
        : jsonEncode(owner.userPreferences!.toJson()),
  ),
);
