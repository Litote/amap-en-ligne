import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'producer_management_bloc.freezed.dart';
part 'producer_management_event.dart';
part 'producer_management_state.dart';

class ProducerManagementBloc
    extends Bloc<ProducerManagementEvent, ProducerManagementState> {
  ProducerManagementBloc({
    required OrganizationRepository organizationRepository,
    required AdminApi adminApi,
    required String organizationId,
  }) : _orgRepo = organizationRepository,
       _adminApi = adminApi,
       _organizationId = organizationId,
       super(const ProducerManagementState.initial()) {
    on<_LoadRequested>(_onLoadRequested);
    on<_StatusFilterChanged>(_onStatusFilterChanged);
    on<_DetailRequested>(_onDetailRequested);
    on<_BackToListRequested>(_onBackToListRequested);
    on<_UpdateStatusRequested>(_onUpdateStatusRequested);
    on<_EnrollSearchChanged>(_onEnrollSearchChanged);
    on<_EnrollProducerSelected>(_onEnrollProducerSelected);
    on<_EnrollNoAccountStarted>(_onEnrollNoAccountStarted);
    on<_EnrollConfirmed>(_onEnrollConfirmed);
    on<_UpdateProductsRequested>(_onUpdateProductsRequested);
    on<_EnrollNoAccountConfirmed>(_onEnrollNoAccountConfirmed);
    on<_UpdateNoAccountProductsRequested>(_onUpdateNoAccountProductsRequested);
  }

  final OrganizationRepository _orgRepo;
  final AdminApi _adminApi;
  final String _organizationId;

  ProducerManagementState _buildListLoaded(
    Organization organization, {
    OrganizationProducerStatus? statusFilter,
    bool preserveExplicitFilter = false,
  }) {
    final effectiveFilter = preserveExplicitFilter
        ? statusFilter
        : statusFilter ?? OrganizationProducerStatus.active;
    return ProducerManagementState.listLoaded(
      organization: organization,
      statusFilter: effectiveFilter,
    );
  }

  Future<void> _onLoadRequested(
    _LoadRequested event,
    Emitter<ProducerManagementState> emit,
  ) async {
    emit(const ProducerManagementState.loading());
    await emit.forEach<Organization?>(
      _orgRepo.watch(_organizationId),
      onData: (org) {
        if (org == null) {
          return const ProducerManagementState.error(
            'Organisation introuvable.',
          );
        }
        return switch (state) {
          ProducerManagementListLoaded(:final statusFilter) => _buildListLoaded(
            org,
            statusFilter: statusFilter,
            preserveExplicitFilter: true,
          ),
          _ => _buildListLoaded(org),
        };
      },
      onError: (error, stackTrace) =>
          const ProducerManagementState.error('Erreur de chargement.'),
    );
  }

  void _onStatusFilterChanged(
    _StatusFilterChanged event,
    Emitter<ProducerManagementState> emit,
  ) {
    final current = state;
    if (current is! ProducerManagementListLoaded) return;
    emit(current.copyWith(statusFilter: event.status));
  }

  void _onDetailRequested(
    _DetailRequested event,
    Emitter<ProducerManagementState> emit,
  ) {
    final current = state;
    if (current is! ProducerManagementListLoaded) return;
    emit(
      ProducerManagementState.detailLoaded(
        organization: current.organization,
        producerAccountId: event.producerAccountId,
      ),
    );
  }

  void _onBackToListRequested(
    _BackToListRequested event,
    Emitter<ProducerManagementState> emit,
  ) {
    final current = state;
    if (current is ProducerManagementDetailLoaded) {
      emit(_buildListLoaded(current.organization));
    } else if (current is ProducerManagementEnrollStep1 ||
        current is ProducerManagementEnrollStep2 ||
        current is ProducerManagementEnrollNoAccountStep2) {
      final org = switch (current) {
        ProducerManagementEnrollStep1(:final organization) => organization,
        ProducerManagementEnrollStep2(:final organization) => organization,
        ProducerManagementEnrollNoAccountStep2(:final organization) =>
          organization,
        _ => null,
      };
      if (org != null) {
        emit(_buildListLoaded(org));
      }
    }
  }

  Future<void> _onUpdateStatusRequested(
    _UpdateStatusRequested event,
    Emitter<ProducerManagementState> emit,
  ) async {
    final current = state;
    if (current is! ProducerManagementDetailLoaded) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _orgRepo.updateProducerStatus(
        currentOrg: current.organization,
        producerAccountId: event.producerAccountId,
        newStatus: event.newStatus,
      );
      // The stream from emit.forEach in _onLoadRequested will emit a new
      // listLoaded state automatically. Here we just clear the in-progress flag.
      final org = await _orgRepo.watch(_organizationId).first;
      if (org != null) {
        emit(_buildListLoaded(org));
      } else {
        emit(const ProducerManagementState.error('Organisation introuvable.'));
      }
    } catch (_) {
      emit(
        current.copyWith(
          actionInProgress: false,
          actionError: 'Impossible de mettre à jour le statut.',
        ),
      );
    }
  }

  Future<void> _onEnrollSearchChanged(
    _EnrollSearchChanged event,
    Emitter<ProducerManagementState> emit,
  ) async {
    final current = state;
    Organization? org;
    if (current is ProducerManagementEnrollStep1) {
      org = current.organization;
    } else if (current is ProducerManagementListLoaded) {
      org = current.organization;
    } else {
      return;
    }

    emit(
      ProducerManagementState.enrollStep1(
        organization: org,
        searchQuery: event.query,
        searching: event.query.isNotEmpty,
      ),
    );

    if (event.query.isEmpty) return;

    try {
      final results = await _adminApi.searchProducers(event.query);
      emit(
        ProducerManagementState.enrollStep1(
          organization: org,
          searchQuery: event.query,
          searchResults: results,
          searching: false,
        ),
      );
    } catch (_) {
      emit(
        ProducerManagementState.enrollStep1(
          organization: org,
          searchQuery: event.query,
          searching: false,
        ),
      );
    }
  }

  void _onEnrollProducerSelected(
    _EnrollProducerSelected event,
    Emitter<ProducerManagementState> emit,
  ) {
    final current = state;
    if (current is! ProducerManagementEnrollStep1) return;
    emit(
      ProducerManagementState.enrollStep2(
        organization: current.organization,
        selectedProducer: event.producer,
      ),
    );
  }

  void _onEnrollNoAccountStarted(
    _EnrollNoAccountStarted event,
    Emitter<ProducerManagementState> emit,
  ) {
    final current = state;
    final organization = switch (current) {
      ProducerManagementListLoaded(:final organization) => organization,
      ProducerManagementEnrollStep1(:final organization) => organization,
      _ => null,
    };
    if (organization == null) return;
    emit(
      ProducerManagementState.enrollNoAccountStep2(organization: organization),
    );
  }

  Future<void> _onEnrollConfirmed(
    _EnrollConfirmed event,
    Emitter<ProducerManagementState> emit,
  ) async {
    final current = state;
    if (current is! ProducerManagementEnrollStep2) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _orgRepo.enrollProducer(
        currentOrg: current.organization,
        producerAccountId: current.selectedProducer.producerAccountId,
        products: event.products,
      );
      final org = await _orgRepo.watch(_organizationId).first;
      if (org != null) {
        emit(_buildListLoaded(org));
      } else {
        emit(const ProducerManagementState.error('Organisation introuvable.'));
      }
    } catch (_) {
      emit(
        current.copyWith(
          actionInProgress: false,
          actionError: 'Impossible d\'inscrire le producteur.',
        ),
      );
    }
  }

  Future<void> _onEnrollNoAccountConfirmed(
    _EnrollNoAccountConfirmed event,
    Emitter<ProducerManagementState> emit,
  ) async {
    final current = state;
    if (current is! ProducerManagementEnrollNoAccountStep2) return;
    emit(current.copyWith(actionInProgress: true, actionError: null));
    try {
      await _orgRepo.createNoAccountProducer(
        currentOrg: current.organization,
        name: event.name,
        contactEmail: event.contactEmail,
        address: event.address,
        website: event.website,
        products: event.products,
      );
      final org = await _orgRepo.watch(_organizationId).first;
      if (org != null) {
        emit(_buildListLoaded(org));
      } else {
        emit(const ProducerManagementState.error('Organisation introuvable.'));
      }
    } catch (_) {
      emit(
        current.copyWith(
          actionInProgress: false,
          actionError: 'Impossible de créer le producteur sans compte.',
        ),
      );
    }
  }

  Future<void> _onUpdateProductsRequested(
    _UpdateProductsRequested event,
    Emitter<ProducerManagementState> emit,
  ) async {
    final current = state;
    final organization = switch (current) {
      ProducerManagementDetailLoaded(:final organization) => organization,
      ProducerManagementListLoaded(:final organization) => organization,
      _ => null,
    };
    if (organization == null) return;
    switch (current) {
      case ProducerManagementDetailLoaded():
        emit(current.copyWith(actionInProgress: true, actionError: null));
      case ProducerManagementListLoaded():
        emit(current.copyWith(actionInProgress: true, actionError: null));
      default:
        return;
    }
    try {
      await _orgRepo.updateProducerProducts(
        currentOrg: organization,
        producerAccountId: event.producerAccount.producerAccountId,
        products: event.products,
      );
      final org = await _orgRepo.watch(_organizationId).first;
      if (org != null) {
        switch (current) {
          case ProducerManagementDetailLoaded():
            emit(
              ProducerManagementState.detailLoaded(
                organization: org,
                producerAccountId: event.producerAccount.producerAccountId,
              ),
            );
          case ProducerManagementListLoaded(:final statusFilter):
            emit(
              ProducerManagementState.listLoaded(
                organization: org,
                statusFilter: statusFilter,
              ),
            );
          default:
            return;
        }
      } else {
        emit(const ProducerManagementState.error('Organisation introuvable.'));
      }
    } catch (_) {
      switch (current) {
        case ProducerManagementDetailLoaded():
          emit(
            current.copyWith(
              actionInProgress: false,
              actionError: 'Impossible de mettre à jour les produits.',
            ),
          );
        case ProducerManagementListLoaded():
          emit(
            current.copyWith(
              actionInProgress: false,
              actionError: 'Impossible de mettre à jour les produits.',
            ),
          );
        default:
          return;
      }
    }
  }

  Future<void> _onUpdateNoAccountProductsRequested(
    _UpdateNoAccountProductsRequested event,
    Emitter<ProducerManagementState> emit,
  ) async {
    final current = state;
    final organization = switch (current) {
      ProducerManagementDetailLoaded(:final organization) => organization,
      ProducerManagementListLoaded(:final organization) => organization,
      _ => null,
    };
    if (organization == null) return;
    switch (current) {
      case ProducerManagementDetailLoaded():
        emit(current.copyWith(actionInProgress: true, actionError: null));
      case ProducerManagementListLoaded():
        emit(current.copyWith(actionInProgress: true, actionError: null));
      default:
        return;
    }
    try {
      await _orgRepo.updateNoAccountProducerProducts(
        currentOrg: organization,
        producerAccount: event.producerAccount,
        products: event.products,
      );
      final org = await _orgRepo.watch(_organizationId).first;
      if (org != null) {
        switch (current) {
          case ProducerManagementDetailLoaded():
            emit(
              ProducerManagementState.detailLoaded(
                organization: org,
                producerAccountId: event.producerAccount.producerAccountId,
              ),
            );
          case ProducerManagementListLoaded(:final statusFilter):
            emit(
              ProducerManagementState.listLoaded(
                organization: org,
                statusFilter: statusFilter,
              ),
            );
          default:
            return;
        }
      } else {
        emit(const ProducerManagementState.error('Organisation introuvable.'));
      }
    } catch (_) {
      switch (current) {
        case ProducerManagementDetailLoaded():
          emit(
            current.copyWith(
              actionInProgress: false,
              actionError: 'Impossible de mettre à jour les produits.',
            ),
          );
        case ProducerManagementListLoaded():
          emit(
            current.copyWith(
              actionInProgress: false,
              actionError: 'Impossible de mettre à jour les produits.',
            ),
          );
        default:
          return;
      }
    }
  }
}
