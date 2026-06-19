import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockBasketExchangeRepository extends Mock
    implements BasketExchangeRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

const _orgId = 'org-1';

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
    _delivery('d-1', '2026-06-15T10:00:00'),
    _delivery('d-2', '2026-06-22T10:00:00'),
  ],
);

final _alice = Member(
  memberId: 'm-alice',
  organizationId: _orgId,
  firstName: 'Alice',
  lastName: 'Martin',
);

final _bob = Member(
  memberId: 'm-bob',
  organizationId: _orgId,
  firstName: 'Bob',
  lastName: 'Durand',
);

/// An OPEN offer from Alice with two pending requests.
const _openOffer = BasketExchange(
  basketExchangeId: 'be-open',
  organizationId: _orgId,
  deliveryId: 'd-1',
  contractId: 'c-1',
  offeringMemberId: 'm-alice',
  status: BasketExchangeStatus.open,
  createdAt: '2026-01-01T00:00:00Z',
  motive: 'Absent',
  requests: [
    BasketExchangeRequest(
      requestId: 'req-1',
      requesterMemberId: 'm-bob',
      createdAt: '2026-01-01T08:00:00Z',
      status: BasketExchangeRequestStatus.pending,
      proposedDeliveryId: 'd-2',
    ),
    BasketExchangeRequest(
      requestId: 'req-2',
      requesterMemberId: 'm-x',
      createdAt: '2026-01-01T09:00:00Z',
      status: BasketExchangeRequestStatus.pending,
      proposedDeliveryId: 'd-2',
    ),
  ],
);

/// A settled swap: Alice offered d-1, Bob's counter d-2 was accepted.
const _acceptedSwap = BasketExchange(
  basketExchangeId: 'be-accepted',
  organizationId: _orgId,
  deliveryId: 'd-1',
  contractId: 'c-1',
  offeringMemberId: 'm-alice',
  status: BasketExchangeStatus.accepted,
  createdAt: '2026-01-02T00:00:00Z',
  acceptedRequestId: 'req-1',
  motive: 'Absent',
  requests: [
    BasketExchangeRequest(
      requestId: 'req-1',
      requesterMemberId: 'm-bob',
      createdAt: '2026-01-02T08:00:00Z',
      status: BasketExchangeRequestStatus.accepted,
      proposedDeliveryId: 'd-2',
    ),
  ],
);

/// A cancelled exchange — must not appear in the overview.
const _cancelled = BasketExchange(
  basketExchangeId: 'be-cancelled',
  organizationId: _orgId,
  deliveryId: 'd-2',
  contractId: 'c-1',
  offeringMemberId: 'm-bob',
  status: BasketExchangeStatus.cancelled,
  createdAt: '2026-01-03T00:00:00Z',
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
    when(
      () => memberRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value([_alice, _bob]));
    when(() => orgRepo.watch(_orgId)).thenAnswer((_) => Stream.value(_org));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BasketExchangeRepository>.value(
            value: exchangeRepo,
          ),
          RepositoryProvider<MemberRepository>.value(value: memberRepo),
          RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        ],
        child: const MaterialApp(
          home: BasketExchangeOverviewScreen(orgId: _orgId),
        ),
      ),
    );
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

  testWidgets('shows the empty state and disables the CSV export', (
    tester,
  ) async {
    when(
      () => exchangeRepo.watch(_orgId),
    ).thenAnswer((_) => Stream.value(const []));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Aucun échange en cours dans votre AMAP.'),
      findsOneWidget,
    );
    final export = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download),
    );
    expect(export.onPressed, isNull);
  });

  testWidgets(
    'renders open and accepted exchanges in the table, hides cancelled ones',
    (tester) async {
      when(() => exchangeRepo.watch(_orgId)).thenAnswer(
        (_) => Stream.value(const [_openOffer, _acceptedSwap, _cancelled]),
      );

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('Offreur'), findsOneWidget);
      // Two visible rows, both offered by Alice.
      expect(find.text('Alice Martin'), findsNWidgets(2));
      expect(find.text('15/06/2026'), findsNWidgets(2));
      // Open row: no taker yet, 2 pending requests.
      expect(find.text('Ouvert'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      // Accepted row: Bob is the retained requester with his counter date.
      expect(find.text('Confirmé'), findsOneWidget);
      expect(find.text('Bob Durand'), findsOneWidget);
      expect(find.text('22/06/2026'), findsOneWidget);
      // Unknown member falls back to the raw id; cancelled row is hidden.
      expect(find.text('be-cancelled'), findsNothing);
    },
  );
}
