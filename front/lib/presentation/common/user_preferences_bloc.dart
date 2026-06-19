import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences_bloc.freezed.dart';

// ---------------------------------------------------------------------------
// Source — describes where user preferences come from, based on role.
// ---------------------------------------------------------------------------

/// Describes the data source for user preferences depending on role.
sealed class UserPreferencesSource {
  const UserPreferencesSource();
}

/// Source for VOLUNTEER / COORDINATOR / ADMIN members.
class MemberSource extends UserPreferencesSource {
  const MemberSource({required this.memberId, required this.memberRepository});

  final String memberId;
  final MemberRepository memberRepository;
}

/// Source for OWNER users.
class OwnerSource extends UserPreferencesSource {
  const OwnerSource({required this.ownerId, required this.ownerRepository});

  final String ownerId;
  final OwnerRepository ownerRepository;
}

/// Source for PRODUCER users.
class ProducerSource extends UserPreferencesSource {
  const ProducerSource({
    required this.producerAccountId,
    required this.producerAccountRepository,
  });

  final String producerAccountId;
  final ProducerAccountRepository producerAccountRepository;
}

// ---------------------------------------------------------------------------
// Field enums — which logical toggle was changed
// ---------------------------------------------------------------------------

/// Reminder fields that live in [MemberPreferences].
enum ReminderField { reminder24h, reminder2h, reminder30min }

/// Alert fields that live in [MemberPreferences].
enum AlertField { urgentNeed, incompleteSlot, planningChanges }

/// Notification-channel fields that live in [UserPreferences].
enum ChannelField { email, push }

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

@freezed
sealed class UserPreferencesEvent with _$UserPreferencesEvent {
  /// Internal — fired by the member-stream subscription.
  const factory UserPreferencesEvent.loaded(Member? member) =
      _UserPreferencesLoaded;

  /// Internal — fired by the owner-stream subscription.
  const factory UserPreferencesEvent.ownerLoaded(Owner? owner) =
      _UserPreferencesOwnerLoaded;

  /// Internal — fired by the producer-stream subscription.
  const factory UserPreferencesEvent.producerLoaded(
    ProducerAccount? producerAccount,
  ) = _UserPreferencesProducerLoaded;

  /// User toggled a delivery-reminder checkbox.
  const factory UserPreferencesEvent.reminderToggled(
    ReminderField field,
    bool value,
  ) = _UserPreferencesReminderToggled;

  /// User toggled an alert checkbox.
  const factory UserPreferencesEvent.alertToggled(
    AlertField field,
    bool value,
  ) = _UserPreferencesAlertToggled;

  /// User toggled a notification-channel checkbox.
  const factory UserPreferencesEvent.channelToggled(
    ChannelField field,
    bool value,
  ) = _UserPreferencesChannelToggled;

  /// User pressed the save button (for notification preferences).
  const factory UserPreferencesEvent.saved() = _UserPreferencesSaved;

  /// User submitted the edit-profile dialog.
  ///
  /// For [OwnerSource]: [firstName], [lastName], [email] are required;
  /// [phone] is optional.
  /// For [ProducerSource]: [producerName] is required; [contactEmail],
  /// [address], [website] are optional.
  /// Fields irrelevant to the active source are ignored.
  const factory UserPreferencesEvent.profileSaved({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? producerName,
    String? contactEmail,
    String? address,
    String? website,
  }) = _UserPreferencesProfileSaved;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Lifecycle of the in-flight save operation.
enum SaveStatus { idle, saving, success, failure }

@freezed
sealed class UserPreferencesState with _$UserPreferencesState {
  /// Waiting for the first stream emission.
  const factory UserPreferencesState.loading() = UserPreferencesLoading;

  /// Stream emitted null — entity not yet synced.
  const factory UserPreferencesState.missing() = UserPreferencesMissing;

  /// Editable state seeded from the loaded entity.
  ///
  /// Exactly one of [member], [owner], [producerAccount] is non-null depending
  /// on which [UserPreferencesSource] was provided to the bloc.
  const factory UserPreferencesState.ready({
    Member? member,
    Owner? owner,
    ProducerAccount? producerAccount,
    required MemberPreferences memberPreferences,
    required UserPreferences userPreferences,
    @Default(false) bool dirty,
    @Default(SaveStatus.idle) SaveStatus saveStatus,
    String? saveErrorMessage,
    @Default(SaveStatus.idle) SaveStatus profileSaveStatus,
    String? profileSaveErrorMessage,
  }) = UserPreferencesReady;
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

// Fallback instant used when preferences are not yet persisted.
const _kEpoch = '1970-01-01T00:00:00.000Z';

class UserPreferencesBloc
    extends Bloc<UserPreferencesEvent, UserPreferencesState> {
  UserPreferencesBloc({required UserPreferencesSource source})
    : _source = source,
      super(const UserPreferencesState.loading()) {
    on<_UserPreferencesLoaded>(_onLoaded);
    on<_UserPreferencesOwnerLoaded>(_onOwnerLoaded);
    on<_UserPreferencesProducerLoaded>(_onProducerLoaded);
    on<_UserPreferencesReminderToggled>(_onReminderToggled);
    on<_UserPreferencesAlertToggled>(_onAlertToggled);
    on<_UserPreferencesChannelToggled>(_onChannelToggled);
    on<_UserPreferencesSaved>(_onSaved);
    on<_UserPreferencesProfileSaved>(_onProfileSaved);

    switch (source) {
      case MemberSource(:final memberId, :final memberRepository):
        _primarySub = memberRepository
            .watchMyMember(memberId)
            .listen((m) => add(UserPreferencesEvent.loaded(m)));
      case OwnerSource(:final ownerId, :final ownerRepository):
        _primarySub = ownerRepository
            .watchMySelf(ownerId)
            .listen((o) => add(UserPreferencesEvent.ownerLoaded(o)));
      case ProducerSource(
        :final producerAccountId,
        :final producerAccountRepository,
      ):
        _primarySub = producerAccountRepository
            .watchMine(producerAccountId)
            .listen((p) => add(UserPreferencesEvent.producerLoaded(p)));
    }
  }

  final UserPreferencesSource _source;
  late final StreamSubscription<Object?> _primarySub;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onLoaded(
    _UserPreferencesLoaded event,
    Emitter<UserPreferencesState> emit,
  ) {
    final member = event.member;
    final current = state;
    if (current is UserPreferencesReady && current.dirty) return;

    if (member == null) {
      emit(const UserPreferencesState.missing());
    } else {
      emit(_seedFromMember(member));
    }
  }

  void _onOwnerLoaded(
    _UserPreferencesOwnerLoaded event,
    Emitter<UserPreferencesState> emit,
  ) {
    final owner = event.owner;
    final current = state;
    if (current is UserPreferencesReady && current.dirty) return;

    if (owner == null) {
      emit(const UserPreferencesState.missing());
    } else {
      emit(_seedFromOwner(owner));
    }
  }

  void _onProducerLoaded(
    _UserPreferencesProducerLoaded event,
    Emitter<UserPreferencesState> emit,
  ) {
    final producer = event.producerAccount;
    final current = state;
    if (current is UserPreferencesReady && current.dirty) return;

    if (producer == null) {
      emit(const UserPreferencesState.missing());
    } else {
      emit(_seedFromProducer(producer));
    }
  }

  void _onReminderToggled(
    _UserPreferencesReminderToggled event,
    Emitter<UserPreferencesState> emit,
  ) {
    final current = state;
    if (current is! UserPreferencesReady) return;

    final updated = switch (event.field) {
      ReminderField.reminder24h => current.memberPreferences.copyWith(
        reminder24hEnabled: event.value,
      ),
      ReminderField.reminder2h => current.memberPreferences.copyWith(
        reminder2hEnabled: event.value,
      ),
      ReminderField.reminder30min => current.memberPreferences.copyWith(
        reminder30minEnabled: event.value,
      ),
    };

    emit(_withUpdatedPrefs(current, memberPreferences: updated));
  }

  void _onAlertToggled(
    _UserPreferencesAlertToggled event,
    Emitter<UserPreferencesState> emit,
  ) {
    final current = state;
    if (current is! UserPreferencesReady) return;

    final updated = switch (event.field) {
      AlertField.urgentNeed => current.memberPreferences.copyWith(
        urgentNeedAlertsEnabled: event.value,
      ),
      AlertField.incompleteSlot => current.memberPreferences.copyWith(
        incompleteSlotRemindersEnabled: event.value,
      ),
      AlertField.planningChanges => current.memberPreferences.copyWith(
        planningChangesAlertsEnabled: event.value,
      ),
    };

    emit(_withUpdatedPrefs(current, memberPreferences: updated));
  }

  void _onChannelToggled(
    _UserPreferencesChannelToggled event,
    Emitter<UserPreferencesState> emit,
  ) {
    final current = state;
    if (current is! UserPreferencesReady) return;

    final updated = switch (event.field) {
      ChannelField.email => current.userPreferences.copyWith(
        emailNotificationsEnabled: event.value,
      ),
      ChannelField.push => current.userPreferences.copyWith(
        pushNotificationsEnabled: event.value,
      ),
    };

    emit(_withUpdatedPrefs(current, userPreferences: updated));
  }

  Future<void> _onSaved(
    _UserPreferencesSaved event,
    Emitter<UserPreferencesState> emit,
  ) async {
    final current = state;
    if (current is! UserPreferencesReady) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final memberPrefs = current.memberPreferences.copyWith(
      lastUpdatedInstant: now,
    );
    final userPrefs = current.userPreferences.copyWith(lastUpdatedInstant: now);

    emit(
      current.copyWith(saveStatus: SaveStatus.saving, saveErrorMessage: null),
    );

    try {
      if (current.member != null) {
        final src = _source as MemberSource;
        await src.memberRepository.updatePreferences(
          memberId: current.member!.memberId,
          organizationId: current.member!.organizationId,
          memberPreferences: memberPrefs,
          userPreferences: userPrefs,
        );
      } else if (current.owner != null) {
        final src = _source as OwnerSource;
        await src.ownerRepository.updateUserPreferences(
          current.owner!.ownerId,
          userPrefs,
        );
      } else if (current.producerAccount != null) {
        final src = _source as ProducerSource;
        await src.producerAccountRepository.updateUserPreferences(
          current.producerAccount!.producerAccountId,
          userPrefs,
        );
      }
      emit(
        current.copyWith(
          memberPreferences: memberPrefs,
          userPreferences: userPrefs,
          dirty: false,
          saveStatus: SaveStatus.success,
          saveErrorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          saveStatus: SaveStatus.failure,
          saveErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onProfileSaved(
    _UserPreferencesProfileSaved event,
    Emitter<UserPreferencesState> emit,
  ) async {
    final current = state;
    if (current is! UserPreferencesReady) return;

    emit(
      current.copyWith(
        profileSaveStatus: SaveStatus.saving,
        profileSaveErrorMessage: null,
      ),
    );

    try {
      if (current.member != null) {
        final src = _source as MemberSource;
        final member = current.member!;
        await src.memberRepository.updateProfile(
          memberId: member.memberId,
          organizationId: member.organizationId,
          firstName: event.firstName ?? member.firstName,
          lastName: event.lastName ?? member.lastName,
          email: event.email ?? member.email,
          phone: event.phone ?? member.phone,
        );
      } else if (current.owner != null) {
        final src = _source as OwnerSource;
        final ownerId = current.owner!.ownerId;
        await src.ownerRepository.updateProfile(
          ownerId: ownerId,
          firstName: event.firstName ?? current.owner!.firstName,
          lastName: event.lastName ?? current.owner!.lastName,
          email: event.email ?? current.owner!.email,
          phone: event.phone ?? current.owner!.phone,
        );
      } else if (current.producerAccount != null) {
        final src = _source as ProducerSource;
        final producerAccountId = current.producerAccount!.producerAccountId;
        final name = event.producerName ?? current.producerAccount!.name;
        final contactEmail =
            event.contactEmail ?? current.producerAccount!.contactEmail;
        final address = event.address ?? current.producerAccount!.address;
        final website = event.website ?? current.producerAccount!.website;

        // Optimistic local write + enqueues sync mutation.
        await src.producerAccountRepository.updateProfile(
          producerAccountId: producerAccountId,
          name: name,
          contactEmail: contactEmail,
          address: address,
          website: website,
        );
      }

      emit(
        current.copyWith(
          profileSaveStatus: SaveStatus.success,
          profileSaveErrorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          profileSaveStatus: SaveStatus.failure,
          profileSaveErrorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _primarySub.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Seed helpers
  // ---------------------------------------------------------------------------

  UserPreferencesReady _seedFromMember(Member member) {
    final memberPrefs =
        member.memberPreferences ??
        const MemberPreferences(lastUpdatedInstant: _kEpoch);
    final userPrefs =
        member.userPreferences ??
        const UserPreferences(lastUpdatedInstant: _kEpoch);
    return UserPreferencesReady(
      member: member,
      memberPreferences: memberPrefs,
      userPreferences: userPrefs,
    );
  }

  UserPreferencesReady _seedFromOwner(Owner owner) {
    final userPrefs =
        owner.userPreferences ??
        const UserPreferences(lastUpdatedInstant: _kEpoch);
    return UserPreferencesReady(
      owner: owner,
      memberPreferences: const MemberPreferences(lastUpdatedInstant: _kEpoch),
      userPreferences: userPrefs,
    );
  }

  UserPreferencesReady _seedFromProducer(ProducerAccount producerAccount) {
    final userPrefs =
        producerAccount.userPreferences ??
        const UserPreferences(lastUpdatedInstant: _kEpoch);
    return UserPreferencesReady(
      producerAccount: producerAccount,
      memberPreferences: const MemberPreferences(lastUpdatedInstant: _kEpoch),
      userPreferences: userPrefs,
    );
  }

  // ---------------------------------------------------------------------------
  // Dirty-recompute helper
  // ---------------------------------------------------------------------------

  /// Returns an updated [UserPreferencesReady] with [dirty] recomputed from
  /// whether any toggleable preference differs from the loaded entity.
  UserPreferencesReady _withUpdatedPrefs(
    UserPreferencesReady current, {
    MemberPreferences? memberPreferences,
    UserPreferences? userPreferences,
  }) {
    final newMemberPrefs = memberPreferences ?? current.memberPreferences;
    final newUserPrefs = userPreferences ?? current.userPreferences;

    final loadedUserPrefs = _loadedUserPrefs(current);

    // Member-specific dirty check (reminder/alert toggles).
    final memberDirty =
        current.member != null &&
        _isMemberPrefsDirty(
          newMemberPrefs,
          current.member!.memberPreferences ??
              const MemberPreferences(lastUpdatedInstant: _kEpoch),
        );

    final channelDirty =
        newUserPrefs.emailNotificationsEnabled !=
            loadedUserPrefs.emailNotificationsEnabled ||
        newUserPrefs.pushNotificationsEnabled !=
            loadedUserPrefs.pushNotificationsEnabled;

    return current.copyWith(
      memberPreferences: newMemberPrefs,
      userPreferences: newUserPrefs,
      dirty: memberDirty || channelDirty,
    );
  }

  /// Returns the baseline [UserPreferences] to compare against for dirty
  /// detection, derived from the currently loaded entity.
  UserPreferences _loadedUserPrefs(UserPreferencesReady current) {
    const epoch = UserPreferences(lastUpdatedInstant: _kEpoch);
    if (current.member != null) {
      return current.member!.userPreferences ?? epoch;
    } else if (current.owner != null) {
      return current.owner!.userPreferences ?? epoch;
    } else if (current.producerAccount != null) {
      return current.producerAccount!.userPreferences ?? epoch;
    }
    return epoch;
  }

  bool _isMemberPrefsDirty(
    MemberPreferences newPrefs,
    MemberPreferences loadedPrefs,
  ) =>
      newPrefs.reminder24hEnabled != loadedPrefs.reminder24hEnabled ||
      newPrefs.reminder2hEnabled != loadedPrefs.reminder2hEnabled ||
      newPrefs.reminder30minEnabled != loadedPrefs.reminder30minEnabled ||
      newPrefs.urgentNeedAlertsEnabled != loadedPrefs.urgentNeedAlertsEnabled ||
      newPrefs.incompleteSlotRemindersEnabled !=
          loadedPrefs.incompleteSlotRemindersEnabled ||
      newPrefs.planningChangesAlertsEnabled !=
          loadedPrefs.planningChangesAlertsEnabled;
}
