import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/presentation/owner/users/dialogs/modify_membership_dialog.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

UserRow _memberRow() => UserRow(
  identityKey: 's-m-1',
  ownerId: 'm-1',
  firstName: 'Alice',
  lastName: 'Martin',
  email: 'alice@example.com',
  displayStatus: UserDisplayStatus.active,
  memberships: const [],
  isOwner: false,
  isProducer: false,
);

UserMembership _membership({Set<Role> roles = const {Role.admin}}) =>
    UserMembership(
      memberId: 'm-1',
      organizationId: 'org-1',
      organizationName: 'AMAP des Pins',
      roles: roles,
    );

Future<void> _pumpDialog(
  WidgetTester tester, {
  required UserMembership membership,
  required bool isLastAdmin,
  required bool canEditAdminRole,
  required ValueChanged<MembershipEditResult?> onClosed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showDialog<MembershipEditResult>(
              context: ctx,
              builder: (_) => ModifyMembershipDialog(
                userRow: _memberRow(),
                membership: membership,
                isLastAdmin: isLastAdmin,
                canEditAdminRole: canEditAdminRole,
              ),
            ).then(onClosed),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('ModifyMembershipDialog', () {
    testWidgets('renders org name in title', (tester) async {
      await _pumpDialog(
        tester,
        membership: _membership(),
        isLastAdmin: false,
        canEditAdminRole: true,
        onClosed: (_) {},
      );

      expect(find.textContaining('AMAP des Pins'), findsOneWidget);
    });

    testWidgets('pre-checks roles from membership', (tester) async {
      await _pumpDialog(
        tester,
        membership: _membership(roles: {Role.admin, Role.volunteer}),
        isLastAdmin: false,
        canEditAdminRole: true,
        onClosed: (_) {},
      );

      final adminBox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('admin_checkbox')),
      );
      expect(adminBox.value, isTrue);

      final volunteerBox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('volunteer_checkbox')),
      );
      expect(volunteerBox.value, isTrue);

      final coordBox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('coordinator_checkbox')),
      );
      expect(coordBox.value, isFalse);
    });

    testWidgets('SAUVEGARDER disabled when no checkbox is checked', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        membership: _membership(roles: {Role.admin}),
        isLastAdmin: false,
        canEditAdminRole: true,
        onClosed: (_) {},
      );

      // Uncheck Admin (currently the only checked role).
      await tester.ensureVisible(find.byKey(const Key('admin_checkbox')));
      await tester.tap(find.byKey(const Key('admin_checkbox')));
      await tester.pump();

      final saveBtn = tester.widget<FilledButton>(
        find.byKey(const Key('save_button')),
      );
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('SAUVEGARDER returns updated values', (tester) async {
      MembershipEditResult? result;
      await _pumpDialog(
        tester,
        membership: _membership(roles: {Role.volunteer}),
        isLastAdmin: false,
        canEditAdminRole: true,
        onClosed: (value) => result = value,
      );

      // Check coordinator as well.
      await tester.ensureVisible(find.byKey(const Key('coordinator_checkbox')));
      await tester.tap(find.byKey(const Key('coordinator_checkbox')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '06 01 02 03 04',
      );

      await tester.ensureVisible(find.byKey(const Key('save_button')));
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pumpAndSettle();

      expect(result?.roles, containsAll([Role.volunteer, Role.coordinator]));
      expect(result?.phone, '06 01 02 03 04');
    });

    testWidgets('ANNULER closes dialog without returning a result', (
      tester,
    ) async {
      MembershipEditResult? result;
      await _pumpDialog(
        tester,
        membership: _membership(),
        isLastAdmin: false,
        canEditAdminRole: true,
        onClosed: (value) => result = value,
      );

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.textContaining('AMAP des Pins'), findsNothing);
    });
  });
}
