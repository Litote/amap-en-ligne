part of 'delivery_template_bloc.dart';

@freezed
sealed class DeliveryTemplateState with _$DeliveryTemplateState {
  const factory DeliveryTemplateState.initial() = DeliveryTemplateInitial;

  const factory DeliveryTemplateState.loading() = DeliveryTemplateLoading;

  const factory DeliveryTemplateState.loaded(List<DeliveryTemplate> templates) =
      DeliveryTemplateLoaded;

  const factory DeliveryTemplateState.error(String message) =
      DeliveryTemplateError;
}
