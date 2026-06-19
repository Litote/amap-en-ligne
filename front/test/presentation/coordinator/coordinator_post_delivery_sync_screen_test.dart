import 'dart:async';

import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_post_delivery_sync_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/organization_fixtures.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockAttendanceEmailRequestRepository extends Mock
    implements AttendanceEmailRequestRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

Future<void> _pumpWith(
  WidgetTester tester, {
  required OrganizationRepository repo,
  required AttendanceEmailRequestRepository attendanceRepo,
  required SyncBloc syncBloc,
  String tenantId = 'org-1',
  String deliveryId = 'd-1',
}) async {
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: repo),
        RepositoryProvider<AttendanceEmailRequestRepository>.value(
          value: attendanceRepo,
        ),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: CoordinatorPostDeliverySyncScreen(
            tenantId: tenantId,
            deliveryId: deliveryId,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _MockOrganizationRepository repo;
  late _MockAttendanceEmailRequestRepository attendanceRepo;
  late _MockSyncBloc syncBloc;
  late StreamController<Organization?> orgStream;

  setUpAll(() async {
    await initializeDateFormatting('fr');
    registerFallbackValue(
      const Organization(
        organizationId: 'fallback',
        name: 'fallback',
        contactEmail: 'fallback@test.fr',
      ),
    );
    registerFallbackValue(DeliveryStatus.completed);
  });

  setUp(() {
    repo = _MockOrganizationRepository();
    attendanceRepo = _MockAttendanceEmailRequestRepository();
    syncBloc = _MockSyncBloc();
    orgStream = StreamController<Organization?>.broadcast();
    when(() => repo.watch(any())).thenAnswer((_) => orgStream.stream);
  });

  tearDown(() async {
    await orgStream.close();
  });

  group('CoordinatorPostDeliverySyncScreen', () {
    testWidgets('shows loading indicator when tenantId is empty', (
      tester,
    ) async {
      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
        tenantId: '',
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Livraison introuvable." for unknown deliveryId', (
      tester,
    ) async {
      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
        deliveryId: 'unknown',
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: []));
      await tester.pump();

      expect(find.text('Livraison introuvable.'), findsOneWidget);
    });

    testWidgets('shows volunteer sync section', (tester) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    displayName: 'Sophie Martin',
                    status: RegistrationStatus.confirmed,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.textContaining('Synchronisation émargement'), findsOneWidget);
      expect(find.text('Sophie Martin'), findsOneWidget);
    });

    testWidgets('shows ✅ Présent label for confirmed registration', (
      tester,
    ) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(status: RegistrationStatus.confirmed),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('✅ Présent'), findsOneWidget);
    });

    testWidgets('shows ❌ Absent label for cancelled registration', (
      tester,
    ) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(status: RegistrationStatus.cancelled),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('❌ Absent'), findsOneWidget);
    });

    testWidgets('shows ⏳ Non confirmé label for registered registration', (
      tester,
    ) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(status: RegistrationStatus.registered),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('⏳ Non confirmé'), findsOneWidget);
    });

    testWidgets('shows basket recap section with contract description', (
      tester,
    ) async {
      final delivery = buildDelivery(
        contracts: [buildContract(deliveryDescription: 'Panier œufs')],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(
        find.textContaining('Récapitulatif récupérations'),
        findsOneWidget,
      );
      expect(find.textContaining('Panier œufs'), findsOneWidget);
    });

    testWidgets('shows 100% for distributed contract', (tester) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            status: DeliveryContractStatus.distributed,
            basketQuantity: 10,
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('10/10 récupérés (100%)'), findsOneWidget);
    });

    testWidgets('shows final stats section', (tester) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            status: DeliveryContractStatus.distributed,
            basketQuantity: 5,
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(status: RegistrationStatus.confirmed),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.textContaining('Statistiques finales'), findsOneWidget);
    });

    testWidgets('shows closure action buttons', (tester) async {
      final delivery = buildDelivery(contracts: [buildContract()]);

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('GÉNÉRER RAPPORT'), findsOneWidget);
      expect(find.text('RÉSUMÉ EMAIL'), findsOneWidget);
      expect(find.text('ARCHIVER'), findsOneWidget);
    });

    testWidgets('shows loading indicator before stream emits', (tester) async {
      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'shows "Aucun bénévole enregistré." when delivery has no registrations',
      (tester) async {
        final delivery = buildDelivery(
          contracts: [
            buildContract(slots: [buildSlot(registrations: [])]),
          ],
        );

        await _pumpWith(
          tester,
          repo: repo,
          attendanceRepo: attendanceRepo,
          syncBloc: syncBloc,
        );
        await tester.pump();

        orgStream.add(buildOrg(deliveries: [delivery]));
        await tester.pump();

        expect(find.text('Aucun bénévole enregistré.'), findsOneWidget);
      },
    );

    testWidgets('shows 0% for non-distributed contract', (tester) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            status: DeliveryContractStatus.pending,
            basketQuantity: 10,
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('0/10 récupérés (0%)'), findsOneWidget);
    });

    testWidgets('shows ✅ Présent for completed registration', (tester) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(status: RegistrationStatus.completed),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('✅ Présent'), findsOneWidget);
    });

    testWidgets('stats show correct presence percentage', (tester) async {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    memberId: 'm-1',
                    status: RegistrationStatus.confirmed,
                  ),
                  buildRegistration(
                    memberId: 'm-2',
                    status: RegistrationStatus.cancelled,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('50% (1/2)'), findsOneWidget);
    });

    testWidgets('ARCHIVER confirms then marks the delivery COMPLETED', (
      tester,
    ) async {
      final delivery = buildDelivery(contracts: [buildContract()]);
      when(
        () => repo.updateDeliveryStatus(
          currentOrg: any(named: 'currentOrg'),
          deliveryId: any(named: 'deliveryId'),
          newStatus: any(named: 'newStatus'),
        ),
      ).thenAnswer((_) async {});

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      await tester.ensureVisible(find.text('ARCHIVER'));
      await tester.tap(find.text('ARCHIVER'));
      await tester.pumpAndSettle();

      expect(find.text('Archiver la distribution ?'), findsOneWidget);
      // Confirm via the dialog's filled ARCHIVER button (the last one).
      await tester.tap(find.text('ARCHIVER').last);
      await tester.pumpAndSettle();

      verify(
        () => repo.updateDeliveryStatus(
          currentOrg: any(named: 'currentOrg'),
          deliveryId: 'd-1',
          newStatus: DeliveryStatus.completed,
        ),
      ).called(1);
      verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
    });

    testWidgets('ARCHIVER cancelled does not touch the delivery', (
      tester,
    ) async {
      final delivery = buildDelivery(contracts: [buildContract()]);

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      await tester.ensureVisible(find.text('ARCHIVER'));
      await tester.tap(find.text('ARCHIVER'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repo.updateDeliveryStatus(
          currentOrg: any(named: 'currentOrg'),
          deliveryId: any(named: 'deliveryId'),
          newStatus: any(named: 'newStatus'),
        ),
      );
    });

    testWidgets('RÉSUMÉ EMAIL sends an attendance email request', (
      tester,
    ) async {
      final delivery = buildDelivery(contracts: [buildContract()]);
      when(
        () => attendanceRepo.create(
          organizationId: any(named: 'organizationId'),
          deliveryId: any(named: 'deliveryId'),
          recipientEmail: any(named: 'recipientEmail'),
        ),
      ).thenAnswer((_) async => 'req-1');

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      await tester.ensureVisible(find.text('RÉSUMÉ EMAIL'));
      await tester.tap(find.text('RÉSUMÉ EMAIL'));
      await tester.pumpAndSettle();

      expect(find.text('Envoyer par email'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'coordo@amap.fr');
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();

      verify(
        () => attendanceRepo.create(
          organizationId: 'org-1',
          deliveryId: 'd-1',
          recipientEmail: 'coordo@amap.fr',
        ),
      ).called(1);
      verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
      expect(find.text('Envoi planifié pour coordo@amap.fr'), findsOneWidget);
    });

    testWidgets('RÉSUMÉ EMAIL cancelled sends nothing', (tester) async {
      final delivery = buildDelivery(contracts: [buildContract()]);

      await _pumpWith(
        tester,
        repo: repo,
        attendanceRepo: attendanceRepo,
        syncBloc: syncBloc,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      await tester.ensureVisible(find.text('RÉSUMÉ EMAIL'));
      await tester.tap(find.text('RÉSUMÉ EMAIL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(
        () => attendanceRepo.create(
          organizationId: any(named: 'organizationId'),
          deliveryId: any(named: 'deliveryId'),
          recipientEmail: any(named: 'recipientEmail'),
        ),
      );
    });
  });

  group('postDeliveryStats', () {
    test('aggregates presence and basket recovery over all contracts', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            status: DeliveryContractStatus.distributed,
            basketQuantity: 5,
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    memberId: 'm-1',
                    status: RegistrationStatus.confirmed,
                  ),
                  buildRegistration(
                    memberId: 'm-2',
                    status: RegistrationStatus.cancelled,
                  ),
                ],
              ),
            ],
          ),
          buildContract(
            contractId: 'c-2',
            status: DeliveryContractStatus.pending,
            basketQuantity: 3,
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    memberId: 'm-3',
                    status: RegistrationStatus.completed,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final stats = postDeliveryStats(delivery);

      expect(stats.totalRegistrations, 3);
      expect(stats.presentCount, 2);
      expect(stats.totalBaskets, 8);
      expect(stats.collectedBaskets, 5);
    });
  });
}
