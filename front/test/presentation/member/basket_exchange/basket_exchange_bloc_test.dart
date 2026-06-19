import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_bloc.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_event.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_state.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockBasketExchangeRepository extends Mock
    implements BasketExchangeRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _orgId = 'org-1';
const _sub = 'sub-me';

final _me = Member(
  memberId: 'm-me',
  organizationId: _orgId,
  firstName: 'Alice',
  lastName: 'Martin',
);

const _org = Organization(
  organizationId: _orgId,
  name: 'Test AMAP',
  contactEmail: 'contact@test.com',
);

// An OPEN offer from another member (the one I can request).
const _otherOffer = BasketExchange(
  basketExchangeId: 'be-other',
  organizationId: _orgId,
  deliveryId: 'd-other',
  contractId: 'c-other',
  offeringMemberId: 'm-bob',
  status: BasketExchangeStatus.open,
  createdAt: '2026-01-01T00:00:00Z',
);

BasketExchangeReady _ready({
  List<BasketExchange> exchanges = const [],
  BasketExchangeDialogState dialogState =
      const BasketExchangeDialogState.none(),
  BasketExchangeSaveStatus saveStatus = BasketExchangeSaveStatus.idle,
}) =>
    BasketExchangeState.ready(
          me: _me,
          org: _org,
          allExchanges: exchanges,
          dialogState: dialogState,
          saveStatus: saveStatus,
        )
        as BasketExchangeReady;

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockMemberRepository memberRepo;
  late _MockBasketExchangeRepository exchangeRepo;
  late _MockContractRepository contractRepo;
  late _MockSyncBloc syncBloc;

  setUpAll(() {
    registerFallbackValue(_otherOffer);
  });

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    memberRepo = _MockMemberRepository();
    exchangeRepo = _MockBasketExchangeRepository();
    contractRepo = _MockContractRepository();
    syncBloc = _MockSyncBloc();

    // Default: streams never emit, so the bloc stays in its seeded/initial state
    // and we can drive event handlers deterministically.
    when(
      () => orgRepo.watch(any()),
    ).thenAnswer((_) => const Stream<Organization?>.empty());
    when(
      () => memberRepo.watchMyMember(any()),
    ).thenAnswer((_) => const Stream<Member?>.empty());
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => const Stream<List<Member>>.empty());
    when(
      () => exchangeRepo.watch(any()),
    ).thenAnswer((_) => const Stream<List<BasketExchange>>.empty());
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => const Stream<List<Contract>>.empty());
  });

  BasketExchangeBloc buildBloc() => BasketExchangeBloc(
    organizationRepository: orgRepo,
    memberRepository: memberRepo,
    basketExchangeRepository: exchangeRepo,
    contractRepository: contractRepo,
    syncBloc: syncBloc,
    orgId: _orgId,
    sub: _sub,
  );

  // -------------------------------------------------------------------------
  // Stream consolidation → loadedFromStreams
  // -------------------------------------------------------------------------

  group('stream consolidation', () {
    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'GIVEN org + member + exchanges all emit WHEN streams resolve THEN emits ready',
      build: () {
        final orgCtrl = StreamController<Organization?>.broadcast();
        final memberCtrl = StreamController<Member?>.broadcast();
        final exchangeCtrl = StreamController<List<BasketExchange>>.broadcast();
        when(() => orgRepo.watch(any())).thenAnswer((_) => orgCtrl.stream);
        when(
          () => memberRepo.watchMyMember(any()),
        ).thenAnswer((_) => memberCtrl.stream);
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => exchangeCtrl.stream);
        addTearDown(orgCtrl.close);
        addTearDown(memberCtrl.close);
        addTearDown(exchangeCtrl.close);
        // Stash controllers for act via closures on the repos.
        _orgCtrl = orgCtrl;
        _memberCtrl = memberCtrl;
        _exchangeCtrl = exchangeCtrl;
        return buildBloc();
      },
      act: (_) async {
        _orgCtrl.add(_org);
        _memberCtrl.add(_me);
        _exchangeCtrl.add(const [_otherOffer]);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<BasketExchangeReady>()
            .having((s) => s.me.memberId, 'me', 'm-me')
            .having((s) => s.allExchanges, 'allExchanges', const [_otherOffer]),
      ],
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'GIVEN org + exchanges but member null WHEN streams resolve THEN emits unauthorized',
      build: () {
        final orgCtrl = StreamController<Organization?>.broadcast();
        final exchangeCtrl = StreamController<List<BasketExchange>>.broadcast();
        when(() => orgRepo.watch(any())).thenAnswer((_) => orgCtrl.stream);
        when(
          () => exchangeRepo.watch(any()),
        ).thenAnswer((_) => exchangeCtrl.stream);
        addTearDown(orgCtrl.close);
        addTearDown(exchangeCtrl.close);
        _orgCtrl = orgCtrl;
        _exchangeCtrl = exchangeCtrl;
        return buildBloc();
      },
      act: (_) async {
        _orgCtrl.add(_org);
        _exchangeCtrl.add(const []);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [isA<BasketExchangeUnauthorized>()],
    );
  });

  // -------------------------------------------------------------------------
  // Propose flow
  // -------------------------------------------------------------------------

  group('propose flow', () {
    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'proposeRequested opens the propose dialog',
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(const BasketExchangeEvent.proposeRequested()),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.dialogState,
          'dialogState',
          const BasketExchangeDialogState.propose(),
        ),
      ],
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'proposeCancelled closes the dialog',
      build: buildBloc,
      seed: () =>
          _ready(dialogState: const BasketExchangeDialogState.propose()),
      act: (bloc) => bloc.add(const BasketExchangeEvent.proposeCancelled()),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.dialogState,
          'dialogState',
          const BasketExchangeDialogState.none(),
        ),
      ],
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'proposeSubmitted success: saving then success, creates offer and triggers sync',
      setUp: () => when(
        () => exchangeRepo.createOffer(
          orgId: any(named: 'orgId'),
          deliveryId: any(named: 'deliveryId'),
          contractId: any(named: 'contractId'),
          offeringMemberId: any(named: 'offeringMemberId'),
          motive: any(named: 'motive'),
        ),
      ).thenAnswer((_) async {}),
      build: buildBloc,
      seed: () =>
          _ready(dialogState: const BasketExchangeDialogState.propose()),
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.proposeSubmitted(
          deliveryId: 'd-1',
          contractId: 'c-1',
          motive: 'en vacances',
        ),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.saving,
        ),
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.success,
        ),
      ],
      verify: (_) {
        verify(
          () => exchangeRepo.createOffer(
            orgId: _orgId,
            deliveryId: 'd-1',
            contractId: 'c-1',
            offeringMemberId: 'm-me',
            motive: 'en vacances',
          ),
        ).called(1);
        verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
      },
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'proposeSubmitted failure: saving then failure with errorMessage',
      setUp: () => when(
        () => exchangeRepo.createOffer(
          orgId: any(named: 'orgId'),
          deliveryId: any(named: 'deliveryId'),
          contractId: any(named: 'contractId'),
          offeringMemberId: any(named: 'offeringMemberId'),
          motive: any(named: 'motive'),
        ),
      ).thenThrow(Exception('boom')),
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.proposeSubmitted(
          deliveryId: 'd-1',
          contractId: 'c-1',
        ),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.saving,
        ),
        isA<BasketExchangeReady>()
            .having(
              (s) => s.saveStatus,
              'saveStatus',
              BasketExchangeSaveStatus.failure,
            )
            .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // Request flow (as a requester)
  // -------------------------------------------------------------------------

  group('request flow', () {
    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'requestRequested opens the submit-request dialog for the offer',
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.requestRequested(offer: _otherOffer),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.dialogState,
          'dialogState',
          const BasketExchangeDialogState.submitRequest(offer: _otherOffer),
        ),
      ],
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'requestSubmitted success: submits request and triggers sync',
      setUp: () => when(
        () => exchangeRepo.submitRequest(
          basketExchange: any(named: 'basketExchange'),
          requesterMemberId: any(named: 'requesterMemberId'),
          proposedDeliveryId: any(named: 'proposedDeliveryId'),
          proposedContractId: any(named: 'proposedContractId'),
        ),
      ).thenAnswer((_) async {}),
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.requestSubmitted(
          offer: _otherOffer,
          proposedDeliveryId: 'd-mine',
          proposedContractId: 'c-mine',
        ),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.saving,
        ),
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.success,
        ),
      ],
      verify: (_) {
        verify(
          () => exchangeRepo.submitRequest(
            basketExchange: _otherOffer,
            requesterMemberId: 'm-me',
            proposedDeliveryId: 'd-mine',
            proposedContractId: 'c-mine',
          ),
        ).called(1);
        verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
      },
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'requestWithdrawn success: withdraws and triggers sync',
      setUp: () => when(
        () => exchangeRepo.withdrawRequest(
          basketExchange: any(named: 'basketExchange'),
          requestId: any(named: 'requestId'),
        ),
      ).thenAnswer((_) async {}),
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.requestWithdrawn(
          offer: _otherOffer,
          requestId: 'req-1',
        ),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.saving,
        ),
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.success,
        ),
      ],
      verify: (_) => verify(
        () => exchangeRepo.withdrawRequest(
          basketExchange: _otherOffer,
          requestId: 'req-1',
        ),
      ).called(1),
    );
  });

  // -------------------------------------------------------------------------
  // Offerer actions (accept / refuse / cancel)
  // -------------------------------------------------------------------------

  group('offerer actions', () {
    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'requestAccepted success: accepts with a decidedAt timestamp and syncs',
      setUp: () => when(
        () => exchangeRepo.acceptRequest(
          basketExchange: any(named: 'basketExchange'),
          requestId: any(named: 'requestId'),
          decidedAt: any(named: 'decidedAt'),
        ),
      ).thenAnswer((_) async {}),
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.requestAccepted(
          offer: _otherOffer,
          requestId: 'req-1',
        ),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.saving,
        ),
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.success,
        ),
      ],
      verify: (_) {
        verify(
          () => exchangeRepo.acceptRequest(
            basketExchange: _otherOffer,
            requestId: 'req-1',
            decidedAt: any(named: 'decidedAt'),
          ),
        ).called(1);
        verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
      },
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'requestRefused success: refuses with a decidedAt timestamp',
      setUp: () => when(
        () => exchangeRepo.refuseRequest(
          basketExchange: any(named: 'basketExchange'),
          requestId: any(named: 'requestId'),
          decidedAt: any(named: 'decidedAt'),
        ),
      ).thenAnswer((_) async {}),
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.requestRefused(
          offer: _otherOffer,
          requestId: 'req-1',
        ),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.saving,
        ),
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.success,
        ),
      ],
      verify: (_) => verify(
        () => exchangeRepo.refuseRequest(
          basketExchange: _otherOffer,
          requestId: 'req-1',
          decidedAt: any(named: 'decidedAt'),
        ),
      ).called(1),
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'offerCancelled failure: emits failure with errorMessage',
      setUp: () => when(
        () => exchangeRepo.cancelOffer(
          basketExchange: any(named: 'basketExchange'),
          decidedAt: any(named: 'decidedAt'),
        ),
      ).thenThrow(Exception('nope')),
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(
        const BasketExchangeEvent.offerCancelled(offer: _otherOffer),
      ),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.saveStatus,
          'saveStatus',
          BasketExchangeSaveStatus.saving,
        ),
        isA<BasketExchangeReady>()
            .having(
              (s) => s.saveStatus,
              'saveStatus',
              BasketExchangeSaveStatus.failure,
            )
            .having((s) => s.errorMessage, 'errorMessage', contains('nope')),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // Dialog dismiss / refresh / guards
  // -------------------------------------------------------------------------

  group('misc', () {
    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'dialogDismissed closes the open dialog',
      build: buildBloc,
      seed: () => _ready(
        dialogState: const BasketExchangeDialogState.submitRequest(
          offer: _otherOffer,
        ),
      ),
      act: (bloc) => bloc.add(const BasketExchangeEvent.dialogDismissed()),
      expect: () => [
        isA<BasketExchangeReady>().having(
          (s) => s.dialogState,
          'dialogState',
          const BasketExchangeDialogState.none(),
        ),
      ],
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'refreshRequested triggers a full sync and emits nothing',
      build: buildBloc,
      seed: _ready,
      act: (bloc) => bloc.add(const BasketExchangeEvent.refreshRequested()),
      expect: () => <BasketExchangeState>[],
      verify: (_) =>
          verify(() => syncBloc.add(const SyncEvent.requested())).called(1),
    );

    blocTest<BasketExchangeBloc, BasketExchangeState>(
      'action events are no-ops when state is not ready',
      build: buildBloc,
      // No seed → stays in loading.
      act: (bloc) => bloc
        ..add(const BasketExchangeEvent.proposeRequested())
        ..add(
          const BasketExchangeEvent.requestAccepted(
            offer: _otherOffer,
            requestId: 'req-1',
          ),
        ),
      expect: () => <BasketExchangeState>[],
      verify: (_) {
        verifyNever(
          () => exchangeRepo.acceptRequest(
            basketExchange: any(named: 'basketExchange'),
            requestId: any(named: 'requestId'),
            decidedAt: any(named: 'decidedAt'),
          ),
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // BasketExchangeReadyX derived selectors
  // -------------------------------------------------------------------------

  group('BasketExchangeReadyX', () {
    final myOpenOffer = _otherOffer.copyWith(
      basketExchangeId: 'be-mine',
      offeringMemberId: 'm-me',
    );
    final acceptedByMeThisYear = _otherOffer.copyWith(
      basketExchangeId: 'be-acc',
      offeringMemberId: 'm-me',
      status: BasketExchangeStatus.accepted,
      decidedAt: '${DateTime.now().year}-03-01T10:00:00Z',
    );
    final myPending = _otherOffer.copyWith(
      basketExchangeId: 'be-pending',
      requests: const [
        BasketExchangeRequest(
          requestId: 'r-1',
          requesterMemberId: 'm-me',
          createdAt: '2026-01-02T00:00:00Z',
          status: BasketExchangeRequestStatus.pending,
        ),
      ],
    );

    test('myOffers / availableOffers / historyItems partition correctly', () {
      final ready = _ready(
        exchanges: [_otherOffer, myOpenOffer, acceptedByMeThisYear, myPending],
      );

      expect(
        ready.myOffers.map((e) => e.basketExchangeId),
        containsAll(['be-mine', 'be-acc']),
      );
      // Open offers from others (not me).
      expect(
        ready.availableOffers.map((e) => e.basketExchangeId),
        containsAll(['be-other', 'be-pending']),
      );
      expect(
        ready.availableOffers.map((e) => e.basketExchangeId),
        isNot(contains('be-mine')),
      );
      // Non-open exchanges where I'm involved.
      expect(
        ready.historyItems.map((e) => e.basketExchangeId),
        contains('be-acc'),
      );
    });

    test(
      'successfulExchangesThisYear counts accepted exchanges decided this year',
      () {
        final ready = _ready(exchanges: [acceptedByMeThisYear]);
        expect(ready.successfulExchangesThisYear, 1);
      },
    );

    test('membersById indexes members by id', () {
      final ready =
          BasketExchangeState.ready(
                me: _me,
                org: _org,
                allExchanges: const [],
                members: [_me],
              )
              as BasketExchangeReady;
      expect(ready.membersById['m-me'], _me);
    });

    test('myPendingRequestOn returns my pending request, null otherwise', () {
      final ready = _ready(exchanges: [myPending, _otherOffer]);
      expect(ready.myPendingRequestOn(myPending)?.requestId, 'r-1');
      expect(ready.myPendingRequestOn(_otherOffer), isNull);
    });
  });
}

// Controllers shared between blocTest `build` and `act` (set inside build).
late StreamController<Organization?> _orgCtrl;
late StreamController<Member?> _memberCtrl;
late StreamController<List<BasketExchange>> _exchangeCtrl;
