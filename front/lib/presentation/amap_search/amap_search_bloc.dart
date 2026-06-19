import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/member_join_request.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_event.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_state.dart';
import 'package:bloc/bloc.dart';

class AmapSearchBloc extends Bloc<AmapSearchEvent, AmapSearchState> {
  AmapSearchBloc({
    required PublicApi publicApi,
    String? preselectedOrganizationId,
  }) : _publicApi = publicApi,
       _preselectedOrganizationId = preselectedOrganizationId,
       super(const AmapSearchState.initial()) {
    on<OrgsLoadRequested>(_onOrgsLoadRequested);
    on<OrgSelected>(_onOrgSelected);
    on<JoinFormSubmitted>(_onJoinFormSubmitted);
  }

  final PublicApi _publicApi;
  final String? _preselectedOrganizationId;

  Future<void> _onOrgsLoadRequested(
    OrgsLoadRequested event,
    Emitter<AmapSearchState> emit,
  ) async {
    emit(const AmapSearchState.loadingOrgs());
    try {
      final orgs = await _publicApi.listOrganizations();
      final selectedOrg = _preselectedOrganizationId != null
          ? orgs
                .where((o) => o.organizationId == _preselectedOrganizationId)
                .firstOrNull
          : null;
      emit(AmapSearchState.orgsLoaded(orgs: orgs, selectedOrg: selectedOrg));
    } catch (_) {
      emit(
        const AmapSearchState.error(
          message: 'Une erreur est survenue. Veuillez réessayer.',
        ),
      );
    }
  }

  void _onOrgSelected(OrgSelected event, Emitter<AmapSearchState> emit) {
    final current = state;
    if (current is AmapSearchOrgsLoaded) {
      emit(current.copyWith(selectedOrg: event.org));
    }
  }

  Future<void> _onJoinFormSubmitted(
    JoinFormSubmitted event,
    Emitter<AmapSearchState> emit,
  ) async {
    final current = state;
    if (current is! AmapSearchOrgsLoaded) return;
    final org = current.selectedOrg;
    if (org == null) return;

    emit(AmapSearchState.submitting(org: org));
    try {
      final response = await _publicApi.createMemberJoinRequest(
        MemberJoinRequest(
          organizationId: org.organizationId,
          email: event.email,
          firstName: event.firstName,
          lastName: event.lastName,
        ),
      );
      emit(
        AmapSearchState.success(
          requestId: response.requestId,
          organizationName: org.name,
        ),
      );
    } on MemberJoinConflictException catch (e) {
      final message = switch (e.field) {
        MemberJoinConflictField.email =>
          'Cette adresse email est déjà inscrite pour cette AMAP.',
        MemberJoinConflictField.emailMember =>
          'Cette adresse email est déjà utilisée par un membre d\'une autre AMAP.',
        MemberJoinConflictField.emailOwner =>
          'Cette adresse email est déjà utilisée par un administrateur de l\'instance.',
        MemberJoinConflictField.emailProducer =>
          'Cette adresse email est déjà utilisée par un producteur.',
        MemberJoinConflictField.unknown =>
          'Cette adresse email est déjà utilisée.',
      };
      emit(AmapSearchState.error(message: message, selectedOrg: org));
    } catch (_) {
      emit(
        AmapSearchState.error(
          message: 'Une erreur est survenue. Veuillez réessayer.',
          selectedOrg: org,
        ),
      );
    }
  }
}
