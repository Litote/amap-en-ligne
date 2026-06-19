import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

void main() {
  late _MockPublicApi publicApi;

  setUpAll(() {
    registerFallbackValue(
      const OrganizationCreationRequest(
        organizationName: 'x',
        timezone: 'Europe/Paris',
        defaultLanguage: 'fr',
        adminFirstName: 'x',
        adminLastName: 'x',
        adminEmail: 'x@y.z',
        organizationType: OrganizationType.amap,
      ),
    );
  });

  setUp(() {
    publicApi = _MockPublicApi();
  });

  Future<void> pump(WidgetTester tester) async {
    // The form is taller than the default 600px test viewport — give it room so the
    // terms checkbox and submit button are on-screen and tappable.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/create',
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<PublicApi>.value(value: publicApi),
              RepositoryProvider<ServerConfig>.value(
                value: serverPresets.first,
              ),
            ],
            child: const OrganizationCreationScreen(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('org_name')), 'AMAP du Coin');
    await tester.enterText(find.byKey(const Key('first_name')), 'Alice');
    await tester.enterText(find.byKey(const Key('last_name')), 'Martin');
    await tester.enterText(
      find.byKey(const Key('admin_email')),
      'alice@example.com',
    );
  }

  testWidgets('renders the creation form', (tester) async {
    await pump(tester);

    expect(find.text('Créer une nouvelle AMAP'), findsOneWidget);
    expect(find.byKey(const Key('org_name')), findsOneWidget);
    expect(find.byKey(const Key('submit')), findsOneWidget);
  });

  testWidgets('submitting an empty form shows validation errors and no call', (
    tester,
  ) async {
    await pump(tester);

    // The submit button is disabled until the terms are accepted; check them so
    // the empty-form submit runs the field validators.
    await tester.tap(find.byKey(const Key('terms')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Requis'), findsWidgets);
    verifyNever(() => publicApi.createOrganizationRequest(any()));
  });

  testWidgets('does not submit when the terms checkbox is unchecked', (
    tester,
  ) async {
    await pump(tester);
    await fillValidForm(tester);

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    verifyNever(() => publicApi.createOrganizationRequest(any()));
  });

  testWidgets('a valid submission shows the success view', (tester) async {
    when(() => publicApi.createOrganizationRequest(any())).thenAnswer(
      (_) async => const OrganizationRequestResponse(
        requestId: 'req-42',
        status: 'PENDING_VALIDATION',
      ),
    );

    await pump(tester);
    await fillValidForm(tester);
    await tester.tap(find.byKey(const Key('terms')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text("Demande de création d'AMAP soumise"), findsOneWidget);
    expect(find.textContaining('req-42'), findsOneWidget);
  });

  testWidgets('a name conflict keeps the form and shows an error', (
    tester,
  ) async {
    when(() => publicApi.createOrganizationRequest(any())).thenThrow(
      const OrganizationConflictException(
        OrganizationConflictField.organizationName,
      ),
    );

    await pump(tester);
    await fillValidForm(tester);
    await tester.tap(find.byKey(const Key('terms')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    // Still on the form (not the success view), and the request was attempted.
    expect(find.text("Demande de création d'AMAP soumise"), findsNothing);
    expect(find.byKey(const Key('submit')), findsOneWidget);
    verify(() => publicApi.createOrganizationRequest(any())).called(1);
  });
}
