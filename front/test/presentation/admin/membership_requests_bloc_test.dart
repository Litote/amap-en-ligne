import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_state.dart';
import 'package:amap_en_ligne/presentation/sync/sync_messages.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMemberJoinRequestRepository extends Mock
    implements MemberJoinRequestRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

final _pending = AdminMemberJoinRequest(
  requestId: 'req-1',
  organizationId: 'org-1',
  email: 'jean@example.fr',
  firstName: 'Jean',
  lastName: 'Dupont',
  status: MemberJoinRequestStatus.pending,
  submittedAt: '2024-01-01T00:00:00Z',
);

final _rejectedMutation = MutationOutcome(
  clientOpId: 'op-1',
  status: MutationStatus.rejected,
  error: const MutationError(
    code: MutationErrorCode.conflict,
    message: 'Already processed',
  ),
);

void main() {
  late _MockMemberJoinRequestRepository repo;
  late _MockSyncRepository syncRepository;

  setUp(() {
    repo = _MockMemberJoinRequestRepository();
    syncRepository = _MockSyncRepository();
    when(() => repo.watch('org-1')).thenAnswer((_) => const Stream.empty());
  });

  group('loadRequested', () {
    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'emits loading then loaded from repository stream',
      setUp: () => when(
        () => repo.watch('org-1'),
      ).thenAnswer((_) => Stream.value([_pending])),
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      act: (bloc) => bloc.add(const MembershipRequestsEvent.loadRequested()),
      expect: () => [
        const MembershipRequestsState.loading(),
        isA<MembershipRequestsLoaded>()
            .having((s) => s.requests, 'requests', [_pending])
            .having((s) => s.statusFilter, 'statusFilter', isNull),
      ],
    );

    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'stores the requested status filter',
      setUp: () => when(
        () => repo.watch('org-1'),
      ).thenAnswer((_) => Stream.value([_pending])),
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      act: (bloc) => bloc.add(
        const MembershipRequestsEvent.loadRequested(
          statusFilter: MemberJoinRequestStatus.pending,
        ),
      ),
      expect: () => [
        const MembershipRequestsState.loading(),
        isA<MembershipRequestsLoaded>().having(
          (s) => s.statusFilter,
          'statusFilter',
          MemberJoinRequestStatus.pending,
        ),
      ],
    );
  });

  group('approveRequested', () {
    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'emits actionInProgress then clears it on successful sync',
      setUp: () {
        when(() => repo.approve(_pending)).thenAnswer((_) async => 'op-1');
        when(
          () => syncRepository.sync(tenantId: 'org-1'),
        ).thenAnswer((_) async => const SyncOutcome.success());
      },
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      seed: () => MembershipRequestsState.loaded(requests: [_pending]),
      act: (bloc) =>
          bloc.add(MembershipRequestsEvent.approveRequested(request: _pending)),
      expect: () => [
        isA<MembershipRequestsLoaded>().having(
          (s) => s.actionInProgress,
          'actionInProgress',
          true,
        ),
        isA<MembershipRequestsLoaded>().having(
          (s) => s.actionInProgress,
          'actionInProgress',
          false,
        ),
      ],
    );

    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'emits actionError when sync rejects the mutation',
      setUp: () {
        when(() => repo.approve(_pending)).thenAnswer((_) async => 'op-1');
        when(() => syncRepository.sync(tenantId: 'org-1')).thenAnswer(
          (_) async =>
              SyncOutcome.success(rejectedMutations: [_rejectedMutation]),
        );
      },
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      seed: () => MembershipRequestsState.loaded(requests: [_pending]),
      act: (bloc) =>
          bloc.add(MembershipRequestsEvent.approveRequested(request: _pending)),
      expect: () => [
        isA<MembershipRequestsLoaded>().having(
          (s) => s.actionInProgress,
          'actionInProgress',
          true,
        ),
        isA<MembershipRequestsLoaded>()
            .having((s) => s.actionInProgress, 'actionInProgress', false)
            .having(
              (s) => s.actionError,
              'actionError',
              'Cette demande a déjà été traitée ou n’est plus disponible.',
            ),
      ],
    );

    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'emits the server-unreachable message when sync fails for network '
      'reasons',
      setUp: () {
        when(() => repo.approve(_pending)).thenAnswer((_) async => 'op-1');
        when(
          () => syncRepository.sync(tenantId: 'org-1'),
        ).thenAnswer((_) async => const SyncOutcome.networkFailure());
      },
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      seed: () => MembershipRequestsState.loaded(requests: [_pending]),
      act: (bloc) =>
          bloc.add(MembershipRequestsEvent.approveRequested(request: _pending)),
      expect: () => [
        isA<MembershipRequestsLoaded>().having(
          (s) => s.actionInProgress,
          'actionInProgress',
          true,
        ),
        isA<MembershipRequestsLoaded>()
            .having((s) => s.actionInProgress, 'actionInProgress', false)
            .having(
              (s) => s.actionError,
              'actionError',
              syncServerUnreachableMessage,
            ),
      ],
    );

    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'is a no-op when state is not loaded',
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      act: (bloc) =>
          bloc.add(MembershipRequestsEvent.approveRequested(request: _pending)),
      expect: () => <MembershipRequestsState>[],
    );
  });

  group('rejectRequested', () {
    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'emits actionError when sync fails after enqueueing the mutation',
      setUp: () {
        when(
          () => repo.reject(_pending, reviewComment: 'Missing info'),
        ).thenAnswer((_) async => 'op-1');
        when(() => syncRepository.sync(tenantId: 'org-1')).thenAnswer(
          (_) async => const SyncOutcome.failure('network unavailable'),
        );
      },
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      seed: () => MembershipRequestsState.loaded(requests: [_pending]),
      act: (bloc) => bloc.add(
        MembershipRequestsEvent.rejectRequested(
          request: _pending,
          reviewComment: 'Missing info',
        ),
      ),
      expect: () => [
        isA<MembershipRequestsLoaded>().having(
          (s) => s.actionInProgress,
          'actionInProgress',
          true,
        ),
        isA<MembershipRequestsLoaded>()
            .having((s) => s.actionInProgress, 'actionInProgress', false)
            .having(
              (s) => s.actionError,
              'actionError',
              "La synchronisation a échoué. La demande reste en attente de synchronisation.",
            ),
      ],
    );

    blocTest<MembershipRequestsBloc, MembershipRequestsState>(
      'emits actionError when repository rejects a stale request',
      setUp: () => when(
        () => repo.reject(_pending, reviewComment: null),
      ).thenThrow(StateError('stale')),
      build: () => MembershipRequestsBloc(
        organizationId: 'org-1',
        memberJoinRequestRepository: repo,
        syncRepository: syncRepository,
      ),
      seed: () => MembershipRequestsState.loaded(requests: [_pending]),
      act: (bloc) =>
          bloc.add(MembershipRequestsEvent.rejectRequested(request: _pending)),
      expect: () => [
        isA<MembershipRequestsLoaded>().having(
          (s) => s.actionInProgress,
          'actionInProgress',
          true,
        ),
        isA<MembershipRequestsLoaded>()
            .having((s) => s.actionInProgress, 'actionInProgress', false)
            .having(
              (s) => s.actionError,
              'actionError',
              'Cette demande a déjà été traitée.',
            ),
      ],
    );
  });
}
