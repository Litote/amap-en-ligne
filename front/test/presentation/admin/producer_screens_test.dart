import 'dart:async';

import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/admin/producers/enroll_producer_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_detail_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_list_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

_MockSyncBloc _makeSyncBloc() {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _MockAdminApi extends Mock implements AdminApi {}

class _MockProductTypeRepository extends Mock
    implements ProductTypeRepository {}

const _organization = Organization(
  organizationId: 'org-1',
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  producers: [
    OrganizationProducer(
      producerAccountId: 'pa-1',
      associationInstant: '2025-01-01T00:00:00Z',
      status: OrganizationProducerStatus.active,
    ),
    OrganizationProducer(
      producerAccountId: 'pa-2',
      associationInstant: '2025-01-01T00:00:00Z',
      status: OrganizationProducerStatus.suspended,
    ),
    OrganizationProducer(
      producerAccountId: 'pa-3',
      associationInstant: '2025-01-01T00:00:00Z',
      status: OrganizationProducerStatus.terminated,
    ),
  ],
  products: [
    OrgProduct(
      name: 'Tomates',
      productTypeId: 'pt-1',
      producerAccountId: 'pa-1',
      supportedBasketSizes: [BasketSize(name: 'Petit')],
    ),
    // Organization.products mirrors the no-account producer's products locally
    // for responsive UI. ProducerAccount.products is the authoritative source.
    OrgProduct(
      name: 'Poires',
      productTypeId: 'pt-3',
      producerAccountId: 'pa-2',
    ),
  ],
);

final _producerProfiles = [
  const ProducerAccount(
    producerAccountId: 'pa-1',
    name: 'Ferme des Prés',
    contactEmail: 'contact@pres.fr',
    managementMode: ProducerManagementMode.accountBacked,
    products: [
      ProducerProduct(
        name: 'Tomates',
        productTypeId: 'pt-1',
        supportedBasketSizes: [BasketSize(name: 'Petit')],
      ),
      ProducerProduct(name: 'Salades', productTypeId: 'pt-2'),
    ],
  ),
  // No-account producer: products live in ProducerAccount.products (single
  // source of truth). Organization.products mirrors them locally for UI but is
  // not the authoritative source.
  const ProducerAccount(
    producerAccountId: 'pa-2',
    name: 'Vergers du Sud',
    contactEmail: 'bonjour@vergers.fr',
    managementMode: ProducerManagementMode.noAccount,
    products: [ProducerProduct(name: 'Poires', productTypeId: 'pt-3')],
  ),
  const ProducerAccount(
    producerAccountId: 'pa-3',
    name: 'Ancienne Ferme',
    contactEmail: 'archive@ferme.fr',
  ),
];

Future<void> _pumpListScreen(
  WidgetTester tester, {
  required _MockOrganizationRepository organizationRepository,
  required _MockProducerAccountRepository producerAccountRepository,
  required _MockAdminApi adminApi,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
        RepositoryProvider<ProducerAccountRepository>.value(
          value: producerAccountRepository,
        ),
        RepositoryProvider<AdminApi>.value(value: adminApi),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: const MaterialApp(
          home: ProducerListScreen(organizationId: 'org-1'),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpDetailScreen(
  WidgetTester tester, {
  required _MockOrganizationRepository organizationRepository,
  required _MockProducerAccountRepository producerAccountRepository,
  required _MockAdminApi adminApi,
  List<ProductType> productTypes = const [],
}) async {
  final productTypeRepository = _MockProductTypeRepository();
  when(
    () => productTypeRepository.watch(any()),
  ).thenAnswer((_) => Stream.value(productTypes));
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
        RepositoryProvider<ProducerAccountRepository>.value(
          value: producerAccountRepository,
        ),
        RepositoryProvider<AdminApi>.value(value: adminApi),
        RepositoryProvider<ProductTypeRepository>.value(
          value: productTypeRepository,
        ),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: const MaterialApp(
          home: ProducerDetailScreen(
            organizationId: 'org-1',
            producerAccountId: 'pa-1',
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpProducerRouter(
  WidgetTester tester, {
  required _MockOrganizationRepository organizationRepository,
  required _MockProducerAccountRepository producerAccountRepository,
  required _MockAdminApi adminApi,
  String initialLocation = '/admin/producers',
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/admin/producers',
        builder: (_, _) => const ProducerListScreen(organizationId: 'org-1'),
      ),
      GoRoute(
        path: '/admin/producers/enroll',
        builder: (_, _) => const EnrollProducerScreen(organizationId: 'org-1'),
      ),
      GoRoute(
        path: '/admin/producers/:producerAccountId',
        builder: (_, state) => ProducerDetailScreen(
          organizationId: 'org-1',
          producerAccountId: state.pathParameters['producerAccountId']!,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
        RepositoryProvider<ProducerAccountRepository>.value(
          value: producerAccountRepository,
        ),
        RepositoryProvider<AdminApi>.value(value: adminApi),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockOrganizationRepository organizationRepository;
  late _MockProducerAccountRepository producerAccountRepository;
  late _MockAdminApi adminApi;

  setUpAll(() async => initializeDateFormatting('fr'));

  setUp(() {
    organizationRepository = _MockOrganizationRepository();
    producerAccountRepository = _MockProducerAccountRepository();
    adminApi = _MockAdminApi();
    when(
      () => organizationRepository.watch('org-1'),
    ).thenAnswer((_) => Stream.value(_organization));
    when(
      () => producerAccountRepository.watchAll(),
    ).thenAnswer((_) => Stream.value(_producerProfiles));
  });

  testWidgets(
    'producer list defaults to active and all filter includes terminated producers',
    (tester) async {
      await _pumpListScreen(
        tester,
        organizationRepository: organizationRepository,
        producerAccountRepository: producerAccountRepository,
        adminApi: adminApi,
      );

      expect(find.text('Ajouter un producteur'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Actifs'))
            .selected,
        isTrue,
      );
      expect(find.text('Ferme des Prés'), findsOneWidget);
      expect(find.text('contact@pres.fr'), findsOneWidget);
      expect(find.text('Avec compte'), findsOneWidget);
      expect(find.text('Sans compte'), findsNothing);
      expect(find.text('Ancienne Ferme'), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Tous'));
      await tester.pump();

      expect(find.text('Sans compte'), findsOneWidget);
      expect(find.text('Ancienne Ferme'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsNWidgets(3));

      await tester.tap(find.widgetWithText(FilterChip, 'Terminés'));
      await tester.pump();

      expect(find.text('Ancienne Ferme'), findsOneWidget);
    },
  );

  testWidgets('producer detail shows synced name and email', (tester) async {
    await _pumpDetailScreen(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
    );

    expect(find.text('Ferme des Prés'), findsOneWidget);
    expect(find.text('contact@pres.fr'), findsOneWidget);
    expect(find.text('Avec compte'), findsOneWidget);
  });

  testWidgets('account-backed producer products are selected from its catalog '
      '(its product types) when its account lists none', (tester) async {
    // Spec screen-admin-04: [Modifier] on an account-backed producer opens the
    // selection of its catalog products for this AMAP. Its account usually
    // has no `products`: the catalog is its ProductTypes (synced read-only
    // on the organization scope), as the back producer search does.
    when(() => producerAccountRepository.watchAll()).thenAnswer(
      (_) => Stream.value([
        _producerProfiles.first.copyWith(products: const []),
        ..._producerProfiles.skip(1),
      ]),
    );
    await _pumpDetailScreen(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
      productTypes: const [
        ProductType(
          productTypeId: 'pt-1',
          producerAccountId: 'pa-1',
          name: 'Tomates',
          supportedBasketSizes: [BasketSize(name: 'Petit')],
        ),
        ProductType(
          productTypeId: 'pt-2',
          producerAccountId: 'pa-1',
          name: 'Salades',
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('edit_producer_products_button')));
    await tester.pumpAndSettle();

    expect(find.text('Modifier les produits'), findsOneWidget);
    // Pushed over the producer screen: a back arrow, not the menu.
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text("Ce producteur n'a aucun produit."), findsNothing);
    expect(find.widgetWithText(CheckboxListTile, 'Tomates'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Salades'), findsOneWidget);
  });

  testWidgets('producer detail shows a French date, basket sizes and no '
      'technical id', (tester) async {
    await _pumpDetailScreen(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
    );

    expect(find.text('1er janv. 2025'), findsOneWidget);
    expect(find.text('2025-01-01'), findsNothing);
    expect(find.text('Identifiant'), findsNothing);
    expect(find.text('pa-1'), findsNothing);
    // Tomates is offered in the "Petit" basket size.
    expect(find.text('Paniers : Petit'), findsOneWidget);
  });

  testWidgets('a terminated association offers no product editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrganizationRepository>.value(
            value: organizationRepository,
          ),
          RepositoryProvider<ProducerAccountRepository>.value(
            value: producerAccountRepository,
          ),
          RepositoryProvider<AdminApi>.value(value: adminApi),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: _makeSyncBloc(),
          child: const MaterialApp(
            home: ProducerDetailScreen(
              organizationId: 'org-1',
              producerAccountId: 'pa-3',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('edit_producer_products_button')),
      findsNothing,
    );
  });

  testWidgets(
    'no-account producer product editor is prefilled from ProducerAccount.products',
    (tester) async {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<OrganizationRepository>.value(
              value: organizationRepository,
            ),
            RepositoryProvider<ProducerAccountRepository>.value(
              value: producerAccountRepository,
            ),
            RepositoryProvider<AdminApi>.value(value: adminApi),
          ],
          child: BlocProvider<SyncBloc>.value(
            value: _makeSyncBloc(),
            child: const MaterialApp(
              home: ProducerDetailScreen(
                organizationId: 'org-1',
                producerAccountId: 'pa-2',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('edit_producer_products_button')));
      await tester.pumpAndSettle();

      expect(find.text('Modifier les produits'), findsOneWidget);
      // The product 'Poires' lives in ProducerAccount.products (single source
      // of truth for NO_ACCOUNT producers — not in Organization.products).
      expect(find.text('Poires'), findsOneWidget);
    },
  );

  testWidgets(
    'no-account producer detail shows edit button but no link button',
    (tester) async {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<OrganizationRepository>.value(
              value: organizationRepository,
            ),
            RepositoryProvider<ProducerAccountRepository>.value(
              value: producerAccountRepository,
            ),
            RepositoryProvider<AdminApi>.value(value: adminApi),
          ],
          child: BlocProvider<SyncBloc>.value(
            value: _makeSyncBloc(),
            child: const MaterialApp(
              home: ProducerDetailScreen(
                organizationId: 'org-1',
                producerAccountId: 'pa-2',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Sans compte'), findsOneWidget);
      expect(
        find.byKey(const Key('link_no_account_producer_button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('edit_producer_products_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets('no-account producer row menu exposes product editing', (
    tester,
  ) async {
    await _pumpListScreen(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Tous'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_horiz).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Voir la fiche'), findsOneWidget);
    expect(find.text('Modifier les produits'), findsOneWidget);
  });

  testWidgets('back from the enroll flow opened by its URL (nothing to pop) '
      'lands on the producer list', (tester) async {
    await _pumpProducerRouter(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
      initialLocation: '/admin/producers/enroll',
    );
    expect(find.text('Inscrire un producteur — Étape 1'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Inscrire un producteur — Étape 1'), findsNothing);
    expect(find.byKey(const Key('add_producer_button')), findsOneWidget);
  });

  testWidgets('« Retour » from a producer page opened by its URL (nothing to '
      'pop) lands on the producer list', (tester) async {
    await _pumpProducerRouter(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
      initialLocation: '/admin/producers/pa-1',
    );
    expect(find.text('Producteur'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Retour'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('add_producer_button')), findsOneWidget);
  });

  testWidgets('add producer button navigates to enroll flow', (tester) async {
    await _pumpProducerRouter(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
    );

    await tester.tap(find.byKey(const Key('add_producer_button')));
    await tester.pumpAndSettle();

    expect(find.text('Inscrire un producteur — Étape 1'), findsOneWidget);
    expect(find.text('Créer un producteur sans compte'), findsOneWidget);
  });

  testWidgets(
    'enroll screen opens step 1 after organization loads asynchronously',
    (tester) async {
      final organizationStream = StreamController<Organization?>.broadcast();
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => organizationStream.stream);

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<OrganizationRepository>.value(
              value: organizationRepository,
            ),
            RepositoryProvider<ProducerAccountRepository>.value(
              value: producerAccountRepository,
            ),
            RepositoryProvider<AdminApi>.value(value: adminApi),
          ],
          child: const MaterialApp(
            home: EnrollProducerScreen(organizationId: 'org-1'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Inscrire un producteur — Étape 1'), findsNothing);

      organizationStream.add(_organization);
      await tester.pump();
      await tester.pump();

      expect(find.text('Inscrire un producteur — Étape 1'), findsOneWidget);
      expect(find.text('Créer un producteur sans compte'), findsOneWidget);

      await organizationStream.close();
    },
  );

  testWidgets('no-account producer action opens step 2', (tester) async {
    await _pumpProducerRouter(
      tester,
      organizationRepository: organizationRepository,
      producerAccountRepository: producerAccountRepository,
      adminApi: adminApi,
    );

    await tester.tap(find.byKey(const Key('add_producer_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('create_no_account_producer_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Créer un producteur sans compte — Étape 2'),
      findsOneWidget,
    );
    expect(find.text('Créer le producteur'), findsOneWidget);
  });

  testWidgets(
    'no-account producer form rejects a malformed contact email and website',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pumpProducerRouter(
        tester,
        organizationRepository: organizationRepository,
        producerAccountRepository: producerAccountRepository,
        adminApi: adminApi,
      );
      await tester.tap(find.byKey(const Key('add_producer_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('create_no_account_producer_button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du producteur *'),
        'Poulailler',
      );
      await tester.enterText(
        find.byKey(const Key('no_account_contact_email')),
        'poulailler@nowhere',
      );
      await tester.enterText(
        find.byKey(const Key('no_account_website')),
        'www.poulailler.example',
      );
      await tester.tap(find.text('Ajouter').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du produit'),
        'Oeufs',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer le producteur'));
      await tester.pumpAndSettle();

      expect(find.text('Adresse email invalide.'), findsOneWidget);
      expect(
        find.text("L'URL n'est pas valide (ex. https://…)."),
        findsOneWidget,
      );
    },
  );
}
