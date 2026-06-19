import 'dart:async';

import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/common/alert_templates_bloc.dart' show AlertTemplatesBloc;
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_config_bloc.freezed.dart';

/// Save status for the organization identity form.
enum OrgConfigSaveStatus { idle, saving, success, failure }

@freezed
sealed class OrgConfigEvent with _$OrgConfigEvent {
  /// Internal — fired by the org-stream subscription.
  const factory OrgConfigEvent.loaded(Organization? organization) =
      _OrgConfigLoaded;

  /// User submitted the identity form with updated field values.
  const factory OrgConfigEvent.saved({
    required String name,
    required String contactEmail,
    String? timezone,
    String? defaultLanguage,
    String? website,
  }) = _OrgConfigSaved;
}

@freezed
sealed class OrgConfigState with _$OrgConfigState {
  const factory OrgConfigState.loading() = OrgConfigLoading;

  /// Organization not yet synced — nothing to edit yet.
  const factory OrgConfigState.missing() = OrgConfigMissing;

  const factory OrgConfigState.ready({
    required Organization organization,
    @Default(OrgConfigSaveStatus.idle) OrgConfigSaveStatus saveStatus,
    String? saveErrorMessage,
  }) = OrgConfigReady;
}

/// BLoC for the admin organization-identity configuration screen.
///
/// Mirrors [AlertTemplatesBloc]: subscribes to the org stream on construction,
/// re-emits [OrgConfigState.ready] on every change (without clobbering an
/// in-flight save), and delegates [OrgConfigEvent.saved] to
/// [OrganizationRepository.updateIdentity].
class OrgConfigBloc extends Bloc<OrgConfigEvent, OrgConfigState> {
  OrgConfigBloc({
    required OrganizationRepository organizationRepository,
    required String tenantId,
  }) : _organizationRepository = organizationRepository,
       super(const OrgConfigState.loading()) {
    on<_OrgConfigLoaded>(_onLoaded);
    on<_OrgConfigSaved>(_onSaved);

    _sub = _organizationRepository
        .watch(tenantId)
        .listen((org) => add(OrgConfigEvent.loaded(org)));
  }

  final OrganizationRepository _organizationRepository;
  late final StreamSubscription<Organization?> _sub;

  void _onLoaded(_OrgConfigLoaded event, Emitter<OrgConfigState> emit) {
    final org = event.organization;
    final current = state;
    // Don't clobber an in-flight save with a stream echo.
    if (current is OrgConfigReady &&
        current.saveStatus == OrgConfigSaveStatus.saving) {
      return;
    }
    if (org == null) {
      emit(const OrgConfigState.missing());
    } else {
      emit(OrgConfigState.ready(organization: org));
    }
  }

  Future<void> _onSaved(
    _OrgConfigSaved event,
    Emitter<OrgConfigState> emit,
  ) async {
    final current = state;
    if (current is! OrgConfigReady) return;
    emit(
      current.copyWith(
        saveStatus: OrgConfigSaveStatus.saving,
        saveErrorMessage: null,
      ),
    );
    try {
      await _organizationRepository.updateIdentity(
        currentOrg: current.organization,
        name: event.name,
        contactEmail: event.contactEmail,
        timezone: event.timezone,
        defaultLanguage: event.defaultLanguage,
        website: event.website,
      );
      emit(current.copyWith(saveStatus: OrgConfigSaveStatus.success));
    } on Exception catch (e) {
      emit(
        current.copyWith(
          saveStatus: OrgConfigSaveStatus.failure,
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
