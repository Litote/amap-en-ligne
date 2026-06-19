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
import 'package:amap_en_ligne/presentation/member/member_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
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
// Minimal JWT whose 'sub' claim is readable by JwtClaims.decode.
// ---------------------------------------------------------------------------
String _fakeToken(String sub) {
  final payload = '{"sub":"$sub","exp":9999999999}';
  final encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$encoded.fakesig';
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

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

/// Builds a minimal ACTIVE contract for the given season year with
/// contractId matching the delivery's contractId.
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

/// Pumps [MemberHistoryScreen] with an optional [GoRouter] for navigation tests.
Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRepository orgRepo,
  required _MockMemberRepository memberRepo,
  required _MockAuthService authService,
  required _MockContractRepository contractRepo,
  String tenantId = 'org-1',
  GoRouter? router,
}) async {
  final screen = MemberHistoryScreen(tenantId: tenantId);

  Widget child;
  if (router != null) {
    child = MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  } else {
    child = MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
      ],
      child: MaterialApp(home: screen),
    );
  }

  await tester.pumpWidget(child);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

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

  group('MemberHistoryScreen', () {
    // --- Loading states ---

    testWidgets('shows loading indicator when tenantId is empty', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
        tenantId: '',
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading indicator when org loaded but member is null', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: []));
      // member and allMembers not emitted yet.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // --- Empty state ---

    testWidgets('shows empty-state card when member has no registrations', (
      tester,
    ) async {
      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(_buildMember());
      allMembersStream.add([_buildMember()]);
      contractsStream.add([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucune participation pour le moment.'), findsOneWidget);
      expect(find.text('Inscrivez-vous depuis le planning.'), findsOneWidget);
      expect(find.text('📅 PLANNING'), findsOneWidget);
    });

    // --- Stats card ---

    testWidgets('stats card renders total, rank, last participation, status', (
      tester,
    ) async {
      // Build 3 completed registrations for member-1 via a season contract.
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;
      final completedDeliveries = [
        for (var i = 1; i <= 3; i++)
          buildDelivery(
            deliveryId: 'd-$i',
            scheduledDate: '$seasonYear-0${i.clamp(1, 9)}-10T18:00:00',
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
      orgStream.add(buildOrg(deliveries: completedDeliveries));
      memberStream.add(me);
      allMembersStream.add([me]);
      contractsStream.add([
        _activeContract(contractId: contractId, seasonYear: seasonYear),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Stats card visible.
      expect(find.text('🎯 Mes statistiques'), findsOneWidget);
      expect(
        find.textContaining('📈 Total participations : 3'),
        findsOneWidget,
      );
      // Rank: member-1 is the only active member → rank 1/1, not tied.
      expect(
        find.textContaining('🏆 Rang dans l\'Amap : 1er / 1 membres'),
        findsOneWidget,
      );
      // Status: 3 completions < 5 → Occasionnel.
      expect(find.textContaining('⭐ Statut : Occasionnel'), findsOneWidget);
    });

    testWidgets('stats card shows "Membre actif" when >= 5 completions', (
      tester,
    ) async {
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;
      final completedDeliveries = [
        for (var i = 1; i <= 6; i++)
          buildDelivery(
            deliveryId: 'd-$i',
            scheduledDate: '$seasonYear-0${i.clamp(1, 9)}-10T18:00:00',
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
      orgStream.add(buildOrg(deliveries: completedDeliveries));
      memberStream.add(me);
      allMembersStream.add([me]);
      contractsStream.add([
        _activeContract(contractId: contractId, seasonYear: seasonYear),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('⭐ Statut : Membre actif'), findsOneWidget);
    });

    // --- Ex-aequo rank label ---

    testWidgets(
      'rank label shows ex-aequo when two members share the same count',
      (tester) async {
        final contractId = 'c-season';
        final seasonYear = DateTime.now().year;

        // Both member-1 and member-2 have 1 completed participation.
        final delivery = buildDelivery(
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
        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(me);
        allMembersStream.add([me, other]);
        contractsStream.add([
          _activeContract(contractId: contractId, seasonYear: seasonYear),
        ]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Tied → "1er ex-aequo / 2 membres"
        expect(
          find.textContaining(
            '🏆 Rang dans l\'Amap : 1er ex-aequo / 2 membres',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('rank label shows no ex-aequo when member has unique count', (
      tester,
    ) async {
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;

      // member-1 has 2 completions, member-2 has 1.
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

      // Not tied → "1er / 2 membres"
      expect(
        find.textContaining('🏆 Rang dans l\'Amap : 1er / 2 membres'),
        findsOneWidget,
      );
    });

    // --- Upcoming commitments ---

    testWidgets('upcoming section shows commitment card with teammates', (
      tester,
    ) async {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 3));
      final futureIso =
          '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-'
          '${futureDate.day.toString().padLeft(2, '0')}T18:00:00';

      final registrations = [
        buildRegistration(memberId: _kMemberId, displayName: 'Marie D.'),
        buildRegistration(memberId: 'm-2', displayName: 'Paul M.'),
        buildRegistration(memberId: 'm-3', displayName: 'Lisa K.'),
        buildRegistration(memberId: 'm-4', displayName: 'Tom R.'),
        buildRegistration(memberId: 'm-5', displayName: 'Anna B.'),
        buildRegistration(memberId: 'm-6', displayName: 'Extra X.'),
      ];
      final delivery = buildDelivery(
        deliveryId: 'd-future',
        scheduledDate: futureIso,
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(slots: [buildSlot(registrations: registrations)]),
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
      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(me);
      allMembersStream.add([me]);
      contractsStream.add([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('⭕ Engagements à venir'), findsOneWidget);
      expect(find.text('✅ Confirmé - Préparation paniers'), findsOneWidget);
      // 5 teammates but maxShown = 4 → suffix "… et 1 autres".
      expect(find.textContaining('… et 1 autres'), findsOneWidget);
    });

    // --- Completed participations ---

    testWidgets(
      'completed section shows COMPLETED registrations in descending order',
      (tester) async {
        final now = DateTime.now();
        final older = buildDelivery(
          deliveryId: 'd-older',
          scheduledDate: '${now.year}-01-10T18:00:00',
          status: DeliveryStatus.completed,
          contracts: [
            buildContract(
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
        final newer = buildDelivery(
          deliveryId: 'd-newer',
          scheduledDate: '${now.year}-02-20T18:00:00',
          status: DeliveryStatus.completed,
          contracts: [
            buildContract(
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
        orgStream.add(buildOrg(deliveries: [older, newer]));
        memberStream.add(me);
        allMembersStream.add([me]);
        contractsStream.add([]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('✅ Participations réalisées'), findsOneWidget);
        // Two completed cards.
        expect(find.text('✅ Participation confirmée'), findsNWidgets(2));

        // Verify descending order: newer month (Feb) should appear before older (Jan).
        final janFinder = find.textContaining('janv.');
        final febFinder = find.textContaining('févr.');
        // Both dates should render.
        expect(janFinder, findsOneWidget);
        expect(febFinder, findsOneWidget);
        // Feb card should appear higher (lower Y) than Jan card.
        final febY = tester.getTopLeft(febFinder).dy;
        final janY = tester.getTopLeft(janFinder).dy;
        expect(febY, lessThan(janY));
      },
    );

    // --- Monthly histogram ---

    testWidgets('monthly histogram section renders', (tester) async {
      final now = DateTime.now();
      final delivery = buildDelivery(
        scheduledDate:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-10T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
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
      orgStream.add(buildOrg(deliveries: [delivery]));
      memberStream.add(me);
      allMembersStream.add([me]);
      contractsStream.add([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('📊 Répartition par mois'), findsOneWidget);
    });

    // --- Footer ---

    testWidgets(
      'footer shows PLANNING (active) and Participations globales (active), NO MES RAPPELS',
      (tester) async {
        final now = DateTime.now();
        final delivery = buildDelivery(
          scheduledDate: '${now.year}-01-10T18:00:00',
          status: DeliveryStatus.completed,
          contracts: [
            buildContract(
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
        orgStream.add(buildOrg(deliveries: [delivery]));
        memberStream.add(me);
        allMembersStream.add([me]);
        contractsStream.add([]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Scroll to the bottom to ensure the footer is built and visible.
        await tester.scrollUntilVisible(
          find.text('PLANNING'),
          50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();

        // PLANNING present and active.
        expect(find.text('PLANNING'), findsOneWidget);
        final planningButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'PLANNING'),
        );
        expect(planningButton.onPressed, isNotNull);

        // Participations globales present and active.
        expect(find.text('Participations globales'), findsOneWidget);
        final rankingButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Participations globales'),
        );
        expect(rankingButton.onPressed, isNotNull);

        // MES RAPPELS must NOT be present.
        expect(find.text('MES RAPPELS'), findsNothing);
        // Old CLASSEMENT label also gone.
        expect(find.text('CLASSEMENT Amap'), findsNothing);
      },
    );

    // --- Navigation ---

    testWidgets('tap PLANNING navigates to /planning', (tester) async {
      String? navigatedTo;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MemberHistoryScreen(tenantId: 'org-1'),
          ),
          GoRoute(
            path: '/planning',
            builder: (context, state) =>
                const Scaffold(body: Text('planning-page')),
          ),
          GoRoute(
            path: '/history/ranking',
            builder: (context, state) =>
                const Scaffold(body: Text('ranking-page')),
          ),
        ],
      );

      await _pump(
        tester,
        orgRepo: orgRepo,
        memberRepo: memberRepo,
        authService: authService,
        contractRepo: contractRepo,
        router: router,
      );
      await tester.pump();

      orgStream.add(buildOrg(deliveries: []));
      memberStream.add(_buildMember());
      allMembersStream.add([_buildMember()]);
      contractsStream.add([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Empty state shows 📅 PLANNING button.
      await tester.tap(find.text('📅 PLANNING'));
      await tester.pumpAndSettle();

      expect(find.text('planning-page'), findsOneWidget);
      navigatedTo = '/planning';
      expect(navigatedTo, '/planning');
    });

    // --- Inscriptions cette saison row ---

    testWidgets('stats card shows "Inscriptions cette saison" row', (
      tester,
    ) async {
      final contractId = 'c-season';
      final seasonYear = DateTime.now().year;

      // 2 completed + 1 active/upcoming (= 3 non-cancelled) + 1 cancelled (excluded).
      final completedDelivery = buildDelivery(
        deliveryId: 'd-completed',
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
                ],
              ),
            ],
          ),
        ],
      );
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 7));
      final futureIso =
          '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-'
          '${futureDate.day.toString().padLeft(2, '0')}T18:00:00';
      final upcomingDelivery = buildDelivery(
        deliveryId: 'd-upcoming',
        scheduledDate: futureIso,
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            contractId: contractId,
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    memberId: _kMemberId,
                    status: RegistrationStatus.registered,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final cancelledDelivery = buildDelivery(
        deliveryId: 'd-cancelled',
        scheduledDate: '$seasonYear-03-10T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: contractId,
            slots: [
              buildSlot(
                registrations: [
                  buildRegistration(
                    memberId: _kMemberId,
                    status: RegistrationStatus.cancelled,
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
      orgStream.add(
        buildOrg(
          deliveries: [completedDelivery, upcomingDelivery, cancelledDelivery],
        ),
      );
      memberStream.add(me);
      allMembersStream.add([me]);
      contractsStream.add([
        _activeContract(contractId: contractId, seasonYear: seasonYear),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 2 non-cancelled (1 completed + 1 upcoming), 1 cancelled is excluded.
      expect(
        find.textContaining('📝 Inscriptions cette saison : 2'),
        findsOneWidget,
      );
      // Completed is also counted in total participations.
      expect(
        find.textContaining('📈 Total participations : 1'),
        findsOneWidget,
      );
    });

    // --- Season label cross-year ---

    testWidgets(
      'season header shows "Saison 2026-2027" for cross-year contract',
      (tester) async {
        final crossYearContract = Contract(
          contractId: 'c-cross',
          name: 'Contrat cross',
          organizationId: 'org-1',
          producerAccountId: 'producer-1',
          minDeliveryDate: '2026-06-01',
          maxDeliveryDate: '2027-03-31',
          deliveryCount: 10,
          seasonYear: 2026,
          status: ContractStatus.active,
        );
        // Need a completed delivery so the screen is not in empty state.
        final completedDelivery = buildDelivery(
          deliveryId: 'd-done',
          scheduledDate: '2026-06-15T18:00:00',
          status: DeliveryStatus.completed,
          contracts: [
            buildContract(
              contractId: 'c-cross',
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
        orgStream.add(buildOrg(deliveries: [completedDelivery]));
        memberStream.add(me);
        allMembersStream.add([me]);
        contractsStream.add([crossYearContract]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Saison 2026-2027'), findsOneWidget);
      },
    );

    // --- Bar chart renders month labels ---

    testWidgets(
      'bar chart renders month labels for all months in season range',
      (tester) async {
        // Contract from June 2026 to August 2026 → expect Juin, Juil, Août.
        final contract = Contract(
          contractId: 'c-bar',
          name: 'Contrat bar',
          organizationId: 'org-1',
          producerAccountId: 'producer-1',
          minDeliveryDate: '2026-06-01',
          maxDeliveryDate: '2026-08-31',
          deliveryCount: 6,
          seasonYear: 2026,
          status: ContractStatus.active,
        );
        final completedDelivery = buildDelivery(
          deliveryId: 'd-done',
          scheduledDate: '2026-07-15T18:00:00',
          status: DeliveryStatus.completed,
          contracts: [
            buildContract(
              contractId: 'c-bar',
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
        orgStream.add(buildOrg(deliveries: [completedDelivery]));
        memberStream.add(me);
        allMembersStream.add([me]);
        contractsStream.add([contract]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Chart title present.
        expect(find.text('📊 Répartition par mois'), findsOneWidget);
        // All three month abbreviations rendered.
        expect(find.text('Juin'), findsOneWidget);
        expect(find.text('Juil'), findsOneWidget);
        expect(find.text('Août'), findsOneWidget);
      },
    );
  });
}
