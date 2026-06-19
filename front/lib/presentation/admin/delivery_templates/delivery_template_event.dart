part of 'delivery_template_bloc.dart';

@freezed
sealed class DeliveryTemplateEvent with _$DeliveryTemplateEvent {
  const factory DeliveryTemplateEvent.loadTemplates() = _LoadTemplates;

  const factory DeliveryTemplateEvent.createTemplate(
    DeliveryTemplate template,
  ) = _CreateTemplate;

  const factory DeliveryTemplateEvent.updateTemplate(
    DeliveryTemplate template,
  ) = _UpdateTemplate;

  const factory DeliveryTemplateEvent.deleteTemplate({
    required String templateId,
    required String organizationId,
  }) = _DeleteTemplate;
}
