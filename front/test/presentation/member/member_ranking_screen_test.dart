import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/member_ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/organization_fixtures.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockContractRepository extends Mock implements ContractRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _fakeToken(String sub) {
  final payload = '{"sub":"$sub","exp":9999999999}';
  final encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$encoded.fakesig';
}

const _kSub = 'user-sub-1';
const _kMemberId = 'member-1';

Member _buildMember({
  String memberId = _kMemberId,
  MemberAccountStatus? accountStatus = MemberAccountStatus.active,
}) => Member(
  memberId: memberId,
  organizationId: 'org-1',
  firstName: 'Marie',
  lastName: 'Dupont',
  accountStatus: accountStatus,
  roles: const {Role.volunteer},
);

Contract _activeContract({
  required String contractId,
  required int seasonYear,
}) => Contract(
  contractId: contractId,
  name: 'Contrat $seasonYear',
  organizationId: 'org-1',
  producerAccountId: 'producer-1',
  minDeliveryDate: '$seasonYear-01-01',
  maxDeliveryDate: '$seasonYear-12-31',
  deliveryCount: 10,
  seasonYear: seasonYear,
  status: ContractStatus.active,
);

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRepository orgRepo,
  required _MockMemberRepository memberRepo,
  required _MockAuthService authService,
  required _MockContractRepository contractRepo,
  String tenantId = 'org-1',
}) async {
  final screen = MemberRankingScreen(tenantId: tenantId);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
      ],
      child: MaterialApp(home: screen),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockMemberRepository memberRepo;
  late _MockAuthService authService;
  late _MockContractRepository contractRepo;
  late StreamController<Organization?> orgStream;
  late StreamController<Member?> memberStream;
  late StreamController<List<Member>> allMembersStream;
  late StreamController<List<Contract>> contractsStream;

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    memberRepo = _MockMemberRepository();
    authService = _MockAuthService();
    contractRepo = _MockContractRepository();

    orgStream = StreamController<Organization?>.broadcast();
    memberStream = StreamController<Member?>.broadcast();
    allMembersStream = StreamController<List<Member>>.broadcast();
    contractsStream = StreamController<List<Contract>>.broadcast();

    when(() => orgRepo.watch(any())).thenAnswer((_) => orgStream.stream);
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => memberStream.stream);
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => allMembersStream.stream);
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => contractsStream.stream);
    when(() => authService.currentState).thenReturn(
      AuthState.authenticated(
        producerId: 'prod-1',
        accessToken: _fakeToken(_kSub),
        roles: ['VOLUNTEER'],
      ),
    );
  });

  tearDown(() async {
    await orgStream.close();
    await memberStream.close();
    await allMembersStream.close();
    await contractsStream.close();
  });

  group('MemberRankingScreen', () {
    // --- Loading state ---

    testWidgets('shows loading when org not yet available', (tester) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // --- My position card ---

    testWidgets('renders Ma position card with rank and count', (tester) async {
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;

      // member-1 has 2 completions; member-2 has 1 → member-1 is rank 1, not tied.
      final d1 = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: '$seasonYear-01-10T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: contractId,
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    memberId: _kMemberId,
                    status: RegistrationStatus.completed,
                  ),
                  buildRegistration(
                    memberId: 'member-2',
                    status: RegistrationStatus.completed,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final d2 = buildDelivery(
        deliveryId: 'd-2',
        scheduledDate: '$seasonYear-02-10T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: contractId,
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    memberId: _kMemberId,
                    status: RegistrationStatus.completed,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
      );
      await tester.pump();

      final me = _buildMember();
      final other = _buildMember(memberId: 'member-2');
      orgStream.add(buildOrg(deliveries: [d1, d2]));
      memberStream.add(me);
      allMembersStream.add([me, other]);
      contractsStream.add([
        _activeContract(contractId: contractId, seasonYear: seasonYear),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('📍 Ma position'), findsOneWidget);
      // Not tied → no "ex-aequo"
      expect(
        find.textContaining('Vous êtes 1er / 2 membres actifs'),
        findsOneWidget,
      );
      expect(
        find.textContaining('📈 Mes participations cette saison : 2'),
        findsOneWidget,
      );
    });

    testWidgets('renders ex-aequo in position label when tied', (tester) async {
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;

      // Both members have 0 completions → tied at rank 1.
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
      );
      await tester.pump();

      final me = _buildMember();
      final other = _buildMember(memberId: 'member-2');
      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(me);
      allMembersStream.add([me, other]);
      contractsStream.add([
        _activeContract(contractId: contractId, seasonYear: seasonYear),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Everyone at 0 → tied.
      expect(
        find.textContaining('Vous êtes 1er ex-aequo / 2 membres actifs'),
        findsOneWidget,
      );
    });

    // --- Distribution section ---

    testWidgets('renders distribution section with three tier rows', (
      tester,
    ) async {
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;

      // member-1: 5 completions (active tier)
      // member-2: 1 completion (occasional tier)
      // member-3: 0 completions (inactive tier)
      final deliveries = [
        for (var i = 1; i <= 5; i++)
          buildDelivery(
            deliveryId: 'd-m1-$i',
            scheduledDate: '$seasonYear-0$i-10T18:00:00',
            status: DeliveryStatus.completed,
            contracts: [
              buildContract(
                contractId: contractId,
                slots: [
                  buildSlot(
                    registrations: [
                      buildRegistration(
                        memberId: _kMemberId,
                        status: RegistrationStatus.completed,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        buildDelivery(
          deliveryId: 'd-m2-1',
          scheduledDate: '$seasonYear-01-11T18:00:00',
          status: DeliveryStatus.completed,
          contracts: [
            buildContract(
              contractId: contractId,
              slots: [
                buildSlot(
                  registrations: [
                    buildRegistration(
                      memberId: 'member-2',
                      status: RegistrationStatus.completed,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
      );
      await tester.pump();

      final me = _buildMember();
      final m2 = _buildMember(memberId: 'member-2');
      final m3 = _buildMember(memberId: 'member-3');
      orgStream.add(buildOrg(deliveries: deliveries));
      memberStream.add(me);
      allMembersStream.add([me, m2, m3]);
      contractsStream.add([
        _activeContract(contractId: contractId, seasonYear: seasonYear),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('📊 Répartition des membres actifs'), findsOneWidget);
      // Three tier rows.
      expect(find.textContaining('Actifs (≥5)'), findsOneWidget);
      expect(find.textContaining('Occasionnels (1-4)'), findsOneWidget);
      expect(find.textContaining('Inactifs (0)'), findsOneWidget);
      // member-1 is in active tier → "← vous" marker on Actifs row.
      expect(find.textContaining('← vous'), findsOneWidget);
      expect(
        find.textContaining('Actifs (≥5) : ■ (1 membres)  ← vous'),
        findsOneWidget,
      );
    });

    // --- Anonymity: no other member names ---

    testWidgets('does not display any other member names', (tester) async {
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
      );
      await tester.pump();

      final me = _buildMember();
      final other = _buildMember(
        memberId: 'member-2',
      ).copyWith(firstName: 'Jacques', lastName: 'Tartempion');
      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(me);
      allMembersStream.add([me, other]);
      contractsStream.add([
        _activeContract(contractId: contractId, seasonYear: seasonYear),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The other member's name must never appear on screen.
      expect(find.text('Jacques'), findsNothing);
      expect(find.text('Tartempion'), findsNothing);
      expect(find.text('Jacques Tartempion'), findsNothing);
    });
  });
}
