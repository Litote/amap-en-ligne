part of 'producer_management_bloc.dart';

@freezed
sealed class ProducerManagementEvent with _$ProducerManagementEvent {
  const factory ProducerManagementEvent.loadRequested() = _LoadRequested;

  const factory ProducerManagementEvent.statusFilterChanged(
    OrganizationProducerStatus? status,
  ) = _StatusFilterChanged;

  const factory ProducerManagementEvent.detailRequested(
    String producerAccountId,
  ) = _DetailRequested;

  const factory ProducerManagementEvent.backToListRequested() =
      _BackToListRequested;

  const factory ProducerManagementEvent.updateStatusRequested({
    required String producerAccountId,
    required OrganizationProducerStatus newStatus,
  }) = _UpdateStatusRequested;

  const factory ProducerManagementEvent.enrollSearchChanged(String query) =
      _EnrollSearchChanged;

  const factory ProducerManagementEvent.enrollProducerSelected(
    ProducerAccount producer,
  ) = _EnrollProducerSelected;

  const factory ProducerManagementEvent.enrollNoAccountStarted() =
      _EnrollNoAccountStarted;

  const factory ProducerManagementEvent.enrollConfirmed(
    List<OrgProduct> products,
  ) = _EnrollConfirmed;

  const factory ProducerManagementEvent.enrollNoAccountConfirmed({
    required String name,
    String? contactEmail,
    String? address,
    String? website,
    required List<ProducerProduct> products,
  }) = _EnrollNoAccountConfirmed;

  const factory ProducerManagementEvent.updateProductsRequested({
    required ProducerAccount producerAccount,
    required List<OrgProduct> products,
  }) = _UpdateProductsRequested;

  const factory ProducerManagementEvent.updateNoAccountProductsRequested({
    required ProducerAccount producerAccount,
    required List<ProducerProduct> products,
  }) = _UpdateNoAccountProductsRequested;
}
