import 'dart:async';

import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/member_join_request.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

const _orgA = Organization(
  organizationId: 'org-a',
  name: 'Les Jardins de Provence',
  contactEmail: 'jardins@example.com',
);
const _orgB = Organization(
  organizationId: 'org-b',
  name: 'Ferme du Coteau',
  contactEmail: 'coteau@example.com',
);

void main() {
  late _MockPublicApi publicApi;

  setUpAll(() {
    registerFallbackValue(
      const MemberJoinRequest(
        organizationId: 'x',
        email: 'x',
        firstName: 'x',
        lastName: 'x',
      ),
    );
  });

  setUp(() {
    publicApi = _MockPublicApi();
  });

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/search',
          builder: (_, _) => RepositoryProvider<PublicApi>.value(
            value: publicApi,
            child: const AmapSearchScreen(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('shows a progress indicator while organizations load', (
    tester,
  ) async {
    final completer = Completer<List<Organization>>();
    when(
      () => publicApi.listOrganizations(),
    ).thenAnswer((_) => completer.future);

    await pump(tester);
    await tester.pump(); // build + first bloc transition

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    completer.complete(const [_orgA]);
    await tester.pumpAndSettle();
  });

  testWidgets('lists organizations and filters them by the search query', (
    tester,
  ) async {
    when(
      () => publicApi.listOrganizations(),
    ).thenAnswer((_) async => const [_orgA, _orgB]);

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Les Jardins de Provence'), findsOneWidget);
    expect(find.text('Ferme du Coteau'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ferme');
    await tester.pumpAndSettle();

    expect(find.text('Les Jardins de Provence'), findsNothing);
    expect(find.text('Ferme du Coteau'), findsOneWidget);
  });

  testWidgets('shows empty message when no organization matches', (
    tester,
  ) async {
    when(
      () => publicApi.listOrganizations(),
    ).thenAnswer((_) async => const [_orgA]);

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Aucune AMAP trouvée.'), findsOneWidget);
  });

  testWidgets('shows error view with retry when loading fails', (tester) async {
    when(() => publicApi.listOrganizations()).thenThrow(Exception('network'));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('selecting an org opens the join form', (tester) async {
    when(
      () => publicApi.listOrganizations(),
    ).thenAnswer((_) async => const [_orgA]);

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Les Jardins de Provence'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first_name')), findsOneWidget);
    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "S'INSCRIRE"), findsOneWidget);
  });

  testWidgets('submitting the empty join form shows validation errors', (
    tester,
  ) async {
    when(
      () => publicApi.listOrganizations(),
    ).thenAnswer((_) async => const [_orgA]);

    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Les Jardins de Provence'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('Requis.'), findsWidgets);
    expect(find.text("L'email est requis."), findsOneWidget);
    verifyNever(() => publicApi.createMemberJoinRequest(any()));
  });

  testWidgets('successful submission shows the confirmation view', (
    tester,
  ) async {
    when(
      () => publicApi.listOrganizations(),
    ).thenAnswer((_) async => const [_orgA]);
    when(() => publicApi.createMemberJoinRequest(any())).thenAnswer(
      (_) async => const MemberJoinRequestResponse(
        requestId: 'req-1',
        status: 'PENDING',
      ),
    );

    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Les Jardins de Provence'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('first_name')), 'Alice');
    await tester.enterText(find.byKey(const Key('last_name')), 'Martin');
    await tester.enterText(find.byKey(const Key('email')), 'alice@example.com');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('Votre demande a été enregistrée'), findsOneWidget);
    expect(find.textContaining('Les Jardins de Provence'), findsOneWidget);
  });

  testWidgets('a join conflict shows the error message inside the form', (
    tester,
  ) async {
    when(
      () => publicApi.listOrganizations(),
    ).thenAnswer((_) async => const [_orgA]);
    when(() => publicApi.createMemberJoinRequest(any())).thenThrow(
      const MemberJoinConflictException(MemberJoinConflictField.email),
    );

    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Les Jardins de Provence'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('first_name')), 'Alice');
    await tester.enterText(find.byKey(const Key('last_name')), 'Martin');
    await tester.enterText(find.byKey(const Key('email')), 'dup@example.com');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('déjà inscrite pour cette AMAP'),
      findsOneWidget,
    );
  });
}
