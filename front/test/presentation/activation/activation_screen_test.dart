import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/presentation/activation/activation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

/// Pumps an [ActivationScreen] with a fake [PublicApi] and a stub router so
/// that [context.go('/login')] does not throw.
Future<void> _pump(WidgetTester tester, PublicApi api, String token) async {
  await tester.pumpWidget(
    RepositoryProvider<PublicApi>.value(
      value: api,
      child: MaterialApp(home: ActivationScreen(token: token)),
    ),
  );
}

void main() {
  late _MockPublicApi api;

  setUp(() {
    api = _MockPublicApi();
  });

  testWidgets('shows password validation errors on empty submit', (
    tester,
  ) async {
    await _pump(tester, api, 'tok');

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();

    expect(find.text('Le mot de passe est requis.'), findsOneWidget);
  });

  testWidgets('shows min-length error for short password', (tester) async {
    await _pump(tester, api, 'tok');

    await tester.enterText(find.byKey(const Key('password')), 'short');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();

    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères.'),
      findsOneWidget,
    );
  });

  testWidgets('shows mismatch error when passwords differ', (tester) async {
    await _pump(tester, api, 'tok');

    await tester.enterText(find.byKey(const Key('password')), 'Password1');
    await tester.enterText(
      find.byKey(const Key('confirm_password')),
      'Other999',
    );
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();

    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );
    verifyNever(
      () => api.activate(
        token: any(named: 'token'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows success card on activate success', (tester) async {
    when(
      () => api.activate(
        token: any(named: 'token'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const ActivationResult(
        kind: ActivationKind.organizationAdmin,
        organizationName: 'AMAP des Collines',
        email: 'admin@example.com',
      ),
    );

    await _pump(tester, api, 'valid-token');

    await tester.enterText(find.byKey(const Key('password')), 'Password1');
    await tester.enterText(
      find.byKey(const Key('confirm_password')),
      'Password1',
    );
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump(); // setState loading
    await tester.pump(); // async result

    expect(
      find.text('Votre compte pour AMAP des Collines a été activé.'),
      findsOneWidget,
    );
    expect(find.text('SE CONNECTER'), findsOneWidget);
  });

  testWidgets(
    'shows invalidToken error message on ActivationError.invalidToken',
    (tester) async {
      when(
        () => api.activate(
          token: any(named: 'token'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ActivationException(ActivationError.invalidToken));

      await _pump(tester, api, 'bad-token');

      await tester.enterText(find.byKey(const Key('password')), 'Password1');
      await tester.enterText(
        find.byKey(const Key('confirm_password')),
        'Password1',
      );
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();
      await tester.pump();

      expect(find.text("Ce lien d'activation est invalide."), findsOneWidget);
    },
  );

  testWidgets('shows expired error message on ActivationError.expired', (
    tester,
  ) async {
    when(
      () => api.activate(
        token: any(named: 'token'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const ActivationException(ActivationError.expired));

    await _pump(tester, api, 'old-token');

    await tester.enterText(find.byKey(const Key('password')), 'Password1');
    await tester.enterText(
      find.byKey(const Key('confirm_password')),
      'Password1',
    );
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text("Ce lien d'activation a expiré. Contactez l'administrateur."),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows alreadyActivated error message on ActivationError.alreadyActivated',
    (tester) async {
      when(
        () => api.activate(
          token: any(named: 'token'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ActivationException(ActivationError.alreadyActivated));

      await _pump(tester, api, 'used-token');

      await tester.enterText(find.byKey(const Key('password')), 'Password1');
      await tester.enterText(
        find.byKey(const Key('confirm_password')),
        'Password1',
      );
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Ce compte a déjà été activé. Connectez-vous.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows generic error message on serverError', (tester) async {
    when(
      () => api.activate(
        token: any(named: 'token'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const ActivationException(ActivationError.serverError));

    await _pump(tester, api, 'any-token');

    await tester.enterText(find.byKey(const Key('password')), 'Password1');
    await tester.enterText(
      find.byKey(const Key('confirm_password')),
      'Password1',
    );
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Une erreur est survenue. Veuillez réessayer.'),
      findsOneWidget,
    );
  });

  testWidgets('shows owner success message when kind is owner', (tester) async {
    when(
      () => api.activate(
        token: any(named: 'token'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const ActivationResult(
        kind: ActivationKind.owner,
        email: 'owner@example.com',
      ),
    );

    await _pump(tester, api, 'owner-token');

    await tester.enterText(find.byKey(const Key('password')), 'Password1');
    await tester.enterText(
      find.byKey(const Key('confirm_password')),
      'Password1',
    );
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Votre compte Owner a été activé. Vous pouvez maintenant vous connecter.',
      ),
      findsOneWidget,
    );
    expect(find.text('SE CONNECTER'), findsOneWidget);
  });

  testWidgets('shows producer success message when kind is producer', (
    tester,
  ) async {
    when(
      () => api.activate(
        token: any(named: 'token'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const ActivationResult(
        kind: ActivationKind.producer,
        organizationName: 'Ferme des Collines',
        email: 'producer@example.com',
      ),
    );

    await _pump(tester, api, 'producer-token');

    await tester.enterText(find.byKey(const Key('password')), 'Password1');
    await tester.enterText(
      find.byKey(const Key('confirm_password')),
      'Password1',
    );
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Votre compte producteur pour Ferme des Collines a été activé.',
      ),
      findsOneWidget,
    );
  });
}
