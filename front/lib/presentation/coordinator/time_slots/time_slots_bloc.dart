import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_slots_bloc.freezed.dart';

@freezed
sealed class TimeSlotsEvent with _$TimeSlotsEvent {
  /// Triggered when the user requests deletion of a delivery slot.
  const factory TimeSlotsEvent.deleteRequested({
    required Organization currentOrg,
    required String deliveryId,
  }) = TimeSlotsDeleteRequested;

  /// Triggered when a coordinator cancels a volunteer slot.
  ///
  /// The slot is set to [SlotStatus.cancelled] with an optimistic local
  /// cascade of its registrations (the server is authoritative and re-applies
  /// the cascade on the next sync).
  const factory TimeSlotsEvent.slotCancelRequested({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required MemberSlot slot,
  }) = SlotCancelRequested;

  /// Triggered when a coordinator deletes a volunteer slot.
  ///
  /// Local validation (no active registration) happens in the UI; the server
  /// re-validates and returns CONFLICT on an offline race.
  const factory TimeSlotsEvent.slotDeleteRequested({
    required Organization currentOrg,
    required String deliveryId,
    required String contractId,
    required MemberSlot slot,
  }) = SlotDeleteRequested;
}

@freezed
sealed class TimeSlotsState with _$TimeSlotsState {
  /// Initial / idle state — no pending operation.
  const factory TimeSlotsState.idle() = TimeSlotsIdle;

  /// A delete operation is in progress.
  const factory TimeSlotsState.deleting() = TimeSlotsDeleting;

  /// The delete completed successfully.
  const factory TimeSlotsState.deleted() = TimeSlotsDeleted;

  /// A slot cancel/delete mutation is in progress.
  const factory TimeSlotsState.slotMutating() = TimeSlotsSlotMutating;

  /// The slot cancel/delete mutation was enqueued successfully.
  const factory TimeSlotsState.slotMutated() = TimeSlotsSlotMutated;

  /// An error occurred during an operation.
  const factory TimeSlotsState.error({required String message}) =
      TimeSlotsError;
}

/// Bloc handling delivery and per-slot mutations for the coordinator
/// time-slot screens. All writes go through
/// [OrganizationRepository.updateDelivery] / [OrganizationRepository.deleteDelivery]
/// (Upsert of the whole aggregate) followed by an eager sync flush.
class TimeSlotsBloc extends Bloc<TimeSlotsEvent, TimeSlotsState> {
  TimeSlotsBloc({
    required OrganizationRepository orgRepo,
    required SyncBloc syncBloc,
  }) : _orgRepo = orgRepo,
       _syncBloc = syncBloc,
       super(const TimeSlotsState.idle()) {
    on<TimeSlotsDeleteRequested>(_onDeleteRequested);
    on<SlotCancelRequested>(_onSlotCancelRequested);
    on<SlotDeleteRequested>(_onSlotDeleteRequested);
  }

  final OrganizationRepository _orgRepo;
  final SyncBloc _syncBloc;

  Future<void> _onDeleteRequested(
    TimeSlotsDeleteRequested event,
    Emitter<TimeSlotsState> emit,
  ) async {
    emit(const TimeSlotsState.deleting());
    try {
      await _orgRepo.deleteDelivery(
        currentOrg: event.currentOrg,
        deliveryId: event.deliveryId,
      );
      _syncBloc.add(const SyncEvent.mutationApplied());
      emit(const TimeSlotsState.deleted());
      emit(const TimeSlotsState.idle());
    } on Object catch (e) {
      emit(TimeSlotsState.error(message: e.toString()));
    }
  }

  Future<void> _onSlotCancelRequested(
    SlotCancelRequested event,
    Emitter<TimeSlotsState> emit,
  ) async {
    emit(const TimeSlotsState.slotMutating());
    try {
      final cancelledSlot = event.slot.copyWith(
        status: SlotStatus.cancelled,
        currentRegistrations: 0,
        registrations: event.slot.registrations
            .map((r) => r.copyWith(status: RegistrationStatus.cancelled))
            .toList(),
      );
      await _submitSlotChange(event, (slots) {
        return slots
            .map((s) => _isSameSlot(s, event.slot) ? cancelledSlot : s)
            .toList();
      });
      emit(const TimeSlotsState.slotMutated());
      emit(const TimeSlotsState.idle());
    } on Object catch (e) {
      emit(TimeSlotsState.error(message: e.toString()));
    }
  }

  Future<void> _onSlotDeleteRequested(
    SlotDeleteRequested event,
    Emitter<TimeSlotsState> emit,
  ) async {
    emit(const TimeSlotsState.slotMutating());
    try {
      await _submitSlotChange(event, (slots) {
        return slots.where((s) => !_isSameSlot(s, event.slot)).toList();
      });
      emit(const TimeSlotsState.slotMutated());
      emit(const TimeSlotsState.idle());
    } on Object catch (e) {
      emit(TimeSlotsState.error(message: e.toString()));
    }
  }

  Future<void> _submitSlotChange(
    TimeSlotsEvent event,
    List<MemberSlot> Function(List<MemberSlot>) transformSlots,
  ) async {
    final (currentOrg, deliveryId, contractId) = switch (event) {
      SlotCancelRequested(
        :final currentOrg,
        :final deliveryId,
        :final contractId,
      ) =>
        (currentOrg, deliveryId, contractId),
      SlotDeleteRequested(
        :final currentOrg,
        :final deliveryId,
        :final contractId,
      ) =>
        (currentOrg, deliveryId, contractId),
      _ => throw StateError('unsupported event'),
    };
    final delivery = currentOrg.deliveries.firstWhere(
      (d) => d.deliveryId == deliveryId,
    );
    final updatedDelivery = delivery.copyWith(
      contracts: delivery.contracts.map((c) {
        if (c.contractId != contractId) return c;
        return c.copyWith(slots: transformSlots(c.slots));
      }).toList(),
    );
    await _orgRepo.updateDelivery(
      currentOrg: currentOrg,
      delivery: updatedDelivery,
    );
    _syncBloc.add(const SyncEvent.mutationApplied());
  }

  /// Matches a slot by [MemberSlot.slotId] when present, falling back to the
  /// natural key (start, end, activity) for legacy slots without an id.
  static bool _isSameSlot(MemberSlot a, MemberSlot b) {
    if (a.slotId != null || b.slotId != null) return a.slotId == b.slotId;
    return a.startTime == b.startTime &&
        a.endTime == b.endTime &&
        a.activityType == b.activityType;
  }
}
