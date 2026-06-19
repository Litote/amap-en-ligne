import 'dart:async';

import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/nav/app_shell_layout.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    when(
      () => authBloc.state,
    ).thenReturn(const AuthViewState(role: UserRole.producer));
    when(() => authBloc.stream).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() async {
    await authStateController.close();
  });

  testWidgets('mobile layout: tapping the close button hides the nav menu', (
    tester,
  ) async {
    // Default test surface (800×600) is below the 1024 desktop breakpoint.
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: AppShellLayout(
            child: ConnectedScaffold(title: 'Test', body: const SizedBox()),
          ),
        ),
      ),
    );
    await tester.pump();

    // Open the menu via the hamburger button.
    await tester.tap(find.byKey(const Key('nav_menu_button')));
    await tester.pump();

    // Menu should be visible with the close button.
    expect(find.byTooltip('Fermer le menu'), findsOneWidget);

    // Tap the close button.
    await tester.tap(find.byTooltip('Fermer le menu'));
    await tester.pump();

    // Menu should be hidden after tapping close.
    expect(find.byTooltip('Fermer le menu'), findsNothing);
  });

  testWidgets(
    'desktop layout: close button is absent from the permanent sidebar',
    (tester) async {
      // Set a wide surface to trigger the desktop layout (>= 1024).
      tester.view.physicalSize = const Size(2048, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: AppShellLayout(
              child: ConnectedScaffold(title: 'Test', body: const SizedBox()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Desktop sidebar is always visible but has no close button.
      expect(find.byTooltip('Fermer le menu'), findsNothing);
    },
  );
}
