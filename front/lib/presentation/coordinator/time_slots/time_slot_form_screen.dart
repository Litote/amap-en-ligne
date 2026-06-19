import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_slots.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart'
    show activeRegistrationsExcluding, deliveryCoordinatorIds, mainContractIdsOf;
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/common/app_time_picker.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_ended_listener.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:amap_en_ligne/presentation/coordinator/missing_coordinator_listener.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slots_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';

/// Slot-time override values passed to [_withDefaultSlots] and
/// [_withRewrittenSlots]. Grouped into a single record to keep both functions
/// within the 7-parameter limit (SonarQube S107).
typedef _SlotTimeOverrides = ({
  String? standardEndTime,
  String? volunteerArrivalTime,
  EarlySlot? earlySlot,
});

/// Form screen for creating or editing a delivery time slot.
///
/// When [deliveryId] is null the form is in creation mode.
/// When [deliveryId] is provided the screen loads the matching delivery and
/// allows editing it.
class TimeSlotFormScreen extends StatefulWidget {
  const TimeSlotFormScreen({
    super.key,
    required this.tenantId,
    this.deliveryId,
  });

  final String tenantId;
  final String? deliveryId;

  @override
  State<TimeSlotFormScreen> createState() => _TimeSlotFormScreenState();
}

class _TimeSlotFormScreenState extends State<TimeSlotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  String? _selectedDeliveryTemplateId;
  Set<String> _selectedProductTypeIds = <String>{};
  Set<String> _selectedContractIds = <String>{};
  bool _hasTouchedContractSelection = false;
  final _minVolunteersCtrl = TextEditingController(text: '1');
  final _instructionsCtrl = TextEditingController();
  bool _saving = false;
  bool _hasEditedMinVolunteers = false;
  bool _isUpdatingMinVolunteers = false;
  bool _hasEditedScheduledTime = false;
  bool _hasTouchedTemplateSelection = false;
  bool _isApplyingDefaultTemplate = false;
  bool _hasInitializedProductSelection = false;

  // Per-delivery slot-time overrides. Null/unedited fields fall back to the
  // selected template, then to the hard-coded defaults (see defaultVolunteerSlots).
  TimeOfDay? _volunteerArrivalTime;
  TimeOfDay? _standardEndTime;
  bool _earlySlotEnabled = false;
  TimeOfDay? _earlySlotArrivalTime;
  final _earlySlotMaxCtrl = TextEditingController(text: '1');
  final _earlySlotExplanationCtrl = TextEditingController();
  bool _hasEditedArrival = false;
  bool _hasEditedEnd = false;
  bool _hasEditedEarlySlot = false;
  bool _hasPrefilledTimes = false;

  bool get _isEditing => widget.deliveryId != null;

  @override
  void dispose() {
    _minVolunteersCtrl.dispose();
    _instructionsCtrl.dispose();
    _earlySlotMaxCtrl.dispose();
    _earlySlotExplanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _scheduledTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
        _hasEditedScheduledTime = true;
      });
    }
  }

  Future<void> _pickArrivalTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime:
          _volunteerArrivalTime ??
          _scheduledTime ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _volunteerArrivalTime = picked;
        _hasEditedArrival = true;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _standardEndTime ?? const TimeOfDay(hour: 11, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _standardEndTime = picked;
        _hasEditedEnd = true;
      });
    }
  }

  Future<void> _pickEarlyArrivalTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime:
          _earlySlotArrivalTime ?? const TimeOfDay(hour: 8, minute: 30),
    );
    if (picked != null) {
      setState(() {
        _earlySlotArrivalTime = picked;
        _hasEditedEarlySlot = true;
      });
    }
  }

  void _toggleEarlySlot(bool enabled) {
    setState(() {
      _earlySlotEnabled = enabled;
      _hasEditedEarlySlot = true;
      // Seed a sensible default arrival when enabling without a prior value.
      if (enabled) {
        _earlySlotArrivalTime ??=
            _volunteerArrivalTime ??
            _scheduledTime ??
            const TimeOfDay(hour: 8, minute: 30);
      }
    });
  }

  DeliveryTemplate? _findTemplateById(
    List<DeliveryTemplate> templates,
    String? templateId,
  ) {
    if (templateId == null) return null;
    for (final template in templates) {
      if (template.deliveryTemplateId == templateId) return template;
    }
    return null;
  }

  void _setMinVolunteers(int count) {
    _isUpdatingMinVolunteers = true;
    _minVolunteersCtrl.text = count.toString();
    _isUpdatingMinVolunteers = false;
  }

  TimeOfDay? _parseTemplateStartTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _handleMinVolunteersChanged(String _) {
    if (_isUpdatingMinVolunteers) return;
    _hasEditedMinVolunteers = true;
  }

  void _toggleProductSelection(String productTypeId, bool selected) {
    setState(() {
      final next = {..._selectedProductTypeIds};
      if (selected) {
        next.add(productTypeId);
      } else {
        next.remove(productTypeId);
      }
      _selectedProductTypeIds = next;
    });
  }

  void _toggleContractSelection(
    String contractId,
    bool selected,
    Set<String> effectiveSelection,
  ) {
    setState(() {
      final next = {...effectiveSelection};
      if (selected) {
        next.add(contractId);
      } else {
        next.remove(contractId);
      }
      _selectedContractIds = next;
      _hasTouchedContractSelection = true;
    });
  }

  /// Season contracts linkable at the chosen delivery date (today until
  /// a date is picked).
  List<Contract> _activeContracts(List<Contract> contracts) {
    return [
      for (final contract in contracts)
        if (contractLinkableAt(contract, _scheduledDate ?? DateTime.now()))
          contract,
    ];
  }

  /// The contract selection to render and submit. Until the coordinator
  /// touches the checkboxes, creation defaults to every active contract and
  /// edition derives the selection from the delivery's existing contract
  /// links (ids of contracts not cached locally stay in the set so their
  /// links are preserved).
  Set<String> _effectiveSelectedContractIds(
    List<Contract> contracts,
    Delivery? existingDelivery,
  ) {
    if (_hasTouchedContractSelection) return _selectedContractIds;
    if (_isEditing) {
      return {
        for (final link in existingDelivery?.contracts ?? const [])
          link.contractId,
      };
    }
    return {
      for (final contract in _activeContracts(contracts)) contract.contractId,
    };
  }

  String _producerDisplayName(
    String producerAccountId,
    Organization organization,
    List<ProducerAccount> producerAccounts,
  ) {
    for (final account in producerAccounts) {
      if (account.producerAccountId == producerAccountId) return account.name;
    }
    for (final product in organization.products) {
      if (product.producerAccountId == producerAccountId) return product.name;
    }
    return producerAccountId;
  }

  /// Products offered for selection: when the org has at least one active
  /// contract, only the products of the selected contracts — those referenced
  /// by the contract's productPrices, or every product of the contract's
  /// producer for a legacy contract without any price entry. Otherwise (org
  /// without contracts) every org product, as before.
  List<OrgProduct> _visibleProductsForContracts(
    Organization organization,
    List<Contract> activeContracts,
    Set<String> selectedContractIds,
  ) {
    if (activeContracts.isEmpty) return organization.products;
    final allowed = <String>{};
    for (final contract in activeContracts) {
      if (selectedContractIds.contains(contract.contractId)) {
        allowed.addAll(
          _allowedProductTypeIdsForContract(organization, contract),
        );
      }
    }
    // Iterate the org catalog to keep a stable order and deduplicate products
    // shared by several contracts.
    return [
      for (final product in organization.products)
        if (allowed.contains(product.productTypeId)) product,
    ];
  }

  /// Products offered for selection, grouped by the checked contract they
  /// belong to. When the org has no active contract, a single group with a null
  /// [contractName] carries every org product (flat list, as the spec's
  /// no-contract fallback). Otherwise one group per checked contract holds the
  /// products allowed by that contract; a product shared by several contracts
  /// appears under each (the selection — keyed by product-type id — is shared).
  List<({String? contractName, List<OrgProduct> products})>
  _visibleProductGroups(
    Organization organization,
    List<Contract> activeContracts,
    Set<String> selectedContractIds,
  ) {
    if (activeContracts.isEmpty) {
      return [(contractName: null, products: organization.products)];
    }
    final groups = <({String? contractName, List<OrgProduct> products})>[];
    for (final contract in activeContracts) {
      if (!selectedContractIds.contains(contract.contractId)) continue;
      final allowed = _allowedProductTypeIdsForContract(organization, contract);
      // Iterate the org catalog to keep a stable order within each group.
      final products = [
        for (final product in organization.products)
          if (allowed.contains(product.productTypeId)) product,
      ];
      if (products.isEmpty) continue;
      groups.add((contractName: contract.name, products: products));
    }
    return groups;
  }

  /// Product-type ids allowed by [contract]: those referenced by its product
  /// prices, or every product of its producer for a legacy price-less contract.
  Set<String> _allowedProductTypeIdsForContract(
    Organization organization,
    Contract contract,
  ) {
    if (contract.productPrices.isNotEmpty) {
      return {for (final price in contract.productPrices) price.productTypeId};
    }
    return {
      for (final product in organization.products)
        if (product.producerAccountId == contract.producerAccountId)
          product.productTypeId,
    };
  }

  void _initializeProductSelection(
    Organization organization,
    Delivery? delivery,
  ) {
    if (_hasInitializedProductSelection) return;
    final selectedFromDelivery =
        delivery?.basketDescriptions
            .map((description) => description.productTypeId)
            .toSet() ??
        <String>{};
    _selectedProductTypeIds = selectedFromDelivery.isNotEmpty
        ? selectedFromDelivery
        : organization.products.map((product) => product.productTypeId).toSet();
    _hasInitializedProductSelection = true;
  }

  List<BasketDeliveryDescription> _buildBasketDescriptions(
    List<OrgProduct> products, {
    Delivery? existingDelivery,
  }) {
    final existingByKey = {
      for (final description
          in existingDelivery?.basketDescriptions ?? const [])
        '${description.productTypeId}::${description.basketSizeName}':
            description,
    };
    final descriptions = <BasketDeliveryDescription>[];
    final seenKeys = <String>{};

    for (final product in products) {
      if (!_selectedProductTypeIds.contains(product.productTypeId)) continue;
      for (final basketSize in product.supportedBasketSizes) {
        final key = '${product.productTypeId}::${basketSize.name}';
        if (!seenKeys.add(key)) continue;
        descriptions.add(
          existingByKey[key] ??
              BasketDeliveryDescription(
                productTypeId: product.productTypeId,
                basketSizeName: basketSize.name,
              ),
        );
      }
    }

    return descriptions;
  }

  void _applyTemplateSelection(
    String? templateId,
    List<DeliveryTemplate> templates, {
    required bool markTouched,
  }) {
    final template = _findTemplateById(templates, templateId);
    setState(() {
      if (markTouched) _hasTouchedTemplateSelection = true;
      _selectedDeliveryTemplateId = templateId;
      _applyTemplateDefaults(template);
    });
  }

  /// Applies [template]'s defaults to the not-yet-edited form fields. No-op when
  /// [template] is null.
  void _applyTemplateDefaults(DeliveryTemplate? template) {
    if (template == null) return;
    if (!_isEditing && !_hasEditedScheduledTime) {
      _scheduledTime = _parseTemplateStartTime(template.standardStartTime);
    }
    if (!_hasEditedMinVolunteers) {
      _setMinVolunteers(template.desiredVolunteerCount);
    }
    if (!_hasEditedArrival && template.volunteerArrivalTime != null) {
      _volunteerArrivalTime = _parseTemplateStartTime(
        template.volunteerArrivalTime!,
      );
    }
    if (!_hasEditedEnd) {
      _standardEndTime = _parseTemplateStartTime(template.standardEndTime);
    }
    if (!_hasEditedEarlySlot) {
      final early = template.earlySlot;
      _earlySlotEnabled = early != null;
      if (early != null) {
        _earlySlotArrivalTime = _parseTemplateStartTime(early.arrivalTime);
        _earlySlotMaxCtrl.text = early.maxVolunteers.toString();
        _earlySlotExplanationCtrl.text = early.explanation ?? '';
      }
    }
  }

  void _maybeApplyDefaultTemplate(
    Organization organization,
    List<DeliveryTemplate> templates,
  ) {
    if (_isEditing ||
        _hasTouchedTemplateSelection ||
        _selectedDeliveryTemplateId != null ||
        _isApplyingDefaultTemplate) {
      return;
    }
    // The org's explicit default wins; otherwise fall back to the first
    // available template so a template is always pre-selected when one exists.
    final defaultTemplate =
        _findTemplateById(templates, organization.defaultDeliveryTemplateId) ??
        templates.firstOrNull;
    if (defaultTemplate == null) return;

    _isApplyingDefaultTemplate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isApplyingDefaultTemplate = false;
      if (!mounted ||
          _isEditing ||
          _hasTouchedTemplateSelection ||
          _selectedDeliveryTemplateId != null) {
        return;
      }
      _applyTemplateSelection(
        defaultTemplate.deliveryTemplateId,
        templates,
        markTouched: false,
      );
    });
  }

  bool _hasSameDayConflict(Organization org, DateTime scheduledDay) {
    for (final delivery in org.deliveries) {
      if (_isEditing && delivery.deliveryId == widget.deliveryId) continue;
      final existing = DateTime.tryParse(delivery.scheduledDate);
      if (existing == null) continue;
      if (existing.year == scheduledDay.year &&
          existing.month == scheduledDay.month &&
          existing.day == scheduledDay.day) {
        return true;
      }
    }
    return false;
  }

  String _resolveSub() {
    final authService = context.read<AuthService>();
    final state = authService.currentState;
    if (state is! Authenticated) return '';
    try {
      final claims = JwtClaims.decode(state.accessToken);
      return claims.string('sub') ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Counts the active (non-CANCELLED) registrations across all slots of
  /// [delivery].
  int _activeRegistrationCount(Delivery delivery) {
    var count = 0;
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        count += slot.registrations
            .where((r) => r.status != RegistrationStatus.cancelled)
            .length;
      }
    }
    return count;
  }

  /// Seeds the slot-time override fields when editing an existing delivery:
  /// prefers the delivery's own override fields, then derives from the already
  /// materialised slots (covers legacy deliveries created before overrides
  /// existed).
  void _prefillTimesFromDelivery(Delivery delivery) {
    if (_hasPrefilledTimes) return;
    _hasPrefilledTimes = true;
    final standard = _firstSlotOfKind(delivery, SlotKind.standard);
    final early = _firstSlotOfKind(delivery, SlotKind.early);

    _volunteerArrivalTime =
        _parseHm(delivery.volunteerArrivalTime) ??
        (standard != null ? _slotTimeOfDay(standard.startTime) : null);
    _standardEndTime =
        _parseHm(delivery.standardEndTime) ??
        (standard != null ? _slotTimeOfDay(standard.endTime) : null);

    final earlyOverride = delivery.earlySlot;
    if (earlyOverride != null) {
      _earlySlotEnabled = true;
      _earlySlotArrivalTime = _parseHm(earlyOverride.arrivalTime);
      _earlySlotMaxCtrl.text = earlyOverride.maxVolunteers.toString();
      _earlySlotExplanationCtrl.text = earlyOverride.explanation ?? '';
    } else if (early != null && early.status != SlotStatus.cancelled) {
      _earlySlotEnabled = true;
      _earlySlotArrivalTime = _slotTimeOfDay(early.startTime);
      _earlySlotMaxCtrl.text = early.requiredVolunteers.toString();
    }
  }

  TimeOfDay? _parseHm(String? value) {
    if (value == null) return null;
    return _parseTemplateStartTime(value);
  }

  MemberSlot? _firstSlotOfKind(Delivery delivery, SlotKind kind) {
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        if (slot.slotKind == kind) return slot;
      }
    }
    return null;
  }

  TimeOfDay _slotTimeOfDay(String iso) {
    final dt = DateTime.parse(iso);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  bool _slotHasActiveRegistrations(MemberSlot slot) =>
      slot.registrations.any((r) => r.status != RegistrationStatus.cancelled);

  String? _hmFromTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Builds the per-delivery early-slot override from the form state, or null
  /// when the early slot is disabled or has no arrival time set.
  EarlySlot? _earlySlotOverride() {
    if (!_earlySlotEnabled) return null;
    final arrival = _hmFromTimeOfDay(_earlySlotArrivalTime);
    if (arrival == null) return null;
    final max = int.tryParse(_earlySlotMaxCtrl.text) ?? 1;
    final explanationText = _earlySlotExplanationCtrl.text.trim();
    return EarlySlot(
      arrivalTime: arrival,
      explanation: explanationText.isEmpty ? null : explanationText,
      maxVolunteers: max < 1 ? 1 : max,
    );
  }

  /// Number of baskets to prepare for [contract]: one per subscription of
  /// each ACTIVE contract member.
  int _contractBasketQuantity(Contract contract) {
    var quantity = 0;
    for (final member in contract.members) {
      if (member.status != ContractMemberStatus.active) continue;
      quantity += member.subscriptions.length;
    }
    return quantity;
  }

  /// Derives the delivery's contract links from the selected season
  /// [contracts].
  ///
  /// Existing links are preserved as-is (coordinators, slots, status) while
  /// their contract stays selected, and dropped when it is deselected. Links
  /// whose contract definition is not cached locally are preserved — the
  /// back never re-validates existing links, so dropping them would be a
  /// silent data loss. Exception: a `tmp_*` link without a matching cached
  /// contract can never be resolved (optimistic creations always cache their
  /// contract), it is a leftover from a missed id remap — dropping it heals
  /// the delivery instead of duplicating the re-identified contract. New
  /// links start PENDING with no coordinator (spec: the block starts empty
  /// at creation).
  List<DeliveryContract> _buildDeliveryContracts(
    List<Contract> contracts,
    Set<String> selectedContractIds, {
    Delivery? existingDelivery,
  }) {
    final existingByContractId = {
      for (final link in existingDelivery?.contracts ?? const [])
        link.contractId: link,
    };
    final result = <DeliveryContract>[];
    final knownContractIds = <String>{};
    for (final contract in contracts) {
      knownContractIds.add(contract.contractId);
      final selected = selectedContractIds.contains(contract.contractId);
      final existing = existingByContractId[contract.contractId];
      if (existing != null) {
        if (selected) result.add(existing);
        continue;
      }
      if (!selected) continue;
      if (!contractLinkableAt(contract, _scheduledDate ?? DateTime.now())) {
        continue;
      }
      result.add(
        DeliveryContract(
          contractId: contract.contractId,
          basketQuantity: _contractBasketQuantity(contract),
          deliveryDescription: contract.name,
          status: DeliveryContractStatus.pending,
        ),
      );
    }
    result.addAll(_carryOverUnmatchedLinks(existingDelivery, knownContractIds));
    return result;
  }

  /// Existing links whose contract is no longer cached: carried over as-is
  /// (the back never re-validates existing links) except dangling `tmp_*` links
  /// from a missed id remap, which are dropped to heal the delivery.
  List<DeliveryContract> _carryOverUnmatchedLinks(
    Delivery? existingDelivery,
    Set<String> knownContractIds,
  ) {
    final carried = <DeliveryContract>[];
    for (final link in existingDelivery?.contracts ?? const []) {
      if (knownContractIds.contains(link.contractId)) continue;
      if (link.contractId.startsWith(ClientMutation.tmpIdPrefix)) continue;
      carried.add(link);
    }
    return carried;
  }

  /// Materialises the default volunteer slots on the main contract link when the
  /// delivery has none: volunteers cannot register without a slot (the back only
  /// lets privileged callers create them), so every privileged save backfills
  /// one. Only main contracts mobilise volunteers — when no linked contract is
  /// flagged main, **no** volunteer slot is created (secondary contracts mobilise
  /// only the coordinator).
  List<DeliveryContract> _withDefaultSlots(
    List<DeliveryContract> contracts, {
    required DateTime scheduled,
    required int minVolunteers,
    required DeliveryTemplate? template,
    required Set<String> mainContractIds,
    _SlotTimeOverrides? timeOverrides,
  }) {
    if (contracts.isEmpty) return contracts;
    if (contracts.any((c) => c.slots.isNotEmpty)) return contracts;
    final targetIndex = _mainContractLinkIndex(contracts, mainContractIds);
    // No main contract among the links ⇒ no volunteers proposed for this
    // delivery: leave the links slot-less.
    if (targetIndex < 0) return contracts;
    return [
      for (var i = 0; i < contracts.length; i++)
        if (i == targetIndex)
          contracts[i].copyWith(
            slots: defaultVolunteerSlots(
              scheduled: scheduled,
              requiredVolunteers: minVolunteers,
              template: template,
              standardEndTimeOverride: timeOverrides?.standardEndTime,
              volunteerArrivalTimeOverride: timeOverrides?.volunteerArrivalTime,
              earlySlotOverride: timeOverrides?.earlySlot,
            ),
          )
        else
          contracts[i],
    ];
  }

  /// Index of the first link whose contract is flagged main, or -1 when none
  /// is — in which case no volunteer slot is materialised.
  int _mainContractLinkIndex(
    List<DeliveryContract> contracts,
    Set<String> mainContractIds,
  ) => contracts.indexWhere((c) => mainContractIds.contains(c.contractId));

  /// Cleans up legacy volunteer slots sitting on non-main contract links: only
  /// main contracts mobilise volunteers, so a secondary contract should carry no
  /// volunteer slot. Empty slots are dropped; a slot still holding an active
  /// registration is kept (never silently lose a registration). No-op when no
  /// linked contract is flagged main (legacy fallback).
  List<DeliveryContract> _pruneNonMainContractSlots(
    List<DeliveryContract> contracts,
    Set<String> mainContractIds,
  ) {
    final hasMain = contracts.any(
      (c) => mainContractIds.contains(c.contractId),
    );
    if (!hasMain) return contracts;
    return [
      for (final contract in contracts)
        if (mainContractIds.contains(contract.contractId) ||
            contract.slots.isEmpty)
          contract
        else
          contract.copyWith(
            slots: [
              for (final slot in contract.slots)
                if (slot.registrations.any(
                  (r) => r.status != RegistrationStatus.cancelled,
                ))
                  slot,
            ],
          ),
    ];
  }

  /// Rewrites the existing volunteer slots of an edited delivery to the
  /// resolved override times, **preserving each slot's `slotId`, status and
  /// registrations** so the back matches them (and notifies registered members
  /// of any reschedule) instead of treating them as new slots.
  ///
  /// - the STANDARD slot start/end and capacity follow the overrides;
  /// - an EARLY slot is rewritten when still enabled, added when newly enabled,
  ///   and dropped when disabled — but kept (to avoid a server-side `CONFLICT`
  ///   on deleting a slot with active registrations) when volunteers are still
  ///   registered;
  /// - CANCELLED slots are left untouched (their schedule is terminal).
  ///
  /// Falls back to [_withDefaultSlots] when no slot exists yet.
  List<DeliveryContract> _withRewrittenSlots(
    List<DeliveryContract> contracts, {
    required DateTime scheduled,
    required int minVolunteers,
    required DeliveryTemplate? template,
    required Set<String> mainContractIds,
    _SlotTimeOverrides? timeOverrides,
  }) {
    final hasSlots = contracts.any((c) => c.slots.isNotEmpty);
    if (!hasSlots) {
      return _withDefaultSlots(
        contracts,
        scheduled: scheduled,
        minVolunteers: minVolunteers,
        template: template,
        mainContractIds: mainContractIds,
        timeOverrides: timeOverrides,
      );
    }
    final fresh = defaultVolunteerSlots(
      scheduled: scheduled,
      requiredVolunteers: minVolunteers,
      template: template,
      standardEndTimeOverride: timeOverrides?.standardEndTime,
      volunteerArrivalTimeOverride: timeOverrides?.volunteerArrivalTime,
      earlySlotOverride: timeOverrides?.earlySlot,
    );
    final freshByKind = <SlotKind, MemberSlot>{
      for (final slot in fresh) slot.slotKind: slot,
    };
    var addMissingDone = false;
    return [
      for (final contract in contracts)
        if (contract.slots.isEmpty)
          contract
        else
          () {
            final addMissing = !addMissingDone;
            addMissingDone = true;
            return contract.copyWith(
              slots: _mergeSlots(
                contract.slots,
                freshByKind,
                addMissingKinds: addMissing,
              ),
            );
          }(),
    ];
  }

  /// Merges the freshly-computed slot times into the existing slots, matched by
  /// [SlotKind]. See [_withRewrittenSlots] for the rules.
  List<MemberSlot> _mergeSlots(
    List<MemberSlot> existing,
    Map<SlotKind, MemberSlot> freshByKind, {
    required bool addMissingKinds,
  }) {
    final result = <MemberSlot>[];
    final seenKinds = <SlotKind>{};
    for (final old in existing) {
      if (old.status == SlotStatus.cancelled) {
        result.add(old);
        continue;
      }
      seenKinds.add(old.slotKind);
      final fresh = freshByKind[old.slotKind];
      if (fresh != null) {
        result.add(
          fresh.copyWith(
            slotId: old.slotId,
            status: old.status,
            registrations: old.registrations,
            currentRegistrations: old.currentRegistrations,
          ),
        );
      } else if (_slotHasActiveRegistrations(old)) {
        // Kind removed (e.g. early disabled) but volunteers still registered:
        // keep the slot so the server does not reject the whole save.
        result.add(old);
      }
    }
    if (addMissingKinds) {
      for (final entry in freshByKind.entries) {
        if (!seenKinds.contains(entry.key)) result.add(entry.value);
      }
    }
    return result;
  }

  Future<void> _submit(
    Organization org,
    List<Contract> contracts,
    List<DeliveryTemplate> templates,
  ) async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final validationError = _validateSchedule(org);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final scheduled = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );

    final existingDelivery = _isEditing
        ? org.deliveries
              .where((d) => d.deliveryId == widget.deliveryId)
              .firstOrNull
        : null;

    // Reschedule confirmation: editing the schedule OR the slot times of a
    // delivery whose slots still carry active registrations is allowed, but the
    // registered members will be notified by the server — ask for confirmation
    // first.
    if (!await _confirmRescheduleIfNeeded(existingDelivery, scheduled)) return;
    if (!mounted) return;

    final minVolunteers = int.tryParse(_minVolunteersCtrl.text) ?? 1;
    final orgRepo = context.read<OrganizationRepository>();
    final syncBloc = context.read<SyncBloc>();
    final idGen = IdGenerator(Random());
    final selectedTemplate = _findTemplateById(
      templates,
      _selectedDeliveryTemplateId,
    );

    final activeContracts = _activeContracts(contracts);
    final mainContractIds = mainContractIdsOf(contracts);
    final selectedContractIds = _effectiveSelectedContractIds(
      contracts,
      existingDelivery,
    );
    final products = _visibleProductsForContracts(
      org,
      activeContracts,
      selectedContractIds,
    );

    final arrivalOverride = _hmFromTimeOfDay(_volunteerArrivalTime);
    final endOverride = _hmFromTimeOfDay(_standardEndTime);
    final earlyOverride = _earlySlotOverride();

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final existing =
            existingDelivery ??
            (throw StateError('Delivery ${widget.deliveryId} not found'));
        final updated = existing.copyWith(
          scheduledDate: scheduled.toIso8601String(),
          minVolunteersRequired: minVolunteers,
          deliveryTemplateId: _selectedDeliveryTemplateId,
          standardEndTime: endOverride,
          volunteerArrivalTime: arrivalOverride,
          earlySlot: earlyOverride,
          basketDescriptions: _buildBasketDescriptions(
            products,
            existingDelivery: existing,
          ),
          contracts: _pruneNonMainContractSlots(
            _withRewrittenSlots(
              _buildDeliveryContracts(
                contracts,
                selectedContractIds,
                existingDelivery: existing,
              ),
              scheduled: scheduled,
              minVolunteers: minVolunteers,
              template: selectedTemplate,
              mainContractIds: mainContractIds,
              timeOverrides: (
                standardEndTime: endOverride,
                volunteerArrivalTime: arrivalOverride,
                earlySlot: earlyOverride,
              ),
            ),
            mainContractIds,
          ),
        );
        await orgRepo.updateDelivery(currentOrg: org, delivery: updated);
      } else {
        final delivery = Delivery(
          deliveryId: idGen.nextTmpId(),
          organizationId: org.organizationId,
          scheduledDate: scheduled.toIso8601String(),
          status: DeliveryStatus.planned,
          minVolunteersRequired: minVolunteers,
          deliveryTemplateId: _selectedDeliveryTemplateId,
          standardEndTime: endOverride,
          volunteerArrivalTime: arrivalOverride,
          earlySlot: earlyOverride,
          basketDescriptions: _buildBasketDescriptions(products),
          contracts: _pruneNonMainContractSlots(
            _withDefaultSlots(
              _buildDeliveryContracts(contracts, selectedContractIds),
              scheduled: scheduled,
              minVolunteers: minVolunteers,
              template: selectedTemplate,
              mainContractIds: mainContractIds,
              timeOverrides: (
                standardEndTime: endOverride,
                volunteerArrivalTime: arrivalOverride,
                earlySlot: earlyOverride,
              ),
            ),
            mainContractIds,
          ),
        );
        await orgRepo.addDelivery(currentOrg: org, delivery: delivery);
      }
      syncBloc.add(const SyncEvent.mutationApplied());
      if (mounted) context.pop();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Validates the schedule preconditions; returns an error message or null.
  String? _validateSchedule(Organization org) {
    if (_scheduledDate == null || _scheduledTime == null) {
      return 'Veuillez sélectionner une date et heure.';
    }
    if (_hasSameDayConflict(org, _scheduledDate!)) {
      return 'Une livraison existe déjà ce jour-là pour cette AMAP.';
    }
    return null;
  }

  /// Asks for confirmation when an edit reschedules a delivery (or changes its
  /// slot times) that still carries active registrations. Returns true to
  /// proceed, false to abort.
  Future<bool> _confirmRescheduleIfNeeded(
    Delivery? existingDelivery,
    DateTime scheduled,
  ) async {
    if (!_isEditing || existingDelivery == null) return true;
    final scheduleDelta = scheduled.difference(
      DateTime.parse(existingDelivery.scheduledDate),
    );
    final timesChanged =
        scheduleDelta != Duration.zero ||
        _hasEditedArrival ||
        _hasEditedEnd ||
        _hasEditedEarlySlot;
    final activeCount = _activeRegistrationCount(existingDelivery);
    if (!timesChanged || activeCount == 0) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Modifier l'horaire ?"),
        content: Text(
          '$activeCount inscrit(s) seront notifiés du changement '
          "d'horaire.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ANNULER'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Widget _buildForm({
    required Organization org,
    required Delivery? existingDelivery,
    required List<DeliveryTemplate> templates,
    required List<Member> allMembers,
    required Member? me,
    required List<Contract> contracts,
    required List<ProducerAccount> producerAccounts,
  }) {
    final selectedTemplateExists = templates.any(
      (template) => template.deliveryTemplateId == _selectedDeliveryTemplateId,
    );
    final activeContracts = _activeContracts(contracts);
    final selectedContractIds = _effectiveSelectedContractIds(
      contracts,
      existingDelivery,
    );
    final contractOptions = [
      for (final contract in activeContracts)
        (
          id: contract.contractId,
          label:
              '${contract.name} — '
              '${_producerDisplayName(contract.producerAccountId, org, producerAccounts)}',
        ),
    ]..sort((a, b) => a.label.compareTo(b.label));
    final productGroups = _visibleProductGroups(
      org,
      activeContracts,
      selectedContractIds,
    );
    // In creation mode, preview the contracts that will be linked on save.
    final previewContractNames = _isEditing
        ? const <String>[]
        : [
            for (final contract in activeContracts)
              if (selectedContractIds.contains(contract.contractId))
                contract.name,
          ];

    return ContractEndedListener(
      child: MissingCoordinatorListener(
        org: org,
        child: _SlotConflictListener(
          child: _FormBody(
            formKey: _formKey,
            scheduledDate: _scheduledDate,
            scheduledTime: _scheduledTime,
            selectedDeliveryTemplateId: _selectedDeliveryTemplateId,
            hasMissingSelectedTemplate:
                _selectedDeliveryTemplateId != null && !selectedTemplateExists,
            contractOptions: contractOptions,
            selectedContractIds: selectedContractIds,
            onContractSelectionChanged: (contractId, selected) =>
                _toggleContractSelection(
                  contractId,
                  selected,
                  selectedContractIds,
                ),
            productGroups: productGroups,
            selectedProductTypeIds: _selectedProductTypeIds,
            templates: templates,
            minVolunteersCtrl: _minVolunteersCtrl,
            instructionsCtrl: _instructionsCtrl,
            saving: _saving,
            onPickDate: _pickDate,
            onPickTime: _pickTime,
            onTemplateChanged: (value) =>
                _applyTemplateSelection(value, templates, markTouched: true),
            onProductSelectionChanged: _toggleProductSelection,
            onMinVolunteersChanged: _handleMinVolunteersChanged,
            slotTimesBlock: _SlotTimesBlock(
              arrivalTime: _volunteerArrivalTime,
              endTime: _standardEndTime,
              earlySlotEnabled: _earlySlotEnabled,
              earlySlotArrivalTime: _earlySlotArrivalTime,
              earlySlotMaxCtrl: _earlySlotMaxCtrl,
              earlySlotExplanationCtrl: _earlySlotExplanationCtrl,
              onPickArrival: _pickArrivalTime,
              onPickEnd: _pickEndTime,
              onToggleEarlySlot: _toggleEarlySlot,
              onPickEarlyArrival: _pickEarlyArrivalTime,
            ),
            onSubmit: () => _submit(org, contracts, templates),
            // Coordinator block data
            existingDelivery: existingDelivery,
            previewContractNames: previewContractNames,
            org: org,
            me: me,
            allMembers: allMembers,
            contracts: contracts,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: 'Livraison',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider(
      create: (_) => TimeSlotsBloc(
        orgRepo: context.read<OrganizationRepository>(),
        syncBloc: context.read<SyncBloc>(),
      ),
      child: ConnectedScaffold(
        title: _isEditing ? 'Modifier la livraison' : 'Nouvelle livraison',
        body: StreamBuilder<Organization?>(
          stream: context.read<OrganizationRepository>().watch(widget.tenantId),
          builder: (context, orgSnapshot) {
            if (!orgSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final org = orgSnapshot.data;
            if (org == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final existingDelivery = _isEditing
                ? org.deliveries
                      .where((d) => d.deliveryId == widget.deliveryId)
                      .firstOrNull
                : null;

            // Pre-fill form when editing.
            if (_isEditing && _scheduledDate == null) {
              final delivery = existingDelivery;
              if (delivery != null) {
                final dt = DateTime.parse(delivery.scheduledDate);
                _scheduledDate = dt;
                _scheduledTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                _selectedDeliveryTemplateId = delivery.deliveryTemplateId;
                _minVolunteersCtrl.text = delivery.minVolunteersRequired
                    .toString();
                _prefillTimesFromDelivery(delivery);
              }
            }
            _initializeProductSelection(org, existingDelivery);

            return StreamBuilder<List<DeliveryTemplate>>(
              stream: context.read<DeliveryTemplateRepository>().watch(
                widget.tenantId,
              ),
              initialData: const <DeliveryTemplate>[],
              builder: (context, templateSnapshot) {
                final templates =
                    templateSnapshot.data ?? const <DeliveryTemplate>[];
                _maybeApplyDefaultTemplate(org, templates);

                // Resolve current member for coordinator block.
                return StreamBuilder<List<Member>>(
                  stream: context.read<MemberRepository>().watch(
                    widget.tenantId,
                  ),
                  initialData: const <Member>[],
                  builder: (context, membersSnapshot) {
                    final allMembers = membersSnapshot.data ?? const <Member>[];
                    final sub = _resolveSub();
                    // After sub/id unification: memberId == sub by invariant.
                    final me = allMembers
                        .where((m) => m.memberId == sub)
                        .firstOrNull;

                    return StreamBuilder<List<Contract>>(
                      stream: context.read<ContractRepository>().watch(
                        widget.tenantId,
                      ),
                      initialData: const <Contract>[],
                      builder: (context, contractsSnapshot) {
                        final contracts =
                            contractsSnapshot.data ?? const <Contract>[];
                        return StreamBuilder<List<ProducerAccount>>(
                          stream: context
                              .read<ProducerAccountRepository>()
                              .watchAll(),
                          initialData: const <ProducerAccount>[],
                          builder: (context, producersSnapshot) {
                            final producerAccounts =
                                producersSnapshot.data ??
                                const <ProducerAccount>[];
                            return _buildForm(
                              org: org,
                              existingDelivery: existingDelivery,
                              templates: templates,
                              allMembers: allMembers,
                              me: me,
                              contracts: contracts,
                              producerAccounts: producerAccounts,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Listens for [SyncSucceeded] states carrying a rejected mutation with
/// [MutationErrorCode.conflict] — an offline race where another device
/// deleted/cancelled a slot or registrations changed between the local
/// validation and the server-side guard.
class _SlotConflictListener extends StatelessWidget {
  const _SlotConflictListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (_, current) => current is SyncSucceeded,
      listener: (context, state) {
        if (state is! SyncSucceeded) return;
        final conflicts = state.rejectedMutations.where(
          (m) =>
              m.status == MutationStatus.rejected &&
              m.error?.code == MutationErrorCode.conflict,
        );
        if (conflicts.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opération refusée par le serveur : des bénévoles sont encore '
              'inscrits sur cette livraison.',
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.selectedDeliveryTemplateId,
    required this.hasMissingSelectedTemplate,
    required this.contractOptions,
    required this.selectedContractIds,
    required this.onContractSelectionChanged,
    required this.productGroups,
    required this.selectedProductTypeIds,
    required this.templates,
    required this.minVolunteersCtrl,
    required this.instructionsCtrl,
    required this.saving,
    required this.onPickDate,
    required this.onPickTime,
    required this.onTemplateChanged,
    required this.onProductSelectionChanged,
    required this.onMinVolunteersChanged,
    required this.slotTimesBlock,
    required this.onSubmit,
    required this.existingDelivery,
    required this.previewContractNames,
    required this.org,
    required this.me,
    required this.allMembers,
    required this.contracts,
  });

  final GlobalKey<FormState> formKey;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final String? selectedDeliveryTemplateId;
  final bool hasMissingSelectedTemplate;

  /// Season contracts active at the chosen date, as (contractId, label)
  /// pairs sorted by label — the label combines the contract name and its
  /// producer's display name. Empty when the org has no active contract —
  /// the contract section is then hidden.
  final List<({String id, String label})> contractOptions;
  final Set<String> selectedContractIds;
  final void Function(String contractId, bool selected)
  onContractSelectionChanged;

  /// Selectable products grouped by the checked contract they belong to. A null
  /// [contractName] (single group) means the org has no contract — flat list.
  final List<({String? contractName, List<OrgProduct> products})> productGroups;
  final Set<String> selectedProductTypeIds;
  final List<DeliveryTemplate> templates;
  final TextEditingController minVolunteersCtrl;
  final TextEditingController instructionsCtrl;
  final bool saving;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<String?> onTemplateChanged;
  final void Function(String productTypeId, bool selected)
  onProductSelectionChanged;
  final ValueChanged<String> onMinVolunteersChanged;

  /// Editable per-delivery slot-time overrides (arrival / end / early slot).
  final Widget slotTimesBlock;
  final VoidCallback onSubmit;

  /// The delivery being edited (null in creation mode).
  final Delivery? existingDelivery;

  /// Names of the contracts that will be linked on save (creation mode only).
  final List<String> previewContractNames;

  /// Current organisation — used for coordinator mutations.
  final Organization org;

  /// The connected user's [Member] row (null while loading or not yet synced).
  final Member? me;

  /// All members of the AMAP — used for the ADMIN coordinator picker.
  final List<Member> allMembers;

  /// Season contract definitions — the coordinator picker is restricted to
  /// each contract's [Contract.coordinators] pool.
  final List<Contract> contracts;

  @override
  Widget build(BuildContext context) {
    // Volunteers are only mobilised for main contracts: the volunteer-slot
    // controls (minimum count + slot times) are offered only when at least one
    // linked contract is flagged main.
    final mainContractIds = mainContractIdsOf(contracts);
    final hasMainContract = selectedContractIds.any(mainContractIds.contains);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateTimePickers(context),
            const SizedBox(height: 16),
            _buildTemplateDropdown(),
            const SizedBox(height: 16),
            if (hasMainContract) ...[
              _buildMinVolunteersField(),
              const SizedBox(height: 16),
              slotTimesBlock,
            ],
            _buildContractsSection(context),
            _buildProductsSection(context),
            _CoordinatorBlock(
              delivery: existingDelivery,
              previewContractNames: previewContractNames,
              org: org,
              me: me,
              allMembers: allMembers,
              contracts: contracts,
            ),
            if (existingDelivery != null)
              _SlotsBlock(
                delivery: existingDelivery!,
                org: org,
                mainContractIds: mainContractIds,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: instructionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Instructions (facultatif)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _BasketCompositionBlock(
              existingDelivery: existingDelivery,
              org: org,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : onSubmit,
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePickers(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            scheduledDate == null
                ? 'Sélectionner une date'
                : '${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year}',
          ),
          leading: const Icon(Icons.calendar_today),
          onTap: onPickDate,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            scheduledTime == null
                ? "Sélectionner l'heure"
                : formatAppTimeOfDay(context, scheduledTime!),
          ),
          leading: const Icon(Icons.access_time),
          onTap: onPickTime,
        ),
      ],
    );
  }

  Widget _buildTemplateDropdown() {
    return DropdownButtonFormField<String?>(
      key: ValueKey(selectedDeliveryTemplateId),
      initialValue: selectedDeliveryTemplateId,
      decoration: const InputDecoration(
        labelText: 'Modèle de livraison (facultatif)',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Aucun modèle'),
        ),
        if (hasMissingSelectedTemplate)
          DropdownMenuItem<String?>(
            value: selectedDeliveryTemplateId,
            child: const Text('Modèle introuvable'),
          ),
        ...templates.map(
          (template) => DropdownMenuItem<String?>(
            value: template.deliveryTemplateId,
            child: Text(template.name),
          ),
        ),
      ],
      onChanged: onTemplateChanged,
    );
  }

  Widget _buildMinVolunteersField() {
    return TextFormField(
      controller: minVolunteersCtrl,
      onChanged: onMinVolunteersChanged,
      decoration: const InputDecoration(
        labelText: 'Bénévoles minimum requis',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Champ obligatoire';
        final n = int.tryParse(v);
        if (n == null || n < 1) return 'Valeur invalide';
        return null;
      },
    );
  }

  Widget _buildContractsSection(BuildContext context) {
    if (contractOptions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          '🌿 Contrats présents',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...contractOptions.map(
          (option) => CheckboxListTile(
            value: selectedContractIds.contains(option.id),
            contentPadding: EdgeInsets.zero,
            title: Text(option.label),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (selected) =>
                onContractSelectionChanged(option.id, selected ?? false),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    if (!productGroups.any((g) => g.products.isNotEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Produits présents',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final group in productGroups)
          if (group.products.isNotEmpty) ...[
            if (group.contractName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Text(
                  group.contractName!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            for (final product in group.products)
              CheckboxListTile(
                value: selectedProductTypeIds.contains(product.productTypeId),
                contentPadding: EdgeInsets.zero,
                title: Text(product.name),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (selected) => onProductSelectionChanged(
                  product.productTypeId,
                  selected ?? false,
                ),
              ),
          ],
      ],
    );
  }
}

/// Entry point to the per-delivery basket composition editor
/// ([DeliveryDescriptionScreen]). Only an already-saved delivery can be
/// composed (the editor loads the delivery from the org cache), so in creation
/// mode this shows a hint to save first.
class _BasketCompositionBlock extends StatelessWidget {
  const _BasketCompositionBlock({
    required this.existingDelivery,
    required this.org,
  });

  final Delivery? existingDelivery;
  final Organization org;

  @override
  Widget build(BuildContext context) {
    final delivery = existingDelivery;
    if (delivery == null) {
      return const Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.shopping_basket_outlined),
          title: Text('Composition du panier'),
          subtitle: Text(
            'Enregistrez la livraison pour définir la composition.',
          ),
          enabled: false,
        ),
      );
    }
    final itemCount = delivery.basketDescriptions.fold<int>(
      0,
      (sum, d) => sum + d.items.length,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.shopping_basket_outlined),
        title: const Text('Composition du panier'),
        subtitle: Text(
          itemCount == 0
              ? 'Aucun composant'
              : '$itemCount composant${itemCount > 1 ? 's' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          '/coordinator/deliveries/${delivery.deliveryId}/description',
          extra: org,
        ),
      ),
    );
  }
}

/// Editable per-delivery slot-time overrides: the volunteer arrival time, the
/// end time, and an optional early slot (arrival + capacity + explanation).
///
/// Empty fields fall back to the selected template, then to the hard-coded
/// defaults when the delivery is saved.
class _SlotTimesBlock extends StatelessWidget {
  const _SlotTimesBlock({
    required this.arrivalTime,
    required this.endTime,
    required this.earlySlotEnabled,
    required this.earlySlotArrivalTime,
    required this.earlySlotMaxCtrl,
    required this.earlySlotExplanationCtrl,
    required this.onPickArrival,
    required this.onPickEnd,
    required this.onToggleEarlySlot,
    required this.onPickEarlyArrival,
  });

  final TimeOfDay? arrivalTime;
  final TimeOfDay? endTime;
  final bool earlySlotEnabled;
  final TimeOfDay? earlySlotArrivalTime;
  final TextEditingController earlySlotMaxCtrl;
  final TextEditingController earlySlotExplanationCtrl;
  final VoidCallback onPickArrival;
  final VoidCallback onPickEnd;
  final ValueChanged<bool> onToggleEarlySlot;
  final VoidCallback onPickEarlyArrival;

  Widget _timeField(
    BuildContext context, {
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value == null
              ? 'Selon le modèle'
              : formatAppTimeOfDay(context, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Horaires des créneaux',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _timeField(
          context,
          label: 'Heure d\'arrivée des bénévoles',
          value: arrivalTime,
          onTap: onPickArrival,
        ),
        const SizedBox(height: 12),
        _timeField(
          context,
          label: 'Heure de fin',
          value: endTime,
          onTap: onPickEnd,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Créneau anticipé'),
          value: earlySlotEnabled,
          onChanged: onToggleEarlySlot,
        ),
        if (earlySlotEnabled) ...[
          _timeField(
            context,
            label: 'Arrivée (créneau anticipé)',
            value: earlySlotArrivalTime,
            onTap: onPickEarlyArrival,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: earlySlotMaxCtrl,
            decoration: const InputDecoration(
              labelText: 'Bénévoles max (créneau anticipé)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: earlySlotExplanationCtrl,
            decoration: const InputDecoration(
              labelText: 'Explication (créneau anticipé, facultatif)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}

/// Block showing one row per [DeliveryContract] with coordinator chips and
/// self-assign / admin-assign actions.
///
/// Spec: screen-coordinator-02-time-slots.md § "Coordinateurs par contrat".
class _CoordinatorBlock extends StatelessWidget {
  const _CoordinatorBlock({
    required this.delivery,
    required this.previewContractNames,
    required this.org,
    required this.me,
    required this.allMembers,
    required this.contracts,
  });

  /// The delivery whose contracts are displayed. Null in creation mode
  /// (before contracts exist).
  final Delivery? delivery;

  /// Contracts that will be linked on save (creation mode preview) — shown
  /// without coordinator actions, which require an existing delivery.
  final List<String> previewContractNames;
  final Organization org;
  final Member? me;
  final List<Member> allMembers;

  /// Season contract definitions — used to resolve each delivery-contract's
  /// [Contract.coordinators] pool, which constrains who can be assigned.
  final List<Contract> contracts;

  bool get _isAdmin => me?.roles.contains(Role.admin) ?? false;

  /// The coordinator pool of the [Contract] matching [contractId], or empty
  /// when the contract is not cached locally.
  List<String> _poolFor(String contractId) {
    for (final c in contracts) {
      if (c.contractId == contractId) return c.coordinators;
    }
    return const [];
  }

  /// Resolves the displayable contract name from the live [contracts] catalog
  /// by id, falling back to the link's denormalised
  /// [DeliveryContract.deliveryDescription] (which is blank on imported data).
  String _nameFor(DeliveryContract link) {
    for (final c in contracts) {
      if (c.contractId == link.contractId && c.name.trim().isNotEmpty) {
        return c.name;
      }
    }
    return link.deliveryDescription;
  }

  @override
  Widget build(BuildContext context) {
    final contracts = delivery?.contracts ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '👥 Coordinateurs par contrat',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (contracts.isNotEmpty)
          for (final contract in contracts)
            _ContractCoordinatorRow(
              contract: contract,
              contractName: _nameFor(contract),
              delivery: delivery!,
              org: org,
              me: me,
              allMembers: allMembers,
              isAdmin: _isAdmin,
              coordinatorPool: _poolFor(contract.contractId),
            )
        else if (previewContractNames.isNotEmpty)
          for (final name in previewContractNames)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aucun coordinateur',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
        else
          const Text('Aucun contrat encore défini.'),
      ],
    );
  }
}

/// One row in the coordinator block for a single [DeliveryContract].
class _ContractCoordinatorRow extends StatelessWidget {
  const _ContractCoordinatorRow({
    required this.contract,
    required this.contractName,
    required this.delivery,
    required this.org,
    required this.me,
    required this.allMembers,
    required this.isAdmin,
    required this.coordinatorPool,
  });

  final DeliveryContract contract;

  /// Resolved contract name (from the contracts catalog), used as the row
  /// header so the coordinator knows which contract each entry belongs to.
  final String contractName;
  final Delivery delivery;
  final Organization org;
  final Member? me;
  final List<Member> allMembers;
  final bool isAdmin;

  /// The linked [Contract.coordinators] pool — the effective coordinator(s)
  /// assigned for this delivery must be chosen among these members.
  final List<String> coordinatorPool;

  bool get _isActive => delivery.status.isActive;

  /// Whether the ✕ button should be enabled for [coordinatorId].
  ///
  /// ADMIN: active on any coordinator while the delivery is active.
  /// COORDINATOR non-ADMIN: only own entry, only while not IN_PROGRESS.
  bool _canRemove(String coordinatorId) {
    if (!_isActive) return false;
    if (isAdmin) return true;
    // Non-admin coordinator: own entry only, not IN_PROGRESS or beyond.
    if (me == null) return false;
    if (coordinatorId != me!.memberId) return false;
    return delivery.status != DeliveryStatus.inProgress &&
        delivery.status != DeliveryStatus.completed &&
        delivery.status != DeliveryStatus.cancelled;
  }

  bool get _canSelfAssign {
    if (!_isActive) return false;
    if (me == null) return false;
    // A coordinator may only stand for a contract they belong to (the pool).
    return coordinatorPool.contains(me!.memberId) &&
        !contract.coordinators.contains(me!.memberId);
  }

  /// Pool members not yet assigned on this delivery-contract — the candidates
  /// the ADMIN picker may add.
  List<String> get _assignablePoolMemberIds => coordinatorPool
      .where((id) => !contract.coordinators.contains(id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final membersById = {for (final m in allMembers) m.memberId: m};

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contractName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (contract.coordinators.isEmpty)
            Text(
              'Aucun coordinateur',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            )
          else
            for (final id in contract.coordinators)
              _CoordinatorChip(
                coordinatorId: id,
                displayName: _resolveName(id, membersById),
                canRemove: _canRemove(id),
                onRemove: () => _removeCoordinator(context, id),
              ),
          const SizedBox(height: 4),
          // Self-assign button
          if (_canSelfAssign)
            OutlinedButton(
              onPressed: () => _selfAssign(context),
              child: const Text('ME PORTER COORDINATEUR'),
            )
          else if (me == null)
            const Tooltip(
              message: 'Chargement du compte…',
              child: OutlinedButton(
                onPressed: null,
                child: Text('ME PORTER COORDINATEUR'),
              ),
            ),
          // Admin add button — only when the contract pool has an
          // assignable (not-yet-assigned) coordinator.
          if (isAdmin && _isActive && _assignablePoolMemberIds.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _showAdminPicker(context, membersById),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un coordinateur'),
            ),
        ],
      ),
    );
  }

  String _resolveName(String memberId, Map<String, Member> membersById) {
    final member = membersById[memberId];
    if (member == null) return memberId;
    final first = member.firstName?.trim() ?? '';
    final last = member.lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return memberId;
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  void _selfAssign(BuildContext context) {
    if (me == null) return;
    final orgRepo = context.read<OrganizationRepository>();
    final syncBloc = context.read<SyncBloc>();
    orgRepo
        .assignCoordinatorById(
          organizationId: org.organizationId,
          deliveryId: delivery.deliveryId,
          contractId: contract.contractId,
          memberId: me!.memberId,
        )
        .then((_) => syncBloc.add(const SyncEvent.mutationApplied()));
  }

  void _removeCoordinator(BuildContext context, String coordinatorId) {
    final orgRepo = context.read<OrganizationRepository>();
    final syncBloc = context.read<SyncBloc>();
    orgRepo
        .unassignCoordinatorById(
          organizationId: org.organizationId,
          deliveryId: delivery.deliveryId,
          contractId: contract.contractId,
          memberId: coordinatorId,
        )
        .then((_) => syncBloc.add(const SyncEvent.mutationApplied()));
  }

  void _showAdminPicker(BuildContext context, Map<String, Member> membersById) {
    // Restrict to the contract's coordinator pool, excluding members already
    // assigned on this delivery-contract.
    final coordinators = _assignablePoolMemberIds
        .map((id) => membersById[id])
        .whereType<Member>()
        .toList();

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _AdminCoordinatorPickerSheet(
        coordinators: coordinators,
        onSelected: (memberId) {
          Navigator.of(sheetContext).pop();
          final orgRepo = context.read<OrganizationRepository>();
          final syncBloc = context.read<SyncBloc>();
          orgRepo
              .assignCoordinatorById(
                organizationId: org.organizationId,
                deliveryId: delivery.deliveryId,
                contractId: contract.contractId,
                memberId: memberId,
              )
              .then((_) => syncBloc.add(const SyncEvent.mutationApplied()));
        },
      ),
    );
  }
}

/// A chip displaying one coordinator's name with an optional ✕ button.
class _CoordinatorChip extends StatelessWidget {
  const _CoordinatorChip({
    required this.coordinatorId,
    required this.displayName,
    required this.canRemove,
    required this.onRemove,
  });

  final String coordinatorId;
  final String displayName;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(displayName),
        IconButton(
          icon: const Icon(Icons.close),
          iconSize: 16,
          splashRadius: 16,
          // null onPressed disables the button visually.
          onPressed: canRemove ? onRemove : null,
          tooltip: canRemove ? 'Retirer' : null,
        ),
      ],
    );
  }
}

/// Bottom sheet for ADMIN to pick a coordinator from the AMAP roster.
class _AdminCoordinatorPickerSheet extends StatelessWidget {
  const _AdminCoordinatorPickerSheet({
    required this.coordinators,
    required this.onSelected,
  });

  final List<Member> coordinators;
  final ValueChanged<String> onSelected;

  String _name(Member m) {
    final first = m.firstName?.trim() ?? '';
    final last = m.lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return m.memberId;
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Ajouter un coordinateur',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (coordinators.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun coordinateur dans cette AMAP.'),
            )
          else
            for (final coordinator in coordinators)
              ListTile(
                title: Text(_name(coordinator)),
                onTap: () => onSelected(coordinator.memberId),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Block listing every volunteer slot of the edited delivery with per-slot
/// lifecycle actions (cancel / delete).
///
/// States per slot:
///  - active registrations → [ANNULER] enabled, [SUPPRIMER] disabled;
///  - no active registration → both enabled;
///  - CANCELLED → "ANNULÉ" badge, all actions disabled.
class _SlotsBlock extends StatelessWidget {
  const _SlotsBlock({
    required this.delivery,
    required this.org,
    required this.mainContractIds,
  });

  final Delivery delivery;
  final Organization org;

  /// Ids of the org's main contracts: only those mobilise volunteers, so only
  /// their slots are listed here (legacy fallback: when none of the delivery's
  /// links is main, every contract is shown).
  final Set<String> mainContractIds;

  @override
  Widget build(BuildContext context) {
    final mains = delivery.contracts
        .where((c) => mainContractIds.contains(c.contractId))
        .toList();
    final shownContracts = mains.isEmpty ? delivery.contracts : mains;
    final rows = <Widget>[];
    for (final contract in shownContracts) {
      for (final slot in contract.slots) {
        rows.add(
          _SlotRow(
            org: org,
            delivery: delivery,
            contract: contract,
            slot: slot,
          ),
        );
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '🕐 Créneaux bénévoles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

/// One row of [_SlotsBlock]: time range, active registration count, status
/// badge and the [ANNULER] / [SUPPRIMER] actions.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.org,
    required this.delivery,
    required this.contract,
    required this.slot,
  });

  final Organization org;
  final Delivery delivery;
  final DeliveryContract contract;
  final MemberSlot slot;

  bool get _isCancelled => slot.status == SlotStatus.cancelled;

  int get _activeRegistrations =>
      activeRegistrationsExcluding(slot, deliveryCoordinatorIds(delivery));

  String get _timeLabel {
    String hhmm(String iso) {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return '${hhmm(slot.startTime)} – ${hhmm(slot.endTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeRegistrations;
    final kindLabel = slot.slotKind == SlotKind.early
        ? 'Créneau anticipé'
        : 'Créneau standard';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$kindLabel • $_timeLabel • '
                  '$active inscrit${active > 1 ? 's' : ''}',
                  style: _isCancelled
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                        )
                      : Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (_isCancelled)
                Chip(
                  label: const Text('ANNULÉ'),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          if (!_isCancelled)
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _confirmCancel(context, active),
                  child: const Text('ANNULER'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  // Local guard: deletion requires no active registration.
                  // The server re-validates and returns CONFLICT on a race.
                  onPressed: active == 0 ? () => _confirmDelete(context) : null,
                  child: const Text('SUPPRIMER'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, int activeCount) {
    final bloc = context.read<TimeSlotsBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Annuler ce créneau ?',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                activeCount > 0
                    ? '$activeCount inscrit${activeCount > 1 ? 's' : ''} '
                          'seront notifiés et leurs inscriptions annulées.'
                    : 'Ce créneau ne compte aucun inscrit.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  bloc.add(
                    TimeSlotsEvent.slotCancelRequested(
                      currentOrg: org,
                      deliveryId: delivery.deliveryId,
                      contractId: contract.contractId,
                      slot: slot,
                    ),
                  );
                },
                child: const Text("CONFIRMER L'ANNULATION"),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('RETOUR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final bloc = context.read<TimeSlotsBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce créneau ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ANNULER'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(
                TimeSlotsEvent.slotDeleteRequested(
                  currentOrg: org,
                  deliveryId: delivery.deliveryId,
                  contractId: contract.contractId,
                  slot: slot,
                ),
              );
            },
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }
}
