import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/model/weekly_delivery_plan.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_ended_listener.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CoordinatorContractsScreen extends StatefulWidget {
  const CoordinatorContractsScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  State<CoordinatorContractsScreen> createState() =>
      _CoordinatorContractsScreenState();
}

class _CoordinatorContractsScreenState
    extends State<CoordinatorContractsScreen> {
  static const _desktopBreakpoint = 800.0;
  final _formKey = GlobalKey<FormState>();
  final _coordinatorSelectorKey = GlobalKey<_CoordinatorSelectorState>();
  final _nameController = TextEditingController();
  final _seasonYearController = TextEditingController();
  final _minDateController = TextEditingController();
  final _maxDateController = TextEditingController();
  final _deliveryCountController = TextEditingController();
  final _memberSearchController = TextEditingController();
  final Map<String, TextEditingController> _priceControllers = {};

  String? _selectedContractId;
  String? _selectedProducerAccountId;
  Set<String> _includedProductTypeIds = <String>{};
  Map<String, ContractMember> _initialMembersById = {};
  Set<String> _selectedMemberIds = <String>{};
  Map<String, Set<String>> _memberSubscriptionKeys = {};
  String? _loadedFormKey;
  bool _saving = false;
  bool _seasonYearUserEdited = false;
  bool _deliveryCountUserEdited = false;
  ContractStatus _selectedStatus = ContractStatus.inPreparation;
  String? _selectedDeliveryTemplateId;
  bool _selectedIsMainContract = false;

  // Cached watch streams. Repository `watch(...)` calls return a fresh drift
  // stream on every invocation, so creating them inline in `build` would make
  // each `setState` resubscribe every StreamBuilder — momentarily reporting
  // ConnectionState.waiting and tearing down the form subtree, which drops
  // input focus. Memoising them by tenant keeps the same instances across
  // rebuilds.
  String? _streamsTenantId;
  late Stream<Organization?> _organizationStream;
  late Stream<List<Contract>> _contractStream;
  late Stream<List<Member>> _memberStream;
  late Stream<List<ProducerAccount>> _producerStream;
  late Stream<List<DeliveryTemplate>> _templateStream;

  void _ensureStreams() {
    if (_streamsTenantId == widget.tenantId) return;
    _streamsTenantId = widget.tenantId;
    _organizationStream = context.read<OrganizationRepository>().watch(
      widget.tenantId,
    );
    _contractStream = context.read<ContractRepository>().watch(widget.tenantId);
    _memberStream = context.read<MemberRepository>().watch(widget.tenantId);
    _producerStream = context.read<ProducerAccountRepository>().watchAll();
    _templateStream = context.read<DeliveryTemplateRepository>().watch(
      widget.tenantId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seasonYearController.dispose();
    _minDateController.dispose();
    _maxDateController.dispose();
    _deliveryCountController.dispose();
    _memberSearchController.dispose();
    for (final ctrl in _priceControllers.values) {
      ctrl.dispose();
    }
    _priceControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: 'Gestion des contrats',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _ensureStreams();
    return ConnectedScaffold(
      title: 'Gestion des contrats',
      actions: const [SyncButton()],
      body: ContractEndedListener(
        child: StreamBuilder<Organization?>(
          stream: _organizationStream,
          builder: (context, organizationSnapshot) {
            if (organizationSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final organization = organizationSnapshot.data;
            if (organization == null) {
              return const Center(child: Text('Synchronisation en cours...'));
            }
            return _buildContractStream(context, organization);
          },
        ),
      ),
    );
  }

  Widget _buildContractStream(BuildContext context, Organization organization) {
    return StreamBuilder<List<Contract>>(
      stream: _contractStream,
      builder: (context, contractSnapshot) {
        if (!contractSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final contracts = [...contractSnapshot.data ?? const <Contract>[]]
          ..sort((a, b) => b.seasonYear.compareTo(a.seasonYear));
        return _buildMemberStream(context, organization, contracts);
      },
    );
  }

  Widget _buildMemberStream(
    BuildContext context,
    Organization organization,
    List<Contract> contracts,
  ) {
    return StreamBuilder<List<Member>>(
      stream: _memberStream,
      builder: (context, memberSnapshot) {
        if (!memberSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = memberSnapshot.data ?? const <Member>[];
        return _buildProducerStream(context, organization, contracts, members);
      },
    );
  }

  /// Auto-selects the first active main contract when nothing is selected yet.
  /// Schedules the setState via addPostFrameCallback to avoid mutating state
  /// during build.
  void _autoSelectFirstMainContract(
    List<Contract> contracts,
    Contract? selectedContract,
  ) {
    if (_selectedContractId != null || selectedContract != null) return;
    Contract? firstActiveMainContract;
    for (final contract in contracts) {
      if (contract.status == ContractStatus.active && contract.isMainContract) {
        firstActiveMainContract = contract;
        break;
      }
    }
    if (firstActiveMainContract == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedContractId == null) {
        setState(() {
          _selectedContractId = firstActiveMainContract!.contractId;
        });
      }
    });
  }

  Widget _buildProducerStream(
    BuildContext context,
    Organization organization,
    List<Contract> contracts,
    List<Member> members,
  ) {
    return StreamBuilder<List<ProducerAccount>>(
      stream: _producerStream,
      builder: (context, producerSnapshot) {
        if (!producerSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final producerAccounts =
            producerSnapshot.data ?? const <ProducerAccount>[];
        final selectedContract = _selectedContract(contracts);

        _autoSelectFirstMainContract(contracts, selectedContract);

        _maybeLoadForm(organization, selectedContract);
        return _buildTemplateStream(context, (
          organization: organization,
          members: members,
          producerAccounts: producerAccounts,
          contracts: contracts,
          selectedContract: selectedContract,
        ));
      },
    );
  }

  Widget _buildTemplateStream(
    BuildContext context,
    ({
      Organization organization,
      List<Member> members,
      List<ProducerAccount> producerAccounts,
      List<Contract> contracts,
      Contract? selectedContract,
    })
    data,
  ) {
    return StreamBuilder<List<DeliveryTemplate>>(
      stream: _templateStream,
      builder: (context, templateSnapshot) {
        final deliveryTemplates =
            templateSnapshot.data ?? const <DeliveryTemplate>[];
        return LayoutBuilder(
          builder: (context, constraints) =>
              _buildWorkspace(context, constraints, data, deliveryTemplates),
        );
      },
    );
  }

  void _onStatusChanged(ContractStatus? status) {
    if (status != null) setState(() => _selectedStatus = status);
  }

  void _onTemplateChanged(String? templateId) {
    setState(() => _selectedDeliveryTemplateId = templateId);
  }

  void _onMainContractChanged(bool value) {
    setState(() => _selectedIsMainContract = value);
  }

  void _onSeasonYearChanged() {
    setState(() => _seasonYearUserEdited = true);
  }

  void _onDeliveryCountChanged() {
    setState(() => _deliveryCountUserEdited = true);
  }

  void _onProducerChanged(Organization organization, String? value) {
    setState(() {
      _selectedProducerAccountId = value;
      _includedProductTypeIds = _allProducerProductTypeIds(organization, value);
      for (final ctrl in _priceControllers.values) {
        ctrl.dispose();
      }
      _priceControllers.clear();
    });
  }

  void _onProductIncludedToggled(String productTypeId, bool selected) {
    setState(() {
      final next = {..._includedProductTypeIds};
      if (selected) {
        next.add(productTypeId);
      } else {
        next.remove(productTypeId);
      }
      _includedProductTypeIds = next;
    });
  }

  void _onMemberSubscriptionChanged(
    String memberId,
    String key,
    bool selected,
  ) {
    setState(() {
      final keys = _memberSubscriptionKeys[memberId] ?? <String>{};
      final next = {...keys};
      if (selected) {
        next.add(key);
      } else {
        next.remove(key);
      }
      _memberSubscriptionKeys[memberId] = next;
    });
  }

  void _handleMemberToggle(
    BuildContext context,
    Organization organization,
    Member member,
    bool selected,
  ) {
    if (selected) _autoSelectSoleSubscription(organization, member);
    _onMemberToggled(context, member: member, selected: selected);
  }

  /// When the included products yield exactly one subscription option and the
  /// member has none selected yet, pre-select it.
  void _autoSelectSoleSubscription(Organization organization, Member member) {
    final productPrices = _priceControllers.keys
        .map((key) {
          final parts = key.split(':');
          final productTypeId = parts[0];
          if (!_includedProductTypeIds.contains(productTypeId)) return null;
          final basketSizeName = parts.length > 1 ? parts[1] : '';
          return ProductPrice(
            productTypeId: productTypeId,
            basketSize: basketSizeName.isEmpty
                ? null
                : BasketSize(name: basketSizeName),
          );
        })
        .whereType<ProductPrice>()
        .toList();
    final options = subscriptionOptionsFromPrices(productPrices, organization);
    if (options.length == 1 &&
        (_memberSubscriptionKeys[member.memberId]?.isEmpty ?? true)) {
      setState(() {
        _memberSubscriptionKeys = {
          ..._memberSubscriptionKeys,
          member.memberId: {options.first.key},
        };
      });
    }
  }

  Widget _buildWorkspace(
    BuildContext context,
    BoxConstraints constraints,
    ({
      Organization organization,
      List<Member> members,
      List<ProducerAccount> producerAccounts,
      List<Contract> contracts,
      Contract? selectedContract,
    })
    data,
    List<DeliveryTemplate> deliveryTemplates,
  ) {
    final organization = data.organization;
    final contracts = data.contracts;
    final selectedContract = data.selectedContract;
    final hasActiveMembers =
        selectedContract != null &&
        selectedContract.members.any(
          (m) => m.status != ContractMemberStatus.cancelled,
        );
    final form = _ContractEditor(
      formKey: _formKey,
      organization: organization,
      members: data.members,
      producerAccounts: data.producerAccounts,
      selectedContract: selectedContract,
      selectedProducerAccountId: _selectedProducerAccountId,
      priceControllers: _priceControllers,
      nameController: _nameController,
      seasonYearController: _seasonYearController,
      minDateController: _minDateController,
      maxDateController: _maxDateController,
      deliveryCountController: _deliveryCountController,
      coordinatorSelectorKey: _coordinatorSelectorKey,
      memberSearchController: _memberSearchController,
      initialMembersById: _initialMembersById,
      selectedMemberIds: _selectedMemberIds,
      memberSubscriptionKeys: _memberSubscriptionKeys,
      saving: _saving,
      contracts: contracts,
      includedProductTypeIds: _includedProductTypeIds,
      selectedStatus: _selectedStatus,
      onStatusChanged: _onStatusChanged,
      selectedDeliveryTemplateId: _selectedDeliveryTemplateId,
      onTemplateChanged: _onTemplateChanged,
      selectedIsMainContract: _selectedIsMainContract,
      onMainContractChanged: _onMainContractChanged,
      deliveryTemplates: deliveryTemplates,
      onProducerChanged: (value) => _onProducerChanged(organization, value),
      onProductIncludedToggled: _onProductIncludedToggled,
      onMemberToggled: (member, selected) =>
          _handleMemberToggle(context, organization, member, selected),
      onSelectAllMembers: _selectAllVisibleMembers,
      onMemberSearchChanged: (_) => setState(() {}),
      onMemberSubscriptionChanged: _onMemberSubscriptionChanged,
      onDateChanged: _onDateChanged,
      onSeasonYearChanged: _onSeasonYearChanged,
      onDeliveryCountChanged: _onDeliveryCountChanged,
      onSubmit: () => _saveContract(
        context,
        organization: organization,
        members: data.members,
        selectedContract: selectedContract,
        contracts: contracts,
      ),
      onDelete: selectedContract == null || hasActiveMembers
          ? null
          : () => _deleteContract(context, contract: selectedContract),
    );
    final list = _ContractList(
      contracts: contracts,
      organization: organization,
      producerAccounts: data.producerAccounts,
      selectedContractId: _selectedContractId,
      onCreateRequested: _resetFormForCreate,
      onSelected: (contract) =>
          setState(() => _selectedContractId = contract.contractId),
    );
    if (constraints.maxWidth >= _desktopBreakpoint) {
      return Row(
        children: [
          SizedBox(width: 360, child: list),
          const VerticalDivider(width: 1),
          Expanded(child: form),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(height: 320, child: list),
        const SizedBox(height: 16),
        form,
      ],
    );
  }

  Contract? _selectedContract(List<Contract> contracts) {
    for (final contract in contracts) {
      if (contract.contractId == _selectedContractId) return contract;
    }
    if (_selectedContractId != null) {
      _selectedContractId = null;
      _loadedFormKey = null;
    }
    return null;
  }

  void _maybeLoadForm(Organization organization, Contract? contract) {
    final key =
        '${organization.organizationId}:${contract?.contractId ?? 'new'}';
    if (_loadedFormKey == key) return;
    _loadedFormKey = key;
    _selectedProducerAccountId = contract?.producerAccountId;
    // A product is part of the contract iff it has at least one entry in
    // productPrices; a legacy contract without any entry includes every
    // product of its producer.
    if (contract == null) {
      _includedProductTypeIds = <String>{};
    } else if (contract.productPrices.isNotEmpty) {
      _includedProductTypeIds = {
        for (final p in contract.productPrices) p.productTypeId,
      };
    } else {
      _includedProductTypeIds = _allProducerProductTypeIds(
        organization,
        contract.producerAccountId,
      );
    }
    _nameController.text = contract?.name ?? '';
    _seasonYearController.text = contract?.seasonYear.toString() ?? '';
    _minDateController.text = contract?.minDeliveryDate ?? '';
    _maxDateController.text = contract?.maxDeliveryDate ?? '';
    _deliveryCountController.text = contract?.deliveryCount.toString() ?? '';
    _selectedStatus = contract?.status ?? ContractStatus.inPreparation;
    _selectedDeliveryTemplateId = contract?.deliveryTemplateId;
    _selectedIsMainContract = contract?.isMainContract ?? false;
    _initialMembersById = {
      for (final entry in contract?.members ?? const <ContractMember>[])
        entry.memberId: entry,
    };
    _selectedMemberIds = _initialMembersById.keys.toSet();
    _memberSubscriptionKeys = {
      for (final entry in contract?.members ?? const <ContractMember>[])
        entry.memberId: keysFromSubscriptions(entry.subscriptions),
    };
    _memberSearchController.clear();
    _seasonYearUserEdited = false;
    _deliveryCountUserEdited = false;
    for (final ctrl in _priceControllers.values) {
      ctrl.dispose();
    }
    _priceControllers.clear();
    if (contract != null) {
      for (final p in contract.productPrices) {
        final key = '${p.productTypeId}:${p.basketSize?.name ?? ''}';
        _priceControllers[key] = TextEditingController(
          text: p.price?.toString() ?? '',
        );
      }
    }
  }

  Set<String> _allProducerProductTypeIds(
    Organization organization,
    String? producerAccountId,
  ) {
    if (producerAccountId == null) return <String>{};
    return {
      for (final product in organization.products)
        if (product.producerAccountId == producerAccountId)
          product.productTypeId,
    };
  }

  void _onDateChanged() {
    final minDate = DateTime.tryParse(_minDateController.text.trim());
    final maxDate = DateTime.tryParse(_maxDateController.text.trim());
    if (minDate != null && !_seasonYearUserEdited) {
      _seasonYearController.text = minDate.year.toString();
    }
    if (minDate != null && maxDate != null && !_deliveryCountUserEdited) {
      final weeks = (maxDate.difference(minDate).inDays / 7).round();
      _deliveryCountController.text = weeks < 1 ? '1' : '$weeks';
    }
  }

  void _resetFormForCreate() {
    setState(() {
      _selectedContractId = null;
      _loadedFormKey = null;
      _seasonYearUserEdited = false;
      _deliveryCountUserEdited = false;
    });
  }

  Future<void> _onMemberToggled(
    BuildContext context, {
    required Member member,
    required bool selected,
  }) async {
    if (selected) {
      setState(() {
        _selectedMemberIds = {..._selectedMemberIds, member.memberId};
      });
      return;
    }
    if (_initialMembersById.containsKey(member.memberId)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Retirer cet amapien du contrat ?'),
          content: Text(
            '${memberDisplayName(member)} : son inscription (date, statut, '
            'souscriptions) sera définitivement supprimée à l\'enregistrement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULER'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('RETIRER'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    setState(() {
      _selectedMemberIds = {..._selectedMemberIds}..remove(member.memberId);
    });
  }

  void _selectAllVisibleMembers(List<Member> visibleMembers) {
    setState(() {
      _selectedMemberIds = {
        ..._selectedMemberIds,
        for (final member in visibleMembers) member.memberId,
      };
    });
  }

  Future<void> _deleteContract(
    BuildContext context, {
    required Contract contract,
  }) async {
    final repository = context.read<ContractRepository>();
    final syncBloc = context.read<SyncBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contrat ?'),
        content: const Text(
          'Cette action est irréversible. Le contrat sera définitivement supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await repository.delete(contract.contractId, contract.organizationId);
    if (!mounted) return;
    syncBloc.add(const SyncEvent.mutationApplied());
    setState(() => _selectedContractId = null);
    messenger.showSnackBar(
      const SnackBar(content: Text('Le contrat a été supprimé.')),
    );
  }

  Future<void> _saveContract(
    BuildContext context, {
    required Organization organization,
    required List<Member> members,
    required Contract? selectedContract,
    required List<Contract> contracts,
  }) async {
    if (_saving) return;
    final trimmedName = _nameController.text.trim();
    final basics = _validateContractBasics(
      context,
      organization: organization,
      selectedContract: selectedContract,
      contracts: contracts,
      trimmedName: trimmedName,
    );
    if (basics == null) return;

    final productPrices = _buildProductPrices(
      organization,
      basics.producerAccountId,
    );
    if (!_validateMemberSubscriptions(
      context,
      organization,
      members,
      productPrices,
    )) {
      return;
    }

    final options = subscriptionOptionsFromPrices(productPrices, organization);
    final keptMembers = [
      for (final entry in selectedContract?.members ?? const <ContractMember>[])
        if (_selectedMemberIds.contains(entry.memberId))
          entry.copyWith(
            subscriptions: subscriptionsFromKeys(
              _memberSubscriptionKeys[entry.memberId] ?? <String>{},
              options,
            ),
          ),
    ];
    final newMemberIds =
        _selectedMemberIds
            .difference(keptMembers.map((entry) => entry.memberId).toSet())
            .toList()
          ..sort();
    final subscriptionInstant = DateTime.now().toUtc().toIso8601String();
    final coordinators =
        _coordinatorSelectorKey.currentState?.getSelectedCoordinators() ??
        <String>{};
    final contract = Contract(
      contractId: selectedContract?.contractId ?? '',
      name: trimmedName,
      organizationId: organization.organizationId,
      producerAccountId: basics.producerAccountId,
      minDeliveryDate: _minDateController.text.trim(),
      maxDeliveryDate: _maxDateController.text.trim(),
      deliveryCount: basics.deliveryCount,
      seasonYear: basics.seasonYear,
      productPrices: productPrices,
      coordinators: coordinators.toList()..sort(),
      status: _selectedStatus,
      deliveryTemplateId: _selectedDeliveryTemplateId,
      isMainContract: _selectedIsMainContract,
      members: [
        ...keptMembers,
        for (final memberId in newMemberIds)
          ContractMember(
            memberId: memberId,
            subscriptionInstant: subscriptionInstant,
            status: ContractMemberStatus.active,
            subscriptions: subscriptionsFromKeys(
              _memberSubscriptionKeys[memberId] ?? <String>{},
              options,
            ),
          ),
      ],
    );
    await _persistContract(
      context,
      organization: organization,
      selectedContract: selectedContract,
      contract: contract,
    );
  }

  /// Validates the contract form's basic fields, showing a SnackBar and
  /// returning null on the first failure; otherwise returns the parsed values.
  ({String producerAccountId, int seasonYear, int deliveryCount})?
  _validateContractBasics(
    BuildContext context, {
    required Organization organization,
    required Contract? selectedContract,
    required List<Contract> contracts,
    required String trimmedName,
  }) {
    void showError(String message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (trimmedName.isEmpty) {
      showError('Le nom du contrat est obligatoire.');
      return null;
    }
    final duplicate = contracts.any(
      (c) =>
          c.name == trimmedName &&
          c.contractId != (selectedContract?.contractId ?? ''),
    );
    if (duplicate) {
      showError('Un contrat avec ce nom existe déjà dans cette AMAP.');
      return null;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    final producerAccountId = _selectedProducerAccountId;
    if (producerAccountId == null || producerAccountId.isEmpty) {
      showError('Veuillez sélectionner un producteur.');
      return null;
    }
    final seasonYear = int.tryParse(_seasonYearController.text.trim());
    final deliveryCount = int.tryParse(_deliveryCountController.text.trim());
    if (seasonYear == null || deliveryCount == null) {
      showError('Veuillez corriger les champs du contrat.');
      return null;
    }
    final producerProductTypeIds = _allProducerProductTypeIds(
      organization,
      producerAccountId,
    );
    if (producerProductTypeIds.isNotEmpty &&
        producerProductTypeIds.intersection(_includedProductTypeIds).isEmpty) {
      showError('Sélectionnez au moins un produit pour ce contrat.');
      return null;
    }
    return (
      producerAccountId: producerAccountId,
      seasonYear: seasonYear,
      deliveryCount: deliveryCount,
    );
  }

  ProductPrice _priceFor(
    String productTypeId,
    BasketSize? basketSize,
    String controllerKey,
  ) {
    final rawPrice = _priceControllers[controllerKey]?.text.trim() ?? '';
    final price = rawPrice.isEmpty
        ? null
        : double.tryParse(rawPrice.replaceAll(',', '.'));
    return ProductPrice(
      productTypeId: productTypeId,
      basketSize: basketSize,
      price: price,
    );
  }

  List<ProductPrice> _buildProductPrices(
    Organization organization,
    String producerAccountId,
  ) {
    final productPrices = <ProductPrice>[];
    final producerProducts = organization.products
        .where((p) => p.producerAccountId == producerAccountId)
        .toList();
    for (final product in producerProducts) {
      if (!_includedProductTypeIds.contains(product.productTypeId)) continue;
      if (product.supportedBasketSizes.isEmpty) {
        productPrices.add(
          _priceFor(product.productTypeId, null, '${product.productTypeId}:'),
        );
      } else {
        for (final basketSize in product.supportedBasketSizes) {
          productPrices.add(
            _priceFor(
              product.productTypeId,
              basketSize,
              '${product.productTypeId}:${basketSize.name}',
            ),
          );
        }
      }
    }
    return productPrices;
  }

  /// Ensures each selected member keeps at least one offered subscription;
  /// shows a SnackBar and returns false on the first member without one.
  bool _validateMemberSubscriptions(
    BuildContext context,
    Organization organization,
    List<Member> members,
    List<ProductPrice> productPrices,
  ) {
    final offeredKeys = subscriptionOptionsFromPrices(
      productPrices,
      organization,
    ).map((opt) => opt.key).toSet();
    for (final memberId in _selectedMemberIds) {
      final memberKeys = _memberSubscriptionKeys[memberId] ?? <String>{};
      if (memberKeys.intersection(offeredKeys).isNotEmpty) continue;
      Member? member;
      for (final candidate in members) {
        if (candidate.memberId == memberId) {
          member = candidate;
          break;
        }
      }
      final memberName = member != null ? memberDisplayName(member) : memberId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sélectionnez au moins un produit pour $memberName.'),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _persistContract(
    BuildContext context, {
    required Organization organization,
    required Contract? selectedContract,
    required Contract contract,
  }) async {
    setState(() => _saving = true);
    try {
      final repository = context.read<ContractRepository>();
      final syncBloc = context.read<SyncBloc>();
      final messenger = ScaffoldMessenger.of(context);
      final deliveryTemplateRepository = context
          .read<DeliveryTemplateRepository>();
      final orgRepo = context.read<OrganizationRepository>();
      final saved = selectedContract == null
          ? await repository.create(contract)
          : contract;
      if (selectedContract != null) {
        await repository.update(contract);
      }
      if (!mounted) return;

      // After creating a new contract, offer to plan weekly deliveries.
      // The sync trigger is deferred until after this flow so the contract
      // upsert and the generated deliveries ride the same sync batch — the
      // back only remaps a tmp_* contract id within a single batch, so
      // syncing the contract alone first would leave the delivery links
      // pointing at a tmp id nothing can resolve any more.
      if (selectedContract == null && mounted) {
        await _maybeOfferWeeklyDeliveries(
          saved,
          organization,
          deliveryTemplateRepository,
          orgRepo,
          repository,
        );
      }
      syncBloc.add(const SyncEvent.mutationApplied());

      if (!mounted) return;
      setState(() {
        _selectedContractId = selectedContract == null
            ? saved.contractId
            : selectedContract.contractId;
        // Reload the form state from the persisted contract so the member
        // selection reflects the saved entries (new ids, fresh instants).
        _loadedFormKey = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            selectedContract == null
                ? 'Le contrat a été créé.'
                : 'Le contrat a été mis à jour.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _maybeOfferWeeklyDeliveries(
    Contract saved,
    Organization organization,
    DeliveryTemplateRepository deliveryTemplateRepository,
    OrganizationRepository orgRepo,
    ContractRepository repository,
  ) async {
    final deliveryTemplates = await deliveryTemplateRepository
        .watch(widget.tenantId)
        .first;
    if (!mounted) return;
    final resolvedTemplate = _resolveTemplate(
      saved,
      organization,
      deliveryTemplates,
    );
    var counter = 0;
    final plan = planWeeklyDeliveries(
      contract: saved,
      org: organization,
      template: resolvedTemplate,
      nextTmpId: () => ++counter,
    );
    if (plan.totalAffected > 0 && mounted) {
      await _offerWeeklyDeliveries(
        plan: plan,
        savedContract: saved,
        template: resolvedTemplate,
        orgRepo: orgRepo,
        contractRepo: repository,
      );
    }
  }

  /// Presents the weekly-delivery confirmation dialog and, if the user
  /// confirms, applies the plan via [orgRepo].
  ///
  /// [plan] only feeds the dialog labels: on confirmation the organization
  /// and the contract are re-read from the repositories and the plan is
  /// recomputed — a sync may have completed while the dialog was open,
  /// remapping [savedContract]'s `tmp_*` id to its server id.
  ///
  /// Extracted to a separate method so that [context] is only used in a
  /// synchronous frame — no [await] precedes this call site in the caller.
  Future<void> _offerWeeklyDeliveries({
    required WeeklyDeliveryPlan plan,
    required Contract savedContract,
    required DeliveryTemplate? template,
    required OrganizationRepository orgRepo,
    required ContractRepository contractRepo,
  }) async {
    final newPlural = plan.newCount > 1 ? 's' : '';
    final newLabel = plan.newCount > 0
        ? '${plan.newCount} nouvelle$newPlural livraison$newPlural'
        : null;
    final linkedPlural = plan.linkedCount > 1 ? 's' : '';
    final linkedLabel = plan.linkedCount > 0
        ? '${plan.linkedCount} livraison$linkedPlural existante$linkedPlural'
        : null;
    final parts = [?newLabel, if (linkedLabel != null) 'lier $linkedLabel'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer les livraisons hebdomadaires ?'),
        content: Text('${parts.join(' et ')} à ce contrat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final freshOrg = await orgRepo.watch(widget.tenantId).first;
      if (freshOrg == null) return;
      final freshContracts = await contractRepo.watch(widget.tenantId).first;
      final resolvedContract = resolveSavedContract(
        freshContracts,
        savedContract,
      );
      var counter = 0;
      final freshPlan = planWeeklyDeliveries(
        contract: resolvedContract,
        org: freshOrg,
        template: template,
        nextTmpId: () => ++counter,
      );
      if (freshPlan.totalAffected == 0) return;
      await orgRepo.updateDeliveries(
        currentOrg: freshOrg,
        deliveries: freshPlan.deliveries,
      );
    }
  }

  /// Resolves the [DeliveryTemplate] to use for a newly created [contract].
  ///
  /// Priority:
  /// 1. [Contract.deliveryTemplateId] if set.
  /// 2. [Organization.defaultDeliveryTemplateId] if set.
  /// 3. First template in the list, if any.
  /// 4. null.
  DeliveryTemplate? _resolveTemplate(
    Contract contract,
    Organization org,
    List<DeliveryTemplate> templates,
  ) {
    if (templates.isEmpty) return null;
    final contractTplId = contract.deliveryTemplateId;
    if (contractTplId != null) {
      final found = templates.where(
        (t) => t.deliveryTemplateId == contractTplId,
      );
      if (found.isNotEmpty) return found.first;
    }
    final orgTplId = org.defaultDeliveryTemplateId;
    if (orgTplId != null) {
      final found = templates.where((t) => t.deliveryTemplateId == orgTplId);
      if (found.isNotEmpty) return found.first;
    }
    return templates.first;
  }
}

class _ContractList extends StatelessWidget {
  const _ContractList({
    required this.contracts,
    required this.organization,
    required this.producerAccounts,
    required this.selectedContractId,
    required this.onCreateRequested,
    required this.onSelected,
  });

  final List<Contract> contracts;
  final Organization organization;
  final List<ProducerAccount> producerAccounts;
  final String? selectedContractId;
  final VoidCallback onCreateRequested;
  final ValueChanged<Contract> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contrats',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onCreateRequested,
                  child: const Text('➕ NOUVEAU CONTRAT'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: contracts.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun contrat de saison n\'est encore défini. Créez votre premier contrat.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: contracts.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final contract = contracts[index];
                        final selected =
                            contract.contractId == selectedContractId;
                        final producerName = contractProductLabel(
                          contract,
                          organization,
                          producerAccounts,
                        );
                        return ListTile(
                          selected: selected,
                          title: Text(contract.name),
                          subtitle: Text(
                            '$producerName • ${contract.seasonYear} • ${contract.members.length} amapiens',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => onSelected(contract),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractEditor extends StatelessWidget {
  const _ContractEditor({
    required this.formKey,
    required this.organization,
    required this.members,
    required this.producerAccounts,
    required this.selectedContract,
    required this.selectedProducerAccountId,
    required this.priceControllers,
    required this.nameController,
    required this.seasonYearController,
    required this.minDateController,
    required this.maxDateController,
    required this.deliveryCountController,
    required this.coordinatorSelectorKey,
    required this.memberSearchController,
    required this.initialMembersById,
    required this.selectedMemberIds,
    required this.memberSubscriptionKeys,
    required this.saving,
    required this.contracts,
    required this.includedProductTypeIds,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.selectedDeliveryTemplateId,
    required this.onTemplateChanged,
    required this.selectedIsMainContract,
    required this.onMainContractChanged,
    required this.deliveryTemplates,
    required this.onProducerChanged,
    required this.onProductIncludedToggled,
    required this.onMemberToggled,
    required this.onSelectAllMembers,
    required this.onMemberSearchChanged,
    required this.onMemberSubscriptionChanged,
    required this.onDateChanged,
    required this.onSeasonYearChanged,
    required this.onDeliveryCountChanged,
    required this.onSubmit,
    required this.onDelete,
  });

  final GlobalKey<FormState> formKey;
  final Organization organization;
  final List<Member> members;
  final List<ProducerAccount> producerAccounts;
  final Contract? selectedContract;
  final String? selectedProducerAccountId;
  final Map<String, TextEditingController> priceControllers;
  final TextEditingController nameController;
  final TextEditingController seasonYearController;
  final TextEditingController minDateController;
  final TextEditingController maxDateController;
  final TextEditingController deliveryCountController;
  final GlobalKey<_CoordinatorSelectorState> coordinatorSelectorKey;
  final TextEditingController memberSearchController;
  final Map<String, ContractMember> initialMembersById;
  final Set<String> selectedMemberIds;
  final Map<String, Set<String>> memberSubscriptionKeys;
  final bool saving;
  final List<Contract> contracts;
  final Set<String> includedProductTypeIds;
  final ContractStatus selectedStatus;
  final ValueChanged<ContractStatus?> onStatusChanged;
  final String? selectedDeliveryTemplateId;
  final ValueChanged<String?> onTemplateChanged;
  final bool selectedIsMainContract;
  final ValueChanged<bool> onMainContractChanged;
  final List<DeliveryTemplate> deliveryTemplates;
  final ValueChanged<String?> onProducerChanged;
  final void Function(String productTypeId, bool selected)
  onProductIncludedToggled;
  final void Function(Member member, bool selected) onMemberToggled;
  final ValueChanged<List<Member>> onSelectAllMembers;
  final ValueChanged<String> onMemberSearchChanged;
  final void Function(String memberId, String key, bool selected)
  onMemberSubscriptionChanged;
  final VoidCallback onDateChanged;
  final VoidCallback onSeasonYearChanged;
  final VoidCallback onDeliveryCountChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onDelete;

  List<OrgProduct> get _producerProducts {
    if (selectedProducerAccountId == null) return const [];
    return organization.products
        .where((p) => p.producerAccountId == selectedProducerAccountId)
        .toList();
  }

  List<Member> get _visibleMembers {
    final search = memberSearchController.text.trim().toLowerCase();
    return members.where((member) {
        if (search.isEmpty) return true;
        return memberDisplayName(member).toLowerCase().contains(search) ||
            (member.email?.toLowerCase().contains(search) ?? false);
      }).toList()
      ..sort((a, b) => memberDisplayName(a).compareTo(memberDisplayName(b)));
  }

  @override
  Widget build(BuildContext context) {
    final activeProducers = organization.producers
        .where((p) => p.status == OrganizationProducerStatus.active)
        .toList();
    final coordinators = members
        .where(
          (member) =>
              member.roles.contains(Role.coordinator) ||
              member.roles.contains(Role.admin),
        )
        .toList();
    final contract = selectedContract;
    final contractEnded =
        contract != null && isContractEffectivelyEnded(contract);
    final visibleMembers = _visibleMembers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._buildBasicFields(context, activeProducers),
                ..._buildPricesSection(context),
                ..._buildMembersSection(
                  context,
                  visibleMembers,
                  coordinators,
                  contractEnded,
                ),
                const SizedBox(height: 16),
                ..._buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) =>
      value == null || value.trim().isEmpty ? 'Nom requis' : null;

  String? _validateProducer(String? value) =>
      value == null || value.isEmpty ? 'Producteur requis' : null;

  String? _validateSeasonYear(String? value) =>
      int.tryParse(value?.trim() ?? '') == null ? 'Année invalide' : null;

  String? _validateDeliveryCount(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0 ? 'Valeur invalide' : null;
  }

  Widget _buildProducerDropdown(List<OrganizationProducer> activeProducers) {
    final hasSelected = activeProducers.any(
      (p) => p.producerAccountId == selectedProducerAccountId,
    );
    return DropdownButtonFormField<String>(
      initialValue: hasSelected ? selectedProducerAccountId : null,
      decoration: const InputDecoration(labelText: 'Producteur *'),
      items: [
        for (final producer in activeProducers)
          DropdownMenuItem(
            value: producer.producerAccountId,
            child: Text(_producerName(producer.producerAccountId)),
          ),
      ],
      onChanged: saving ? null : onProducerChanged,
      validator: _validateProducer,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<ContractStatus>(
      initialValue: selectedStatus,
      decoration: const InputDecoration(labelText: 'Statut'),
      items: [
        for (final status in ContractStatus.values)
          DropdownMenuItem(
            value: status,
            child: Text(_contractStatusLabel(status)),
          ),
      ],
      onChanged: saving ? null : onStatusChanged,
    );
  }

  Widget _buildTemplateDropdown() {
    final hasSelected =
        selectedDeliveryTemplateId != null &&
        deliveryTemplates.any(
          (t) => t.deliveryTemplateId == selectedDeliveryTemplateId,
        );
    return DropdownButtonFormField<String?>(
      initialValue: hasSelected ? selectedDeliveryTemplateId : null,
      decoration: const InputDecoration(labelText: 'Modèle de livraison'),
      items: [
        const DropdownMenuItem(value: null, child: Text('Aucun')),
        for (final template in deliveryTemplates)
          DropdownMenuItem(
            value: template.deliveryTemplateId,
            child: Text(template.name),
          ),
      ],
      onChanged: saving ? null : onTemplateChanged,
    );
  }

  Widget _buildMainContractSwitch() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: selectedIsMainContract,
      title: const Text('Contrat principal'),
      subtitle: const Text(
        'Ce contrat mobilise des bénévoles (ex. légumes). '
        'Les contrats secondaires ne requièrent que le coordinateur.',
      ),
      onChanged: saving ? null : onMainContractChanged,
    );
  }

  List<Widget> _buildBasicFields(
    BuildContext context,
    List<OrganizationProducer> activeProducers,
  ) {
    return [
      Text(
        selectedContract == null ? 'Nouveau contrat' : 'Contrat sélectionné',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: nameController,
        enabled: !saving,
        decoration: const InputDecoration(labelText: 'Nom du contrat *'),
        validator: _validateName,
      ),
      const SizedBox(height: 12),
      _buildProducerDropdown(activeProducers),
      const SizedBox(height: 12),
      _buildStatusDropdown(),
      const SizedBox(height: 12),
      _buildTemplateDropdown(),
      const SizedBox(height: 12),
      _buildMainContractSwitch(),
      const SizedBox(height: 12),
      _DatePickerField(
        controller: minDateController,
        labelText: 'Date de première livraison *',
        enabled: !saving,
        onChanged: onDateChanged,
      ),
      const SizedBox(height: 12),
      _DatePickerField(
        controller: maxDateController,
        labelText: 'Date de dernière livraison *',
        enabled: !saving,
        onChanged: onDateChanged,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: seasonYearController,
        enabled: !saving,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Année de saison *'),
        onChanged: (_) => onSeasonYearChanged(),
        validator: _validateSeasonYear,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: deliveryCountController,
        enabled: !saving,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Nombre de livraisons *'),
        onChanged: (_) => onDeliveryCountChanged(),
        validator: _validateDeliveryCount,
      ),
    ];
  }

  List<Widget> _buildPricesSection(BuildContext context) {
    if (selectedProducerAccountId == null) return const [];
    return [
      const SizedBox(height: 16),
      Text('Prix par produit', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      if (_producerProducts.isEmpty)
        Text(
          'Aucun produit associé à ce producteur.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        )
      else
        for (final product in _producerProducts)
          ..._buildProductPriceTile(product),
    ];
  }

  List<Widget> _buildProductPriceTile(OrgProduct product) {
    return [
      CheckboxListTile(
        value: includedProductTypeIds.contains(product.productTypeId),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(product.name),
        onChanged: saving
            ? null
            : (value) => onProductIncludedToggled(
                product.productTypeId,
                value ?? false,
              ),
      ),
      if (includedProductTypeIds.contains(product.productTypeId))
        if (product.supportedBasketSizes.isEmpty)
          _PriceRow(
            label: null,
            controllerKey: '${product.productTypeId}:',
            priceControllers: priceControllers,
            saving: saving,
          )
        else
          for (final basketSize in product.supportedBasketSizes)
            _PriceRow(
              label: basketSize.name,
              controllerKey: '${product.productTypeId}:${basketSize.name}',
              priceControllers: priceControllers,
              saving: saving,
            ),
    ];
  }

  List<Widget> _buildMembersSection(
    BuildContext context,
    List<Member> visibleMembers,
    List<Member> coordinators,
    bool contractEnded,
  ) {
    return [
      const SizedBox(height: 16),
      Text(
        'Coordinateurs référents',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      if (coordinators.isEmpty)
        const Text('Aucun coordinateur disponible dans cette AMAP.')
      else
        _CoordinatorSelector(
          key: coordinatorSelectorKey,
          coordinators: coordinators,
          saving: saving,
          initialCoordinatorIds: {...?selectedContract?.coordinators},
        ),
      const SizedBox(height: 16),
      Text(
        'Amapiens rattachés (${selectedMemberIds.length})',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      if (members.isEmpty)
        const Text('Aucun amapien dans cette AMAP.')
      else ...[
        TextField(
          controller: memberSearchController,
          enabled: !saving,
          decoration: const InputDecoration(
            labelText: 'Rechercher un amapien',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onMemberSearchChanged,
        ),
        const SizedBox(height: 8),
        if (contractEnded)
          Text(
            'Contrat terminé — aucune nouvelle inscription possible.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          )
        else
          _buildSelectAllButton(visibleMembers),
        if (visibleMembers.isEmpty)
          const Text('Aucun Amapien ne correspond à ces critères.')
        else
          for (final member in visibleMembers)
            ..._buildMemberTile(member, contractEnded),
      ],
    ];
  }

  Widget _buildSelectAllButton(List<Member> visibleMembers) {
    final allSelected = visibleMembers.every(
      (member) => selectedMemberIds.contains(member.memberId),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: saving || allSelected
            ? null
            : () => onSelectAllMembers(visibleMembers),
        child: const Text('TOUT SÉLECTIONNER'),
      ),
    );
  }

  List<Widget> _buildMemberTile(Member member, bool contractEnded) {
    return [
      CheckboxListTile(
        value: selectedMemberIds.contains(member.memberId),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(memberDisplayName(member)),
        subtitle: member.email != null && member.email!.trim().isNotEmpty
            ? Text(member.email!)
            : null,
        secondary: initialMembersById[member.memberId] != null
            ? Text(
                contractMemberStatusLabel(
                  initialMembersById[member.memberId]!.status,
                ),
              )
            : null,
        onChanged:
            saving ||
                (contractEnded &&
                    !initialMembersById.containsKey(member.memberId))
            ? null
            : (value) => onMemberToggled(member, value ?? false),
      ),
      if (selectedMemberIds.contains(member.memberId) &&
          selectedProducerAccountId != null)
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: _SubscriptionCheckboxes(
            memberId: member.memberId,
            memberSubscriptionKeys:
                memberSubscriptionKeys[member.memberId] ?? <String>{},
            productPrices: _currentProductPrices(),
            organization: organization,
            saving: saving,
            onSubscriptionToggled: (key, selected) =>
                onMemberSubscriptionChanged(member.memberId, key, selected),
          ),
        ),
    ];
  }

  List<ProductPrice> _currentProductPrices() {
    return priceControllers.keys
        .map((key) {
          final parts = key.split(':');
          final productTypeId = parts[0];
          final basketSizeName = parts.length > 1 ? parts[1] : '';
          if (!includedProductTypeIds.contains(productTypeId)) return null;
          return ProductPrice(
            productTypeId: productTypeId,
            basketSize: basketSizeName.isEmpty
                ? null
                : BasketSize(name: basketSizeName),
          );
        })
        .whereType<ProductPrice>()
        .toList();
  }

  List<Widget> _buildActions() {
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          if (selectedContract != null)
            OutlinedButton(
              onPressed: saving ? null : onDelete,
              child: const Text('🗑 SUPPRIMER'),
            ),
          FilledButton(
            onPressed: saving ? null : onSubmit,
            child: Text(
              saving ? 'Enregistrement...' : 'ENREGISTRER LE CONTRAT',
            ),
          ),
        ],
      ),
    ];
  }

  String _producerName(String producerAccountId) {
    try {
      return producerAccounts
          .firstWhere((p) => p.producerAccountId == producerAccountId)
          .name;
    } catch (_) {
      return producerAccountId;
    }
  }

  String _contractStatusLabel(ContractStatus status) => switch (status) {
    ContractStatus.inPreparation => 'En préparation',
    ContractStatus.active => 'Actif',
    ContractStatus.ended => 'Terminé',
  };
}

class _DatePickerField extends StatefulWidget {
  const _DatePickerField({
    required this.controller,
    required this.labelText,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  late final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: widget.enabled
            ? IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _showDatePicker,
              )
            : null,
      ),
      validator: (value) => DateTime.tryParse(value?.trim() ?? '') == null
          ? 'Date invalide'
          : null,
    );
  }

  Future<void> _showDatePicker() async {
    _focusNode.unfocus();
    final dateText = widget.controller.text.trim();
    final parsedDate = DateTime.tryParse(dateText) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parsedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      widget.controller.text = picked.toString().split(' ')[0];
      widget.onChanged();
    }
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.controllerKey,
    required this.priceControllers,
    required this.saving,
  });

  final String? label;
  final String controllerKey;
  final Map<String, TextEditingController> priceControllers;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final controller = priceControllers.putIfAbsent(
      controllerKey,
      () => TextEditingController(),
    );
    final displayLabel = label ?? 'Prix (€)';
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(displayLabel)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Prix (€)',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCheckboxes extends StatelessWidget {
  const _SubscriptionCheckboxes({
    required this.memberId,
    required this.memberSubscriptionKeys,
    required this.productPrices,
    required this.organization,
    required this.saving,
    required this.onSubscriptionToggled,
  });

  final String memberId;
  final Set<String> memberSubscriptionKeys;
  final List<ProductPrice> productPrices;
  final Organization organization;
  final bool saving;
  final void Function(String key, bool selected) onSubscriptionToggled;

  @override
  Widget build(BuildContext context) {
    final options = subscriptionOptionsFromPrices(productPrices, organization);

    return Column(
      children: [
        for (final option in options)
          CheckboxListTile(
            value: memberSubscriptionKeys.contains(option.key),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(
              option.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onChanged: saving
                ? null
                : (value) => onSubscriptionToggled(option.key, value ?? false),
          ),
      ],
    );
  }
}

class _CoordinatorSelector extends StatefulWidget {
  const _CoordinatorSelector({
    super.key,
    required this.coordinators,
    required this.saving,
    required this.initialCoordinatorIds,
  });

  final List<Member> coordinators;
  final bool saving;
  final Set<String> initialCoordinatorIds;

  @override
  State<_CoordinatorSelector> createState() => _CoordinatorSelectorState();
}

class _CoordinatorSelectorState extends State<_CoordinatorSelector> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialCoordinatorIds};
  }

  @override
  void didUpdateWidget(_CoordinatorSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCoordinatorIds != widget.initialCoordinatorIds) {
      _selectedIds = {...widget.initialCoordinatorIds};
    }
  }

  Set<String> getSelectedCoordinators() => _selectedIds;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final member in widget.coordinators)
          FilterChip(
            label: Text(memberDisplayName(member)),
            selected: _selectedIds.contains(member.memberId),
            onSelected: widget.saving
                ? null
                : (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds.add(member.memberId);
                      } else {
                        _selectedIds.remove(member.memberId);
                      }
                    });
                  },
          ),
      ],
    );
  }
}
