import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_display.dart';
import 'package:flutter/material.dart';
import 'package:amap_en_ligne/presentation/common/open_url_stub.dart'
    if (dart.library.js_interop) 'package:amap_en_ligne/presentation/common/open_url_web.dart'
    if (dart.library.io) 'package:amap_en_ligne/presentation/common/open_url_native.dart';

/// Compact single-line coordinator display: "👥 Coord. : J. Morel 📞 06… · —".
///
/// Abbreviated names per contract, separated by " · "; when [Member.phone] is
/// set the number is rendered as a tappable `tel:` link via [PhoneLink] — the
/// same interaction offered by [CoordinatorsSection] on the planning and
/// delivery-tracking screens (a missing phone is silently omitted to stay
/// compact).
class CompactCoordinatorsLine extends StatelessWidget {
  const CompactCoordinatorsLine({
    required this.delivery,
    required this.membersById,
    super.key,
  });

  final Delivery delivery;
  final Map<String, Member> membersById;

  @override
  Widget build(BuildContext context) {
    if (delivery.contracts.isEmpty) return const SizedBox.shrink();

    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );

    final spans = <InlineSpan>[
      TextSpan(text: '👥 Coord. : ', style: baseStyle),
    ];
    var firstContract = true;
    for (final contract in delivery.contracts) {
      if (!firstContract) spans.add(TextSpan(text: ' · ', style: baseStyle));
      firstContract = false;

      final coordinators = contract.coordinators
          .map((id) => membersById[id])
          .whereType<Member>()
          .toList();
      if (coordinators.isEmpty) {
        spans.add(TextSpan(text: '—', style: baseStyle));
        continue;
      }

      var firstCoordinator = true;
      for (final coordinator in coordinators) {
        if (!firstCoordinator) {
          spans.add(TextSpan(text: ', ', style: baseStyle));
        }
        firstCoordinator = false;
        spans.add(
          TextSpan(text: abbreviateMemberName(coordinator), style: baseStyle),
        );
        final phone = coordinator.phone?.trim();
        if (phone != null && phone.isNotEmpty) {
          spans.add(const TextSpan(text: ' '));
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: PhoneLink(phone: phone),
            ),
          );
        }
      }
    }

    return Text.rich(TextSpan(children: spans));
  }
}

/// Detailed "👥 Coordinateurs :" section: one sub-row per [DeliveryContract],
/// showing coordinator name + tel: link (when [Member.phone] is set) or
/// "(téléphone non communiqué)", or "Coordinateur à confirmer" when no
/// coordinator is assigned.
class CoordinatorsSection extends StatelessWidget {
  const CoordinatorsSection({
    required this.delivery,
    required this.membersById,
    super.key,
  });

  final Delivery delivery;
  final Map<String, Member> membersById;

  @override
  Widget build(BuildContext context) {
    if (delivery.contracts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👥 Coordinateurs :',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          for (final contract in delivery.contracts)
            _ContractCoordinatorRow(
              contract: contract,
              membersById: membersById,
            ),
        ],
      ),
    );
  }
}

class _ContractCoordinatorRow extends StatelessWidget {
  const _ContractCoordinatorRow({
    required this.contract,
    required this.membersById,
  });

  final DeliveryContract contract;
  final Map<String, Member> membersById;

  @override
  Widget build(BuildContext context) {
    final description = contract.deliveryDescription;
    final resolvedCoordinators = contract.coordinators
        .map((id) => membersById[id])
        .whereType<Member>()
        .toList();

    if (resolvedCoordinators.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          '$description — Coordinateur à confirmer',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final coordinator in resolvedCoordinators)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text(
                  '$description — ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  displayMemberName(coordinator),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_hasPhone(coordinator)) ...[
                  Text(' • ', style: Theme.of(context).textTheme.bodySmall),
                  PhoneLink(phone: coordinator.phone!.trim()),
                ] else ...[
                  Text(
                    ' • (téléphone non communiqué)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  bool _hasPhone(Member member) {
    final phone = member.phone?.trim();
    return phone != null && phone.isNotEmpty;
  }
}

/// Renders a phone number as a tappable tel: link.
class PhoneLink extends StatelessWidget {
  const PhoneLink({required this.phone, super.key});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openUrl('tel:$phone'),
      child: Text(
        '📞 $phone',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
