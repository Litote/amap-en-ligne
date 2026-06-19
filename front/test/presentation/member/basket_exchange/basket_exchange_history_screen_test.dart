import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_history_screen.dart';
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

const _orgId = 'org-1';
const _me = 'm-me';

Delivery _delivery(String id, String scheduledDate) => Delivery(
  deliveryId: id,
  organizationId: _orgId,
  scheduledDate: scheduledDate,
  status: DeliveryStatus.planned,
  minVolunteersRequired: 0,
);

final _org = Organization(
  organizationId: _orgId,
  name: 'AMAP',
  contactEmail: 'c@e.com',
  deliveries: [
    _delivery('d-offer', '2026-06-15T10:00:00'),
    _delivery('d-bob', '2026-06-22T10:00:00'),
  ],
);

final _bob = Member(
  memberId: 'm-bob',
  organizationId: _orgId,
  firstName: 'Bob',
  lastName: 'Durand',
);

/// A settled swap: I offered d-offer, Bob's counter d-bob was accepted.
const _acceptedSwap = BasketExchange(
  basketExchangeId: 'be-1',
  organizationId: _orgId,
  deliveryId: 'd-offer',
  contractId: 'c-1',
  offeringMemberId: _me,
  status: BasketExchangeStatus.accepted,
  createdAt: '2026-01-01T00:00:00Z',
  decidedAt: '2026-01-02T00:00:00Z',
  acceptedRequestId: 'req-1',
  motive: 'Absent',
  requests: [
    BasketExchangeRequest(
      requestId: 'req-1',
      requesterMemberId: 'm-bob',
      createdAt: '2026-01-01T08:00:00Z',
      status: BasketExchangeRequestStatus.accepted,
      proposedDeliveryId: 'd-bob',
    ),
  ],
);

/// An exchange offered by Bob that he cancelled; I was a requester.
const _cancelledOffer = BasketExchange(
  basketExchangeId: 'be-2',
  organizationId: _orgId,
  deliveryId: 'd-bob',
  contractId: 'c-1',
  offeringMemberId: 'm-bob',
  status: BasketExchangeStatus.cancelled,
  createdAt: '2026-02-01T00:00:00Z',
  motive: 'Absent',
  requests: [],
);

void main() {
  late _MockBasketExchangeRepository exchangeRepo;
  late _MockMemberRepository memberRepo;
  late _MockOrganizationRepository orgRepo;

  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  setUp(() {
    exchangeRepo = _MockBasketExchangeRepository();
    memberRepo = _MockMemberRepository();
    orgRepo = _MockOrganizationRepository();
    when(() => memberRepo.watch(_orgId)).thenAnswer((_) => Stream.value([_bob]));
    when(() => orgRepo.watch(_orgId)).thenAnswer((_) => Stream.value(_org));
  });

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/basket-exchange',
          builder: (_, _) => const Scaffold(body: Text('EXCHANGE HOME')),
        ),
        GoRoute(
          path: '/history',
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<BasketExchangeRepository>.value(
                value: exchangeRepo,
              ),
              RepositoryProvider<MemberRepository>.value(value: memberRepo),
              RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
            ],
            child: const BasketExchangeHistoryScreen(
              orgId: _orgId,
              memberId: _me,
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('shows a spinner while the history stream is pending', (
    tester,
  ) async {
    final controller = StreamController<List<BasketExchange>>();
    when(
      () => exchangeRepo.watchHistory(_orgId, _me),
    ).thenAnswer((_) => controller.stream);
    addTearDown(controller.close);

    await pump(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty state with a back button', (tester) async {
    when(
      () => exchangeRepo.watchHistory(_orgId, _me),
    ).thenAnswer((_) => Stream.value(const []));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Aucun échange dans votre historique.'), findsOneWidget);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();
    expect(find.text('EXCHANGE HOME'), findsOneWidget);
  });

  testWidgets('renders a settled swap I offered with both delivery dates', (
    tester,
  ) async {
    when(
      () => exchangeRepo.watchHistory(_orgId, _me),
    ).thenAnswer((_) => Stream.value(const [_acceptedSwap]));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining("J'ai proposé avec Bob Durand"), findsOneWidget);
    expect(find.textContaining('Échangé'), findsOneWidget);
    expect(find.textContaining('15 juin 2026 ↔ 22 juin 2026'), findsOneWidget);
  });

  testWidgets('renders a cancelled offer where I was a requester', (
    tester,
  ) async {
    when(
      () => exchangeRepo.watchHistory(_orgId, _me),
    ).thenAnswer((_) => Stream.value(const [_cancelledOffer]));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining("J'ai demandé avec Bob Durand"), findsOneWidget);
    expect(find.textContaining('Annulé'), findsOneWidget);
  });

  testWidgets('orders exchanges by most recent decision first', (
    tester,
  ) async {
    when(() => exchangeRepo.watchHistory(_orgId, _me)).thenAnswer(
      (_) => Stream.value(const [_acceptedSwap, _cancelledOffer]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    final direction = tester
        .widgetList<Text>(find.textContaining('avec Bob Durand'))
        .map((t) => t.data)
        .toList();
    // _cancelledOffer (2026-02-01) is more recent than _acceptedSwap's
    // decidedAt (2026-01-02) so it comes first.
    expect(direction.first, contains("J'ai demandé"));
    expect(direction.last, contains("J'ai proposé"));
  });
}
