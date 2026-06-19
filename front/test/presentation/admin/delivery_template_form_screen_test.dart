import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_form_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

const _organization = Organization(
  organizationId: 'org-1',
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
);

Finder _textFormFieldWithValue(String value) => find.byWidgetPredicate(
  (widget) => widget is TextFormField && widget.controller?.text == value,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDeliveryTemplateRepository deliveryTemplateRepository,
  required _MockOrganizationRepository organizationRepository,
  required _MockSyncBloc syncBloc,
  Organization organization = _organization,
  DeliveryTemplate? template,
}) async {
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
  when(
    () => organizationRepository.watch('org-1'),
  ).thenAnswer((_) => Stream.value(organization));
  final router = GoRouter(
    initialLocation: '/templates/form',
    routes: [
      GoRoute(
        path: '/templates',
        builder: (_, _) => const Scaffold(body: SizedBox()),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, _) => DeliveryTemplateFormScreen(
              organizationId: 'org-1',
              template: template,
            ),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DeliveryTemplateRepository>.value(
          value: deliveryTemplateRepository,
        ),
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _MockDeliveryTemplateRepository deliveryTemplateRepository;
  late _MockOrganizationRepository organizationRepository;
  late _MockSyncBloc syncBloc;

  setUpAll(() {
    registerFallbackValue(
      const DeliveryTemplate(
        deliveryTemplateId: 'dt-fallback',
        organizationId: 'org-1',
        name: 'Fallback',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
      ),
    );
    registerFallbackValue(_organization);
  });

  setUp(() {
    deliveryTemplateRepository = _MockDeliveryTemplateRepository();
    organizationRepository = _MockOrganizationRepository();
    syncBloc = _MockSyncBloc();
    when(() => deliveryTemplateRepository.create(any())).thenAnswer((
      invocation,
    ) async {
      final template =
          invocation.positionalArguments.single as DeliveryTemplate;
      return template.copyWith(deliveryTemplateId: 'tmp-created');
    });
    when(
      () => deliveryTemplateRepository.update(any()),
    ).thenAnswer((_) async {});
    when(
      () => organizationRepository.updateDefaultDeliveryTemplateId(
        currentOrg: any(named: 'currentOrg'),
        defaultDeliveryTemplateId: any(named: 'defaultDeliveryTemplateId'),
      ),
    ).thenAnswer((_) async {});
  });

  testWidgets(
    'editing a template persists desired volunteers and updates org default',
    (tester) async {
      const template = DeliveryTemplate(
        deliveryTemplateId: 'dt-1',
        organizationId: 'org-1',
        name: 'Livraison standard',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        desiredVolunteerCount: 3,
      );

      await _pumpScreen(
        tester,
        deliveryTemplateRepository: deliveryTemplateRepository,
        organizationRepository: organizationRepository,
        syncBloc: syncBloc,
        template: template,
      );

      await tester.enterText(_textFormFieldWithValue('3'), '5');
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      // The form is taller than the viewport — drag it up to reveal the button.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      verify(
        () => deliveryTemplateRepository.update(
          any(
            that: isA<DeliveryTemplate>().having(
              (template) => template.desiredVolunteerCount,
              'desiredVolunteerCount',
              5,
            ),
          ),
        ),
      ).called(1);
      verify(
        () => organizationRepository.updateDefaultDeliveryTemplateId(
          currentOrg: _organization,
          defaultDeliveryTemplateId: 'dt-1',
        ),
      ).called(1);
      verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
    },
  );

  testWidgets('editing the current default can clear the org default', (
    tester,
  ) async {
    const template = DeliveryTemplate(
      deliveryTemplateId: 'dt-1',
      organizationId: 'org-1',
      name: 'Livraison standard',
      standardStartTime: '18:00',
      standardEndTime: '20:00',
    );
    const organization = Organization(
      organizationId: 'org-1',
      name: 'AMAP Test',
      contactEmail: 'test@amap.fr',
      defaultDeliveryTemplateId: 'dt-1',
    );

    await _pumpScreen(
      tester,
      deliveryTemplateRepository: deliveryTemplateRepository,
      organizationRepository: organizationRepository,
      syncBloc: syncBloc,
      organization: organization,
      template: template,
    );

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    // The form is taller than the viewport — drag it up to reveal the button.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    verify(
      () => organizationRepository.updateDefaultDeliveryTemplateId(
        currentOrg: organization,
        defaultDeliveryTemplateId: null,
      ),
    ).called(1);
  });

  testWidgets('creating a default template updates org after template creation', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      deliveryTemplateRepository: deliveryTemplateRepository,
      organizationRepository: organizationRepository,
      syncBloc: syncBloc,
    );

    await tester.enterText(find.byType(TextFormField).first, 'Nouveau modèle');
    // Select standard start time (first "Sélectionner une heure").
    await tester.tap(find.text('Sélectionner une heure').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Select standard end time (last remaining "Sélectionner une heure" after
    // the start time was set — volunteer arrival is optional, end time is last).
    // Scroll to it first, then tap.
    final endTimeFinder = find.text('Sélectionner une heure').at(1);
    await tester.scrollUntilVisible(
      endTimeFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(endTimeFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    // The form is taller than the viewport — drag it up to reveal the button.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    verifyInOrder([
      () => deliveryTemplateRepository.create(
        any(
          that: isA<DeliveryTemplate>().having(
            (template) => template.name,
            'name',
            'Nouveau modèle',
          ),
        ),
      ),
      () => organizationRepository.updateDefaultDeliveryTemplateId(
        currentOrg: _organization,
        defaultDeliveryTemplateId: 'tmp-created',
      ),
    ]);
  });

  testWidgets('time picker opens in French 24-hour format', (tester) async {
    await _pumpScreen(
      tester,
      deliveryTemplateRepository: deliveryTemplateRepository,
      organizationRepository: organizationRepository,
      syncBloc: syncBloc,
    );

    await tester.tap(find.text('Sélectionner une heure').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('nnuler'), findsOneWidget);
    expect(find.text('AM'), findsNothing);
  });
}
