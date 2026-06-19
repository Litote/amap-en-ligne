import 'dart:async';

import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_event.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_state.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC for the basket-exchange screen.
///
/// Subscribes to three independent streams:
/// - [OrganizationRepository.watch] — org model (deliveries + contracts)
/// - [MemberRepository.watchMyMember] — current member identity
/// - [BasketExchangeRepository.watch] — all basket exchanges for the org
///
/// Derives [myOffers], [availableOffers], [historyItems] from [allExchanges]
/// + [me.memberId] — no need for separate filtered streams.
class BasketExchangeBloc
    extends Bloc<BasketExchangeEvent, BasketExchangeState> {
  BasketExchangeBloc({
    required OrganizationRepository organizationRepository,
    required MemberRepository memberRepository,
    required BasketExchangeRepository basketExchangeRepository,
    required ContractRepository contractRepository,
    required SyncBloc syncBloc,
    required String orgId,
    required String sub,
  }) : _basketExchangeRepository = basketExchangeRepository,
       _syncBloc = syncBloc,
       _orgId = orgId,
       super(const BasketExchangeState.loading()) {
    on<BasketExchangeLoadedFromStreams>(_onLoadedFromStreams);
    on<BasketExchangeProposeRequested>(_onProposeRequested);
    on<BasketExchangeProposeSubmitted>(_onProposeSubmitted);
    on<BasketExchangeProposeCancelled>(_onProposeCancelled);
    on<BasketExchangeRequestRequested>(_onRequestRequested);
    on<BasketExchangeRequestSubmitted>(_onRequestSubmitted);
    on<BasketExchangeRequestWithdrawn>(_onRequestWithdrawn);
    on<BasketExchangeRequestAccepted>(_onRequestAccepted);
    on<BasketExchangeRequestRefused>(_onRequestRefused);
    on<BasketExchangeOfferCancelled>(_onOfferCancelled);
    on<BasketExchangeDialogDismissed>(_onDialogDismissed);
    on<BasketExchangeRefreshRequested>(_onRefreshRequested);

    // Subscribe to the three independent streams.
    _orgSub = organizationRepository.watch(orgId).listen((org) {
      _latestOrg = org;
      _emit();
    });
    _memberSub = memberRepository.watchMyMember(sub).listen((member) {
      _latestMember = member;
      _emit();
    });
    _allMembersSub = memberRepository.watch(orgId).listen((members) {
      _latestMembers = members;
      _emit();
    });
    _exchangeSub = basketExchangeRepository.watch(orgId).listen((exchanges) {
      _latestExchanges = exchanges;
      _emit();
    });
    _contractsSub = contractRepository.watch(orgId).listen((contracts) {
      _latestContracts = contracts;
      _emit();
    });
  }

  final BasketExchangeRepository _basketExchangeRepository;
  final SyncBloc _syncBloc;
  final String _orgId;

  StreamSubscription<Organization?>? _orgSub;
  StreamSubscription<Member?>? _memberSub;
  StreamSubscription<List<Member>>? _allMembersSub;
  StreamSubscription<List<BasketExchange>>? _exchangeSub;
  StreamSubscription<List<Contract>>? _contractsSub;

  Organization? _latestOrg;
  Member? _latestMember;
  List<Member> _latestMembers = const [];
  List<BasketExchange>? _latestExchanges;
  List<Contract> _latestContracts = const [];

  @override
  Future<void> close() async {
    await _orgSub?.cancel();
    await _memberSub?.cancel();
    await _allMembersSub?.cancel();
    await _exchangeSub?.cancel();
    await _contractsSub?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Stream consolidation
  // ---------------------------------------------------------------------------

  void _emit() {
    final org = _latestOrg;
    final exchanges = _latestExchanges;

    if (org == null || exchanges == null) {
      // Still waiting for at least one stream to emit.
      if (state is! BasketExchangeLoading) {
        add(
          BasketExchangeEvent.loadedFromStreams(
            org:
                org ??
                const Organization(
                  organizationId: '',
                  name: '',
                  contactEmail: '',
                ),
            me: _latestMember,
            exchanges: exchanges ?? const [],
          ),
        );
      }
      return;
    }

    final me = _latestMember;
    add(
      BasketExchangeEvent.loadedFromStreams(
        org: org,
        me: me,
        exchanges: exchanges,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  void _onLoadedFromStreams(
    BasketExchangeLoadedFromStreams event,
    Emitter<BasketExchangeState> emit,
  ) {
    final org = _latestOrg;
    final exchanges = _latestExchanges;

    if (org == null || exchanges == null) {
      emit(const BasketExchangeState.loading());
      return;
    }

    final me = event.me;
    if (me == null) {
      emit(const BasketExchangeState.unauthorized());
      return;
    }

    // Preserve existing dialog/save state when only data changes.
    final prev = state;
    final prevDialog = prev is BasketExchangeReady
        ? prev.dialogState
        : const BasketExchangeDialogState.none();
    final prevSaveStatus = prev is BasketExchangeReady
        ? prev.saveStatus
        : BasketExchangeSaveStatus.idle;

    emit(
      BasketExchangeState.ready(
        me: me,
        org: org,
        allExchanges: exchanges,
        members: _latestMembers,
        contracts: _latestContracts,
        dialogState: prevDialog,
        saveStatus: prevSaveStatus,
      ),
    );
  }

  void _onProposeRequested(
    BasketExchangeProposeRequested event,
    Emitter<BasketExchangeState> emit,
  ) {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(s.copyWith(dialogState: const BasketExchangeDialogState.propose()));
  }

  Future<void> _onProposeSubmitted(
    BasketExchangeProposeSubmitted event,
    Emitter<BasketExchangeState> emit,
  ) async {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(
      s.copyWith(
        dialogState: const BasketExchangeDialogState.none(),
        saveStatus: BasketExchangeSaveStatus.saving,
        errorMessage: null,
      ),
    );
    try {
      await _basketExchangeRepository.createOffer(
        orgId: _orgId,
        deliveryId: event.deliveryId,
        contractId: event.contractId,
        offeringMemberId: s.me.memberId,
        motive: event.motive,
      );
      _syncBloc.add(const SyncEvent.mutationApplied());
      emit(
        s.copyWith(
          dialogState: const BasketExchangeDialogState.none(),
          saveStatus: BasketExchangeSaveStatus.success,
        ),
      );
    } catch (e) {
      emit(
        s.copyWith(
          dialogState: const BasketExchangeDialogState.none(),
          saveStatus: BasketExchangeSaveStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onProposeCancelled(
    BasketExchangeProposeCancelled event,
    Emitter<BasketExchangeState> emit,
  ) {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(s.copyWith(dialogState: const BasketExchangeDialogState.none()));
  }

  void _onRequestRequested(
    BasketExchangeRequestRequested event,
    Emitter<BasketExchangeState> emit,
  ) {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(
      s.copyWith(
        dialogState: BasketExchangeDialogState.submitRequest(
          offer: event.offer,
        ),
      ),
    );
  }

  Future<void> _onRequestSubmitted(
    BasketExchangeRequestSubmitted event,
    Emitter<BasketExchangeState> emit,
  ) async {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(
      s.copyWith(
        dialogState: const BasketExchangeDialogState.none(),
        saveStatus: BasketExchangeSaveStatus.saving,
        errorMessage: null,
      ),
    );
    try {
      await _basketExchangeRepository.submitRequest(
        basketExchange: event.offer,
        requesterMemberId: s.me.memberId,
        proposedDeliveryId: event.proposedDeliveryId,
        proposedContractId: event.proposedContractId,
      );
      _syncBloc.add(const SyncEvent.mutationApplied());
      emit(
        s.copyWith(
          dialogState: const BasketExchangeDialogState.none(),
          saveStatus: BasketExchangeSaveStatus.success,
        ),
      );
    } catch (e) {
      emit(
        s.copyWith(
          dialogState: const BasketExchangeDialogState.none(),
          saveStatus: BasketExchangeSaveStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRequestWithdrawn(
    BasketExchangeRequestWithdrawn event,
    Emitter<BasketExchangeState> emit,
  ) async {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.saving));
    try {
      await _basketExchangeRepository.withdrawRequest(
        basketExchange: event.offer,
        requestId: event.requestId,
      );
      _syncBloc.add(const SyncEvent.mutationApplied());
      emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.success));
    } catch (e) {
      emit(
        s.copyWith(
          saveStatus: BasketExchangeSaveStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRequestAccepted(
    BasketExchangeRequestAccepted event,
    Emitter<BasketExchangeState> emit,
  ) async {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.saving));
    try {
      final decidedAt = DateTime.now().toUtc().toIso8601String();
      await _basketExchangeRepository.acceptRequest(
        basketExchange: event.offer,
        requestId: event.requestId,
        decidedAt: decidedAt,
      );
      _syncBloc.add(const SyncEvent.mutationApplied());
      emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.success));
    } catch (e) {
      emit(
        s.copyWith(
          saveStatus: BasketExchangeSaveStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRequestRefused(
    BasketExchangeRequestRefused event,
    Emitter<BasketExchangeState> emit,
  ) async {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.saving));
    try {
      final decidedAt = DateTime.now().toUtc().toIso8601String();
      await _basketExchangeRepository.refuseRequest(
        basketExchange: event.offer,
        requestId: event.requestId,
        decidedAt: decidedAt,
      );
      _syncBloc.add(const SyncEvent.mutationApplied());
      emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.success));
    } catch (e) {
      emit(
        s.copyWith(
          saveStatus: BasketExchangeSaveStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onOfferCancelled(
    BasketExchangeOfferCancelled event,
    Emitter<BasketExchangeState> emit,
  ) async {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.saving));
    try {
      final decidedAt = DateTime.now().toUtc().toIso8601String();
      await _basketExchangeRepository.cancelOffer(
        basketExchange: event.offer,
        decidedAt: decidedAt,
      );
      _syncBloc.add(const SyncEvent.mutationApplied());
      emit(s.copyWith(saveStatus: BasketExchangeSaveStatus.success));
    } catch (e) {
      emit(
        s.copyWith(
          saveStatus: BasketExchangeSaveStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onDialogDismissed(
    BasketExchangeDialogDismissed event,
    Emitter<BasketExchangeState> emit,
  ) {
    final s = state;
    if (s is! BasketExchangeReady) return;
    emit(s.copyWith(dialogState: const BasketExchangeDialogState.none()));
  }

  void _onRefreshRequested(
    BasketExchangeRefreshRequested event,
    Emitter<BasketExchangeState> emit,
  ) {
    _syncBloc.add(const SyncEvent.requested());
  }
}
