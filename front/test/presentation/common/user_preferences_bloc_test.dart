import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOwnerRepository extends Mock implements OwnerRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _FakeMemberPreferences extends Fake implements MemberPreferences {}

class _FakeUserPreferences extends Fake implements UserPreferences {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _kInstant = '2025-01-01T00:00:00.000Z';

const _memberPrefs = MemberPreferences(
  deliveryRemindersEnabled: true,
  volunteerAlertsEnabled: true,
  reminder24hEnabled: true,
  reminder2hEnabled: true,
  reminder30minEnabled: false,
  urgentNeedAlertsEnabled: true,
  incompleteSlotRemindersEnabled: false,
  planningChangesAlertsEnabled: true,
  lastUpdatedInstant: _kInstant,
);

const _userPrefs = UserPreferences(
  emailNotificationsEnabled: true,
  pushNotificationsEnabled: true,
  lastUpdatedInstant: _kInstant,
);

Member _member({
  String id = 'm-1',
  String orgId = 'org-1',
  MemberPreferences? memberPreferences = _memberPrefs,
  UserPreferences? userPreferences = _userPrefs,
}) => Member(
  memberId: id,
  organizationId: orgId,
  roles: const {Role.volunteer},
  memberPreferences: memberPreferences,
  userPreferences: userPreferences,
);

Owner _owner({
  String id = 'o-1',
  UserPreferences? userPreferences = _userPrefs,
}) => Owner(
  ownerId: id,
  firstName: 'Alice',
  lastName: 'Dupont',
  email: 'alice@example.com',
  registeredAt: _kInstant,
  updatedAt: _kInstant,
  userPreferences: userPreferences,
);

ProducerAccount _producer({
  String id = 'pa-1',
  UserPreferences? userPreferences = _userPrefs,
}) => ProducerAccount(
  producerAccountId: id,
  name: 'Ferme du Test',
  userPreferences: userPreferences,
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Drains microtasks until the bloc emits a non-loading state or times out.
Future<UserPreferencesState> _awaitReady(UserPreferencesBloc bloc) async {
  await bloc.stream
      .firstWhere((s) => s is! UserPreferencesLoading)
      .timeout(const Duration(seconds: 5));
  for (var i = 0; i < 10; i++) {
    await Future<void>.value();
  }
  final s = bloc.state;
  if (s is! UserPreferencesLoading) return s;
  return bloc.stream
      .firstWhere((s) => s is! UserPreferencesLoading)
      .timeout(const Duration(seconds: 5));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMemberPreferences());
    registerFallbackValue(_FakeUserPreferences());
  });

  late _MockMemberRepository memberRepo;

  setUp(() {
    memberRepo = _MockMemberRepository();
  });

  UserPreferencesBloc buildBloc({String memberId = 's-1'}) =>
      UserPreferencesBloc(
        source: MemberSource(memberId: memberId, memberRepository: memberRepo),
      );

  // --------------------------------------------------------------------------
  // Initial load
  // --------------------------------------------------------------------------

  test('emits loading then missing when stream emits null', () async {
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(null));

    final bloc = buildBloc();
    expect(bloc.state, const UserPreferencesState.loading());

    final state = await _awaitReady(bloc);
    expect(state, const UserPreferencesState.missing());

    await bloc.close();
  });

  test('emits loading then ready when stream emits a Member', () async {
    final member = _member();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(member));

    final bloc = buildBloc();
    expect(bloc.state, const UserPreferencesState.loading());

    final state = await _awaitReady(bloc);
    expect(state, isA<UserPreferencesReady>());
    final ready = state as UserPreferencesReady;
    expect(ready.member, member);
    expect(ready.memberPreferences, _memberPrefs);
    expect(ready.userPreferences, _userPrefs);
    expect(ready.dirty, isFalse);
    expect(ready.saveStatus, SaveStatus.idle);

    await bloc.close();
  });

  test(
    'ready state uses Freezed defaults when member has null preferences',
    () async {
      final member = _member(memberPreferences: null, userPreferences: null);
      when(
        () => memberRepo.watchMyMember(any()),
      ).thenAnswer((_) => Stream.value(member));

      final bloc = buildBloc();
      final state = await _awaitReady(bloc);
      expect(state, isA<UserPreferencesReady>());
      final ready = state as UserPreferencesReady;
      // Freezed defaults: reminder24h=true, reminder30min=false, push=true
      expect(ready.memberPreferences.reminder24hEnabled, isTrue);
      expect(ready.memberPreferences.reminder30minEnabled, isFalse);
      expect(ready.userPreferences.pushNotificationsEnabled, isTrue);

      await bloc.close();
    },
  );

  // --------------------------------------------------------------------------
  // Toggles
  // --------------------------------------------------------------------------

  test('reminderToggled updates preference and sets dirty=true', () async {
    final member = _member();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(member));

    final bloc = buildBloc();
    await _awaitReady(bloc);

    bloc.add(
      const UserPreferencesEvent.reminderToggled(
        ReminderField.reminder30min,
        true,
      ),
    );
    await Future<void>.value();

    final state = bloc.state as UserPreferencesReady;
    expect(state.memberPreferences.reminder30minEnabled, isTrue);
    expect(state.dirty, isTrue);

    await bloc.close();
  });

  test('alertToggled updates preference and sets dirty=true', () async {
    final member = _member();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(member));

    final bloc = buildBloc();
    await _awaitReady(bloc);

    bloc.add(
      const UserPreferencesEvent.alertToggled(AlertField.incompleteSlot, true),
    );
    await Future<void>.value();

    final state = bloc.state as UserPreferencesReady;
    expect(state.memberPreferences.incompleteSlotRemindersEnabled, isTrue);
    expect(state.dirty, isTrue);

    await bloc.close();
  });

  test('channelToggled updates preference and sets dirty=true', () async {
    final member = _member();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(member));

    final bloc = buildBloc();
    await _awaitReady(bloc);

    bloc.add(
      const UserPreferencesEvent.channelToggled(ChannelField.email, false),
    );
    await Future<void>.value();

    final state = bloc.state as UserPreferencesReady;
    expect(state.userPreferences.emailNotificationsEnabled, isFalse);
    expect(state.dirty, isTrue);

    await bloc.close();
  });

  test('toggling back to original value resets dirty=false', () async {
    final member = _member();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(member));

    final bloc = buildBloc();
    await _awaitReady(bloc);

    // Toggle on then back off — net change is zero.
    bloc.add(
      const UserPreferencesEvent.reminderToggled(
        ReminderField.reminder30min,
        true,
      ),
    );
    await Future<void>.value();
    expect((bloc.state as UserPreferencesReady).dirty, isTrue);

    bloc.add(
      const UserPreferencesEvent.reminderToggled(
        ReminderField.reminder30min,
        false,
      ),
    );
    await Future<void>.value();
    expect((bloc.state as UserPreferencesReady).dirty, isFalse);

    await bloc.close();
  });

  test(
    'profileSaved calls memberRepo.updateProfile and emits success',
    () async {
      final member = _member();
      when(
        () => memberRepo.watchMyMember(any()),
      ).thenAnswer((_) => Stream.value(member));
      when(
        () => memberRepo.updateProfile(
          memberId: any(named: 'memberId'),
          organizationId: any(named: 'organizationId'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => 'client-op-1');

      final bloc = buildBloc();
      await _awaitReady(bloc);

      final states = <UserPreferencesState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const UserPreferencesEvent.profileSaved(
          firstName: 'Alice',
          lastName: 'Dupont',
          email: 'alice@example.com',
          phone: null,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final last = states.last as UserPreferencesReady;
      expect(last.profileSaveStatus, SaveStatus.success);

      verify(
        () => memberRepo.updateProfile(
          memberId: 'm-1',
          organizationId: 'org-1',
          firstName: 'Alice',
          lastName: 'Dupont',
          email: 'alice@example.com',
          phone: null,
        ),
      ).called(1);

      await bloc.close();
    },
  );

  test(
    'profileSaved emits failure when memberRepo.updateProfile throws',
    () async {
      final member = _member();
      when(
        () => memberRepo.watchMyMember(any()),
      ).thenAnswer((_) => Stream.value(member));
      when(
        () => memberRepo.updateProfile(
          memberId: any(named: 'memberId'),
          organizationId: any(named: 'organizationId'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenThrow(Exception('network error'));

      final bloc = buildBloc();
      await _awaitReady(bloc);

      final states = <UserPreferencesState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const UserPreferencesEvent.profileSaved(
          firstName: 'Alice',
          lastName: 'Dupont',
          email: 'alice@example.com',
          phone: null,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final last = states.last as UserPreferencesReady;
      expect(last.profileSaveStatus, SaveStatus.failure);
      expect(last.profileSaveErrorMessage, isNotNull);

      await bloc.close();
    },
  );

  // --------------------------------------------------------------------------
  // Save — success
  // --------------------------------------------------------------------------

  test('saved emits saving then success and dirty=false', () async {
    final member = _member();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(member));
    when(
      () => memberRepo.updatePreferences(
        memberId: any(named: 'memberId'),
        organizationId: any(named: 'organizationId'),
        memberPreferences: any(named: 'memberPreferences'),
        userPreferences: any(named: 'userPreferences'),
      ),
    ).thenAnswer((_) async {});

    final bloc = buildBloc();
    await _awaitReady(bloc);

    // Mark dirty first so the save is meaningful.
    bloc.add(
      const UserPreferencesEvent.channelToggled(ChannelField.email, false),
    );
    await Future<void>.value();

    final states = <UserPreferencesState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const UserPreferencesEvent.saved());
    await Future.delayed(const Duration(milliseconds: 50));

    await sub.cancel();

    expect(
      states.any(
        (s) => s is UserPreferencesReady && s.saveStatus == SaveStatus.saving,
      ),
      isTrue,
    );
    final last = states.last as UserPreferencesReady;
    expect(last.saveStatus, SaveStatus.success);
    expect(last.dirty, isFalse);

    verify(
      () => memberRepo.updatePreferences(
        memberId: 'm-1',
        organizationId: 'org-1',
        memberPreferences: any(named: 'memberPreferences'),
        userPreferences: any(named: 'userPreferences'),
      ),
    ).called(1);

    await bloc.close();
  });

  // --------------------------------------------------------------------------
  // Save — failure
  // --------------------------------------------------------------------------

  test('saved emits saving then failure and keeps dirty=true', () async {
    final member = _member();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(member));
    when(
      () => memberRepo.updatePreferences(
        memberId: any(named: 'memberId'),
        organizationId: any(named: 'organizationId'),
        memberPreferences: any(named: 'memberPreferences'),
        userPreferences: any(named: 'userPreferences'),
      ),
    ).thenThrow(Exception('network error'));

    final bloc = buildBloc();
    await _awaitReady(bloc);

    bloc.add(
      const UserPreferencesEvent.channelToggled(ChannelField.email, false),
    );
    await Future<void>.value();

    final states = <UserPreferencesState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const UserPreferencesEvent.saved());
    await Future.delayed(const Duration(milliseconds: 50));

    await sub.cancel();

    final last = states.last as UserPreferencesReady;
    expect(last.saveStatus, SaveStatus.failure);
    expect(last.saveErrorMessage, isNotNull);
    expect(last.dirty, isTrue);

    await bloc.close();
  });

  // --------------------------------------------------------------------------
  // Dirty-guard: stream re-emission while dirty=true is ignored
  // --------------------------------------------------------------------------

  test('stream re-emission while dirty=true does not reset state', () async {
    final controller = StreamController<Member?>();
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => controller.stream);

    final bloc = buildBloc();

    // Seed with a member.
    controller.add(_member());
    await _awaitReady(bloc);

    // Dirty the state.
    bloc.add(
      const UserPreferencesEvent.reminderToggled(
        ReminderField.reminder30min,
        true,
      ),
    );
    await Future<void>.value();
    expect((bloc.state as UserPreferencesReady).dirty, isTrue);

    // Simulate the optimistic-write re-emission from drift.
    controller.add(_member());
    // Drain microtasks.
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }

    // State must still have the user's edit and dirty=true.
    final state = bloc.state as UserPreferencesReady;
    expect(state.dirty, isTrue);
    expect(state.memberPreferences.reminder30minEnabled, isTrue);

    await controller.close();
    await bloc.close();
  });

  // --------------------------------------------------------------------------
  // Stream re-emission after successful save re-seeds normally
  // --------------------------------------------------------------------------

  test(
    'stream re-emission after save success (dirty=false) re-seeds state',
    () async {
      final controller = StreamController<Member?>();
      when(
        () => memberRepo.watchMyMember(any()),
      ).thenAnswer((_) => controller.stream);
      when(
        () => memberRepo.updatePreferences(
          memberId: any(named: 'memberId'),
          organizationId: any(named: 'organizationId'),
          memberPreferences: any(named: 'memberPreferences'),
          userPreferences: any(named: 'userPreferences'),
        ),
      ).thenAnswer((_) async {});

      final bloc = buildBloc();

      controller.add(_member());
      await _awaitReady(bloc);

      bloc.add(
        const UserPreferencesEvent.channelToggled(ChannelField.email, false),
      );
      await Future<void>.value();

      bloc.add(const UserPreferencesEvent.saved());
      await Future.delayed(const Duration(milliseconds: 50));

      // After save success dirty=false.
      expect((bloc.state as UserPreferencesReady).dirty, isFalse);

      // A server-confirmed member re-emitted by drift.
      final confirmedMember = _member(
        userPreferences: const UserPreferences(
          emailNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          lastUpdatedInstant: '2025-06-01T00:00:00.000Z',
        ),
      );
      controller.add(confirmedMember);
      for (var i = 0; i < 10; i++) {
        await Future<void>.value();
      }

      final state = bloc.state as UserPreferencesReady;
      // Re-seeded from the new stream emission.
      expect(
        state.userPreferences.lastUpdatedInstant,
        '2025-06-01T00:00:00.000Z',
      );

      await controller.close();
      await bloc.close();
    },
  );

  // --------------------------------------------------------------------------
  // saved is a no-op when state is not ready
  // --------------------------------------------------------------------------

  test('saved is a no-op when state is loading', () async {
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => const Stream.empty());

    final bloc = buildBloc();
    expect(bloc.state, const UserPreferencesState.loading());

    bloc.add(const UserPreferencesEvent.saved());
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }

    expect(bloc.state, const UserPreferencesState.loading());
    verifyNever(
      () => memberRepo.updatePreferences(
        memberId: any(named: 'memberId'),
        organizationId: any(named: 'organizationId'),
        memberPreferences: any(named: 'memberPreferences'),
        userPreferences: any(named: 'userPreferences'),
      ),
    );

    await bloc.close();
  });

  // --------------------------------------------------------------------------
  // OwnerSource
  // --------------------------------------------------------------------------

  group('OwnerSource', () {
    late _MockOwnerRepository ownerRepo;

    setUp(() {
      ownerRepo = _MockOwnerRepository();
    });

    UserPreferencesBloc buildOwnerBloc({String ownerId = 's-1'}) =>
        UserPreferencesBloc(
          source: OwnerSource(ownerId: ownerId, ownerRepository: ownerRepo),
        );

    test('emits loading then ready with owner field set', () async {
      final owner = _owner();
      when(
        () => ownerRepo.watchMySelf(any()),
      ).thenAnswer((_) => Stream.value(owner));

      final bloc = buildOwnerBloc();
      expect(bloc.state, const UserPreferencesState.loading());

      final state = await _awaitReady(bloc);
      expect(state, isA<UserPreferencesReady>());
      final ready = state as UserPreferencesReady;
      expect(ready.owner, owner);
      expect(ready.member, isNull);
      expect(ready.producerAccount, isNull);
      expect(ready.userPreferences, _userPrefs);
      expect(ready.dirty, isFalse);

      await bloc.close();
    });

    test('emits missing when stream emits null', () async {
      when(
        () => ownerRepo.watchMySelf(any()),
      ).thenAnswer((_) => Stream.value(null));

      final bloc = buildOwnerBloc();
      final state = await _awaitReady(bloc);
      expect(state, const UserPreferencesState.missing());

      await bloc.close();
    });

    test(
      'channelToggled updates userPreferences and sets dirty=true',
      () async {
        final owner = _owner();
        when(
          () => ownerRepo.watchMySelf(any()),
        ).thenAnswer((_) => Stream.value(owner));

        final bloc = buildOwnerBloc();
        await _awaitReady(bloc);

        bloc.add(
          const UserPreferencesEvent.channelToggled(ChannelField.email, false),
        );
        await Future<void>.value();

        final state = bloc.state as UserPreferencesReady;
        expect(state.userPreferences.emailNotificationsEnabled, isFalse);
        expect(state.dirty, isTrue);

        await bloc.close();
      },
    );

    test(
      'saved calls ownerRepo.updateUserPreferences and clears dirty',
      () async {
        final owner = _owner();
        when(
          () => ownerRepo.watchMySelf(any()),
        ).thenAnswer((_) => Stream.value(owner));
        when(
          () => ownerRepo.updateUserPreferences(any(), any()),
        ).thenAnswer((_) async {});

        final bloc = buildOwnerBloc();
        await _awaitReady(bloc);

        bloc.add(
          const UserPreferencesEvent.channelToggled(ChannelField.email, false),
        );
        await Future<void>.value();

        final states = <UserPreferencesState>[];
        final sub = bloc.stream.listen(states.add);
        bloc.add(const UserPreferencesEvent.saved());
        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        final last = states.last as UserPreferencesReady;
        expect(last.saveStatus, SaveStatus.success);
        expect(last.dirty, isFalse);

        verify(() => ownerRepo.updateUserPreferences('o-1', any())).called(1);

        await bloc.close();
      },
    );
  });

  // --------------------------------------------------------------------------
  // ProducerSource
  // --------------------------------------------------------------------------

  group('ProducerSource', () {
    late _MockProducerAccountRepository producerRepo;

    setUp(() {
      producerRepo = _MockProducerAccountRepository();
    });

    UserPreferencesBloc buildProducerBloc({
      String producerAccountId = 'pa-1',
    }) => UserPreferencesBloc(
      source: ProducerSource(
        producerAccountId: producerAccountId,
        producerAccountRepository: producerRepo,
      ),
    );

    test('emits loading then ready with producerAccount field set', () async {
      final producer = _producer();
      when(
        () => producerRepo.watchMine(any()),
      ).thenAnswer((_) => Stream.value(producer));

      final bloc = buildProducerBloc();
      expect(bloc.state, const UserPreferencesState.loading());

      final state = await _awaitReady(bloc);
      expect(state, isA<UserPreferencesReady>());
      final ready = state as UserPreferencesReady;
      expect(ready.producerAccount, producer);
      expect(ready.member, isNull);
      expect(ready.owner, isNull);
      expect(ready.userPreferences, _userPrefs);
      expect(ready.dirty, isFalse);

      await bloc.close();
    });

    test('emits missing when stream emits null', () async {
      when(
        () => producerRepo.watchMine(any()),
      ).thenAnswer((_) => Stream.value(null));

      final bloc = buildProducerBloc();
      final state = await _awaitReady(bloc);
      expect(state, const UserPreferencesState.missing());

      await bloc.close();
    });

    test(
      'channelToggled updates userPreferences and sets dirty=true',
      () async {
        final producer = _producer();
        when(
          () => producerRepo.watchMine(any()),
        ).thenAnswer((_) => Stream.value(producer));

        final bloc = buildProducerBloc();
        await _awaitReady(bloc);

        bloc.add(
          const UserPreferencesEvent.channelToggled(ChannelField.push, false),
        );
        await Future<void>.value();

        final state = bloc.state as UserPreferencesReady;
        expect(state.userPreferences.pushNotificationsEnabled, isFalse);
        expect(state.dirty, isTrue);

        await bloc.close();
      },
    );

    test(
      'saved calls producerRepo.updateUserPreferences and clears dirty',
      () async {
        final producer = _producer();
        when(
          () => producerRepo.watchMine(any()),
        ).thenAnswer((_) => Stream.value(producer));
        when(
          () => producerRepo.updateUserPreferences(any(), any()),
        ).thenAnswer((_) async {});

        final bloc = buildProducerBloc();
        await _awaitReady(bloc);

        bloc.add(
          const UserPreferencesEvent.channelToggled(ChannelField.push, false),
        );
        await Future<void>.value();

        final states = <UserPreferencesState>[];
        final sub = bloc.stream.listen(states.add);
        bloc.add(const UserPreferencesEvent.saved());
        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        final last = states.last as UserPreferencesReady;
        expect(last.saveStatus, SaveStatus.success);
        expect(last.dirty, isFalse);

        verify(
          () => producerRepo.updateUserPreferences('pa-1', any()),
        ).called(1);

        await bloc.close();
      },
    );

    test(
      'profileSaved calls producerRepo.updateProfile and emits success',
      () async {
        final producer = _producer();
        when(
          () => producerRepo.watchMine(any()),
        ).thenAnswer((_) => Stream.value(producer));
        when(
          () => producerRepo.updateProfile(
            producerAccountId: any(named: 'producerAccountId'),
            name: any(named: 'name'),
            contactEmail: any(named: 'contactEmail'),
            address: any(named: 'address'),
            website: any(named: 'website'),
          ),
        ).thenAnswer((_) async {});

        final bloc = buildProducerBloc();
        await _awaitReady(bloc);

        final states = <UserPreferencesState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(
          const UserPreferencesEvent.profileSaved(
            producerName: 'Ferme Modifiée',
            contactEmail: null,
            address: null,
            website: null,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        final last = states.last as UserPreferencesReady;
        expect(last.profileSaveStatus, SaveStatus.success);

        verify(
          () => producerRepo.updateProfile(
            producerAccountId: 'pa-1',
            name: 'Ferme Modifiée',
            contactEmail: null,
            address: null,
            website: null,
          ),
        ).called(1);

        await bloc.close();
      },
    );
  });

  // --------------------------------------------------------------------------
  // OwnerSource — profileSaved
  // --------------------------------------------------------------------------

  group('OwnerSource profileSaved', () {
    late _MockOwnerRepository ownerRepo;

    setUp(() {
      ownerRepo = _MockOwnerRepository();
    });

    UserPreferencesBloc buildOwnerBloc({String ownerId = 's-1'}) =>
        UserPreferencesBloc(
          source: OwnerSource(ownerId: ownerId, ownerRepository: ownerRepo),
        );

    test(
      'profileSaved calls ownerRepo.updateProfile and emits success',
      () async {
        final owner = _owner();
        when(
          () => ownerRepo.watchMySelf(any()),
        ).thenAnswer((_) => Stream.value(owner));
        when(
          () => ownerRepo.updateProfile(
            ownerId: any(named: 'ownerId'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async {});

        final bloc = buildOwnerBloc();
        await _awaitReady(bloc);

        final states = <UserPreferencesState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(
          const UserPreferencesEvent.profileSaved(
            firstName: 'Bob',
            lastName: 'Martin',
            email: 'bob@example.com',
            phone: null,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        final last = states.last as UserPreferencesReady;
        expect(last.profileSaveStatus, SaveStatus.success);

        verify(
          () => ownerRepo.updateProfile(
            ownerId: 'o-1',
            firstName: 'Bob',
            lastName: 'Martin',
            email: 'bob@example.com',
            phone: null,
          ),
        ).called(1);

        await bloc.close();
      },
    );

    test(
      'profileSaved emits failure when ownerRepo.updateProfile throws',
      () async {
        final owner = _owner();
        when(
          () => ownerRepo.watchMySelf(any()),
        ).thenAnswer((_) => Stream.value(owner));
        when(
          () => ownerRepo.updateProfile(
            ownerId: any(named: 'ownerId'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenThrow(Exception('network error'));

        final bloc = buildOwnerBloc();
        await _awaitReady(bloc);

        final states = <UserPreferencesState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(
          const UserPreferencesEvent.profileSaved(
            firstName: 'Bob',
            lastName: 'Martin',
            email: 'bob@example.com',
            phone: null,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        final last = states.last as UserPreferencesReady;
        expect(last.profileSaveStatus, SaveStatus.failure);
        expect(last.profileSaveErrorMessage, isNotNull);

        await bloc.close();
      },
    );
  });
}
