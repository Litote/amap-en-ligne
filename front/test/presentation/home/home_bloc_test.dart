import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/home/home_bloc.dart';
import 'package:amap_en_ligne/presentation/home/home_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPublicApi extends Mock implements PublicApi {}

void main() {
  late _MockPublicApi api;

  setUp(() => api = _MockPublicApi());

  blocTest<HomeBloc, HomeState>(
    'auto-dispatches loadRequested on construction — success path',
    setUp: () => when(() => api.listOrganizations()).thenAnswer(
      (_) async => [
        const Organization(
          organizationId: 'org-1',
          name: 'AMAP test',
          contactEmail: 'test@amap.fr',
        ),
      ],
    ),
    build: () => HomeBloc(publicApi: api),
    expect: () => [
      const HomeState.loading(),
      isA<HomeLoaded>().having(
        (s) => s.organizations,
        'organizations',
        hasLength(1),
      ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'emits error when API throws',
    setUp: () =>
        when(() => api.listOrganizations()).thenThrow(Exception('fail')),
    build: () => HomeBloc(publicApi: api),
    expect: () => [const HomeState.loading(), isA<HomeError>()],
  );

  blocTest<HomeBloc, HomeState>(
    'emits empty loaded when API returns no organizations',
    setUp: () =>
        when(() => api.listOrganizations()).thenAnswer((_) async => []),
    build: () => HomeBloc(publicApi: api),
    expect: () => [
      const HomeState.loading(),
      const HomeState.loaded(organizations: []),
    ],
  );
}
