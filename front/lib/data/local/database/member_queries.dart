part of '../database.dart';

mixin _MemberQueries on _$AppDatabase, _OrganizationQueries {
  /// Watches all [Member] rows for [tenantId].
  ///
  /// [tenantId] is the JWT `sub` for non-producer users. The real
  /// `organization_id` is resolved from the `authorized_scopes` stored in
  /// [sync_cursors] by [SyncRepository] after the first sync
  /// (scope key `organization:<orgId>`). [watchEffectiveOrganizationId]
  /// extracts that org id and switches to the concrete members query once it
  /// is available.
  Stream<List<Member>> watchMembersForTenant(String tenantId) =>
      watchEffectiveOrganizationId(tenantId).distinct().asyncExpand(
        (orgId) => orgId == null
            ? Stream.value(<Member>[])
            : (select(
                members,
              )..where((t) => t.organizationId.equals(orgId))).watch().map(
                (rows) => rows
                    .map(
                      (r) => Member.fromJson(
                        jsonDecode(r.dataJson) as Map<String, dynamic>,
                      ),
                    )
                    .toList(),
              ),
      );

  /// Watches all [MemberInvitation] rows for [tenantId].
  /// Same org-id resolution as [watchMembersForTenant].
  Stream<List<MemberInvitation>> watchMemberInvitationsForTenant(
    String tenantId,
  ) => watchEffectiveOrganizationId(tenantId).distinct().asyncExpand(
    (orgId) => orgId == null
        ? Stream.value(<MemberInvitation>[])
        : (select(
            memberInvitations,
          )..where((t) => t.organizationId.equals(orgId))).watch().map(
            (rows) => rows
                .map(
                  (r) => MemberInvitation.fromJson(
                    jsonDecode(r.dataJson) as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
  );

  /// Returns a reactive stream of **all** [Member] rows across all
  /// organisations. Used by instance-wide views (OWNER role).
  Stream<List<Member>> watchAllMembers() => select(members).watch().map(
    (rows) => rows
        .map(
          (r) =>
              Member.fromJson(jsonDecode(r.dataJson) as Map<String, dynamic>),
        )
        .toList(),
  );

  Stream<List<Member>> watchMembers(String organizationId) =>
      (select(
        members,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => Member.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertMember(String organizationId, Member m) =>
      into(members).insertOnConflictUpdate(
        MembersCompanion.insert(
          organizationId: organizationId,
          memberId: m.memberId,
          dataJson: jsonEncode(m.toJson()),
        ),
      );

  Future<void> deleteMember(String organizationId, String memberId) =>
      (delete(members)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.memberId.equals(memberId),
          ))
          .go();

  Future<void> clearMembersForOrganization(String organizationId) => (delete(
    members,
  )..where((t) => t.organizationId.equals(organizationId))).go();

  Stream<List<MemberInvitation>> watchMemberInvitations(
    String organizationId,
  ) =>
      (select(
        memberInvitations,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => MemberInvitation.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<MemberInvitation?> getMemberInvitation(
    String organizationId,
    String invitationId,
  ) async {
    final row =
        await (select(memberInvitations)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.invitationId.equals(invitationId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return MemberInvitation.fromJson(
      jsonDecode(row.dataJson) as Map<String, dynamic>,
    );
  }

  Future<List<MemberInvitation>> getMemberInvitationsForOrganization(
    String organizationId,
  ) async {
    final rows = await (select(
      memberInvitations,
    )..where((t) => t.organizationId.equals(organizationId))).get();
    return rows
        .map(
          (row) => MemberInvitation.fromJson(
            jsonDecode(row.dataJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> upsertMemberInvitation(
    String organizationId,
    MemberInvitation invitation,
  ) => into(memberInvitations).insertOnConflictUpdate(
    MemberInvitationsCompanion.insert(
      organizationId: organizationId,
      invitationId: invitation.invitationId,
      dataJson: jsonEncode(invitation.toJson()),
    ),
  );

  Future<void> deleteMemberInvitation(
    String organizationId,
    String invitationId,
  ) =>
      (delete(memberInvitations)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.invitationId.equals(invitationId),
          ))
          .go();

  Future<void> clearMemberInvitationsForOrganization(String organizationId) =>
      (delete(
        memberInvitations,
      )..where((t) => t.organizationId.equals(organizationId))).go();

  Stream<List<AdminMemberJoinRequest>> watchMemberJoinRequests(
    String organizationId,
  ) =>
      (select(
        memberJoinRequests,
      )..where((t) => t.organizationId.equals(organizationId))).watch().map(
        (rows) => rows
            .map(
              (r) => AdminMemberJoinRequest.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<void> upsertMemberJoinRequest(AdminMemberJoinRequest request) =>
      into(memberJoinRequests).insertOnConflictUpdate(
        MemberJoinRequestsCompanion.insert(
          organizationId: request.organizationId,
          requestId: request.requestId,
          dataJson: jsonEncode(request.toJson()),
        ),
      );

  Future<void> deleteMemberJoinRequest(
    String organizationId,
    String requestId,
  ) =>
      (delete(memberJoinRequests)..where(
            (t) =>
                t.organizationId.equals(organizationId) &
                t.requestId.equals(requestId),
          ))
          .go();

  Future<void> clearMemberJoinRequestsForOrganization(String organizationId) =>
      (delete(
        memberJoinRequests,
      )..where((t) => t.organizationId.equals(organizationId))).go();

  /// Returns the [Member] identified by [memberId] + [organizationId], or
  /// `null` when no row exists in the local cache.
  Future<Member?> getMember(String organizationId, String memberId) async {
    final row =
        await (select(members)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.memberId.equals(memberId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return Member.fromJson(jsonDecode(row.dataJson) as Map<String, dynamic>);
  }

  Future<void> remapMemberId({
    required String organizationId,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(members)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.memberId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final member = Member.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(memberId: newId);
    await (delete(members)..where(
          (t) =>
              t.organizationId.equals(organizationId) &
              t.memberId.equals(oldId),
        ))
        .go();
    await upsertMember(organizationId, member);
  });

  Future<void> remapMemberInvitationId({
    required String organizationId,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(memberInvitations)..where(
              (t) =>
                  t.organizationId.equals(organizationId) &
                  t.invitationId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final invitation = MemberInvitation.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(invitationId: newId);
    await (delete(memberInvitations)..where(
          (t) =>
              t.organizationId.equals(organizationId) &
              t.invitationId.equals(oldId),
        ))
        .go();
    await upsertMemberInvitation(organizationId, invitation);
  });
}
