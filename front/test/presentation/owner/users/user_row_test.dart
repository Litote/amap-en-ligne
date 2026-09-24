import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userRowFromProducerAccount', () {
    test('an approved producer that has not activated yet is pending', () {
      const producer = ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Ferme Test',
        pendingActivation: true,
      );

      expect(
        userRowFromProducerAccount(producer).displayStatus,
        UserDisplayStatus.pendingInvitation,
      );
    });

    test('an activated producer is active, a suspended one suspended', () {
      const producer = ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Ferme Test',
      );

      expect(
        userRowFromProducerAccount(producer).displayStatus,
        UserDisplayStatus.active,
      );
      expect(
        userRowFromProducerAccount(
          producer.copyWith(activeStatus: false),
        ).displayStatus,
        UserDisplayStatus.suspended,
      );
    });
  });
}
