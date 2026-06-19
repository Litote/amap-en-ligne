import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/organization_request_response.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_event.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_state.dart';
import 'package:bloc/bloc.dart';

class OrganizationCreationBloc
    extends Bloc<OrganizationCreationEvent, OrganizationCreationState> {
  OrganizationCreationBloc({required PublicApi publicApi})
    : _publicApi = publicApi,
      super(const OrganizationCreationState.initial()) {
    on<OrganizationCreationSubmitted>(_onSubmitted);
  }

  final PublicApi _publicApi;

  Future<void> _onSubmitted(
    OrganizationCreationSubmitted event,
    Emitter<OrganizationCreationState> emit,
  ) async {
    emit(const OrganizationCreationState.submitting());
    try {
      final response = await _publicApi.createOrganizationRequest(
        OrganizationCreationRequest(
          organizationName: event.organizationName,
          timezone: event.timezone,
          defaultLanguage: event.defaultLanguage,
          adminFirstName: event.adminFirstName,
          adminLastName: event.adminLastName,
          adminEmail: event.adminEmail,
          organizationType: event.organizationType,
          submitterComment: event.submitterComment,
        ),
      );
      emit(OrganizationCreationState.success(response: response));
    } on OrganizationConflictException catch (e) {
      emit(
        OrganizationCreationState.error(
          message: _conflictMessage(e.field, e.existingStatus),
          conflictField: e.field,
        ),
      );
    } catch (_) {
      emit(
        const OrganizationCreationState.error(
          message: 'Une erreur est survenue. Veuillez réessayer.',
        ),
      );
    }
  }

  static String _conflictMessage(
    OrganizationConflictField field,
    String? existingStatus,
  ) => switch (field) {
    OrganizationConflictField.organizationName =>
      existingStatus == 'PENDING_VALIDATION'
          ? 'Une demande pour ce nom d\'AMAP est déjà en cours d\'examen.'
          : existingStatus == 'APPROVED'
          ? 'Une AMAP avec ce nom a déjà été approuvée.'
          : 'Ce nom d\'AMAP est déjà utilisé.',
    OrganizationConflictField.adminEmail =>
      existingStatus == 'PENDING_VALIDATION'
          ? 'Une demande avec cette adresse e-mail est déjà en cours d\'examen.'
          : existingStatus == 'APPROVED'
          ? 'Cette adresse e-mail est déjà associée à une demande approuvée.'
          : 'Un compte avec cette adresse e-mail existe déjà.',
    OrganizationConflictField.unknown =>
      'Un conflit a été détecté. Veuillez vérifier vos informations.',
  };
}
