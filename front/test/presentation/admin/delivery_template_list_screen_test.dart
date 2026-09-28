import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_list_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

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

const _template = DeliveryTemplate(
  deliveryTemplateId: 'dt-1',
  organizationId: 'org-1',
  name: 'Marché du soir',
  standardStartTime: '18:00',
  standardEndTime: '20:00',
);

final _organization = Organization(
  organizationId: 'org-1',
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  deliveries: [
    Delivery(
      deliveryId: 'd-future',
      organizationId: 'org-1',
      scheduledDate: DateTime.now()
          .add(const Duration(days: 7))
          .toUtc()
          .toIso8601String(),
      status: DeliveryStatus.planned,
      minVolunteersRequired: 2,
      deliveryTemplateId: 'dt-1',
    ),
    const Delivery(
      deliveryId: 'd-past',
      organizationId: 'org-1',
      scheduledDate: '2024-06-14T18:00:00Z',
      status: DeliveryStatus.completed,
      minVolunteersRequired: 2,
      deliveryTemplateId: 'dt-1',
    ),
    const Delivery(
      deliveryId: 'd-none',
      organizationId: 'org-1',
      scheduledDate: '2024-06-21T18:00:00Z',
      status: DeliveryStatus.completed,
      minVolunteersRequired: 2,
    ),
  ],
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDeliveryTemplateRepository deliveryTemplateRepository,
  required _MockOrganizationRepository organizationRepository,
}) async {
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
        value: _makeSyncBloc(),
        child: const MaterialApp(
          home: DeliveryTemplateListScreen(organizationId: 'org-1'),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _MockDeliveryTemplateRepository deliveryTemplateRepository;
  late _MockOrganizationRepository organizationRepository;

  setUp(() {
    deliveryTemplateRepository = _MockDeliveryTemplateRepository();
    organizationRepository = _MockOrganizationRepository();
    when(
      () => deliveryTemplateRepository.watch('org-1'),
    ).thenAnswer((_) => Stream.value(const [_template]));
    when(
      () => organizationRepository.watch('org-1'),
    ).thenAnswer((_) => Stream.value(_organization));
  });

  testWidgets('list shows association count and associated deliveries dialog', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      deliveryTemplateRepository: deliveryTemplateRepository,
      organizationRepository: organizationRepository,
    );

    expect(find.text('2 livraisons associées'), findsOneWidget);
    expect(find.text('Voir livraisons'), findsOneWidget);

    await tester.tap(find.text('Voir livraisons'));
    await tester.pumpAndSettle();

    expect(find.text('Livraisons associées'), findsOneWidget);
    expect(find.textContaining('14/06/2024'), findsOneWidget);
  });

  testWidgets('delete is blocked when future deliveries are still associated', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      deliveryTemplateRepository: deliveryTemplateRepository,
      organizationRepository: organizationRepository,
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Suppression impossible'), findsOneWidget);
    verifyNever(() => deliveryTemplateRepository.delete(any(), any()));
  });
}
