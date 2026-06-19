import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/error_report_repository.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_messages.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _MockErrorReportRepository extends Mock
    implements ErrorReportRepository {}

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late _MockSyncBloc syncBloc;
  late _MockErrorReportRepository errorReportRepo;
  late _MockAppDatabase db;

  setUp(() {
    syncBloc = _MockSyncBloc();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    errorReportRepo = _MockErrorReportRepository();
    db = _MockAppDatabase();
  });

  tearDown(() async {
    await syncBloc.close();
  });

  Widget buildBanner() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [BlocProvider<SyncBloc>.value(value: syncBloc)],
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ErrorReportRepository>.value(
                value: errorReportRepo,
              ),
              RepositoryProvider<AppDatabase>.value(value: db),
            ],
            child: const SyncStatusBanner(),
          ),
        ),
      ),
    );
  }

  testWidgets('shows nothing when state is idle', (tester) async {
    await tester.pumpWidget(buildBanner());
    await tester.pump();

    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('shows three icon buttons when SyncFailed', (tester) async {
    whenListen(
      syncBloc,
      Stream.value(const SyncState.failure('timeout')),
      initialState: const SyncState.failure('timeout'),
    );

    await tester.pumpWidget(buildBanner());
    await tester.pump();

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('Échec de la synchronisation : timeout'), findsOneWidget);
    expect(find.byType(IconButton), findsNWidgets(3));
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('retry button dispatches SyncEvent.requested to the bloc', (
    tester,
  ) async {
    whenListen(
      syncBloc,
      Stream.value(const SyncState.failure('error')),
      initialState: const SyncState.failure('error'),
    );

    await tester.pumpWidget(buildBanner());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    verify(() => syncBloc.add(const SyncEvent.requested())).called(1);
  });

  testWidgets(
    'copy button writes error message to clipboard and shows snackbar',
    (tester) async {
      whenListen(
        syncBloc,
        Stream.value(const SyncState.failure('copy-me')),
        initialState: const SyncState.failure('copy-me'),
      );

      final List<MethodCall> log = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          log.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildBanner());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.content_copy));
      await tester.pump();

      final clipboardCall = log.firstWhere(
        (c) => c.method == 'Clipboard.setData',
        orElse: () => throw StateError('Clipboard.setData not called'),
      );
      final text = (clipboardCall.arguments as Map)['text'] as String;
      expect(text, 'copy-me');
      expect(find.text('Erreur copiée'), findsOneWidget);
    },
  );

  testWidgets(
    'report button calls ErrorReportRepository.create and disables itself',
    (tester) async {
      whenListen(
        syncBloc,
        Stream.value(const SyncState.failure('Sync failed')),
        initialState: const SyncState.failure('Sync failed'),
      );
      when(
        () => db.readAllScopeCursors(),
      ).thenAnswer((_) async => {'organization:org-1': 'c1'});
      when(
        () => errorReportRepo.create(
          errorMessage: any(named: 'errorMessage'),
          scopeKey: any(named: 'scopeKey'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildBanner());
      await tester.pump();

      final flagIconButton = find.widgetWithIcon(
        IconButton,
        Icons.flag_outlined,
      );
      expect(tester.widget<IconButton>(flagIconButton).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pump();
      await tester.pump();

      verify(
        () => errorReportRepo.create(
          errorMessage: 'Sync failed',
          scopeKey: 'organization:org-1',
        ),
      ).called(1);
      expect(find.text('Problème signalé'), findsOneWidget);

      expect(tester.widget<IconButton>(flagIconButton).onPressed, isNull);
    },
  );

  testWidgets('report button does nothing when no org or producer scope', (
    tester,
  ) async {
    whenListen(
      syncBloc,
      Stream.value(const SyncState.failure('No scope')),
      initialState: const SyncState.failure('No scope'),
    );
    when(
      () => db.readAllScopeCursors(),
    ).thenAnswer((_) async => {'instance-owner': 'c1'});

    await tester.pumpWidget(buildBanner());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pump();

    verifyNever(
      () => errorReportRepo.create(
        errorMessage: any(named: 'errorMessage'),
        scopeKey: any(named: 'scopeKey'),
      ),
    );
  });

  testWidgets(
    'shows reassuring offline banner with a single retry button when the '
    'server is unreachable',
    (tester) async {
      whenListen(
        syncBloc,
        Stream.value(const SyncState.offline()),
        initialState: const SyncState.offline(),
      );

      await tester.pumpWidget(buildBanner());
      await tester.pump();

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text(syncServerUnreachableMessage), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.content_copy), findsNothing);
      expect(find.byIcon(Icons.flag_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      verify(() => syncBloc.add(const SyncEvent.requested())).called(1);
    },
  );

  testWidgets(
    'shows reload button when sync succeeded with rejected mutations',
    (tester) async {
      const rejected = [
        MutationOutcome(clientOpId: 'op-1', status: MutationStatus.rejected),
      ];
      whenListen(
        syncBloc,
        Stream.value(
          const SyncState.success(hasMore: false, rejectedMutations: rejected),
        ),
        initialState: const SyncState.success(
          hasMore: false,
          rejectedMutations: rejected,
        ),
      );

      await tester.pumpWidget(buildBanner());
      await tester.pump();

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('Recharger'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    },
  );
}
