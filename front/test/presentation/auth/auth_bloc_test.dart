import 'dart:async';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockRememberedUserContextStore extends Mock
    implements RememberedUserContextStore {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const RememberedUserContext(
        email: 'fallback@example.com',
        serverId: 'server-a',
        rememberMe: true,
      ),
    );
  });

  late _MockAuthService service;
  late _MockAppDatabase db;
  late _MockMemberRepository memberRepository;
  late _MockRememberedUserContextStore rememberedUserContextStore;
  late StreamController<AuthState> sessions;

  setUp(() {
    service = _MockAuthService();
    db = _MockAppDatabase();
    memberRepository = _MockMemberRepository();
    rememberedUserContextStore = _MockRememberedUserContextStore();
    sessions = StreamController<AuthState>.broadcast();
    when(() => service.authState).thenAnswer((_) => sessions.stream);
    when(() => service.bootstrap()).thenAnswer((_) async {});
    when(
      () => rememberedUserContextStore.write(any()),
    ).thenAnswer((_) async {});
    when(() => rememberedUserContextStore.clear()).thenAnswer((_) async {});
    when(
      () => db.watchEffectiveOrganizationId(any()),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => db.watchEffectiveProducerAccountId(),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => memberRepository.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(null));
    when(() => db.watchOwnerById(any())).thenAnswer((_) => Stream.value(null));
    when(
      () => db.watchProducerAccountById(any()),
    ).thenAnswer((_) => Stream.value(null));
  });

  tearDown(() async {
    await sessions.close();
  });

  blocTest<AuthBloc, AuthViewState>(
    'auto-fires Started → bootstrap called and initializing turns false',
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    wait: const Duration(milliseconds: 30),
    verify: (_) => verify(() => service.bootstrap()).called(1),
    expect: () => [const AuthViewState(initializing: false)],
  );

  blocTest<AuthBloc, AuthViewState>(
    'corrupted stored session on bootstrap clears session and turns initializing false',
    setUp: () {
      when(() => service.bootstrap()).thenThrow(Exception('corrupt session'));
      when(() => service.signOut()).thenAnswer((_) async {});
    },
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    wait: const Duration(milliseconds: 30),
    verify: (_) => verify(() => service.signOut()).called(1),
    expect: () => [const AuthViewState(initializing: false)],
  );

  blocTest<AuthBloc, AuthViewState>(
    'login success with admin role → isAdmin is true',
    setUp: () =>
        when(
          () => service.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberSession: any(named: 'rememberSession'),
          ),
        ).thenAnswer((_) async {
          sessions.add(
            const AuthState.authenticated(
              producerId: 'u-1',
              accessToken: 't',
              roles: ['OWNER'],
            ),
          );
        }),
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(
        const AuthEvent.loginSubmitted(
          email: 'a@b.c',
          password: 'pw',
          rememberMe: true,
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    skip: 1,
    expect: () => [
      const AuthViewState(initializing: false, submitting: true),
      const AuthViewState(
        initializing: false,
        producerId: 'u-1',
        isAdmin: true,
        role: UserRole.owner,
      ),
    ],
  );

  blocTest<AuthBloc, AuthViewState>(
    'login success emits Authenticated via service stream',
    setUp: () =>
        when(
          () => service.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberSession: any(named: 'rememberSession'),
          ),
        ).thenAnswer((_) async {
          sessions.add(
            const AuthState.authenticated(producerId: 'u-1', accessToken: 't'),
          );
        }),
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      // Let bootstrap drain.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(
        const AuthEvent.loginSubmitted(
          email: 'a@b.c',
          password: 'pw',
          rememberMe: true,
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    skip: 1, // skip initializing → false
    expect: () => [
      const AuthViewState(initializing: false, submitting: true),
      const AuthViewState(initializing: false, producerId: 'u-1'),
    ],
  );

  blocTest<AuthBloc, AuthViewState>(
    'login failure surfaces invalidCredentials',
    setUp: () => when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
        rememberSession: any(named: 'rememberSession'),
      ),
    ).thenThrow(const AuthException(AuthError.invalidCredentials)),
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(
        const AuthEvent.loginSubmitted(
          email: 'a@b.c',
          password: 'wrong',
          rememberMe: false,
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    skip: 1,
    expect: () => [
      const AuthViewState(initializing: false, submitting: true),
      const AuthViewState(
        initializing: false,
        submitting: false,
        lastError: AuthError.invalidCredentials,
      ),
    ],
  );

  blocTest<AuthBloc, AuthViewState>(
    'session expiry clears producerAccountId and surfaces an auth error',
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(
        const AuthState.authenticated(producerId: 'u-1', accessToken: 't'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(const AuthState.unauthenticated());
    },
    wait: const Duration(milliseconds: 60),
    skip: 1,
    expect: () => [
      const AuthViewState(initializing: false, producerId: 'u-1'),
      const AuthViewState(initializing: false, lastError: AuthError.unknown),
    ],
  );

  blocTest<AuthBloc, AuthViewState>(
    'manual logout clears producerAccountId without surfacing an auth error',
    setUp: () => when(() => service.signOut()).thenAnswer((_) async {
      sessions.add(const AuthState.unauthenticated());
    }),
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(
        const AuthState.authenticated(producerId: 'u-1', accessToken: 't'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AuthEvent.logoutRequested());
    },
    wait: const Duration(milliseconds: 60),
    skip: 1,
    expect: () => [
      const AuthViewState(initializing: false, producerId: 'u-1'),
      const AuthViewState(
        initializing: false,
        logoutRequested: true,
        producerId: 'u-1',
      ),
      const AuthViewState(initializing: false, logoutRequested: true),
    ],
  );

  blocTest<AuthBloc, AuthViewState>(
    'logout calls onLogout callback before signOut',
    setUp: () => when(() => service.signOut()).thenAnswer((_) async {
      sessions.add(const AuthState.unauthenticated());
    }),
    build: () {
      final calls = <String>[];
      return AuthBloc(
        service: service,
        db: db,
        memberRepository: memberRepository,
        rememberedUserContextStore: rememberedUserContextStore,
        serverId: 'server-a',
        onLogout: () async => calls.add('onLogout'),
      );
    },
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(
        const AuthState.authenticated(producerId: 'u-1', accessToken: 't'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AuthEvent.logoutRequested());
    },
    wait: const Duration(milliseconds: 60),
    verify: (_) => verify(() => service.signOut()).called(1),
  );

  blocTest<AuthBloc, AuthViewState>(
    'login success persists remembered user context with rememberMe',
    setUp: () => when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
        rememberSession: any(named: 'rememberSession'),
      ),
    ).thenAnswer((_) async {}),
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(
        const AuthEvent.loginSubmitted(
          email: 'a@b.c',
          password: 'pw',
          rememberMe: false,
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    skip: 1,
    verify: (_) {
      verify(
        () => service.signIn(
          email: 'a@b.c',
          password: 'pw',
          rememberSession: false,
        ),
      ).called(1);
      verify(
        () => rememberedUserContextStore.write(
          const RememberedUserContext(
            email: 'a@b.c',
            serverId: 'server-a',
            rememberMe: false,
          ),
        ),
      ).called(1);
    },
    expect: () => [
      const AuthViewState(initializing: false, submitting: true),
      const AuthViewState(initializing: false, submitting: false),
    ],
  );

  blocTest<AuthBloc, AuthViewState>(
    'owner session shows the owner name (not the technical id) in the menu',
    setUp: () => when(() => db.watchOwnerById('owner-1')).thenAnswer(
      (_) => Stream.value(
        const Owner(
          ownerId: 'owner-1',
          firstName: 'Alice',
          lastName: 'Martin',
          email: 'alice@example.com',
          registeredAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        ),
      ),
    ),
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(
        const AuthState.authenticated(
          producerId: 'owner-1',
          accessToken: 't',
          roles: ['OWNER'],
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) {
      expect(bloc.state.firstName, 'Alice');
      expect(bloc.state.lastName, 'Martin');
    },
  );

  blocTest<AuthBloc, AuthViewState>(
    'producer session shows the producer account name in the menu',
    setUp: () => when(() => db.watchProducerAccountById('pa-1')).thenAnswer(
      (_) => Stream.value(
        const ProducerAccount(producerAccountId: 'pa-1', name: 'Ferme du Val'),
      ),
    ),
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(
        const AuthState.authenticated(
          producerId: 'pa-1',
          accessToken: 't',
          roles: ['PRODUCER'],
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) => expect(bloc.state.firstName, 'Ferme du Val'),
  );

  blocTest<AuthBloc, AuthViewState>(
    'producer whose auth sub differs from its account id resolves the account '
    'id from the synced producer-account scope (tenant + menu name)',
    setUp: () {
      when(
        () => db.watchEffectiveProducerAccountId(),
      ).thenAnswer((_) => Stream.value('pa-real'));
      when(() => db.watchProducerAccountById('pa-real')).thenAnswer(
        (_) => Stream.value(
          const ProducerAccount(producerAccountId: 'pa-real', name: 'Ferme'),
        ),
      );
    },
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(
        const AuthState.authenticated(
          producerId: 'cognito-sub',
          accessToken: 't',
          roles: ['PRODUCER'],
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) {
      expect(bloc.state.producerAccountId, 'pa-real');
      expect(bloc.state.firstName, 'Ferme');
    },
  );

  blocTest<AuthBloc, AuthViewState>(
    'a new user logging in on the same tab does not inherit the previous '
    "user's organization (it would become the producer's tenant)",
    setUp: () {
      when(
        () => db.watchEffectiveOrganizationId(any()),
      ).thenAnswer((_) => Stream.value('org-1'));
    },
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sessions.add(
        const AuthState.authenticated(
          producerId: 'admin-sub',
          accessToken: 't',
          roles: ['ADMIN'],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      sessions.add(const AuthState.unauthenticated());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      sessions.add(
        const AuthState.authenticated(
          producerId: 'producer-sub',
          accessToken: 't2',
          roles: ['PRODUCER'],
        ),
      );
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) => expect(bloc.state.organizationId, isNull),
  );

  blocTest<AuthBloc, AuthViewState>(
    'a token refresh for the same user keeps the resolved organization',
    setUp: () {
      when(
        () => db.watchEffectiveOrganizationId(any()),
      ).thenAnswer((_) => Stream.value('org-1'));
    },
    build: () => AuthBloc(
      service: service,
      db: db,
      memberRepository: memberRepository,
      rememberedUserContextStore: rememberedUserContextStore,
      serverId: 'server-a',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      for (final token in ['t1', 't2']) {
        sessions.add(
          AuthState.authenticated(
            producerId: 'admin-sub',
            accessToken: token,
            roles: const ['ADMIN'],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) => expect(bloc.state.organizationId, 'org-1'),
  );
}
