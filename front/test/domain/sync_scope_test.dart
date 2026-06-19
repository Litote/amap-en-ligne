import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/admin_organization_request.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scopeKeyForPayload', () {
    test('covers every payload type', () {
      expect(
        scopeKeyForPayload(
          ProductTypePayload(
            productType: const ProductType(
              productTypeId: 'pt-1',
              producerAccountId: 'producer-1',
              name: 'Vegetables',
              supportedBasketSizes: [],
            ),
          ),
        ),
        producerAccountScopeKey('producer-1'),
      );
      expect(
        scopeKeyForPayload(
          OrganizationPayload(
            organization: const Organization(
              organizationId: 'org-1',
              name: 'AMAP',
              contactEmail: 'contact@amap.fr',
            ),
          ),
        ),
        organizationScopeKey('org-1'),
      );
      expect(
        scopeKeyForPayload(
          ProducerAccountPayload(
            producerAccount: const ProducerAccount(
              producerAccountId: 'producer-1',
              name: 'Ferme',
            ),
          ),
        ),
        producerAccountScopeKey('producer-1'),
      );
      expect(
        scopeKeyForPayload(
          MemberPayload(
            member: const Member(memberId: 'member-1', organizationId: 'org-1'),
          ),
        ),
        organizationScopeKey('org-1'),
      );
      expect(
        scopeKeyForPayload(
          const MemberJoinRequestPayload(
            memberJoinRequest: AdminMemberJoinRequest(
              requestId: 'req-1',
              organizationId: 'org-1',
              email: 'alice@example.org',
              firstName: 'Alice',
              lastName: 'Martin',
              status: MemberJoinRequestStatus.pending,
              submittedAt: '2026-01-01T00:00:00Z',
            ),
          ),
        ),
        organizationScopeKey('org-1'),
      );
      expect(
        scopeKeyForPayload(
          ContractPayload(
            contract: const Contract(
              contractId: 'contract-1',
              name: 'Contrat test',
              organizationId: 'org-1',
              producerAccountId: 'producer-1',
              minDeliveryDate: '2026-01-01',
              maxDeliveryDate: '2026-12-31',
              deliveryCount: 1,
              seasonYear: 2026,
            ),
          ),
        ),
        organizationScopeKey('org-1'),
      );
      expect(
        scopeKeyForPayload(
          DeliveryTemplatePayload(
            deliveryTemplate: const DeliveryTemplate(
              deliveryTemplateId: 'dt-1',
              organizationId: 'org-1',
              name: 'Vendredi',
              standardStartTime: '18:00',
              standardEndTime: '19:00',
            ),
          ),
        ),
        organizationScopeKey('org-1'),
      );
      expect(
        scopeKeyForPayload(
          OrganizationRequestPayload(
            organizationRequest: const AdminOrganizationRequest(
              requestId: 'req-1',
              organizationName: 'AMAP',
              organizationType: OrganizationType.amap,
              timezone: 'Europe/Paris',
              defaultLanguage: 'fr',
              adminFirstName: 'Alice',
              adminLastName: 'Martin',
              adminEmail: 'alice@example.com',
              status: OrganizationRequestStatus.pendingValidation,
              submittedAt: '2026-01-01T00:00:00Z',
            ),
          ),
        ),
        instanceOwnerScopeKey,
      );
      expect(
        scopeKeyForPayload(
          const ProducerRequestPayload(
            producerRequest: AdminProducerRequest(
              requestId: 'producer-req-1',
              producerName: 'Ferme',
              adminFirstName: 'Alice',
              adminLastName: 'Martin',
              adminEmail: 'alice@example.com',
              status: ProducerRequestStatus.pendingValidation,
              submittedAt: '2026-01-01T00:00:00Z',
            ),
          ),
        ),
        instanceOwnerScopeKey,
      );
      expect(
        scopeKeyForPayload(
          OwnerPayload(
            owner: const Owner(
              ownerId: 'owner-1',
              firstName: 'Alice',
              lastName: 'Martin',
              email: 'alice@example.com',
              accountStatus: AccountStatus.active,
              registeredAt: '2026-01-01T00:00:00Z',
              updatedAt: '2026-01-01T00:00:00Z',
            ),
          ),
        ),
        instanceOwnerScopeKey,
      );
      expect(
        scopeKeyForPayload(
          MemberInvitationPayload(
            memberInvitation: const MemberInvitation(
              invitationId: 'inv-1',
              organizationId: 'org-1',
              email: 'alice@example.org',
              firstName: 'Alice',
              lastName: 'Martin',
              roles: {Role.admin},
              status: InvitationStatus.pendingActivation,
              createdAt: '2026-01-01T00:00:00Z',
              expiresAt: '2026-01-08T00:00:00Z',
            ),
          ),
        ),
        organizationScopeKey('org-1'),
      );
      expect(
        scopeKeyForPayload(
          OwnerInvitationPayload(
            ownerInvitation: const OwnerInvitation(
              invitationId: 'inv-2',
              firstName: 'Jean',
              lastName: 'Dupont',
              email: 'jean@example.fr',
              status: InvitationStatus.pendingActivation,
              submittedAt: '2026-01-01T00:00:00Z',
            ),
          ),
        ),
        instanceOwnerScopeKey,
      );
    });
  });

  group('scopeKeyForMutation', () {
    test('resolves intrinsic delete scopes for legacy mutations', () {
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-org',
            op: Delete(entityType: EntityType.organization, entityId: 'org-1'),
          ),
        ),
        organizationScopeKey('org-1'),
      );
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-producer',
            op: Delete(
              entityType: EntityType.producerAccount,
              entityId: 'producer-1',
            ),
          ),
        ),
        producerAccountScopeKey('producer-1'),
      );
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-owner',
            op: Delete(entityType: EntityType.owner, entityId: 'owner-1'),
          ),
        ),
        instanceOwnerScopeKey,
      );
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-producer-request',
            op: Delete(
              entityType: EntityType.producerRequest,
              entityId: 'producer-req-1',
            ),
          ),
        ),
        instanceOwnerScopeKey,
      );
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-owner-invitation',
            op: Delete(
              entityType: EntityType.ownerInvitation,
              entityId: 'inv-1',
            ),
          ),
        ),
        instanceOwnerScopeKey,
      );
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-request',
            op: Delete(
              entityType: EntityType.organizationRequest,
              entityId: 'req-1',
            ),
          ),
        ),
        instanceOwnerScopeKey,
      );
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-member',
            op: Delete(entityType: EntityType.member, entityId: 'member-1'),
          ),
        ),
        isNull,
      );
      expect(
        scopeKeyForMutation(
          const ClientMutation(
            clientOpId: 'op-member-join',
            op: Delete(
              entityType: EntityType.memberJoinRequest,
              entityId: 'req-1',
            ),
          ),
        ),
        isNull,
      );
    });
  });
}
