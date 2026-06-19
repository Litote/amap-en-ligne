import 'dart:async';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_management_bloc.freezed.dart';
part 'user_management_event.dart';
part 'user_management_state.dart';

class _UserManagementSnapshot {
  const _UserManagementSnapshot({
    required this.members,
    required this.memberInvitations,
  });

  final List<Member> members;
  final List<MemberInvitation> memberInvitations;
}

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  UserManagementBloc({
    required MemberRepository memberRepository,
    required MemberInvitationRepository memberInvitationRepository,
    required SyncRepository syncRepository,
    required AppDatabase database,
    required String organizationId,
    required this.canEditAdminRole,
  }) : _memberRepo = memberRepository,
       _memberInvitationRepo = memberInvitationRepository,
       _syncRepository = syncRepository,
       _database = database,
       _organizationId = organizationId,
       _submittingInvitation = false,
       super(const UserManagementState.initial()) {
    on<_LoadRequested>(_onLoadRequested);
    on<_SearchChanged>(_onSearchChanged);
    on<_RoleFilterChanged>(_onRoleFilterChanged);
    on<_InvitationStatusFilterChanged>(_onInvitationStatusFilterChanged);
    on<_UserStatusFilterChanged>(_onUserStatusFilterChanged);
    on<_EditRolesRequested>(_onEditRolesRequested);
    on<_RoleToggled>(_onRoleToggled);
    on<_SaveRolesRequested>(_onSaveRolesRequested);
    on<_EditCancelled>(_onEditCancelled);
    on<_DeleteInvitationRequested>(_onDeleteInvitationRequested);
    on<_ShowInviteForm>(_onShowInviteForm);
    on<_InviteFirstNameChanged>(_onInviteFirstNameChanged);
    on<_InviteLastNameChanged>(_onInviteLastNameChanged);
    on<_InviteEmailChanged>(_onInviteEmailChanged);
    on<_InviteRoleToggled>(_onInviteRoleToggled);
    on<_ResendInvitationRequested>(_onResendInvitationRequested);
    on<_ResendAllPendingRequested>(_onResendAllPendingRequested);
    on<_SubmitInvitation>(_onSubmitInvitation);
    on<_DismissInviteForm>(_onDismissInviteForm);
    on<_FeedbackDismissed>(_onFeedbackDismissed);
  }

  final MemberRepository _memberRepo;
  final MemberInvitationRepository _memberInvitationRepo;
  final SyncRepository _syncRepository;
  final AppDatabase _database;
  String _organizationId;
  bool _submittingInvitation;
  StreamSubscription<String?>? _orgIdSub;

  /// Whether the current user can assign or remove the Admin role.
  /// True for users with Role.admin or Role.owner.
  final bool canEditAdminRole;

  @override
  Future<void> close() {
    _orgIdSub?.cancel();
    return super.close();
  }

  Future<void> _discoverOrganizationId() async {
    // Try to get organizationId from sync cursors (should be available after first sync)
    final orgId = await _database
        .watchEffectiveOrganizationId(_organizationId)
        .first
        .timeout(const Duration(milliseconds: 100), onTimeout: () => null);
    if (orgId != null && orgId.isNotEmpty) {
      _organizationId = orgId;
    }
  }

  Future<void> _onLoadRequested(
    _LoadRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    // If organizationId is empty (router passed '' because auth wasn't ready),
    // discover it from sync cursors before loading.
    if (_organizationId.isEmpty) {
      await _discoverOrganizationId();
    }

    // If still empty after discovery attempt, show loading (waiting for auth)
    if (_organizationId.isEmpty) {
      emit(const UserManagementState.loading());
      return;
    }

    emit(const UserManagementState.loading());
    final members = <Member>[];
    final memberInvitations = <MemberInvitation>[];
    final controller = StreamController<_UserManagementSnapshot>();

    _UserManagementSnapshot snapshot() => _UserManagementSnapshot(
      members: List.of(members),
      memberInvitations: List.of(memberInvitations),
    );

    final membersSub = _memberRepo.watch(_organizationId).listen((data) {
      members
        ..clear()
        ..addAll(data);
      if (!controller.isClosed) controller.add(snapshot());
    });
    final invitationsSub = _memberInvitationRepo.watch(_organizationId).listen((
      data,
    ) {
      memberInvitations
        ..clear()
        ..addAll(data);
      if (!controller.isClosed) controller.add(snapshot());
    });

    await emit.forEach<_UserManagementSnapshot>(
      controller.stream,
      onData: (snapshot) {
        final current = state;
        if (current is UserManagementLoaded) {
          return current.copyWith(
            members: snapshot.members,
            memberInvitations: snapshot.memberInvitations,
          );
        }
        return UserManagementState.loaded(
          members: snapshot.members,
          memberInvitations: snapshot.memberInvitations,
        );
      },
      onError: (error, stackTrace) =>
          const UserManagementState.error('Erreur de chargement.'),
    );

    await membersSub.cancel();
    await invitationsSub.cancel();
    await controller.close();
  }

  void _onSearchChanged(
    _SearchChanged event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(searchQuery: event.query));
  }

  void _onRoleFilterChanged(
    _RoleFilterChanged event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(roleFilter: event.role));
  }

  void _onInvitationStatusFilterChanged(
    _InvitationStatusFilterChanged event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(invitationStatusFilter: event.filter));
  }

  void _onUserStatusFilterChanged(
    _UserStatusFilterChanged event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(userStatusFilter: event.filter));
  }

  void _onEditRolesRequested(
    _EditRolesRequested event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(
      current.copyWith(
        editingMember: event.member,
        pendingRoles: Set<Role>.from(event.member.roles),
      ),
    );
  }

  void _onRoleToggled(_RoleToggled event, Emitter<UserManagementState> emit) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    if (current.editingMember == null) return;
    final roles = Set<Role>.from(current.pendingRoles);
    if (event.isChecked) {
      roles.add(event.role);
    } else {
      roles.remove(event.role);
    }
    emit(current.copyWith(pendingRoles: roles));
  }

  Future<void> _onSaveRolesRequested(
    _SaveRolesRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    final current = state;
    if (current is! UserManagementLoaded) return;
    final editing = current.editingMember;
    if (editing == null) return;
    emit(current.copyWith(saving: true));
    try {
      await _memberRepo.setRoles(
        _organizationId,
        editing,
        current.pendingRoles,
      );
      emit(
        current.copyWith(
          editingMember: null,
          pendingRoles: const {},
          saving: false,
        ),
      );
    } catch (_) {
      emit(current.copyWith(saving: false));
    }
  }

  void _onEditCancelled(
    _EditCancelled event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(editingMember: null, pendingRoles: const {}));
  }

  void _onShowInviteForm(
    _ShowInviteForm event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(
      current.copyWith(
        showingInviteForm: true,
        inviteFirstName: '',
        inviteLastName: '',
        inviteEmail: '',
        inviteRoles: const {},
        inviteError: null,
        inviteSuccess: false,
      ),
    );
  }

  void _onInviteFirstNameChanged(
    _InviteFirstNameChanged event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(inviteFirstName: event.value));
  }

  void _onInviteLastNameChanged(
    _InviteLastNameChanged event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(inviteLastName: event.value));
  }

  void _onInviteEmailChanged(
    _InviteEmailChanged event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(inviteEmail: event.value));
  }

  void _onInviteRoleToggled(
    _InviteRoleToggled event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    final roles = Set<Role>.from(current.inviteRoles);
    if (event.isChecked) {
      roles.add(event.role);
    } else {
      roles.remove(event.role);
    }
    emit(current.copyWith(inviteRoles: roles));
  }

  Future<void> _onResendInvitationRequested(
    _ResendInvitationRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(
      current.copyWith(
        resendingInvitationIds: {
          ...current.resendingInvitationIds,
          event.invitation.invitationId,
        },
      ),
    );
    try {
      final clientOpId = await _memberInvitationRepo.resend(
        organizationId: event.invitation.organizationId,
        invitationId: event.invitation.invitationId,
      );
      final outcome = await _syncRepository.sync(tenantId: _organizationId);
      // Use `state` (not `current`) so that optimistic DB updates applied by the
      // watch stream between the repo call and the sync are not overwritten.
      final latest = state;
      if (latest is! UserManagementLoaded) return;
      if (outcome case SyncSuccess()) {
        final rejected = _findRejectedMutation(outcome, clientOpId);
        if (rejected != null) {
          emit(
            latest.copyWith(
              resendingInvitationIds: _withoutResending(
                latest,
                event.invitation.invitationId,
              ),
              feedbackMessage: _mutationErrorMessage(rejected.error),
              feedbackIsError: true,
            ),
          );
          return;
        }
      } else if (outcome case SyncFailure()) {
        emit(
          latest.copyWith(
            resendingInvitationIds: _withoutResending(
              latest,
              event.invitation.invitationId,
            ),
            feedbackMessage: 'La relance a échoué. Veuillez réessayer.',
            feedbackIsError: true,
          ),
        );
        return;
      }
      emit(
        latest.copyWith(
          resendingInvitationIds: _withoutResending(
            latest,
            event.invitation.invitationId,
          ),
          feedbackMessage: 'Invitation relancée.',
          feedbackIsError: false,
        ),
      );
    } catch (_) {
      final latest = state;
      if (latest is! UserManagementLoaded) return;
      emit(
        latest.copyWith(
          resendingInvitationIds: _withoutResending(
            latest,
            event.invitation.invitationId,
          ),
          feedbackMessage: 'La relance a échoué. Veuillez réessayer.',
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onResendAllPendingRequested(
    _ResendAllPendingRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    final current = state;
    if (current is! UserManagementLoaded) return;
    final pending = current.memberInvitations
        .where((inv) => inv.status == InvitationStatus.pendingActivation)
        .toList();
    if (pending.isEmpty || current.resendingAllPending) return;

    emit(
      current.copyWith(
        resendingAllPending: true,
        resendingInvitationIds: {
          ...current.resendingInvitationIds,
          ...pending.map((inv) => inv.invitationId),
        },
      ),
    );

    final subject = event.customEmailSubject?.trim();
    final body = event.customEmailBody?.trim();
    var failures = 0;
    final clientOpIds = <String>[];
    try {
      for (final invitation in pending) {
        try {
          clientOpIds.add(
            await _memberInvitationRepo.resend(
              organizationId: invitation.organizationId,
              invitationId: invitation.invitationId,
              customEmailSubject: (subject?.isEmpty ?? true) ? null : subject,
              customEmailBody: (body?.isEmpty ?? true) ? null : body,
            ),
          );
        } catch (_) {
          failures++;
        }
      }
      final outcome = await _syncRepository.sync(tenantId: _organizationId);
      if (outcome case SyncSuccess()) {
        failures += clientOpIds
            .where((id) => _findRejectedMutation(outcome, id) != null)
            .length;
      } else if (outcome case SyncFailure()) {
        failures = pending.length;
      }
    } catch (_) {
      failures = pending.length;
    }

    final latest = state;
    if (latest is! UserManagementLoaded) return;
    final remaining = Set<String>.from(latest.resendingInvitationIds)
      ..removeAll(pending.map((inv) => inv.invitationId));
    final succeeded = pending.length - failures;
    emit(
      latest.copyWith(
        resendingAllPending: false,
        resendingInvitationIds: remaining,
        feedbackMessage: failures == 0
            ? 'Invitations relancées ($succeeded).'
            : 'Relance partielle : $succeeded envoyée(s), $failures échec(s).',
        feedbackIsError: failures > 0,
      ),
    );
  }

  Future<void> _onDeleteInvitationRequested(
    _DeleteInvitationRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(
      current.copyWith(
        deletingInvitationIds: {
          ...current.deletingInvitationIds,
          event.invitation.invitationId,
        },
      ),
    );
    try {
      final clientOpId = await _memberInvitationRepo.delete(
        organizationId: event.invitation.organizationId,
        invitationId: event.invitation.invitationId,
      );
      final outcome = await _syncRepository.sync(tenantId: _organizationId);
      // Use `state` (not `current`) so that the optimistic local delete applied
      // by the watch stream between the repo call and sync is not overwritten.
      final latest = state;
      if (latest is! UserManagementLoaded) return;
      if (outcome case SyncSuccess()) {
        final rejected = _findRejectedMutation(outcome, clientOpId);
        if (rejected != null) {
          emit(
            latest.copyWith(
              deletingInvitationIds: _withoutDeleting(
                latest,
                event.invitation.invitationId,
              ),
              feedbackMessage: _mutationErrorMessage(rejected.error),
              feedbackIsError: true,
            ),
          );
          return;
        }
      } else if (outcome case SyncFailure()) {
        emit(
          latest.copyWith(
            deletingInvitationIds: _withoutDeleting(
              latest,
              event.invitation.invitationId,
            ),
            feedbackMessage: 'La suppression a échoué. Veuillez réessayer.',
            feedbackIsError: true,
          ),
        );
        return;
      }
      emit(
        latest.copyWith(
          deletingInvitationIds: _withoutDeleting(
            latest,
            event.invitation.invitationId,
          ),
          feedbackMessage: 'Invitation supprimée.',
          feedbackIsError: false,
        ),
      );
    } catch (_) {
      final latest = state;
      if (latest is! UserManagementLoaded) return;
      emit(
        latest.copyWith(
          deletingInvitationIds: _withoutDeleting(
            latest,
            event.invitation.invitationId,
          ),
          feedbackMessage: 'La suppression a échoué. Veuillez réessayer.',
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onSubmitInvitation(
    _SubmitInvitation event,
    Emitter<UserManagementState> emit,
  ) async {
    if (_submittingInvitation) return;
    _submittingInvitation = true;

    final current = state;
    if (current is! UserManagementLoaded) {
      _submittingInvitation = false;
      return;
    }

    if (current.inviteFirstName.isEmpty ||
        current.inviteLastName.isEmpty ||
        current.inviteEmail.isEmpty ||
        current.inviteRoles.isEmpty) {
      emit(
        current.copyWith(
          inviteError: 'Veuillez remplir tous les champs obligatoires.',
        ),
      );
      _submittingInvitation = false;
      return;
    }

    emit(current.copyWith(inviting: true, inviteError: null));
    try {
      final clientOpId = await _memberInvitationRepo.create(
        organizationId: _organizationId,
        email: current.inviteEmail,
        firstName: current.inviteFirstName,
        lastName: current.inviteLastName,
        roles: current.inviteRoles,
      );
      final outcome = await _syncRepository.sync(tenantId: _organizationId);
      if (outcome case SyncSuccess()) {
        final rejected = _findRejectedMutation(outcome, clientOpId);
        if (rejected != null) {
          emit(
            current.copyWith(
              inviting: false,
              inviteError: _mutationErrorMessage(rejected.error),
            ),
          );
          return;
        }
      } else if (outcome case SyncFailure()) {
        emit(
          current.copyWith(
            inviting: false,
            inviteError:
                "L'envoi de l'invitation a échoué. Veuillez réessayer.",
          ),
        );
        return;
      }
      emit(
        current.copyWith(
          inviting: false,
          showingInviteForm: false,
          inviteError: null,
          inviteSuccess: true,
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          inviting: false,
          inviteError: "Erreur lors de l'envoi de l'invitation.",
        ),
      );
    } finally {
      _submittingInvitation = false;
    }
  }

  void _onDismissInviteForm(
    _DismissInviteForm event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(showingInviteForm: false, inviteError: null));
  }

  void _onFeedbackDismissed(
    _FeedbackDismissed event,
    Emitter<UserManagementState> emit,
  ) {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(current.copyWith(feedbackMessage: null, feedbackIsError: false));
  }

  MutationOutcome? _findRejectedMutation(
    SyncSuccess outcome,
    String clientOpId,
  ) => outcome.rejectedMutations
      .where((mutation) => mutation.clientOpId == clientOpId)
      .firstOrNull;

  Set<String> _withoutResending(
    UserManagementLoaded state,
    String invitationId,
  ) {
    final next = Set<String>.from(state.resendingInvitationIds);
    next.remove(invitationId);
    return next;
  }

  Set<String> _withoutDeleting(
    UserManagementLoaded state,
    String invitationId,
  ) {
    final next = Set<String>.from(state.deletingInvitationIds);
    next.remove(invitationId);
    return next;
  }

  String _mutationErrorMessage(MutationError? error) {
    if (error == null) return "Erreur lors de l'envoi de l'invitation.";
    return switch (error.code) {
      MutationErrorCode.uniqueViolation ||
      MutationErrorCode.conflict => "Cette invitation existe déjà.",
      MutationErrorCode.ownerExclusive =>
        "Ce compte ne peut pas être invité dans l'AMAP.",
      MutationErrorCode.mixedRoles =>
        "Ce compte ne peut pas cumuler ces rôles.",
      MutationErrorCode.lastAdmin =>
        'Cette AMAP doit conserver au moins un Admin.',
      _ => error.message,
    };
  }
}
