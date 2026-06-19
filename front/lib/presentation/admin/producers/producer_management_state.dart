part of 'producer_management_bloc.dart';

@freezed
sealed class ProducerManagementState with _$ProducerManagementState {
  const factory ProducerManagementState.initial() = ProducerManagementInitial;

  const factory ProducerManagementState.loading() = ProducerManagementLoading;

  const factory ProducerManagementState.listLoaded({
    required Organization organization,
    OrganizationProducerStatus? statusFilter,
    @Default(false) bool actionInProgress,
    String? actionError,
  }) = ProducerManagementListLoaded;

  const factory ProducerManagementState.detailLoaded({
    required Organization organization,
    required String producerAccountId,
    @Default(false) bool actionInProgress,
    String? actionError,
  }) = ProducerManagementDetailLoaded;

  const factory ProducerManagementState.enrollStep1({
    required Organization organization,
    @Default('') String searchQuery,
    @Default([]) List<ProducerAccount> searchResults,
    @Default(false) bool searching,
  }) = ProducerManagementEnrollStep1;

  const factory ProducerManagementState.enrollStep2({
    required Organization organization,
    required ProducerAccount selectedProducer,
    @Default(false) bool actionInProgress,
    String? actionError,
  }) = ProducerManagementEnrollStep2;

  const factory ProducerManagementState.enrollNoAccountStep2({
    required Organization organization,
    @Default(false) bool actionInProgress,
    String? actionError,
  }) = ProducerManagementEnrollNoAccountStep2;

  const factory ProducerManagementState.error(String message) =
      ProducerManagementError;
}
