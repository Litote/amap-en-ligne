@Tags(['acceptance'])
library;

import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _coordinatorToken = String.fromEnvironment('COORDINATOR_TOKEN');
const _memberToken = String.fromEnvironment('MEMBER_TOKEN');
const _organizationId = String.fromEnvironment('ORGANIZATION_ID');
const _memberSub = String.fromEnvironment('MEMBER_SUB');

const _deliveryId = 'delivery-e2e-slot-cancel';
const _contractId = 'contract-e2e-slot-cancel';
const _slotId = 'slot-e2e-1';

class _StaticTokenAuthService implements AuthService {
  const _StaticTokenAuthService(this.token);

  final String token;

  AuthState get _state =>
      AuthState.authenticated(producerId: _organizationId, accessToken: token);

  @override
  Stream<AuthState> get authState => Stream.value(_state);

  @override
  AuthState get currentState => _state;

  @override
  Future<void> bootstrap() async {}

  @override
  Future<String?> currentAccessToken() async => token;

  @override
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  }) async {}

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<void> signInWithSession({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? rememberSession,
  }) async {}

  @override
  Future<void> refreshSession() async {}
}

Delivery _buildDelivery({required MemberSlot slot}) => Delivery(
  deliveryId: _deliveryId,
  organizationId: _organizationId,
  scheduledDate: '2099-06-15T18:00:00',
  status: DeliveryStatus.planned,
  minVolunteersRequired: 2,
  contracts: [
    DeliveryContract(
      contractId: _contractId,
      coordinators: const ['coordinator-1'],
      basketQuantity: 10,
      deliveryDescription: 'Weekly basket',
      status: DeliveryContractStatus.pending,
      slots: [slot],
    ),
  ],
);

MemberSlot _buildSlot({
  required SlotStatus status,
  required List<MemberRegistration> registrations,
}) => MemberSlot(
  slotId: _slotId,
  startTime: '2099-06-15T18:00:00',
  endTime: '2099-06-15T20:00:00',
  activityType: ActivityType.reception,
  requiredVolunteers: 2,
  currentRegistrations: registrations.length,
  status: status,
  slotKind: SlotKind.standard,
  registrations: registrations,
);

void main() {
  final skip =
      _backUrl.isEmpty ||
          _coordinatorToken.isEmpty ||
          _memberToken.isEmpty ||
          _organizationId.isEmpty ||
          _memberSub.isEmpty
      ? 'BACK_URL / COORDINATOR_TOKEN / MEMBER_TOKEN / ORGANIZATION_ID / '
            'MEMBER_SUB not set'
      : false;

  setUpAll(() {
    // Two AppDatabase instances per test (coordinator + member devices), each
    // on its own in-memory executor — the multi-database warning is noise.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('cross-component time slot cancellation', () {
    late AppDatabase coordinatorDb;
    late AppDatabase memberDb;
    late SyncRepository coordinatorSync;
    late SyncRepository memberSync;
    late OrganizationRepository coordinatorOrgRepo;

    setUp(() {
      coordinatorDb = AppDatabase(NativeDatabase.memory());
      memberDb = AppDatabase(NativeDatabase.memory());
      coordinatorSync = SyncRepository(
        db: coordinatorDb,
        api: SyncApi(
          buildSyncDio(
            backendUrl: _backUrl,
            auth: const _StaticTokenAuthService(_coordinatorToken),
          ),
        ),
      );
      memberSync = SyncRepository(
        db: memberDb,
        api: SyncApi(
          buildSyncDio(
            backendUrl: _backUrl,
            auth: const _StaticTokenAuthService(_memberToken),
          ),
        ),
      );
      coordinatorOrgRepo = OrganizationRepository(
        db: coordinatorDb,
        idGenerator: IdGenerator(Random(0)),
      );
    });

    tearDown(() async {
      await coordinatorDb.close();
      await memberDb.close();
    });

    test(
      'coordinator cancels a slot; the member sees it cancelled and receives '
      'the SLOT_CANCELLED notification',
      () async {
        final registration = MemberRegistration(
          memberId: _memberSub,
          displayName: 'Alice Volunteer',
          memberEmail: 'alice@test.invalid',
          registrationInstant: '2099-06-01T10:00:00Z',
          status: RegistrationStatus.registered,
        );

        // 1. Coordinator bootstraps the org scope.
        final bootstrap = await coordinatorSync.sync(tenantId: _organizationId);
        expect(bootstrap, isA<SyncSuccess>());
        var initialOrg = await coordinatorDb
            .watchOrganization(_organizationId)
            .first;
        expect(initialOrg, isNotNull);

        // 1.5 Re-runnable against a persistent backend: drop the leftover
        // delivery from a previous run — the back rejects duplicate scheduled
        // dates per organization and forbids reopening a cancelled slot.
        // Cancel the slot first so the delete guard (active registrations ⇒
        // CONFLICT) cannot trigger on a half-cleaned previous run.
        if (initialOrg!.deliveries.any((d) => d.deliveryId == _deliveryId)) {
          await coordinatorOrgRepo.updateDelivery(
            currentOrg: initialOrg,
            delivery: _buildDelivery(
              slot: _buildSlot(
                status: SlotStatus.cancelled,
                registrations: [registration],
              ),
            ),
          );
          final cancelLeftover = await coordinatorSync.sync(
            tenantId: _organizationId,
          );
          expect(cancelLeftover, isA<SyncSuccess>());
          expect((cancelLeftover as SyncSuccess).rejectedMutations, isEmpty);

          final orgWithLeftover = await coordinatorDb
              .watchOrganization(_organizationId)
              .first;
          await coordinatorOrgRepo.deleteDelivery(
            currentOrg: orgWithLeftover!,
            deliveryId: _deliveryId,
          );
          final cleanupOutcome = await coordinatorSync.sync(
            tenantId: _organizationId,
          );
          expect(cleanupOutcome, isA<SyncSuccess>());
          expect((cleanupOutcome as SyncSuccess).rejectedMutations, isEmpty);

          initialOrg = await coordinatorDb
              .watchOrganization(_organizationId)
              .first;
        }

        // 2. Coordinator creates the delivery with a registered slot.
        await coordinatorOrgRepo.addDelivery(
          currentOrg: initialOrg!,
          delivery: _buildDelivery(
            slot: _buildSlot(
              status: SlotStatus.open,
              registrations: [registration],
            ),
          ),
        );
        final createOutcome = await coordinatorSync.sync(
          tenantId: _organizationId,
        );
        expect(createOutcome, isA<SyncSuccess>());
        expect((createOutcome as SyncSuccess).rejectedMutations, isEmpty);

        // 3. Coordinator cancels the slot WITHOUT cascading the registrations
        //    locally — the server-side cascade is the behaviour under test.
        final orgBeforeCancel = await coordinatorDb
            .watchOrganization(_organizationId)
            .first;
        await coordinatorOrgRepo.updateDelivery(
          currentOrg: orgBeforeCancel!,
          delivery: _buildDelivery(
            slot: _buildSlot(
              status: SlotStatus.cancelled,
              registrations: [registration],
            ),
          ),
        );
        final cancelOutcome = await coordinatorSync.sync(
          tenantId: _organizationId,
        );
        expect(cancelOutcome, isA<SyncSuccess>());
        expect((cancelOutcome as SyncSuccess).rejectedMutations, isEmpty);

        // The coordinator cache reflects the server-side cascade.
        final orgAfterCancel = await coordinatorDb
            .watchOrganization(_organizationId)
            .first;
        final coordinatorSlot = orgAfterCancel!.deliveries
            .singleWhere((d) => d.deliveryId == _deliveryId)
            .contracts
            .single
            .slots
            .single;
        expect(coordinatorSlot.status, SlotStatus.cancelled);
        expect(coordinatorSlot.currentRegistrations, 0);
        expect(
          coordinatorSlot.registrations.every(
            (r) => r.status == RegistrationStatus.cancelled,
          ),
          isTrue,
        );

        // 4. The member bootstraps and sees the cancelled slot.
        final memberOutcome = await memberSync.sync(tenantId: _organizationId);
        expect(memberOutcome, isA<SyncSuccess>());
        final memberOrg = await memberDb
            .watchOrganization(_organizationId)
            .first;
        final memberSlot = memberOrg!.deliveries
            .singleWhere((d) => d.deliveryId == _deliveryId)
            .contracts
            .single
            .slots
            .single;
        expect(memberSlot.status, SlotStatus.cancelled);
        expect(
          memberSlot.registrations.every(
            (r) => r.status == RegistrationStatus.cancelled,
          ),
          isTrue,
        );

        // 5. The member received the SLOT_CANCELLED notification on their
        //    private feed (member:{sub}).
        final notifications = await memberDb
            .watchNotifications(memberScopeKey(_memberSub))
            .first;
        final slotCancelled = notifications.where(
          (n) => n.category == NotificationCategory.slotCancelled,
        );
        expect(
          slotCancelled,
          isNotEmpty,
          reason:
              'expected a SLOT_CANCELLED notification on '
              '${memberScopeKey(_memberSub)}, got '
              '${notifications.map((n) => n.category).toList()}',
        );
        expect(slotCancelled.first.type, NotificationType.alert);
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}
