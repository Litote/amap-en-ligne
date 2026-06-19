import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/member/member_contracts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockAuthService extends Mock implements AuthService {}

String _fakeToken(String sub) {
  final payload = '{"sub":"$sub","exp":9999999999}';
  final encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$encoded.sig';
}

Future<void> _pump(
  WidgetTester tester, {
  required OrganizationRepository organizationRepository,
  required MemberRepository memberRepository,
  required ContractRepository contractRepository,
  required AuthService authService,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
        RepositoryProvider<MemberRepository>.value(value: memberRepository),
        RepositoryProvider<ContractRepository>.value(value: contractRepository),
        RepositoryProvider<AuthService>.value(value: authService),
      ],
      child: const MaterialApp(home: MemberContractsScreen(tenantId: 'org-1')),
    ),
  );
}

void main() {
  late _MockOrganizationRepository organizationRepository;
  late _MockMemberRepository memberRepository;
  late _MockContractRepository contractRepository;
  late _MockAuthService authService;
  late StreamController<Organization?> organizationStream;
  late StreamController<Member?> memberStream;
  late StreamController<List<Contract>> contractStream;

  Organization buildOrganization() => const Organization(
    organizationId: 'org-1',
    name: 'AMAP Test',
    contactEmail: 'contact@amap.fr',
    products: [
      OrgProduct(
        name: 'Tomates',
        productTypeId: 'pt-1',
        producerAccountId: 'p-1',
      ),
      OrgProduct(
        name: 'Oeufs',
        productTypeId: 'pt-2',
        producerAccountId: 'p-2',
      ),
      OrgProduct(name: 'Pain', productTypeId: 'pt-3', producerAccountId: 'p-3'),
    ],
  );

  Contract buildContract({
    required String contractId,
    String producerAccountId = 'pa-1',
    required String minDeliveryDate,
    required String maxDeliveryDate,
    required List<ContractMember> members,
    ContractStatus status = ContractStatus.active,
  }) => Contract(
    contractId: contractId,
    name: 'Contrat test',
    organizationId: 'org-1',
    producerAccountId: producerAccountId,
    minDeliveryDate: minDeliveryDate,
    maxDeliveryDate: maxDeliveryDate,
    deliveryCount: 10,
    seasonYear: 2026,
    members: members,
    status: status,
  );

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    organizationRepository = _MockOrganizationRepository();
    memberRepository = _MockMemberRepository();
    contractRepository = _MockContractRepository();
    authService = _MockAuthService();

    organizationStream = StreamController<Organization?>.broadcast();
    memberStream = StreamController<Member?>.broadcast();
    contractStream = StreamController<List<Contract>>.broadcast();

    when(
      () => organizationRepository.watch(any()),
    ).thenAnswer((_) => organizationStream.stream);
    when(
      () => memberRepository.watchMyMember(any()),
    ).thenAnswer((_) => memberStream.stream);
    when(
      () => contractRepository.watch(any()),
    ).thenAnswer((_) => contractStream.stream);
    when(() => authService.currentState).thenReturn(
      AuthState.authenticated(
        producerId: 'org-1',
        accessToken: _fakeToken('sub-1'),
        roles: const ['VOLUNTEER'],
      ),
    );
  });

  tearDown(() async {
    await organizationStream.close();
    await memberStream.close();
    await contractStream.close();
  });

  testWidgets('filters the current member contracts by period', (tester) async {
    await _pump(
      tester,
      organizationRepository: organizationRepository,
      memberRepository: memberRepository,
      contractRepository: contractRepository,
      authService: authService,
    );
    await tester.pump();

    organizationStream.add(buildOrganization());
    await tester.pump();
    memberStream.add(const Member(memberId: 'm-1', organizationId: 'org-1'));
    await tester.pump();
    contractStream.add([
      buildContract(
        contractId: 'c-active',
        producerAccountId: 'p-1',
        minDeliveryDate: '2020-01-01',
        maxDeliveryDate: '2099-12-31',
        members: const [
          ContractMember(
            memberId: 'm-1',
            subscriptionInstant: '2026-01-01T00:00:00Z',
            status: ContractMemberStatus.active,
          ),
        ],
      ),
      buildContract(
        contractId: 'c-upcoming',
        producerAccountId: 'p-2',
        minDeliveryDate: '2099-01-01',
        maxDeliveryDate: '2099-12-31',
        members: const [
          ContractMember(
            memberId: 'm-1',
            subscriptionInstant: '2026-01-01T00:00:00Z',
            status: ContractMemberStatus.active,
          ),
        ],
      ),
      buildContract(
        contractId: 'c-ended',
        producerAccountId: 'p-3',
        minDeliveryDate: '2020-01-01',
        maxDeliveryDate: '2020-12-31',
        members: const [
          ContractMember(
            memberId: 'm-1',
            subscriptionInstant: '2026-01-01T00:00:00Z',
            status: ContractMemberStatus.completed,
          ),
        ],
      ),
      buildContract(
        contractId: 'c-other-member',
        producerAccountId: 'p-1',
        minDeliveryDate: '2020-01-01',
        maxDeliveryDate: '2099-12-31',
        members: const [
          ContractMember(
            memberId: 'm-2',
            subscriptionInstant: '2026-01-01T00:00:00Z',
            status: ContractMemberStatus.active,
          ),
        ],
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Contrats actifs'), findsOneWidget);
    expect(find.text('Contrats à venir'), findsOneWidget);
    expect(find.text('Contrats terminés'), findsOneWidget);
    expect(find.text('Tomates'), findsOneWidget);
    expect(find.text('Oeufs'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'À venir'));
    await tester.pump();
    expect(find.text('Tomates'), findsNothing);
    expect(find.text('Oeufs'), findsOneWidget);
    expect(find.text('Pain'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Terminés'));
    await tester.pump();
    expect(find.text('Pain'), findsOneWidget);
    expect(find.text('Tomates'), findsNothing);
  });

  testWidgets('shows an empty state when the member has no contracts', (
    tester,
  ) async {
    await _pump(
      tester,
      organizationRepository: organizationRepository,
      memberRepository: memberRepository,
      contractRepository: contractRepository,
      authService: authService,
    );
    await tester.pump();

    organizationStream.add(buildOrganization());
    await tester.pump();
    memberStream.add(const Member(memberId: 'm-1', organizationId: 'org-1'));
    await tester.pump();
    contractStream.add(const []);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aucun contrat ne vous est actuellement attribué. Contactez votre coordinateur si nécessaire.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('displays member subscriptions in read-only format', (
    tester,
  ) async {
    await _pump(
      tester,
      organizationRepository: organizationRepository,
      memberRepository: memberRepository,
      contractRepository: contractRepository,
      authService: authService,
    );
    await tester.pump();

    organizationStream.add(buildOrganization());
    await tester.pump();
    memberStream.add(const Member(memberId: 'm-1', organizationId: 'org-1'));
    await tester.pump();
    contractStream.add([
      buildContract(
        contractId: 'c-active',
        producerAccountId: 'p-1',
        minDeliveryDate: '2020-01-01',
        maxDeliveryDate: '2099-12-31',
        members: [
          ContractMember(
            memberId: 'm-1',
            subscriptionInstant: '2026-01-01T00:00:00Z',
            status: ContractMemberStatus.active,
            subscriptions: const [
              MemberSubscription(
                productTypeId: 'pt-1',
                basketSize: BasketSize(name: 'Petit'),
              ),
            ],
          ),
        ],
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.textContaining('📦'), findsOneWidget);
  });
}
