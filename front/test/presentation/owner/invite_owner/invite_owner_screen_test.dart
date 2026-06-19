import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/owner/invite_owner/invite_owner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockOwnerInvitationRepository extends Mock
    implements OwnerInvitationRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required OwnerInvitationRepository repository,
  required SyncRepository syncRepository,
}) async {
  final router = GoRouter(
    initialLocation: '/owner/invite-administrator',
    routes: [
      GoRoute(
        path: '/owner/invite-administrator',
        builder: (_, _) => const InviteOwnerScreen(),
      ),
      GoRoute(
        path: '/owner/users',
        builder: (_, _) => const Scaffold(body: Text('users-list')),
      ),
      GoRoute(
        path: '/owner/dashboard',
        builder: (_, _) => const Scaffold(body: Text('dashboard')),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OwnerInvitationRepository>.value(value: repository),
        RepositoryProvider<SyncRepository>.value(value: syncRepository),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockOwnerInvitationRepository repository;
  late _MockSyncRepository syncRepository;

  setUp(() {
    repository = _MockOwnerInvitationRepository();
    syncRepository = _MockSyncRepository();
  });

  group('InviteOwnerScreen', () {
    testWidgets('renders form fields and informational copy', (tester) async {
      await _pumpScreen(
        tester,
        repository: repository,
        syncRepository: syncRepository,
      );

      expect(find.byKey(const Key('first_name_field')), findsOneWidget);
      expect(find.byKey(const Key('last_name_field')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('send_invitation_button')), findsOneWidget);
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
      expect(find.text("Conséquences de l'invitation"), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await _pumpScreen(
        tester,
        repository: repository,
        syncRepository: syncRepository,
      );

      await tester.ensureVisible(
        find.byKey(const Key('send_invitation_button')),
      );
      await tester.tap(find.byKey(const Key('send_invitation_button')));
      await tester.pump();

      expect(find.text('Ce champ est requis.'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows email validation error for invalid email', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        repository: repository,
        syncRepository: syncRepository,
      );

      await tester.enterText(find.byKey(const Key('first_name_field')), 'Jean');
      await tester.enterText(
        find.byKey(const Key('last_name_field')),
        'Dupont',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'not-an-email',
      );
      await tester.ensureVisible(
        find.byKey(const Key('send_invitation_button')),
      );
      await tester.tap(find.byKey(const Key('send_invitation_button')));
      await tester.pump();

      expect(find.text('Adresse email invalide.'), findsOneWidget);
    });

    testWidgets('shows confirmation view on success', (tester) async {
      when(
        () => repository.create(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => 'op-1');
      when(
        () => syncRepository.sync(tenantId: any(named: 'tenantId')),
      ).thenAnswer((_) async => const SyncOutcome.success());

      await _pumpScreen(
        tester,
        repository: repository,
        syncRepository: syncRepository,
      );

      await tester.enterText(find.byKey(const Key('first_name_field')), 'Jean');
      await tester.enterText(
        find.byKey(const Key('last_name_field')),
        'Dupont',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'jean@example.fr',
      );
      await tester.ensureVisible(
        find.byKey(const Key('send_invitation_button')),
      );
      await tester.tap(find.byKey(const Key('send_invitation_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmation_message')), findsOneWidget);
      expect(find.textContaining('jean@example.fr'), findsOneWidget);
      expect(find.byKey(const Key('view_users_button')), findsOneWidget);
      expect(find.byKey(const Key('invite_another_button')), findsOneWidget);
      // Form fields no longer visible.
      expect(find.byKey(const Key('send_invitation_button')), findsNothing);
    });

    testWidgets('resets to form when [INVITER UN AUTRE OWNER] is tapped', (
      tester,
    ) async {
      when(
        () => repository.create(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => 'op-1');
      when(
        () => syncRepository.sync(tenantId: any(named: 'tenantId')),
      ).thenAnswer((_) async => const SyncOutcome.success());

      await _pumpScreen(
        tester,
        repository: repository,
        syncRepository: syncRepository,
      );

      await tester.enterText(find.byKey(const Key('first_name_field')), 'Jean');
      await tester.enterText(
        find.byKey(const Key('last_name_field')),
        'Dupont',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'jean@example.fr',
      );
      await tester.ensureVisible(
        find.byKey(const Key('send_invitation_button')),
      );
      await tester.tap(find.byKey(const Key('send_invitation_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invite_another_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('send_invitation_button')), findsOneWidget);
      expect(find.byKey(const Key('confirmation_message')), findsNothing);
    });

    testWidgets('shows inline conflict error on rejected sync mutation', (
      tester,
    ) async {
      when(
        () => repository.create(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => 'op-1');
      when(
        () => syncRepository.sync(tenantId: any(named: 'tenantId')),
      ).thenAnswer(
        (_) async => SyncOutcome.success(
          rejectedMutations: const [
            MutationOutcome(
              clientOpId: 'op-1',
              status: MutationStatus.rejected,
              error: MutationError(
                code: MutationErrorCode.conflict,
                message: 'duplicate',
              ),
            ),
          ],
        ),
      );

      await _pumpScreen(
        tester,
        repository: repository,
        syncRepository: syncRepository,
      );

      await tester.enterText(find.byKey(const Key('first_name_field')), 'Jean');
      await tester.enterText(
        find.byKey(const Key('last_name_field')),
        'Dupont',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'existing@example.fr',
      );
      await tester.ensureVisible(
        find.byKey(const Key('send_invitation_button')),
      );
      await tester.tap(find.byKey(const Key('send_invitation_button')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('conflict_error')), findsOneWidget);
      // Form remains visible.
      expect(find.byKey(const Key('send_invitation_button')), findsOneWidget);
    });

    testWidgets('shows generic error on unexpected exception', (tester) async {
      when(
        () => repository.create(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
        ),
      ).thenThrow(Exception('Server down'));

      await _pumpScreen(
        tester,
        repository: repository,
        syncRepository: syncRepository,
      );

      await tester.enterText(find.byKey(const Key('first_name_field')), 'Jean');
      await tester.enterText(
        find.byKey(const Key('last_name_field')),
        'Dupont',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'jean@example.fr',
      );
      await tester.ensureVisible(
        find.byKey(const Key('send_invitation_button')),
      );
      await tester.tap(find.byKey(const Key('send_invitation_button')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('conflict_error')), findsOneWidget);
    });
  });
}
