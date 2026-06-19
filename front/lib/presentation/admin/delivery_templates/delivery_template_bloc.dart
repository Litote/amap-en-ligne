import 'dart:async';

import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_template_bloc.freezed.dart';
part 'delivery_template_event.dart';
part 'delivery_template_state.dart';

class DeliveryTemplateBloc
    extends Bloc<DeliveryTemplateEvent, DeliveryTemplateState> {
  DeliveryTemplateBloc({
    required DeliveryTemplateRepository repository,
    required String organizationId,
  }) : _repository = repository,
       _organizationId = organizationId,
       super(const DeliveryTemplateState.initial()) {
    on<_LoadTemplates>(_onLoadTemplates);
    on<_CreateTemplate>(_onCreateTemplate);
    on<_UpdateTemplate>(_onUpdateTemplate);
    on<_DeleteTemplate>(_onDeleteTemplate);
  }

  final DeliveryTemplateRepository _repository;
  final String _organizationId;
  StreamSubscription<List<DeliveryTemplate>>? _subscription;

  Future<void> _onLoadTemplates(
    _LoadTemplates event,
    Emitter<DeliveryTemplateState> emit,
  ) async {
    emit(const DeliveryTemplateState.loading());
    await emit.forEach<List<DeliveryTemplate>>(
      _repository.watch(_organizationId),
      onData: (templates) => DeliveryTemplateState.loaded(templates),
      onError: (error, stackTrace) =>
          const DeliveryTemplateState.error('Erreur de chargement.'),
    );
  }

  Future<void> _onCreateTemplate(
    _CreateTemplate event,
    Emitter<DeliveryTemplateState> emit,
  ) async {
    try {
      await _repository.create(event.template);
    } catch (_) {
      emit(
        const DeliveryTemplateState.error(
          'Impossible de créer le modèle de livraison.',
        ),
      );
    }
  }

  Future<void> _onUpdateTemplate(
    _UpdateTemplate event,
    Emitter<DeliveryTemplateState> emit,
  ) async {
    try {
      await _repository.update(event.template);
    } catch (_) {
      emit(
        const DeliveryTemplateState.error(
          'Impossible de mettre à jour le modèle de livraison.',
        ),
      );
    }
  }

  Future<void> _onDeleteTemplate(
    _DeleteTemplate event,
    Emitter<DeliveryTemplateState> emit,
  ) async {
    try {
      await _repository.delete(event.templateId, event.organizationId);
    } catch (_) {
      emit(
        const DeliveryTemplateState.error(
          'Impossible de supprimer le modèle de livraison.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
