import 'dart:async';

import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/nav/nav_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/nav_event.dart';
import 'package:amap_en_ligne/presentation/nav/nav_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_auth_bloc.dart';

void main() {
  late MockAuthBloc authBloc;
  late StreamController<AuthViewState> authStateController;

  setUpAll(registerAuthFallbackValues);

  setUp(() {
    authStateController = StreamController<AuthViewState>.broadcast();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthViewState());
    when(() => authBloc.stream).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() async {
    await authStateController.close();
  });

  group('NavBloc initial state', () {
    test('starts with memberNoRole and items built for that role', () {
      final bloc = NavBloc(authBloc: authBloc);
      // After construction, a roleChanged event is added synchronously — wait
      // for it to be processed.
      expect(bloc.state.isOpen, isFalse);
      bloc.close();
    });
  });

  blocTest<NavBloc, NavState>(
    'NavOpened sets isOpen to true',
    setUp: () {
      when(() => authBloc.state).thenReturn(const AuthViewState());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    },
    build: () => NavBloc(authBloc: authBloc),
    act: (bloc) => bloc.add(const NavEvent.opened()),
    skip: 1, // skip the initial roleChanged emission
    expect: () => [isA<NavState>().having((s) => s.isOpen, 'isOpen', isTrue)],
  );

  blocTest<NavBloc, NavState>(
    'NavClosed sets isOpen to false after NavOpened',
    setUp: () {
      when(() => authBloc.state).thenReturn(const AuthViewState());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    },
    build: () => NavBloc(authBloc: authBloc),
    act: (bloc) async {
      bloc.add(const NavEvent.opened());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const NavEvent.closed());
    },
    skip: 1,
    expect: () => [
      isA<NavState>().having((s) => s.isOpen, 'isOpen', isTrue),
      isA<NavState>().having((s) => s.isOpen, 'isOpen', isFalse),
    ],
  );

  blocTest<NavBloc, NavState>(
    'NavRoleChanged updates role and items, closes menu',
    setUp: () {
      when(() => authBloc.state).thenReturn(const AuthViewState());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    },
    build: () => NavBloc(authBloc: authBloc),
    act: (bloc) async {
      bloc.add(const NavEvent.opened());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(
        const NavEvent.roleChanged(
          role: UserRole.producer,
          memberRoles: <Role>{},
        ),
      );
    },
    skip: 1,
    expect: () => [
      isA<NavState>().having((s) => s.isOpen, 'isOpen', isTrue),
      isA<NavState>()
          .having((s) => s.isOpen, 'isOpen', isFalse)
          .having((s) => s.role, 'role', UserRole.producer)
          .having(
            (s) => s.items.map((i) => i.label),
            'item labels',
            containsAll(['Accueil producteur', 'Se déconnecter']),
          ),
    ],
  );

  blocTest<NavBloc, NavState>(
    'reacts to AuthBloc stream → role changes when auth state changes',
    setUp: () {
      when(() => authBloc.state).thenReturn(const AuthViewState());
      when(() => authBloc.stream).thenAnswer((_) => authStateController.stream);
    },
    build: () => NavBloc(authBloc: authBloc),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      authStateController.add(
        const AuthViewState(
          producerId: 'u-1',
          role: UserRole.admin,
          memberRoles: {Role.admin},
        ),
      );
    },
    wait: const Duration(milliseconds: 30),
    skip: 1, // initial roleChanged
    expect: () => [
      isA<NavState>()
          .having((s) => s.role, 'role', UserRole.admin)
          .having(
            (s) => s.items.map((i) => i.label),
            'labels',
            containsAll([
              'Accueil',
              'Utilisateurs',
              'Producteurs',
              'Templates de livraison',
              "Demandes d'adhésion",
            ]),
          ),
    ],
  );

  blocTest<NavBloc, NavState>(
    'initial auth state with owner role → owner items',
    setUp: () {
      when(() => authBloc.state).thenReturn(
        const AuthViewState(
          producerId: 'u-1',
          isAdmin: true,
          role: UserRole.owner,
          memberRoles: <Role>{},
        ),
      );
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    },
    build: () => NavBloc(authBloc: authBloc),
    expect: () => [
      isA<NavState>()
          .having((s) => s.role, 'role', UserRole.owner)
          .having(
            (s) => s.items.map((i) => i.label),
            'labels',
            containsAll([
              'Accueil',
              "Demandes d'organisation",
              'Utilisateurs',
              'Se déconnecter',
            ]),
          ),
    ],
  );

  blocTest<NavBloc, NavState>(
    'sign-out item onTap dispatches logoutRequested to AuthBloc',
    setUp: () {
      when(() => authBloc.state).thenReturn(const AuthViewState());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => authBloc.add(any())).thenReturn(null);
    },
    build: () => NavBloc(authBloc: authBloc),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final signOut = bloc.state.items.firstWhere(
        (i) => i.label == 'Se déconnecter',
      );
      signOut.onTap!();
    },
    verify: (_) {
      verify(() => authBloc.add(const AuthEvent.logoutRequested())).called(1);
    },
  );
}
