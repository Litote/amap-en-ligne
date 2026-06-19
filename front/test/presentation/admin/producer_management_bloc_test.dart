import 'dart:async';

import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_management_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockAdminApi extends Mock implements AdminApi {}

const _testOrgId = 'org-1';

final _baseOrg = Organization(
  organizationId: _testOrgId,
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  producers: const [
    OrganizationProducer(
      producerAccountId: 'pa-2',
      associationInstant: '1970-01-01T00:00:02Z',
      status: OrganizationProducerStatus.suspended,
    ),
    OrganizationProducer(
      producerAccountId: 'pa-3',
      associationInstant: '1970-01-01T00:00:03Z',
      status: OrganizationProducerStatus.terminated,
    ),
  ],
);

final _updatedOrg = Organization(
  organizationId: _testOrgId,
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  producers: const [
    OrganizationProducer(
      producerAccountId: 'pa-1',
      associationInstant: '1970-01-01T00:00:01Z',
      status: OrganizationProducerStatus.active,
    ),
    OrganizationProducer(
      producerAccountId: 'pa-2',
      associationInstant: '1970-01-01T00:00:02Z',
      status: OrganizationProducerStatus.suspended,
    ),
    OrganizationProducer(
      producerAccountId: 'pa-3',
      associationInstant: '1970-01-01T00:00:03Z',
      status: OrganizationProducerStatus.terminated,
    ),
  ],
);

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockAdminApi adminApi;
  late StreamController<Organization?> refreshController;

  setUpAll(() {
    registerFallbackValue(
      const Organization(
        organizationId: 'fallback',
        name: 'fallback',
        contactEmail: 'fallback@test.fr',
      ),
    );
    registerFallbackValue(OrganizationProducerStatus.active);
    registerFallbackValue(<OrgProduct>[]);
    registerFallbackValue(
      const ProducerAccount(producerAccountId: 'fallback', name: 'fallback'),
    );
    registerFallbackValue(<ProducerProduct>[]);
  });

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    adminApi = _MockAdminApi();
  });

  ProducerManagementBloc buildBloc() => ProducerManagementBloc(
    organizationRepository: orgRepo,
    adminApi: adminApi,
    organizationId: _testOrgId,
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'loadRequested defaults the list filter to active',
    setUp: () {
      final organizationController = StreamController<Organization?>();
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => organizationController.stream);
      organizationController.add(_baseOrg);
      organizationController.close();
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ProducerManagementEvent.loadRequested()),
    expect: () => [
      const ProducerManagementState.loading(),
      isA<ProducerManagementListLoaded>()
          .having((s) => s.organization, 'organization', _baseOrg)
          .having(
            (s) => s.statusFilter,
            'statusFilter',
            OrganizationProducerStatus.active,
          ),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'loadRequested preserves explicit all filter across stream refreshes',
    setUp: () {
      refreshController = StreamController<Organization?>();
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => refreshController.stream);
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ProducerManagementEvent.loadRequested());
      refreshController.add(_baseOrg);
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProducerManagementEvent.statusFilterChanged(null));
      await Future<void>.delayed(Duration.zero);
      refreshController.add(_updatedOrg);
      await refreshController.close();
    },
    tearDown: () async {
      if (!refreshController.isClosed) {
        await refreshController.close();
      }
    },
    expect: () => [
      const ProducerManagementState.loading(),
      isA<ProducerManagementListLoaded>().having(
        (s) => s.statusFilter,
        'statusFilter',
        OrganizationProducerStatus.active,
      ),
      isA<ProducerManagementListLoaded>().having(
        (s) => s.statusFilter,
        'statusFilter',
        null,
      ),
      isA<ProducerManagementListLoaded>()
          .having((s) => s.organization, 'organization', _updatedOrg)
          .having((s) => s.statusFilter, 'statusFilter', null),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'loadRequested emits error when org is null',
    setUp: () {
      final organizationController = StreamController<Organization?>();
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => organizationController.stream);
      organizationController.add(null);
      organizationController.close();
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ProducerManagementEvent.loadRequested()),
    expect: () => [
      const ProducerManagementState.loading(),
      isA<ProducerManagementError>(),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'statusFilterChanged updates filter in listLoaded state',
    build: buildBloc,
    seed: () => ProducerManagementState.listLoaded(organization: _baseOrg),
    act: (bloc) => bloc.add(
      const ProducerManagementEvent.statusFilterChanged(
        OrganizationProducerStatus.suspended,
      ),
    ),
    expect: () => [
      isA<ProducerManagementListLoaded>().having(
        (s) => s.statusFilter,
        'statusFilter',
        OrganizationProducerStatus.suspended,
      ),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'detailRequested transitions to detailLoaded',
    build: buildBloc,
    seed: () => ProducerManagementState.listLoaded(organization: _baseOrg),
    act: (bloc) =>
        bloc.add(const ProducerManagementEvent.detailRequested('pa-1')),
    expect: () => [
      isA<ProducerManagementDetailLoaded>().having(
        (s) => s.producerAccountId,
        'producerAccountId',
        'pa-1',
      ),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'updateStatusRequested success reloads organization',
    setUp: () {
      when(
        () => orgRepo.updateProducerStatus(
          currentOrg: any(named: 'currentOrg'),
          producerAccountId: any(named: 'producerAccountId'),
          newStatus: any(named: 'newStatus'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => Stream.value(_baseOrg));
    },
    build: buildBloc,
    seed: () => ProducerManagementState.detailLoaded(
      organization: _baseOrg,
      producerAccountId: 'pa-1',
    ),
    act: (bloc) => bloc.add(
      const ProducerManagementEvent.updateStatusRequested(
        producerAccountId: 'pa-1',
        newStatus: OrganizationProducerStatus.suspended,
      ),
    ),
    expect: () => [
      isA<ProducerManagementDetailLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<ProducerManagementListLoaded>(),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'updateStatusRequested emits error when repo throws',
    setUp: () => when(
      () => orgRepo.updateProducerStatus(
        currentOrg: any(named: 'currentOrg'),
        producerAccountId: any(named: 'producerAccountId'),
        newStatus: any(named: 'newStatus'),
      ),
    ).thenThrow(Exception('network error')),
    build: buildBloc,
    seed: () => ProducerManagementState.detailLoaded(
      organization: _baseOrg,
      producerAccountId: 'pa-1',
    ),
    act: (bloc) => bloc.add(
      const ProducerManagementEvent.updateStatusRequested(
        producerAccountId: 'pa-1',
        newStatus: OrganizationProducerStatus.suspended,
      ),
    ),
    expect: () => [
      isA<ProducerManagementDetailLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<ProducerManagementDetailLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNotNull),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'enrollSearchChanged with non-empty query fetches results',
    setUp: () => when(() => adminApi.searchProducers('Jean')).thenAnswer(
      (_) async => [
        const ProducerAccount(producerAccountId: 'pa-new', name: 'Jean Dupont'),
      ],
    ),
    build: buildBloc,
    seed: () => ProducerManagementState.listLoaded(organization: _baseOrg),
    act: (bloc) =>
        bloc.add(const ProducerManagementEvent.enrollSearchChanged('Jean')),
    expect: () => [
      isA<ProducerManagementEnrollStep1>().having(
        (s) => s.searching,
        'searching',
        true,
      ),
      isA<ProducerManagementEnrollStep1>()
          .having((s) => s.searching, 'searching', false)
          .having((s) => s.searchResults.length, 'results', 1),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'enrollConfirmed success transitions to listLoaded',
    setUp: () {
      when(
        () => orgRepo.enrollProducer(
          currentOrg: any(named: 'currentOrg'),
          producerAccountId: any(named: 'producerAccountId'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => Stream.value(_baseOrg));
    },
    build: buildBloc,
    seed: () => ProducerManagementState.enrollStep2(
      organization: _baseOrg,
      selectedProducer: const ProducerAccount(
        producerAccountId: 'pa-new',
        name: 'Jean Dupont',
      ),
    ),
    act: (bloc) => bloc.add(const ProducerManagementEvent.enrollConfirmed([])),
    expect: () => [
      isA<ProducerManagementEnrollStep2>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<ProducerManagementListLoaded>(),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'enrollNoAccountStarted transitions to no-account step 2',
    build: buildBloc,
    seed: () => ProducerManagementState.listLoaded(organization: _baseOrg),
    act: (bloc) =>
        bloc.add(const ProducerManagementEvent.enrollNoAccountStarted()),
    expect: () => [isA<ProducerManagementEnrollNoAccountStep2>()],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'enrollNoAccountConfirmed success transitions to listLoaded',
    setUp: () {
      when(
        () => orgRepo.createNoAccountProducer(
          currentOrg: any(named: 'currentOrg'),
          name: any(named: 'name'),
          contactEmail: any(named: 'contactEmail'),
          address: any(named: 'address'),
          website: any(named: 'website'),
          products: any(named: 'products'),
        ),
      ).thenAnswer(
        (_) async =>
            const ProducerAccount(producerAccountId: 'tmp_pa', name: 'Draft'),
      );
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => Stream.value(_baseOrg));
    },
    build: buildBloc,
    seed: () =>
        ProducerManagementState.enrollNoAccountStep2(organization: _baseOrg),
    act: (bloc) => bloc.add(
      const ProducerManagementEvent.enrollNoAccountConfirmed(
        name: 'Ferme locale',
        products: [ProducerProduct(name: 'Tomates', productTypeId: 'tmp_pt')],
      ),
    ),
    expect: () => [
      isA<ProducerManagementEnrollNoAccountStep2>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<ProducerManagementListLoaded>(),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'updateProductsRequested from listLoaded keeps list state after success',
    setUp: () {
      when(
        () => orgRepo.updateProducerProducts(
          currentOrg: any(named: 'currentOrg'),
          producerAccountId: any(named: 'producerAccountId'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => Stream.value(_baseOrg));
    },
    build: buildBloc,
    seed: () => ProducerManagementState.listLoaded(
      organization: _baseOrg,
      statusFilter: OrganizationProducerStatus.suspended,
    ),
    act: (bloc) => bloc.add(
      const ProducerManagementEvent.updateProductsRequested(
        producerAccount: ProducerAccount(
          producerAccountId: 'pa-1',
          name: 'Jean Dupont',
        ),
        products: [],
      ),
    ),
    expect: () => [
      isA<ProducerManagementListLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', true)
          .having(
            (s) => s.statusFilter,
            'statusFilter',
            OrganizationProducerStatus.suspended,
          ),
      isA<ProducerManagementListLoaded>().having(
        (s) => s.statusFilter,
        'statusFilter',
        OrganizationProducerStatus.suspended,
      ),
    ],
  );

  blocTest<ProducerManagementBloc, ProducerManagementState>(
    'updateNoAccountProductsRequested keeps detail state after success',
    setUp: () {
      when(
        () => orgRepo.updateNoAccountProducerProducts(
          currentOrg: any(named: 'currentOrg'),
          producerAccount: any(named: 'producerAccount'),
          products: any(named: 'products'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => orgRepo.watch(_testOrgId),
      ).thenAnswer((_) => Stream.value(_baseOrg));
    },
    build: buildBloc,
    seed: () => ProducerManagementState.detailLoaded(
      organization: _baseOrg,
      producerAccountId: 'pa-1',
    ),
    act: (bloc) => bloc.add(
      const ProducerManagementEvent.updateNoAccountProductsRequested(
        producerAccount: ProducerAccount(
          producerAccountId: 'pa-1',
          name: 'Jean Dupont',
          managementMode: ProducerManagementMode.noAccount,
        ),
        products: [ProducerProduct(name: 'Tomates', productTypeId: 'pt-1')],
      ),
    ),
    expect: () => [
      isA<ProducerManagementDetailLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<ProducerManagementDetailLoaded>(),
    ],
  );
}
