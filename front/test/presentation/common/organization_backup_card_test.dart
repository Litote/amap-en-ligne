import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_bloc.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockAdminApi extends Mock implements AdminApi {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

const _kInstant = '2025-01-01T00:00:00.000Z';

Member _member() => const Member(
  memberId: 'm-1',
  organizationId: 'org-1',
  roles: {Role.admin},
  memberPreferences: MemberPreferences(
    deliveryRemindersEnabled: true,
    volunteerAlertsEnabled: true,
    reminder24hEnabled: true,
    reminder2hEnabled: true,
    reminder30minEnabled: false,
    urgentNeedAlertsEnabled: true,
    incompleteSlotRemindersEnabled: false,
    planningChangesAlertsEnabled: true,
    lastUpdatedInstant: _kInstant,
  ),
  userPreferences: UserPreferences(
    emailNotificationsEnabled: true,
    pushNotificationsEnabled: true,
    lastUpdatedInstant: _kInstant,
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  required _MockMemberRepository memberRepo,
  required _MockAuthService authService,
  required _MockSyncBloc syncBloc,
  required _MockAdminApi adminApi,
}) async {
  await tester.pumpWidget(
    RepositoryProvider<AuthService>.value(
      value: authService,
      child: RepositoryProvider<AdminApi>.value(
        value: adminApi,
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: MaterialApp(
            home: BlocProvider<UserPreferencesBloc>(
              create: (_) => UserPreferencesBloc(
                source: MemberSource(
                  memberId: 's-1',
                  memberRepository: memberRepo,
                ),
              ),
              child: const UserPreferencesScreen(backupOrganizationId: 'org-1'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() => registerFallbackValue(const SyncEvent.mutationApplied()));

  late _MockMemberRepository memberRepo;
  late _MockAuthService authService;
  late _MockSyncBloc syncBloc;
  late _MockAdminApi adminApi;

  setUp(() {
    memberRepo = _MockMemberRepository();
    authService = _MockAuthService();
    syncBloc = _MockSyncBloc();
    adminApi = _MockAdminApi();

    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => authService.currentState).thenReturn(
      const AuthState.authenticated(
        producerId: 'pa-1',
        accessToken: 'x',
        roles: [],
      ),
    );
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => Stream.value(_member()));
  });

  testWidgets('renders the backup card with the export button', (tester) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
      adminApi: adminApi,
    );

    expect(find.text('Sauvegarde & migration'), findsOneWidget);
    expect(find.byKey(const Key('export_organization_button')), findsOneWidget);
  });

  testWidgets('hides the import button on non-web platforms', (tester) async {
    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
      adminApi: adminApi,
    );

    // Widget tests run on the Dart VM (kIsWeb == false) → import is web-only.
    expect(find.byKey(const Key('import_organization_button')), findsNothing);
  });

  testWidgets('export taps call AdminApi.exportOrganization', (tester) async {
    when(
      () => adminApi.exportOrganization('org-1'),
    ).thenAnswer((_) async => '{"format_version":1}');

    await _pump(
      tester,
      memberRepo: memberRepo,
      authService: authService,
      syncBloc: syncBloc,
      adminApi: adminApi,
    );

    final exportButton = find.byKey(const Key('export_organization_button'));
    await tester.ensureVisible(exportButton);
    await tester.tap(exportButton);
    await tester.pump();

    verify(() => adminApi.exportOrganization('org-1')).called(1);
  });
}
