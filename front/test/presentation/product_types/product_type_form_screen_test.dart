import 'dart:async';

import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/product_types/product_type_form_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductTypeRepository extends Mock
    implements ProductTypeRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

const _tenantId = 'tenant-1';
const _productTypeId = 'pt-1';

final _existingProductType = ProductType(
  productTypeId: _productTypeId,
  producerAccountId: _tenantId,
  name: 'Légumes',
  description: 'Paniers de légumes',
  supportedBasketSizes: const [],
);

Widget _buildScreen({
  required _MockProductTypeRepository repo,
  required _MockSyncBloc syncBloc,
  String? productTypeId,
}) {
  final router = GoRouter(
    initialLocation: '/list/form',
    routes: [
      GoRoute(
        path: '/list',
        builder: (_, _) => const Scaffold(body: SizedBox()),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, _) => ProductTypeFormScreen(
              tenantId: _tenantId,
              productTypeId: productTypeId,
            ),
          ),
        ],
      ),
    ],
  );
  return MultiRepositoryProvider(
    providers: [RepositoryProvider<ProductTypeRepository>.value(value: repo)],
    child: BlocProvider<SyncBloc>.value(
      value: syncBloc,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  late _MockProductTypeRepository repo;
  late _MockSyncBloc syncBloc;

  setUp(() {
    repo = _MockProductTypeRepository();
    syncBloc = _MockSyncBloc();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());

    when(
      () => repo.watch(_tenantId),
    ).thenAnswer((_) => Stream.value([_existingProductType]));
    when(
      () => repo.delete(
        tenantId: any(named: 'tenantId'),
        productTypeId: any(named: 'productTypeId'),
      ),
    ).thenAnswer((_) async {});
  });

  group('create mode', () {
    testWidgets('delete button is not shown', (tester) async {
      await tester.pumpWidget(
        _buildScreen(repo: repo, syncBloc: syncBloc, productTypeId: null),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('product_type_delete')), findsNothing);
    });
  });

  group('edit mode', () {
    testWidgets('delete button is shown', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          repo: repo,
          syncBloc: syncBloc,
          productTypeId: _productTypeId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('product_type_delete')), findsOneWidget);
    });

    testWidgets('tapping delete opens confirmation dialog', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          repo: repo,
          syncBloc: syncBloc,
          productTypeId: _productTypeId,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('product_type_delete')));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer ce type de produit ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('cancelling dialog does not delete', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          repo: repo,
          syncBloc: syncBloc,
          productTypeId: _productTypeId,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('product_type_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repo.delete(
          tenantId: any(named: 'tenantId'),
          productTypeId: any(named: 'productTypeId'),
        ),
      );
    });

    testWidgets('confirming delete calls repo.delete and triggers sync', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          repo: repo,
          syncBloc: syncBloc,
          productTypeId: _productTypeId,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('product_type_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product_type_delete_confirm')));
      await tester.pumpAndSettle();

      verify(
        () => repo.delete(tenantId: _tenantId, productTypeId: _productTypeId),
      ).called(1);
      verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
    });
  });
}
