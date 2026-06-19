import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/received_requests_screen.dart';
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

class _MockBasketExchangeRepository extends Mock
    implements BasketExchangeRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

const _orgId = 'org-1';
const _offerId = 'be-1';

const _request = BasketExchangeRequest(
  requestId: 'req-1',
  requesterMemberId: 'm-bob',
  createdAt: '2026-01-01T08:00:00Z',
  status: BasketExchangeRequestStatus.pending,
  proposedDeliveryId: 'd-bob',
);

BasketExchange _offer({
  BasketExchangeStatus status = BasketExchangeStatus.open,
  List<BasketExchangeRequest> requests = const [_request],
}) => BasketExchange(
  basketExchangeId: _offerId,
  organizationId: _orgId,
  deliveryId: 'd-offer',
  contractId: 'c-1',
  offeringMemberId: 'm-me',
  status: status,
  createdAt: '2026-01-01T00:00:00Z',
  motive: 'Absent',
  requests: requests,
);

Delivery _delivery(String id) => Delivery(
  deliveryId: id,
  organizationId: _orgId,
  scheduledDate: '2099-06-15T10:00:00',
  status: DeliveryStatus.planned,
  minVolunteersRequired: 0,
);

const _org = Organization(
  organizationId: _orgId,
  name: 'AMAP',
  contactEmail: 'c@e.com',
  deliveries: [],
);

final _bob = Member(
  memberId: 'm-bob',
  organizationId: _orgId,
  firstName: 'Bob',
  lastName: 'Durand',
);

void main() {
  late _MockBasketExchangeRepository exchangeRepo;
  late _MockMemberRepository memberRepo;
  late _MockOrganizationRepository orgRepo;
  late _MockSyncBloc syncBloc;

  setUpAll(() async {
    registerFallbackValue(_offer());
    await initializeDateFormatting('fr', null);
  });

  setUp(() {
    exchangeRepo = _MockBasketExchangeRepository();
    memberRepo = _MockMemberRepository();
    orgRepo = _MockOrganizationRepository();
    syncBloc = _MockSyncBloc();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => memberRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value([_bob]));
    when(() => orgRepo.watch(_orgId)).thenAnswer(
      (_) => Stream.value(
        _org.copyWith(deliveries: [_delivery('d-offer'), _delivery('d-bob')]),
      ),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/requests',
      routes: [
        GoRoute(
          path: '/basket-exchange',
          builder: (_, _) => const Scaffold(body: Text('EXCHANGE HOME')),
        ),
        GoRoute(
          path: '/requests',
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<BasketExchangeRepository>.value(
                value: exchangeRepo,
              ),
              RepositoryProvider<MemberRepository>.value(value: memberRepo),
              RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
            ],
            child: BlocProvider<SyncBloc>.value(
              value: syncBloc,
              child: const ReceivedRequestsScreen(
                orgId: _orgId,
                offerId: _offerId,
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('shows a spinner while the exchange stream is pending', (
    tester,
  ) async {
    final controller = StreamController<List<BasketExchange>>();
    when(() => exchangeRepo.watch(_orgId)).thenAnswer((_) => controller.stream);
    addTearDown(controller.close);

    await pump(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows "introuvable" when the offer is not in the feed', (
    tester,
  ) async {
    when(
      () => exchangeRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value(const []));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Proposition introuvable.'), findsOneWidget);
  });

  testWidgets('renders the pending requests with requester name and actions', (
    tester,
  ) async {
    when(
      () => exchangeRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value([_offer()]));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Demandes reçues (1)'), findsOneWidget);
    expect(find.textContaining('Bob Durand'), findsOneWidget);
    expect(find.text('VALIDER'), findsOneWidget);
    expect(find.text('REFUSER'), findsOneWidget);
  });

  testWidgets('validating a request confirms then accepts + syncs', (
    tester,
  ) async {
    when(
      () => exchangeRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value([_offer()]));
    when(
      () => exchangeRepo.acceptRequest(
        basketExchange: any(named: 'basketExchange'),
        requestId: any(named: 'requestId'),
        decidedAt: any(named: 'decidedAt'),
      ),
    ).thenAnswer((_) async {});

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('VALIDER'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmer l\'échange'), findsOneWidget);
    await tester.tap(find.text('CONFIRMER'));
    await tester.pumpAndSettle();

    verify(
      () => exchangeRepo.acceptRequest(
        basketExchange: any(named: 'basketExchange'),
        requestId: 'req-1',
        decidedAt: any(named: 'decidedAt'),
      ),
    ).called(1);
    verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
  });

  testWidgets('refusing a request calls refuseRequest + syncs', (tester) async {
    when(
      () => exchangeRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value([_offer()]));
    when(
      () => exchangeRepo.refuseRequest(
        basketExchange: any(named: 'basketExchange'),
        requestId: any(named: 'requestId'),
        decidedAt: any(named: 'decidedAt'),
      ),
    ).thenAnswer((_) async {});

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('REFUSER'));
    await tester.pumpAndSettle();

    verify(
      () => exchangeRepo.refuseRequest(
        basketExchange: any(named: 'basketExchange'),
        requestId: 'req-1',
        decidedAt: any(named: 'decidedAt'),
      ),
    ).called(1);
    verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
  });

  testWidgets(
    'navigates back to the exchange home when the offer is accepted',
    (tester) async {
      when(() => exchangeRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value([_offer(status: BasketExchangeStatus.accepted)]),
      );

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('EXCHANGE HOME'), findsOneWidget);
    },
  );
}
