import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_event.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_state.dart';
import 'package:bloc/bloc.dart';

class ProducerRequestBloc
    extends Bloc<ProducerRequestEvent, ProducerRequestState> {
  ProducerRequestBloc({required PublicApi publicApi})
    : _publicApi = publicApi,
      super(const ProducerRequestState.initial()) {
    on<ProducerRequestSubmitted>(_onSubmitted);
  }

  final PublicApi _publicApi;

  Future<void> _onSubmitted(
    ProducerRequestSubmitted event,
    Emitter<ProducerRequestState> emit,
  ) async {
    emit(const ProducerRequestState.submitting());
    try {
      final response = await _publicApi.createProducerRequest(
        ProducerCreationRequest(
          producerName: event.producerName,
          adminFirstName: event.adminFirstName,
          adminLastName: event.adminLastName,
          adminEmail: event.adminEmail,
          submitterComment: event.submitterComment,
        ),
      );
      emit(ProducerRequestState.success(response: response));
    } on ProducerConflictException catch (e) {
      emit(
        ProducerRequestState.error(
          message: _conflictMessage(e.field, e.existingStatus),
          conflictField: e.field,
        ),
      );
    } catch (_) {
      emit(
        const ProducerRequestState.error(
          message: 'Une erreur est survenue. Veuillez réessayer.',
        ),
      );
    }
  }

  static String _conflictMessage(
    ProducerConflictField field,
    String? existingStatus,
  ) => switch (field) {
    ProducerConflictField.producerName => switch (existingStatus) {
      'PENDING_VALIDATION' =>
        'Une demande pour ce nom de producteur est déjà en cours d\'examen.',
      'APPROVED' => 'Un producteur avec ce nom a déjà été approuvé.',
      _ => 'Ce nom de producteur est déjà utilisé.',
    },
    ProducerConflictField.adminEmail => switch (existingStatus) {
      'PENDING_VALIDATION' =>
        'Une demande avec cette adresse e-mail est déjà en cours d\'examen.',
      'APPROVED' =>
        'Cette adresse e-mail est déjà associée à une demande approuvée.',
      _ => 'Un compte avec cette adresse e-mail existe déjà.',
    },
    ProducerConflictField.unknown =>
      'Un conflit a été détecté. Veuillez vérifier vos informations.',
  };
}
