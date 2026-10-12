import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';

/// The message shown when the back refuses a volunteer (un)registration.
///
/// A CONFLICT means the slot was filled by someone else since the member saw
/// it (the back checks the capacity on the stored state): say so, so they pick
/// another slot instead of retrying the same one.
String registrationRejectionMessage(List<MutationOutcome> rejected) =>
    rejected.any((m) => m.error?.code == MutationErrorCode.conflict)
    ? "Ce créneau vient d'être complété. Choisissez-en un autre."
    : "L'inscription n'a pas pu être enregistrée. Réessayez.";
