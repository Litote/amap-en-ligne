import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProducerCreationRequest', () {
    test('toJson produces correct snake_case keys', () {
      final request = const ProducerCreationRequest(
        producerName: 'Ferme des Collines',
        adminFirstName: 'Alice',
        adminLastName: 'Martin',
        adminEmail: 'alice@example.fr',
      );
      final json = request.toJson();
      expect(json['producer_name'], 'Ferme des Collines');
      expect(json['admin_first_name'], 'Alice');
      expect(json['admin_last_name'], 'Martin');
      expect(json['admin_email'], 'alice@example.fr');
    });
  });

  group('ProducerRequestResponse', () {
    test('fromJson decodes request_id and status', () {
      final response = ProducerRequestResponse.fromJson({
        'request_id': 'producer-req-1',
        'status': 'PENDING_VALIDATION',
      });
      expect(response.requestId, 'producer-req-1');
      expect(response.status, 'PENDING_VALIDATION');
    });
  });

  group('AdminProducerRequest', () {
    test('round-trip preserves reviewed_at and review_comment', () {
      const request = AdminProducerRequest(
        requestId: 'req-1',
        producerName: 'Ferme des Collines',
        adminFirstName: 'Alice',
        adminLastName: 'Martin',
        adminEmail: 'alice@example.fr',
        status: ProducerRequestStatus.rejected,
        submittedAt: '2026-05-07T10:00:00Z',
        reviewedAt: '2026-05-08T10:00:00Z',
        reviewComment: 'Dossier incomplet',
      );

      final decoded = AdminProducerRequest.fromJson(request.toJson());
      expect(decoded.status, ProducerRequestStatus.rejected);
      expect(decoded.reviewedAt, '2026-05-08T10:00:00Z');
      expect(decoded.reviewComment, 'Dossier incomplet');
    });
  });
}
