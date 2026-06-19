import 'dart:async';

import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_post_delivery_sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/organization_fixtures.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

Future<void> _pumpWith(
  WidgetTester tester, {
  required OrganizationRepository repo,
  String tenantId = 'org-1',
  String deliveryId = 'd-1',
}) async {
  await tester.pumpWidget(
    RepositoryProvider<OrganizationRepository>.value(
      value: repo,
      child: MaterialApp(
        home: CoordinatorPostDeliverySyncScreen(
          tenantId: tenantId,
          deliveryId: deliveryId,
        ),
      ),
    ),
  );
}

void main() {
  late _MockOrganizationRepository repo;
  late StreamController<Organization?> orgStream;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    repo = _MockOrganizationRepository();
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
      await _pumpWith(tester, repo: repo, tenantId: '');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Livraison introuvable." for unknown deliveryId', (
      tester,
    ) async {
      await _pumpWith(tester, repo: repo, deliveryId: 'unknown');
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.textContaining('Statistiques finales'), findsOneWidget);
    });

    testWidgets('shows closure action buttons', (tester) async {
      final delivery = buildDelivery(contracts: [buildContract()]);

      await _pumpWith(tester, repo: repo);
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('GÉNÉRER RAPPORT'), findsOneWidget);
      expect(find.text('RÉSUMÉ EMAIL'), findsOneWidget);
      expect(find.text('ARCHIVER'), findsOneWidget);
    });

    testWidgets('shows loading indicator before stream emits', (tester) async {
      await _pumpWith(tester, repo: repo);
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

        await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
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

      await _pumpWith(tester, repo: repo);
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('50% (1/2)'), findsOneWidget);
    });

    testWidgets('closure button tapped shows snackbar', (tester) async {
      final delivery = buildDelivery(contracts: [buildContract()]);

      await _pumpWith(tester, repo: repo);
      await tester.pump();

      orgStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      await tester.ensureVisible(find.text('GÉNÉRER RAPPORT'));
      await tester.tap(find.text('GÉNÉRER RAPPORT'));
      await tester.pump();

      expect(find.textContaining('à venir'), findsOneWidget);
    });
  });
}
