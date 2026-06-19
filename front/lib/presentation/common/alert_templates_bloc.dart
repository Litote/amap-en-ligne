import 'dart:async';

import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/notification_copy_override.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert_templates_bloc.freezed.dart';

/// Org-scoped notification categories an admin can customise from /preferences.
/// Owner/instance categories (organization/producer request submitted) are
/// excluded: they target instance owners and have no owning organization.
const List<NotificationCategory> kCustomisableAlertCategories = [
  NotificationCategory.slotCancelled,
  NotificationCategory.slotRescheduled,
  NotificationCategory.deliveryReminder,
  NotificationCategory.basketExchangeRequestReceived,
  NotificationCategory.basketExchangeAccepted,
  NotificationCategory.basketExchangeRejected,
  NotificationCategory.memberJoinRequestSubmitted,
];

/// Human-readable French label for each customisable category.
String alertCategoryLabel(NotificationCategory category) => switch (category) {
  NotificationCategory.slotCancelled => 'Créneau annulé',
  NotificationCategory.slotRescheduled => 'Horaire de créneau modifié',
  NotificationCategory.deliveryReminder => 'Rappel de livraison',
  NotificationCategory.basketExchangeRequestReceived =>
    'Nouvelle demande d\'échange de panier',
  NotificationCategory.basketExchangeAccepted => 'Échange de panier accepté',
  NotificationCategory.basketExchangeRejected => 'Échange de panier refusé',
  NotificationCategory.memberJoinRequestSubmitted =>
    'Nouvelle demande d\'adhésion',
  NotificationCategory.generic ||
  NotificationCategory.organizationRequestSubmitted ||
  NotificationCategory.producerRequestSubmitted => category.name,
};

/// Default title used by the back when no override is set, shown in the UI as a
/// hint so admins see what will be sent. Dynamic parts appear as `{…}`
/// placeholders (the back fills them at send time when no override is set).
String alertCategoryDefaultTitle(NotificationCategory category) =>
    switch (category) {
      NotificationCategory.slotCancelled => 'Créneau annulé',
      NotificationCategory.slotRescheduled => 'Horaire de créneau modifié',
      NotificationCategory.deliveryReminder => 'Rappel de livraison',
      NotificationCategory.basketExchangeRequestReceived =>
        'Nouvelle demande d\'échange de panier',
      NotificationCategory.basketExchangeAccepted =>
        'Échange de panier confirmé',
      NotificationCategory.basketExchangeRejected =>
        'Demande de panier non retenue',
      NotificationCategory.memberJoinRequestSubmitted =>
        'Nouvelle demande d\'adhésion',
      NotificationCategory.generic ||
      NotificationCategory.organizationRequestSubmitted ||
      NotificationCategory.producerRequestSubmitted => '',
    };

/// Default body used by the back when no override is set (see
/// [alertCategoryDefaultTitle]).
String alertCategoryDefaultBody(
  NotificationCategory category,
) => switch (category) {
  NotificationCategory.slotCancelled => 'Le créneau du {date} a été annulé.',
  NotificationCategory.slotRescheduled =>
    'L\'horaire de votre créneau a été modifié : {créneau}.',
  NotificationCategory.deliveryReminder => 'Une livraison approche.',
  NotificationCategory.basketExchangeRequestReceived =>
    '{membre} propose son panier du {date} en échange du vôtre du {date}.',
  NotificationCategory.basketExchangeAccepted =>
    'Votre échange est confirmé : vous récupérez le panier du {date}, '
        'vous cédez le vôtre du {date}.',
  NotificationCategory.basketExchangeRejected =>
    'Votre proposition d\'échange pour le panier du {date} n\'a pas été retenue.',
  NotificationCategory.memberJoinRequestSubmitted =>
    'Une demande d\'adhésion de {prénom nom} est en attente.',
  NotificationCategory.generic ||
  NotificationCategory.organizationRequestSubmitted ||
  NotificationCategory.producerRequestSubmitted => '',
};

enum AlertTemplatesSaveStatus { idle, saving, success, failure }

@freezed
sealed class AlertTemplatesEvent with _$AlertTemplatesEvent {
  /// Internal — fired by the organization-stream subscription.
  const factory AlertTemplatesEvent.loaded(Organization? organization) =
      _AlertTemplatesLoaded;

  /// User saved the edited overrides.
  const factory AlertTemplatesEvent.saved(
    Map<NotificationCategory, NotificationCopyOverride> overrides,
  ) = _AlertTemplatesSaved;
}

@freezed
sealed class AlertTemplatesState with _$AlertTemplatesState {
  const factory AlertTemplatesState.loading() = AlertTemplatesLoading;

  /// Organization not yet synced — nothing to edit.
  const factory AlertTemplatesState.missing() = AlertTemplatesMissing;

  const factory AlertTemplatesState.ready({
    required Organization organization,
    @Default(AlertTemplatesSaveStatus.idle) AlertTemplatesSaveStatus saveStatus,
    String? saveErrorMessage,
  }) = AlertTemplatesReady;
}

class AlertTemplatesBloc
    extends Bloc<AlertTemplatesEvent, AlertTemplatesState> {
  AlertTemplatesBloc({
    required OrganizationRepository organizationRepository,
    required String tenantId,
  }) : _organizationRepository = organizationRepository,
       super(const AlertTemplatesState.loading()) {
    on<_AlertTemplatesLoaded>(_onLoaded);
    on<_AlertTemplatesSaved>(_onSaved);

    _sub = _organizationRepository
        .watch(tenantId)
        .listen((org) => add(AlertTemplatesEvent.loaded(org)));
  }

  final OrganizationRepository _organizationRepository;
  late final StreamSubscription<Organization?> _sub;

  void _onLoaded(
    _AlertTemplatesLoaded event,
    Emitter<AlertTemplatesState> emit,
  ) {
    final org = event.organization;
    final current = state;
    // Don't clobber an in-flight save with a stream echo.
    if (current is AlertTemplatesReady &&
        current.saveStatus == AlertTemplatesSaveStatus.saving) {
      return;
    }
    if (org == null) {
      emit(const AlertTemplatesState.missing());
    } else {
      emit(AlertTemplatesState.ready(organization: org));
    }
  }

  Future<void> _onSaved(
    _AlertTemplatesSaved event,
    Emitter<AlertTemplatesState> emit,
  ) async {
    final current = state;
    if (current is! AlertTemplatesReady) return;
    emit(
      current.copyWith(
        saveStatus: AlertTemplatesSaveStatus.saving,
        saveErrorMessage: null,
      ),
    );
    try {
      await _organizationRepository.updateNotificationOverrides(
        currentOrg: current.organization,
        overrides: event.overrides,
      );
      emit(current.copyWith(saveStatus: AlertTemplatesSaveStatus.success));
    } catch (e) {
      emit(
        current.copyWith(
          saveStatus: AlertTemplatesSaveStatus.failure,
          saveErrorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
