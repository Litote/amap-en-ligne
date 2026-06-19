import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/domain/model/shared_basket_view.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_display.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_coordinators.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_registration_actions.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Which screen the card is rendered on. Drives the copy, ordering and
/// coordinator style differences mandated by the respective UI specs.
enum DeliveryCardVariant {
  /// Monthly planning screen (screen-member-02): full month label, detailed
  /// coordinators with tel: links, rich volunteer counter, optional edit button.
  planning,

  /// Home dashboard "Prochaines livraisons" list (screen-member-01): abbreviated
  /// label, compact coordinators line, simple counter.
  dashboard,
}

/// Shared card rendering a single [Delivery] with volunteer
/// registration/unregistration actions.
///
/// Centralises the date/capacity/registration logic that was previously
/// duplicated between `member_delivery_plan_screen.dart` and
/// `volunteer_dashboard_section.dart`. The per-variant differences (copy,
/// ordering, coordinator style) follow each screen's UI spec.
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    required this.delivery,
    required this.member,
    required this.org,
    required this.membersById,
    required this.variant,
    this.template,
    this.pendingContractActivation = false,
    this.showEditButton = false,
    this.highlightAsNextParticipation = false,
    this.contracts = const [],
    super.key,
  });

  final Delivery delivery;
  final Member member;
  final Organization org;

  /// The org's contracts, used to resolve shared-basket alternation (whose turn it is to pick up
  /// a shared basket on this delivery). Empty ⇒ no shared-basket line is shown.
  final List<Contract> contracts;

  /// All AMAP members, used to resolve coordinator names/phones.
  final Map<String, Member> membersById;

  final DeliveryCardVariant variant;
  final DeliveryTemplate? template;

  /// True when every linked contract is still IN_PREPARATION (planning only):
  /// the card is flagged "Contrat inactif" and offers no registration action.
  final bool pendingContractActivation;

  /// Planning only: shows the "Modifier" button routing to time-slot edition.
  final bool showEditButton;

  /// Dashboard only: when the card is the highlighted "Ma prochaine
  /// participation" entry (the member is always registered there), the
  /// volunteer counter reads "N/M bénévoles confirmés" per
  /// screen-member-01-home.md.
  final bool highlightAsNextParticipation;

  @override
  Widget build(BuildContext context) {
    final state = _DeliveryCardState.from(delivery);
    final children = switch (variant) {
      DeliveryCardVariant.planning => _planningChildren(context, state),
      DeliveryCardVariant.dashboard => _dashboardChildren(context, state),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Planning variant
  // -------------------------------------------------------------------------

  List<Widget> _planningChildren(
    BuildContext context,
    _DeliveryCardState state,
  ) {
    final memberId = member.memberId;
    final date = DateTime.parse(delivery.scheduledDate);
    final isPast = date.isBefore(DateTime.now());
    final dateLabel = formatDeliveryDateLine(
      delivery.scheduledDate,
      longMonth: true,
    );
    final alreadyRegistered = isRegisteredOn(delivery, memberId);
    final isCompleted = delivery.status == DeliveryStatus.completed;
    final isCancelled = delivery.status == DeliveryStatus.cancelled;

    final productNames = org.productNamesForDelivery(delivery);

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '📅 $dateLabel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (showEditButton)
            TextButton.icon(
              onPressed: () => context.push(
                '/coordinator/time-slots/${delivery.deliveryId}',
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Modifier'),
            ),
        ],
      ),
      if (productNames.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          'Produits : ${productNames.join(' + ')}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
      ..._sharedBasketLines(context),
      const SizedBox(height: 6),
      if (isCancelled) ...[
        const Text('❌ ANNULÉ'),
      ] else if (pendingContractActivation) ...[
        Text(
          '🚧 Contrat inactif',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        _planningCounter(context, state),
      ] else if (isCompleted && alreadyRegistered) ...[
        const Text('✅ TERMINÉ - Vous avez participé'),
        const SizedBox(height: 4),
        _planningCounter(context, state, completed: true),
      ] else if (isCompleted) ...[
        const Text('✅ TERMINÉ'),
        const SizedBox(height: 4),
        _planningCounter(context, state, completed: true),
      ] else if (alreadyRegistered) ...[
        Text(
          '✅ Vous êtes inscrit(e) comme bénévole',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        _planningCounter(context, state),
        const SizedBox(height: 8),
        UnregisterButton(delivery: delivery, memberId: memberId, org: org),
      ] else if (state.allSlotsCancelled) ...[
        Text(
          'Créneau annulé',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).disabledColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        const OutlinedButton(onPressed: null, child: Text('❌ Créneau annulé')),
      ] else if (!isPast) ...[
        _planningUrgencyBadge(context, state),
        const SizedBox(height: 4),
        _planningCounter(context, state),
        const SizedBox(height: 8),
        _planningRegistrationActions(context, state),
      ] else ...[
        _planningCounter(context, state),
      ],
      CoordinatorsSection(delivery: delivery, membersById: membersById),
      BasketCompositionSection(delivery: delivery, org: org),
    ];
  }

  /// For each contract linked to this delivery in which [member] shares a basket, a line stating
  /// whether it is the member's turn to pick it up this week or a co-sharer's.
  List<Widget> _sharedBasketLines(BuildContext context) {
    if (contracts.isEmpty) return const [];
    final theme = Theme.of(context);
    final lines = <Widget>[];
    final linkedContractIds = delivery.contracts.map((c) => c.contractId).toSet();
    for (final contract in contracts) {
      if (!linkedContractIds.contains(contract.contractId)) continue;
      final basket = sharedBasketForMember(contract, member.memberId);
      if (basket == null) continue;
      final ordered = contractDeliveriesOrdered(org, contract.contractId);
      final picker = sharedBasketPickerFor(
        basket,
        ordered,
        delivery.deliveryId,
      );
      if (picker == null) continue;
      final mine = picker == member.memberId;
      final pickerName = membersById[picker];
      lines.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            mine
                ? '🤝 Panier partagé : c\'est votre tour de récupérer le panier.'
                : '🤝 Panier partagé : récupéré par '
                      '${pickerName != null ? displayMemberName(pickerName) : 'une autre famille'} '
                      'cette semaine.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: mine ? FontWeight.w600 : FontWeight.normal,
              color: mine ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      );
    }
    return lines;
  }

  Widget _planningCounter(
    BuildContext context,
    _DeliveryCardState state, {
    bool completed = false,
  }) {
    final required = state.totalRequired;
    final current = state.totalCurrent;
    if (required == 0) return const SizedBox.shrink();
    final missing = required - current;
    final String text;
    if (current >= required) {
      text = '👥 $current/$required bénévoles ─ COMPLET';
    } else if (missing == 1) {
      text = '👥 $current/$required bénévoles ─ 1 place restante';
    } else if (missing <= (required / 2).ceil() && !completed) {
      text = '👥 $current/$required bénévoles ─ $missing places restantes';
    } else {
      text = '👥 $current/$required bénévoles ─ Manque $missing personnes';
    }
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }

  Widget _planningUrgencyBadge(BuildContext context, _DeliveryCardState state) {
    if (state.hasEarlyCapacity) {
      final remaining = state.earlyRemaining;
      return Tooltip(
        message:
            'Un créneau anticipé permet aux bénévoles de s\'inscrire '
            'plus tôt que prévu pour aider à préparer la distribution.',
        child: Text(
          '⏰ Créneau anticipé disponible '
          '($remaining place${remaining > 1 ? 's' : ''} '
          'restante${remaining > 1 ? 's' : ''})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      );
    }
    final required = state.totalRequired;
    if (required == 0) return const SizedBox.shrink();
    final rate = state.totalCurrent / required;
    if (rate >= 0.8) return const SizedBox.shrink();
    if (rate >= 0.5) {
      return Text(
        '⚠️ Attention - Places limitées',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.orange.shade700),
      );
    }
    return Text(
      '🔴 BESOIN URGENT DE BÉNÉVOLES',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _planningRegistrationActions(
    BuildContext context,
    _DeliveryCardState state,
  ) {
    if (!state.hasStandardCapacity && !state.hasEarlyCapacity) {
      final isActuallyFull =
          state.totalRequired > 0 && state.totalCurrent >= state.totalRequired;
      if (!isActuallyFull) return const SizedBox.shrink();
      return Text(
        '✅ COMPLET',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (state.hasEarlyCapacity && state.hasStandardCapacity) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choisissez votre créneau :'),
          const SizedBox(height: 6),
          RegisterButton(
            delivery: delivery,
            slotKind: SlotKind.standard,
            member: member,
            org: org,
            label: _planningStandardLabel(state),
          ),
          const SizedBox(height: 6),
          RegisterButton(
            delivery: delivery,
            slotKind: SlotKind.early,
            member: member,
            org: org,
            label: _planningEarlyLabel(state),
          ),
          _planningExplanationRow(context),
        ],
      );
    }

    final isUrgent =
        state.totalRequired > 0 &&
        (state.totalCurrent / state.totalRequired) < 0.5;
    return RegisterButton(
      delivery: delivery,
      slotKind: SlotKind.standard,
      member: member,
      org: org,
      label: isUrgent ? "S'INSCRIRE MAINTENANT 🚨" : "S'INSCRIRE",
    );
  }

  String _planningStandardLabel(_DeliveryCardState state) {
    final slot = state.standardSlot;
    if (slot == null) return "S'INSCRIRE";
    return "S'inscrire • Créneau standard "
        '${formatSlotTime(slot.startTime)}-${formatSlotTime(slot.endTime)}';
  }

  String _planningEarlyLabel(_DeliveryCardState state) {
    final slot = state.earlySlot;
    if (slot == null) return "S'inscrire • Créneau anticipé";
    return "S'inscrire • Créneau anticipé "
        '${formatSlotTime(slot.startTime)}-${formatSlotTime(slot.endTime)}';
  }

  /// Returns the resolved explanation for the early slot, or null when absent
  /// or blank (delivery override takes priority over the template).
  String? _resolvedExplanation() {
    final fromDelivery = delivery.earlySlot?.explanation?.trim();
    if (fromDelivery != null && fromDelivery.isNotEmpty) return fromDelivery;
    final fromTemplate = template?.earlySlot?.explanation?.trim();
    if (fromTemplate != null && fromTemplate.isNotEmpty) return fromTemplate;
    return null;
  }

  Widget _planningExplanationRow(BuildContext context) {
    final explanation = _resolvedExplanation();
    if (explanation == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'ℹ️ $explanation',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _dashboardExplanationRow(BuildContext context) {
    final explanation = _resolvedExplanation();
    if (explanation == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        explanation,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Dashboard variant
  // -------------------------------------------------------------------------

  List<Widget> _dashboardChildren(
    BuildContext context,
    _DeliveryCardState state,
  ) {
    final memberId = member.memberId;
    final alreadyRegistered = isRegisteredOn(delivery, memberId);
    final dateLabel = formatDeliveryDateLine(
      delivery.scheduledDate,
      slotEndTime: state.standardSlot?.endTime,
    );
    final urgencyBadge = alreadyRegistered
        ? null
        : _dashboardUrgencyBadge(context, state);

    return [
      Text(
        '📅 $dateLabel',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      if (urgencyBadge != null) ...[const SizedBox(height: 4), urgencyBadge],
      const SizedBox(height: 4),
      Text(
        '👥 ${state.totalCurrent}/${state.totalRequired} bénévoles'
        '${highlightAsNextParticipation ? ' confirmés' : ''}',
      ),
      const SizedBox(height: 4),
      CompactCoordinatorsLine(delivery: delivery, membersById: membersById),
      const SizedBox(height: 8),
      if (alreadyRegistered) ...[
        Text(
          '✅ Inscrit(e)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        UnregisterButton(delivery: delivery, memberId: memberId, org: org),
      ] else if (!state.hasStandardCapacity && !state.hasEarlyCapacity) ...[
        OutlinedButton(onPressed: null, child: const Text('✅ COMPLET')),
      ] else if (state.hasEarlyCapacity && state.hasStandardCapacity) ...[
        RegisterButton(
          delivery: delivery,
          slotKind: SlotKind.standard,
          member: member,
          org: org,
          label: _dashboardStandardLabel(state),
        ),
        const SizedBox(height: 4),
        RegisterButton(
          delivery: delivery,
          slotKind: SlotKind.early,
          member: member,
          org: org,
          label: _dashboardEarlyLabel(state),
        ),
        _dashboardExplanationRow(context),
      ] else ...[
        RegisterButton(
          delivery: delivery,
          slotKind: SlotKind.standard,
          member: member,
          org: org,
          label: "S'INSCRIRE",
        ),
      ],
    ];
  }

  Widget? _dashboardUrgencyBadge(
    BuildContext context,
    _DeliveryCardState state,
  ) {
    if (state.hasEarlyCapacity) {
      final remaining = state.earlyRemaining;
      return Tooltip(
        message:
            'Un créneau anticipé permet aux bénévoles de s\'inscrire '
            'plus tôt que prévu pour aider à préparer la distribution.',
        child: Text(
          '⏰ Créneau anticipé disponible '
          '($remaining place${remaining > 1 ? 's' : ''} '
          'restante${remaining > 1 ? 's' : ''})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      );
    }
    final required = state.totalRequired;
    if (required == 0) return null;
    final rate = state.totalCurrent / required;
    if (rate >= 0.8) return null;
    if (rate >= 0.5) {
      return Text(
        '⚠️ Places limitées',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Text(
      '🔴 Besoin urgent de bénévoles',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  String _dashboardStandardLabel(_DeliveryCardState state) {
    final arrivalTime = template?.volunteerArrivalTime;
    if (arrivalTime != null) {
      return "S'inscrire • Créneau standard · "
          'Arrivée ${formatTemplateTime(arrivalTime)}';
    }
    final slot = state.standardSlot;
    if (slot != null) {
      return "S'inscrire • Créneau standard · "
          'Arrivée ${formatSlotTime(slot.startTime)}';
    }
    return "S'INSCRIRE";
  }

  String _dashboardEarlyLabel(_DeliveryCardState state) {
    final slot = state.earlySlot;
    if (slot == null) return "S'inscrire • Créneau anticipé";
    return "S'inscrire • Créneau anticipé · "
        'Arrivée ${formatSlotTime(slot.startTime)}';
  }
}

/// Volunteer-staffing snapshot of a delivery, computed once per card.
///
/// Totals are summed over all non-cancelled slots — STANDARD and EARLY alike
/// (cancelled slots accept no registration and must not count toward capacity),
/// matching [deliveryVolunteerStaffing] and the UI specs' "N/M bénévoles".
/// EARLY capacity is read from the materialised slot's `requiredVolunteers`
/// (which already encodes the delivery override, then the template).
class _DeliveryCardState {
  const _DeliveryCardState({
    required this.totalRequired,
    required this.totalCurrent,
    required this.standardSlot,
    required this.earlySlot,
    required this.allSlotsCancelled,
    required this.hasStandardCapacity,
    required this.hasEarlyCapacity,
    required this.earlyRemaining,
  });

  factory _DeliveryCardState.from(Delivery delivery) {
    var totalRequired = 0;
    var totalCurrent = 0;
    var hasAnySlot = false;
    var hasActiveSlot = false;
    MemberSlot? standardSlot;
    MemberSlot? earlySlot;

    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        hasAnySlot = true;
        if (slot.status == SlotStatus.cancelled) continue;
        hasActiveSlot = true;
        totalRequired += slot.requiredVolunteers;
        totalCurrent += slot.currentRegistrations;
        if (slot.slotKind == SlotKind.standard) {
          standardSlot ??= slot;
        } else if (slot.slotKind == SlotKind.early) {
          earlySlot ??= slot;
        }
      }
    }

    final earlyCapacity = earlySlot?.requiredVolunteers ?? 0;
    final earlyCurrent = earlySlot?.currentRegistrations ?? 0;

    return _DeliveryCardState(
      totalRequired: totalRequired,
      totalCurrent: totalCurrent,
      standardSlot: standardSlot,
      earlySlot: earlySlot,
      allSlotsCancelled: hasAnySlot && !hasActiveSlot,
      hasStandardCapacity:
          standardSlot != null &&
          standardSlot.currentRegistrations < standardSlot.requiredVolunteers,
      hasEarlyCapacity: earlyCapacity > 0 && earlyCurrent < earlyCapacity,
      earlyRemaining: earlyCapacity - earlyCurrent,
    );
  }

  final int totalRequired;
  final int totalCurrent;
  final MemberSlot? standardSlot;
  final MemberSlot? earlySlot;
  final bool allSlotsCancelled;
  final bool hasStandardCapacity;
  final bool hasEarlyCapacity;
  final int earlyRemaining;
}

/// Read-only, purely informative display of a delivery's basket composition.
///
/// Grouped by basket size, lists each component (denormalised name + optional
/// weight + its SVG icon resolved by id from the org-level [Organization.itemTypes]
/// catalog — the heavy SVG is stored once there, not per delivery). Members get
/// the catalog via the `organization:{id}` scope. Renders nothing when no
/// component has been defined.
class BasketCompositionSection extends StatelessWidget {
  const BasketCompositionSection({
    required this.delivery,
    required this.org,
    super.key,
  });

  final Delivery delivery;
  final Organization org;

  @override
  Widget build(BuildContext context) {
    // Group described baskets by basket size, keeping only those with items.
    final byBasketSize = <String, List<DeliveryItem>>{};
    for (final description in delivery.basketDescriptions) {
      if (description.items.isEmpty) continue;
      byBasketSize
          .putIfAbsent(description.basketSizeName, () => <DeliveryItem>[])
          .addAll(description.items);
    }
    if (byBasketSize.isEmpty) return const SizedBox.shrink();

    // Resolve each component's SVG icon once from the org-level catalog.
    final svgByItemTypeId = <String, String?>{
      for (final it in org.itemTypes) it.id: it.imageSvg,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Theme(
        // Drop the ExpansionTile dividers to keep the card visually compact.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            '🧺 Composition du panier',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          children: [
            for (final entry in byBasketSize.entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final item in entry.value)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          ItemTypeSvgIcon(
                            svg: svgByItemTypeId[item.itemTypeId],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name.isEmpty ? item.itemTypeId : item.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          if (item.weight != null &&
                              item.weight!.trim().isNotEmpty)
                            Text(
                              item.weight!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
