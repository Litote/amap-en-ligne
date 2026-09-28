import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';

/// Display name of a delivery↔contract [link]: the live [Contract.name] found
/// in [contracts] by id, falling back to the link's denormalised
/// [DeliveryContract.deliveryDescription] snapshot (stale after a rename, and
/// blank on imported or legacy links). Empty when neither names it.
String deliveryContractName(
  DeliveryContract link,
  Iterable<Contract> contracts,
) {
  for (final contract in contracts) {
    if (contract.contractId == link.contractId &&
        contract.name.trim().isNotEmpty) {
      return contract.name;
    }
  }
  return link.deliveryDescription;
}
