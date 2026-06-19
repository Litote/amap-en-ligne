import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_messages.dart';
import 'package:amap_en_ligne/presentation/sync/sync_offline_listener.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

void main() {
  late _MockSyncBloc syncBloc;
  late GlobalKey<ScaffoldMessengerState> messengerKey;

  setUp(() {
    syncBloc = _MockSyncBloc();
    messengerKey = GlobalKey<ScaffoldMessengerState>();
  });

  tearDown(() async {
    await syncBloc.close();
  });

  Widget buildApp() {
    return BlocProvider<SyncBloc>.value(
      value: syncBloc,
      child: SyncOfflineListener(
        messengerKey: messengerKey,
        child: MaterialApp(
          scaffoldMessengerKey: messengerKey,
          home: const Scaffold(body: Text('content')),
        ),
      ),
    );
  }

  testWidgets('shows the offline snackbar when a sync fails for network '
      'reasons', (tester) async {
    whenListen(
      syncBloc,
      Stream.fromIterable(const [SyncState.syncing(), SyncState.offline()]),
      initialState: const SyncState.idle(),
    );

    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(syncServerUnreachableMessage), findsOneWidget);

    // Let the snackbar duration elapse so no timer is left pending.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('shows nothing on a non-network sync failure', (tester) async {
    whenListen(
      syncBloc,
      Stream.fromIterable(const [
        SyncState.syncing(),
        SyncState.failure('boom'),
      ]),
      initialState: const SyncState.idle(),
    );

    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows nothing on a successful sync', (tester) async {
    whenListen(
      syncBloc,
      Stream.fromIterable(const [SyncState.syncing(), SyncState.success()]),
      initialState: const SyncState.idle(),
    );

    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
