import 'dart:async';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {
  final _authStateController = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get authState => _authStateController.stream;

  @override
  AuthState get currentState => _currentState;
  AuthState _currentState = const AuthState.unauthenticated();

  Future<void> emitAuthenticated(String sub, List<String> roles) async {
    _currentState = AuthState.authenticated(
      producerId: sub,
      accessToken: 'mock-token-$sub',
      roles: roles,
    );
    _authStateController.add(_currentState);
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> bootstrap() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refreshSession() async {
    // Simulate session refresh with no role changes (in the real app,
    // the back would return updated roles in the JWT)
  }
}

void main() {
  group('AuthBloc with member role updates', () {
    late AppDatabase db;
    late _MockAuthService authService;
    late MemberRepository memberRepository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      authService = _MockAuthService();
      memberRepository = MemberRepository(db: db, idGenerator: IdGenerator());
      registerFallbackValue(AuthState.unauthenticated());
    });

    tearDown(() async {
      await db.close();
      await authService._authStateController.close();
    });

    blocTest<AuthBloc, AuthViewState>(
      'member roles update when database changes via watchMyMember stream',
      build: () {
        return AuthBloc(
          service: authService,
          db: db,
          memberRepository: memberRepository,
        );
      },
      setUp: () async {
        // Pre-populate the database with the member's current state
        final member = Member(
          memberId: 'user-123',
          organizationId: 'org-1',
          roles: {Role.admin},
          activeStatus: true,
        );
        await db.upsertMember('org-1', member);
      },
      act: (bloc) async {
        // Simulate authenticated user with ADMIN role
        await authService.emitAuthenticated('user-123', ['ADMIN']);
        await Future.delayed(const Duration(milliseconds: 50));

        // Simulate the member updating their own roles to include COORDINATOR
        final member = await db.getMember('org-1', 'user-123');
        if (member != null) {
          final updatedMember = member.copyWith(
            roles: {Role.admin, Role.coordinator},
          );
          await db.upsertMember('org-1', updatedMember);
        }

        // Give the bloc time to process the member stream update
        await Future.delayed(const Duration(milliseconds: 100));
      },
      skip: 1, // Skip the initial state from AuthBloc startup
      expect: () => [
        // State after first auth emission
        isA<AuthViewState>()
            .having((s) => s.role, 'role', UserRole.admin)
            .having((s) => s.memberRoles, 'memberRoles', {Role.admin}),
        // State after member database update via watchMyMember stream
        isA<AuthViewState>()
            .having((s) => s.role, 'role', UserRole.admin)
            .having(
              (s) => s.memberRoles,
              'memberRoles',
              containsAll([Role.admin, Role.coordinator]),
            ),
      ],
    );

    blocTest<AuthBloc, AuthViewState>(
      'prefers member database roles over JWT roles (source of truth: local database)',
      build: () {
        return AuthBloc(
          service: authService,
          db: db,
          memberRepository: memberRepository,
        );
      },
      setUp: () async {
        // Pre-populate the database with ADMIN role only
        final member = Member(
          memberId: 'user-123',
          organizationId: 'org-1',
          roles: {Role.admin},
          activeStatus: true,
        );
        await db.upsertMember('org-1', member);
      },
      act: (bloc) async {
        // Start authenticated as ADMIN
        await authService.emitAuthenticated('user-123', ['ADMIN']);
        await Future.delayed(const Duration(milliseconds: 50));

        // Even if JWT is refreshed with additional roles (COORDINATOR),
        // the local database is the source of truth for role display.
        // In a real scenario, the sync would have updated the DB first.
        await authService.emitAuthenticated('user-123', [
          'ADMIN',
          'COORDINATOR',
        ]);
        await Future.delayed(const Duration(milliseconds: 50));
      },
      skip: 1, // Skip the initial state
      expect: () => [
        // First auth sets roles from JWT
        isA<AuthViewState>()
            .having((s) => s.role, 'role', UserRole.admin)
            .having((s) => s.memberRoles, 'memberRoles', {Role.admin}),
        // Second auth emits with JWT roles (ADMIN + COORDINATOR)
        isA<AuthViewState>()
            .having((s) => s.role, 'role', UserRole.admin)
            .having(
              (s) => s.memberRoles,
              'memberRoles',
              containsAll([Role.admin, Role.coordinator]),
            ),
        // But then watchMyMember reads DB and reverts to DB value (ADMIN only)
        // This shows that local DB is the ultimate source of truth
        isA<AuthViewState>()
            .having((s) => s.role, 'role', UserRole.admin)
            .having((s) => s.memberRoles, 'memberRoles', {Role.admin}),
      ],
    );
  });
}
