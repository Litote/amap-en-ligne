import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/member_join_request.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_bloc.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_event.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

class _FakeMemberJoinRequest extends Fake implements MemberJoinRequest {}

const _org1 = Organization(
  organizationId: 'org-1',
  name: 'AMAP des Collines',
  contactEmail: 'contact@collines.fr',
);

const _org2 = Organization(
  organizationId: 'org-2',
  name: 'AMAP du Val',
  contactEmail: 'contact@val.fr',
);

const _validJoinEvent = AmapSearchEvent.joinFormSubmitted(
  firstName: 'Jean',
  lastName: 'Dupont',
  email: 'jean@example.fr',
);

void main() {
  setUpAll(() => registerFallbackValue(_FakeMemberJoinRequest()));

  late _MockPublicApi api;

  setUp(() => api = _MockPublicApi());

  group('orgsLoadRequested', () {
    blocTest<AmapSearchBloc, AmapSearchState>(
      'emits loadingOrgs then orgsLoaded on success',
      setUp: () => when(
        () => api.listOrganizations(),
      ).thenAnswer((_) async => [_org1, _org2]),
      build: () => AmapSearchBloc(publicApi: api),
      act: (bloc) => bloc.add(const AmapSearchEvent.orgsLoadRequested()),
      expect: () => [
        const AmapSearchState.loadingOrgs(),
        isA<AmapSearchOrgsLoaded>()
            .having((s) => s.orgs, 'orgs', [_org1, _org2])
            .having((s) => s.selectedOrg, 'selectedOrg', isNull),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'emits error when API throws',
      setUp: () => when(
        () => api.listOrganizations(),
      ).thenThrow(Exception('network error')),
      build: () => AmapSearchBloc(publicApi: api),
      act: (bloc) => bloc.add(const AmapSearchEvent.orgsLoadRequested()),
      expect: () => [
        const AmapSearchState.loadingOrgs(),
        isA<AmapSearchError>().having(
          (s) => s.selectedOrg,
          'selectedOrg',
          isNull,
        ),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'preselects org by id when preselectedOrganizationId is provided',
      setUp: () => when(
        () => api.listOrganizations(),
      ).thenAnswer((_) async => [_org1, _org2]),
      build: () =>
          AmapSearchBloc(publicApi: api, preselectedOrganizationId: 'org-2'),
      act: (bloc) => bloc.add(const AmapSearchEvent.orgsLoadRequested()),
      expect: () => [
        const AmapSearchState.loadingOrgs(),
        isA<AmapSearchOrgsLoaded>().having(
          (s) => s.selectedOrg,
          'selectedOrg',
          _org2,
        ),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'selectedOrg is null when preselectedOrganizationId does not match any org',
      setUp: () => when(
        () => api.listOrganizations(),
      ).thenAnswer((_) async => [_org1, _org2]),
      build: () => AmapSearchBloc(
        publicApi: api,
        preselectedOrganizationId: 'org-unknown',
      ),
      act: (bloc) => bloc.add(const AmapSearchEvent.orgsLoadRequested()),
      expect: () => [
        const AmapSearchState.loadingOrgs(),
        isA<AmapSearchOrgsLoaded>().having(
          (s) => s.selectedOrg,
          'selectedOrg',
          isNull,
        ),
      ],
    );
  });

  group('orgSelected', () {
    blocTest<AmapSearchBloc, AmapSearchState>(
      'updates selectedOrg in orgsLoaded state',
      build: () => AmapSearchBloc(publicApi: api),
      seed: () => const AmapSearchState.orgsLoaded(orgs: [_org1, _org2]),
      act: (bloc) => bloc.add(const AmapSearchEvent.orgSelected(_org1)),
      expect: () => [
        isA<AmapSearchOrgsLoaded>().having(
          (s) => s.selectedOrg,
          'selectedOrg',
          _org1,
        ),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'is a no-op when state is not orgsLoaded',
      build: () => AmapSearchBloc(publicApi: api),
      seed: () => const AmapSearchState.initial(),
      act: (bloc) => bloc.add(const AmapSearchEvent.orgSelected(_org1)),
      expect: () => <AmapSearchState>[],
    );
  });

  group('joinFormSubmitted', () {
    blocTest<AmapSearchBloc, AmapSearchState>(
      'emits submitting then success on API success',
      setUp: () => when(() => api.createMemberJoinRequest(any())).thenAnswer(
        (_) async => const MemberJoinRequestResponse(
          requestId: 'req-1',
          status: 'PENDING',
        ),
      ),
      build: () => AmapSearchBloc(publicApi: api),
      seed: () =>
          const AmapSearchState.orgsLoaded(orgs: [_org1], selectedOrg: _org1),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => [
        isA<AmapSearchSubmitting>().having((s) => s.org, 'org', _org1),
        isA<AmapSearchSuccess>()
            .having((s) => s.requestId, 'requestId', 'req-1')
            .having((s) => s.organizationName, 'organizationName', _org1.name),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'emits error with selectedOrg preserved on email conflict',
      setUp: () => when(() => api.createMemberJoinRequest(any())).thenThrow(
        const MemberJoinConflictException(MemberJoinConflictField.email),
      ),
      build: () => AmapSearchBloc(publicApi: api),
      seed: () =>
          const AmapSearchState.orgsLoaded(orgs: [_org1], selectedOrg: _org1),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => [
        isA<AmapSearchSubmitting>(),
        isA<AmapSearchError>()
            .having((s) => s.selectedOrg, 'selectedOrg', _org1)
            .having((s) => s.message, 'message', contains('email')),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'WHEN joinForm throws MemberJoinConflictException(emailMember) THEN emits error with member message',
      setUp: () => when(() => api.createMemberJoinRequest(any())).thenThrow(
        const MemberJoinConflictException(MemberJoinConflictField.emailMember),
      ),
      build: () => AmapSearchBloc(publicApi: api),
      seed: () =>
          const AmapSearchState.orgsLoaded(orgs: [_org1], selectedOrg: _org1),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => [
        isA<AmapSearchSubmitting>(),
        isA<AmapSearchError>()
            .having((s) => s.selectedOrg, 'selectedOrg', _org1)
            .having(
              (s) => s.message,
              'message',
              'Cette adresse email est déjà utilisée par un membre d\'une autre AMAP.',
            ),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'WHEN joinForm throws MemberJoinConflictException(emailOwner) THEN emits error with owner message',
      setUp: () => when(() => api.createMemberJoinRequest(any())).thenThrow(
        const MemberJoinConflictException(MemberJoinConflictField.emailOwner),
      ),
      build: () => AmapSearchBloc(publicApi: api),
      seed: () =>
          const AmapSearchState.orgsLoaded(orgs: [_org1], selectedOrg: _org1),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => [
        isA<AmapSearchSubmitting>(),
        isA<AmapSearchError>()
            .having((s) => s.selectedOrg, 'selectedOrg', _org1)
            .having(
              (s) => s.message,
              'message',
              'Cette adresse email est déjà utilisée par un administrateur de l\'instance.',
            ),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'WHEN joinForm throws MemberJoinConflictException(emailProducer) THEN emits error with producer message',
      setUp: () => when(() => api.createMemberJoinRequest(any())).thenThrow(
        const MemberJoinConflictException(
          MemberJoinConflictField.emailProducer,
        ),
      ),
      build: () => AmapSearchBloc(publicApi: api),
      seed: () =>
          const AmapSearchState.orgsLoaded(orgs: [_org1], selectedOrg: _org1),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => [
        isA<AmapSearchSubmitting>(),
        isA<AmapSearchError>()
            .having((s) => s.selectedOrg, 'selectedOrg', _org1)
            .having(
              (s) => s.message,
              'message',
              'Cette adresse email est déjà utilisée par un producteur.',
            ),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'emits error with selectedOrg preserved on network error',
      setUp: () => when(
        () => api.createMemberJoinRequest(any()),
      ).thenThrow(Exception('network error')),
      build: () => AmapSearchBloc(publicApi: api),
      seed: () =>
          const AmapSearchState.orgsLoaded(orgs: [_org1], selectedOrg: _org1),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => [
        isA<AmapSearchSubmitting>(),
        isA<AmapSearchError>().having(
          (s) => s.selectedOrg,
          'selectedOrg',
          _org1,
        ),
      ],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'is a no-op when state is not orgsLoaded',
      build: () => AmapSearchBloc(publicApi: api),
      seed: () => const AmapSearchState.initial(),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => <AmapSearchState>[],
    );

    blocTest<AmapSearchBloc, AmapSearchState>(
      'is a no-op when orgsLoaded has no selectedOrg',
      build: () => AmapSearchBloc(publicApi: api),
      seed: () => const AmapSearchState.orgsLoaded(orgs: [_org1]),
      act: (bloc) => bloc.add(_validJoinEvent),
      expect: () => <AmapSearchState>[],
    );
  });
}
