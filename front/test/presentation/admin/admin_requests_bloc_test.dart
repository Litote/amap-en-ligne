import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRequestRepository extends Mock
    implements OrganizationRequestRepository {}

final _pending = AdminOrganizationRequest(
  requestId: 'req-1',
  organizationName: 'AMAP test',
  timezone: 'Europe/Paris',
  defaultLanguage: 'fr',
  adminFirstName: 'Jean',
  adminLastName: 'Dupont',
  adminEmail: 'jean@example.fr',
  status: OrganizationRequestStatus.pendingValidation,
  submittedAt: '2024-01-01T00:00:00Z',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_pending);
  });

  late _MockOrganizationRequestRepository repo;

  setUp(() => repo = _MockOrganizationRequestRepository());

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'loadRequested emits loading then loaded with requests from stream',
    setUp: () =>
        when(() => repo.watch()).thenAnswer((_) => Stream.value([_pending])),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    act: (bloc) => bloc.add(const AdminRequestsEvent.loadRequested()),
    expect: () => [
      const AdminRequestsState.loading(),
      isA<AdminRequestsLoaded>()
          .having((s) => s.requests, 'requests', [_pending])
          .having((s) => s.statusFilter, 'statusFilter', isNull),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'loadRequested with status filter stores filter in state',
    setUp: () =>
        when(() => repo.watch()).thenAnswer((_) => Stream.value([_pending])),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    act: (bloc) => bloc.add(
      const AdminRequestsEvent.loadRequested(
        statusFilter: OrganizationRequestStatus.pendingValidation,
      ),
    ),
    expect: () => [
      const AdminRequestsState.loading(),
      isA<AdminRequestsLoaded>().having(
        (s) => s.statusFilter,
        'statusFilter',
        OrganizationRequestStatus.pendingValidation,
      ),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'loadRequested emits error when watch stream errors',
    setUp: () => when(
      () => repo.watch(),
    ).thenAnswer((_) => Stream.error(Exception('db error'))),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    act: (bloc) => bloc.add(const AdminRequestsEvent.loadRequested()),
    expect: () => [
      const AdminRequestsState.loading(),
      isA<AdminRequestsError>(),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'organizationTypeFilterChanged updates the filter without re-loading',
    setUp: () =>
        when(() => repo.watch()).thenAnswer((_) => const Stream.empty()),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    seed: () => AdminRequestsState.loaded(
      requests: [_pending],
      organizationTypeFilter: OrganizationType.amap,
    ),
    act: (bloc) => bloc.add(
      const AdminRequestsEvent.organizationTypeFilterChanged(
        OrganizationType.producer,
      ),
    ),
    expect: () => [
      isA<AdminRequestsLoaded>().having(
        (s) => s.organizationTypeFilter,
        'organizationTypeFilter',
        OrganizationType.producer,
      ),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'loadRequested preserves the active org-type tab (regression: status filter reset tab)',
    setUp: () =>
        when(() => repo.watch()).thenAnswer((_) => Stream.value([_pending])),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    seed: () => AdminRequestsState.loaded(
      requests: [_pending],
      organizationTypeFilter: OrganizationType.producer,
    ),
    act: (bloc) => bloc.add(
      const AdminRequestsEvent.loadRequested(
        statusFilter: OrganizationRequestStatus.pendingValidation,
      ),
    ),
    expect: () => [
      const AdminRequestsState.loading(),
      isA<AdminRequestsLoaded>().having(
        (s) => s.organizationTypeFilter,
        'organizationTypeFilter',
        OrganizationType.producer,
      ),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'approveRequested emits actionInProgress then clears it on success',
    setUp: () => when(() => repo.approve(_pending)).thenAnswer((_) async {}),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    seed: () => AdminRequestsState.loaded(requests: [_pending]),
    act: (bloc) => bloc.add(AdminRequestsEvent.approveRequested(_pending)),
    expect: () => [
      isA<AdminRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<AdminRequestsLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNull),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'approveRequested emits actionError when repository throws',
    setUp: () =>
        when(() => repo.approve(any())).thenThrow(Exception('server error')),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    seed: () => AdminRequestsState.loaded(requests: [_pending]),
    act: (bloc) => bloc.add(AdminRequestsEvent.approveRequested(_pending)),
    expect: () => [
      isA<AdminRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<AdminRequestsLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNotNull),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'rejectRequested emits actionInProgress then clears it on success',
    setUp: () => when(
      () => repo.reject(_pending, reviewComment: 'Missing info'),
    ).thenAnswer((_) async {}),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    seed: () => AdminRequestsState.loaded(requests: [_pending]),
    act: (bloc) => bloc.add(
      AdminRequestsEvent.rejectRequested(
        request: _pending,
        reviewComment: 'Missing info',
      ),
    ),
    expect: () => [
      isA<AdminRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<AdminRequestsLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNull),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'approveRequested is a no-op when state is not loaded',
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    act: (bloc) => bloc.add(AdminRequestsEvent.approveRequested(_pending)),
    expect: () => <AdminRequestsState>[],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'resendRequested emits actionInProgress then clears it on success',
    setUp: () => when(() => repo.resend(_pending)).thenAnswer((_) async {}),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    seed: () => AdminRequestsState.loaded(requests: [_pending]),
    act: (bloc) => bloc.add(AdminRequestsEvent.resendRequested(_pending)),
    expect: () => [
      isA<AdminRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<AdminRequestsLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNull),
    ],
  );

  blocTest<AdminRequestsBloc, AdminRequestsState>(
    'resendRequested emits actionError when repository throws',
    setUp: () =>
        when(() => repo.resend(any())).thenThrow(Exception('network error')),
    build: () => AdminRequestsBloc(organizationRequestRepository: repo),
    seed: () => AdminRequestsState.loaded(requests: [_pending]),
    act: (bloc) => bloc.add(AdminRequestsEvent.resendRequested(_pending)),
    expect: () => [
      isA<AdminRequestsLoaded>().having(
        (s) => s.actionInProgress,
        'actionInProgress',
        true,
      ),
      isA<AdminRequestsLoaded>()
          .having((s) => s.actionInProgress, 'actionInProgress', false)
          .having((s) => s.actionError, 'actionError', isNotNull),
    ],
  );
}
