import 'package:amap_en_ligne/data/sync/handlers/delivery_template_sync_handler.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const handler = DeliveryTemplateSyncHandler();

  Organization organization({String? defaultTemplateId, String? templateId}) =>
      Organization(
        organizationId: 'org-1',
        name: 'AMAP',
        contactEmail: 'amap@example.com',
        defaultDeliveryTemplateId: defaultTemplateId,
        deliveries: [
          Delivery(
            deliveryId: 'd-1',
            organizationId: 'org-1',
            scheduledDate: '2026-10-01T18:00:00',
            status: DeliveryStatus.planned,
            minVolunteersRequired: 1,
            deliveryTemplateId: templateId,
          ),
        ],
      );

  ClientMutation orgUpsert(Organization org) => ClientMutation(
    clientOpId: 'op-1',
    op: Upsert(payload: OrganizationPayload(organization: org)),
  );

  group('DeliveryTemplateSyncHandler.rewriteMutationReference', () {
    test('rewrites the default template and delivery references of a queued '
        'organization upsert', () {
      final rewritten = handler.rewriteMutationReference(
        orgUpsert(
          organization(defaultTemplateId: 'tmp_1', templateId: 'tmp_1'),
        ),
        oldId: 'tmp_1',
        newId: 'dt-real',
      );

      final org = ((rewritten.op as Upsert).payload as OrganizationPayload)
          .organization;
      expect(org.defaultDeliveryTemplateId, 'dt-real');
      expect(org.deliveries.single.deliveryTemplateId, 'dt-real');
    });

    test('leaves an organization upsert without reference untouched', () {
      final mutation = orgUpsert(
        organization(defaultTemplateId: 'dt-other', templateId: 'dt-other'),
      );

      expect(
        handler.rewriteMutationReference(
          mutation,
          oldId: 'tmp_1',
          newId: 'dt-real',
        ),
        same(mutation),
      );
    });
  });
}
