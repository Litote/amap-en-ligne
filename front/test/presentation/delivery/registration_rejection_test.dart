import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/delivery/registration_rejection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MutationOutcome rejected(MutationErrorCode code) => MutationOutcome(
    clientOpId: 'op-1',
    status: MutationStatus.rejected,
    error: MutationError(code: code, message: 'refused'),
  );

  group('registrationRejectionMessage', () {
    test('GIVEN the slot was filled since the member saw it (CONFLICT) '
        'THEN says so and invites to pick another one', () {
      expect(
        registrationRejectionMessage([rejected(MutationErrorCode.conflict)]),
        'Ce créneau vient d\'être complété. Choisissez-en un autre.',
      );
    });

    test('GIVEN any other refusal THEN the generic message is kept', () {
      expect(
        registrationRejectionMessage([rejected(MutationErrorCode.forbidden)]),
        "L'inscription n'a pas pu être enregistrée. Réessayez.",
      );
    });
  });
}
