import 'package:amap_en_ligne/presentation/owner/users/dialogs/owner_lifecycle_dialogs.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

UserRow _row({
  String firstName = 'Alice',
  String lastName = 'Martin',
  String email = 'alice@example.com',
  bool isOwner = true,
  bool isProducer = false,
  String? producerAccountName,
}) => UserRow(
  identityKey: 'id-1',
  ownerId: 'owner-1',
  firstName: firstName,
  lastName: lastName,
  email: email,
  displayStatus: UserDisplayStatus.active,
  memberships: const [],
  isOwner: isOwner,
  isProducer: isProducer,
  producerAccountName: producerAccountName,
);

/// Opens [dialog] via showDialog and returns the value it pops with.
Future<bool?> _show(WidgetTester tester, Widget dialog) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => dialog,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('owner lifecycle dialogs — content + confirm/cancel return values', () {
    testWidgets('ConfirmSuspendOwnerDialog confirms with true', (tester) async {
      await _show(tester, ConfirmSuspendOwnerDialog(userRow: _row()));
      expect(find.text('Suspendre le compte'), findsOneWidget);
      expect(
        find.textContaining('Alice Martin (alice@example.com)'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm_suspend_button')));
      await tester.pumpAndSettle();
      expect(find.text('Suspendre le compte'), findsNothing);
    });

    testWidgets('ConfirmSuspendOwnerDialog cancels with false', (tester) async {
      await _show(tester, ConfirmSuspendOwnerDialog(userRow: _row()));
      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();
      expect(find.text('Suspendre le compte'), findsNothing);
    });

    testWidgets('ConfirmReactivateOwnerDialog renders and confirms', (
      tester,
    ) async {
      await _show(tester, ConfirmReactivateOwnerDialog(userRow: _row()));
      expect(find.text('Réactiver le compte'), findsOneWidget);
      expect(find.text('RÉACTIVER'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_reactivate_button')));
      await tester.pumpAndSettle();
      expect(find.text('Réactiver le compte'), findsNothing);
    });

    testWidgets(
      'ConfirmSuspendProducerDialog shows producer name and phase-2.5 note',
      (tester) async {
        await _show(
          tester,
          ConfirmSuspendProducerDialog(
            userRow: _row(
              isOwner: false,
              isProducer: true,
              producerAccountName: 'Ferme du Soleil',
            ),
          ),
        );
        expect(find.text('Suspendre le producteur'), findsOneWidget);
        expect(find.textContaining('Ferme du Soleil'), findsOneWidget);
        expect(find.textContaining('phase 2.5'), findsOneWidget);
        await tester.tap(find.byKey(const Key('confirm_suspend_button')));
        await tester.pumpAndSettle();
        expect(find.text('Suspendre le producteur'), findsNothing);
      },
    );

    testWidgets('ConfirmReactivateProducerDialog renders and confirms', (
      tester,
    ) async {
      await _show(
        tester,
        ConfirmReactivateProducerDialog(
          userRow: _row(
            isOwner: false,
            isProducer: true,
            producerAccountName: 'Ferme du Soleil',
          ),
        ),
      );
      expect(find.text('Réactiver le producteur'), findsOneWidget);
      expect(find.textContaining('Ferme du Soleil'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_reactivate_button')));
      await tester.pumpAndSettle();
      expect(find.text('Réactiver le producteur'), findsNothing);
    });

    testWidgets('ConfirmDeleteOwnerDialog shows irreversible RGPD warning', (
      tester,
    ) async {
      await _show(tester, ConfirmDeleteOwnerDialog(userRow: _row()));
      expect(find.text("Supprimer de l'instance"), findsOneWidget);
      expect(find.text('Action irréversible'), findsOneWidget);
      expect(find.text('SUPPRIMER DÉFINITIVEMENT'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_delete_button')));
      await tester.pumpAndSettle();
      expect(find.text("Supprimer de l'instance"), findsNothing);
    });

    testWidgets('ConfirmDeleteProducerDialog renders reinforced confirmation', (
      tester,
    ) async {
      await _show(
        tester,
        ConfirmDeleteProducerDialog(
          userRow: _row(
            isOwner: false,
            isProducer: true,
            producerAccountName: 'Ferme du Soleil',
          ),
        ),
      );
      expect(find.text('Supprimer le producteur'), findsOneWidget);
      expect(find.textContaining('confirmation renforcée'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_delete_button')));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer le producteur'), findsNothing);
    });

    testWidgets(
      'ConfirmSuspendMemberDialog hides email line when email is empty',
      (tester) async {
        await _show(
          tester,
          ConfirmSuspendMemberDialog(userRow: _row(isOwner: false, email: '')),
        );
        expect(find.text('Suspendre le compte'), findsOneWidget);
        // displayName falls back to the name when email is empty.
        expect(find.textContaining('Alice Martin'), findsOneWidget);
        expect(find.textContaining('seul Admin'), findsOneWidget);
        await tester.tap(find.byKey(const Key('confirm_suspend_button')));
        await tester.pumpAndSettle();
        expect(find.text('Suspendre le compte'), findsNothing);
      },
    );

    testWidgets('ConfirmSuspendMemberDialog shows email line when present', (
      tester,
    ) async {
      await _show(
        tester,
        ConfirmSuspendMemberDialog(userRow: _row(isOwner: false)),
      );
      expect(find.text('alice@example.com'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();
      expect(find.text('Suspendre le compte'), findsNothing);
    });

    testWidgets('ConfirmReactivateMemberDialog renders and confirms', (
      tester,
    ) async {
      await _show(
        tester,
        ConfirmReactivateMemberDialog(userRow: _row(isOwner: false)),
      );
      expect(find.text('Réactiver le compte'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_reactivate_button')));
      await tester.pumpAndSettle();
      expect(find.text('Réactiver le compte'), findsNothing);
    });

    testWidgets('ConfirmDeleteMemberDialog shows anonymisation RGPD warning', (
      tester,
    ) async {
      await _show(
        tester,
        ConfirmDeleteMemberDialog(userRow: _row(isOwner: false)),
      );
      expect(find.text("Supprimer de l'instance"), findsOneWidget);
      expect(find.textContaining('anonymise'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_delete_member_button')));
      await tester.pumpAndSettle();
      expect(find.text("Supprimer de l'instance"), findsNothing);
    });
  });
}
