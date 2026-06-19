import 'package:amap_en_ligne/presentation/producer/producer_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

_MockSyncBloc _makeSyncBloc() {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

Future<void> _pump(WidgetTester tester, {String? tenantId}) async {
  await tester.pumpWidget(
    BlocProvider<SyncBloc>.value(
      value: _makeSyncBloc(),
      child: MaterialApp(home: ProducerDashboardScreen(tenantId: tenantId)),
    ),
  );
}

void main() {
  group('ProducerDashboardScreen', () {
    testWidgets('renders greeting header', (tester) async {
      await _pump(tester);

      expect(find.text('Bonjour 👋'), findsOneWidget);
    });

    testWidgets('renders all navigation tiles', (tester) async {
      await _pump(tester);

      expect(find.text('Catalogue de produits'), findsOneWidget);
      expect(find.text('Mes livraisons'), findsOneWidget);
      expect(find.text('Préférences'), findsOneWidget);
    });

    testWidgets('renders three tiles', (tester) async {
      await _pump(tester);

      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('renders with explicit tenantId', (tester) async {
      await _pump(tester, tenantId: 'org-1');

      expect(find.text('Bonjour 👋'), findsOneWidget);
    });
  });
}
