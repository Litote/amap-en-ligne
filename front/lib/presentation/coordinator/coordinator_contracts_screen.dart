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
            return StreamBuilder<List<Contract>>(
              stream: _contractStream,
              builder: (context, contractSnapshot) {
                if (!contractSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<Member>>(
                  stream: _memberStream,
                  builder: (context, memberSnapshot) {
                    if (!memberSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return StreamBuilder<List<ProducerAccount>>(
                      stream: _producerStream,
                      builder: (context, producerSnapshot) {
                        if (!producerSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final contracts = [
                          ...contractSnapshot.data ?? const <Contract>[],
                        ]..sort((a, b) => b.seasonYear.compareTo(a.seasonYear));
                        final members = memberSnapshot.data ?? const <Member>[];
                        final producerAccounts =
                            producerSnapshot.data ?? const <ProducerAccount>[];
                        final selectedContract = _selectedContract(contracts);
                        _maybeLoadForm(organization, selectedContract);
                        return StreamBuilder<List<DeliveryTemplate>>(
                          stream: _templateStream,
                          builder: (context, templateSnapshot) {
                            final deliveryTemplates =
                                templateSnapshot.data ??
                                const <DeliveryTemplate>[];
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final hasActiveMembers =
                                    selectedContract != null &&
                                    selectedContract.members.any(
                                      (m) =>
                                          m.status !=
                                          ContractMemberStatus.cancelled,
                                    );
                                final form = _ContractEditor(
                                  formKey: _formKey,
                                  organization: organization,
                                  members: members,
                                  producerAccounts: producerAccounts,
                                  selectedContract: selectedContract,
                                  selectedProducerAccountId:
                                      _selectedProducerAccountId,
                                  priceControllers: _priceControllers,
                                  nameController: _nameController,
                                  seasonYearController: _seasonYearController,
                                  minDateController: _minDateController,
                                  maxDateController: _maxDateController,
                                  deliveryCountController:
                                      _deliveryCountController,
                                  coordinatorSelectorKey:
                                      _coordinatorSelectorKey,
                                  memberSearchController:
                                      _memberSearchController,
                                  initialMembersById: _initialMembersById,
                                  selectedMemberIds: _selectedMemberIds,
                                  memberSubscriptionKeys:
                                      _memberSubscriptionKeys,
                                  saving: _saving,
                                  contracts: contracts,
                                  includedProductTypeIds:
                                      _includedProductTypeIds,
                                  selectedStatus: _selectedStatus,
                                  onStatusChanged: (status) {
                                    if (status != null) {
                                      setState(() => _selectedStatus = status);
                                    }
                                  },
                                  selectedDeliveryTemplateId:
                                      _selectedDeliveryTemplateId,
                                  onTemplateChanged: (templateId) {
                                    setState(
                                      () => _selectedDeliveryTemplateId =
                                          templateId,
                                    );
                                  },
                                  deliveryTemplates: deliveryTemplates,
                                  onProducerChanged: (value) {
                                    setState(() {
                                      _selectedProducerAccountId = value;
                                      _includedProductTypeIds =
                                          _allProducerProductTypeIds(
                                            organization,
                                            value,
                                          );
                                      for (final ctrl
                                          in _priceControllers.values) {
                                        ctrl.dispose();
                                      }
                                      _priceControllers.clear();
                                    });
                                  },
                                  onProductIncludedToggled:
                                      (productTypeId, selected) {
                                        setState(() {
                                          final next = {
                                            ..._includedProductTypeIds,
                                          };
                                          if (selected) {
                                            next.add(productTypeId);
                                          } else {
                                            next.remove(productTypeId);
                                          }
                                          _includedProductTypeIds = next;
                                        });
                                      },
                                  onMemberToggled: (member, selected) {
                                    if (selected) {
                                      final productPrices = _priceControllers
                                          .keys
                                          .map((key) {
                                            final parts = key.split(':');
                                            final productTypeId = parts[0];
                                            if (!_includedProductTypeIds
                                                .contains(productTypeId)) {
                                              return null;
                                            }
                                            final basketSizeName =
                                                parts.length > 1
                                                ? parts[1]
                                                : '';
                                            return ProductPrice(
                                              productTypeId: productTypeId,
                                              basketSize: basketSizeName.isEmpty
                                                  ? null
                                                  : BasketSize(
                                                      name: basketSizeName,
                                                    ),
                                            );
                                          })
                                          .whereType<ProductPrice>()
                                          .toList();
                                      final options =
                                          subscriptionOptionsFromPrices(
                                            productPrices,
                                            organization,
                                          );
                                      if (options.length == 1 &&
                                          (_memberSubscriptionKeys[member
                                                      .memberId]
                                                  ?.isEmpty ??
                                              true)) {
                                        setState(() {
                                          _memberSubscriptionKeys = {
                                            ..._memberSubscriptionKeys,
                                            member.memberId: {
                                              options.first.key,
                                            },
                                          };
                                        });
                                      }
                                    }
                                    _onMemberToggled(
                                      context,
                                      member: member,
                                      selected: selected,
                                    );
                                  },
                                  onSelectAllMembers: _selectAllVisibleMembers,
                                  onMemberSearchChanged: (_) => setState(() {}),
                                  onMemberSubscriptionChanged:
                                      (memberId, key, selected) {
                                        setState(() {
                                          final keys =
                                              _memberSubscriptionKeys[memberId] ??
                                              <String>{};
                                          final next = {...keys};
                                          if (selected) {
                                            next.add(key);
                                          } else {
                                            next.remove(key);
                                          }
                                          _memberSubscriptionKeys[memberId] =
                                              next;
                                        });
                                      },
                                  onDateChanged: _onDateChanged,
                                  onSeasonYearChanged: () {
                                    setState(
                                      () => _seasonYearUserEdited = true,
                                    );
                                  },
                                  onDeliveryCountChanged: () {
                                    setState(
                                      () => _deliveryCountUserEdited = true,
                                    );
                                  },
                                  onSubmit: () => _saveContract(
                                    context,
                                    organization: organization,
                                    selectedContract: selectedContract,
                                    contracts: contracts,
                                  ),
                                  onDelete:
                                      selectedContract == null ||
                                          hasActiveMembers
                                      ? null
                                      : () => _deleteContract(
                                          context,
                                          contract: selectedContract,
                                        ),
                                );
                                final list = _ContractList(
                                  contracts: contracts,
                                  organization: organization,
                                  producerAccounts: producerAccounts,
                                  selectedContractId: _selectedContractId,
                                  onCreateRequested: _resetFormForCreate,
                                  onSelected: (contract) {
                                    setState(
                                      () => _selectedContractId =
                                          contract.contractId,
                                    );
                                  },
                                );
                                if (constraints.maxWidth >=
                                    _desktopBreakpoint) {
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
                              },
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
    _includedProductTypeIds = contract == null
        ? <String>{}
        : contract.productPrices.isNotEmpty
        ? {for (final p in contract.productPrices) p.productTypeId}
        : _allProducerProductTypeIds(organization, contract.producerAccountId);
    _nameController.text = contract?.name ?? '';
    _seasonYearController.text = contract?.seasonYear.toString() ?? '';
    _minDateController.text = contract?.minDeliveryDate ?? '';
    _maxDateController.text = contract?.maxDeliveryDate ?? '';
    _deliveryCountController.text = contract?.deliveryCount.toString() ?? '';
    _selectedStatus = contract?.status ?? ContractStatus.inPreparation;
    _selectedDeliveryTemplateId = contract?.deliveryTemplateId;
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
    required Contract? selectedContract,
    required List<Contract> contracts,
  }) async {
    if (_saving) return;
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du contrat est obligatoire.')),
      );
      return;
    }
    final duplicate = contracts.any(
      (c) =>
          c.name == trimmedName &&
          c.contractId != (selectedContract?.contractId ?? ''),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un contrat avec ce nom existe déjà dans cette AMAP.'),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final producerAccountId = _selectedProducerAccountId;
    if (producerAccountId == null || producerAccountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un producteur.')),
      );
      return;
    }
    final seasonYear = int.tryParse(_seasonYearController.text.trim());
    final deliveryCount = int.tryParse(_deliveryCountController.text.trim());
    if (seasonYear == null || deliveryCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les champs du contrat.'),
        ),
      );
      return;
    }
    final producerProductTypeIds = _allProducerProductTypeIds(
      organization,
      producerAccountId,
    );
    if (producerProductTypeIds.isNotEmpty &&
        producerProductTypeIds.intersection(_includedProductTypeIds).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un produit pour ce contrat.'),
        ),
      );
      return;
    }
    final productPrices = <ProductPrice>[];
    final producerProducts = organization.products
        .where((p) => p.producerAccountId == producerAccountId)
        .toList();
    for (final product in producerProducts) {
      if (!_includedProductTypeIds.contains(product.productTypeId)) continue;
      if (product.supportedBasketSizes.isEmpty) {
        final controllerKey = '${product.productTypeId}:';
        final controller = _priceControllers[controllerKey];
        final rawPrice = controller?.text.trim() ?? '';
        final price = rawPrice.isEmpty
            ? null
            : double.tryParse(rawPrice.replaceAll(',', '.'));
        productPrices.add(
          ProductPrice(
            productTypeId: product.productTypeId,
            basketSize: null,
            price: price,
          ),
        );
      } else {
        for (final basketSize in product.supportedBasketSizes) {
          final controllerKey = '${product.productTypeId}:${basketSize.name}';
          final controller = _priceControllers[controllerKey];
          final rawPrice = controller?.text.trim() ?? '';
          final price = rawPrice.isEmpty
              ? null
              : double.tryParse(rawPrice.replaceAll(',', '.'));
          productPrices.add(
            ProductPrice(
              productTypeId: product.productTypeId,
              basketSize: basketSize,
              price: price,
            ),
          );
        }
      }
    }
    // Validate subscriptions: each selected member must have at least one subscription
    final offeredKeys = subscriptionOptionsFromPrices(
      productPrices,
      organization,
    ).map((opt) => opt.key).toSet();
    for (final memberId in _selectedMemberIds) {
      final memberKeys = _memberSubscriptionKeys[memberId] ?? <String>{};
      final effectiveKeys = memberKeys.intersection(offeredKeys);
      if (effectiveKeys.isEmpty) {
        final member = _initialMembersById[memberId];
        final memberName = member != null
            ? memberDisplayName(
                Member(
                  memberId: member.memberId,
                  organizationId: organization.organizationId,
                ),
              )
            : memberId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sélectionnez au moins un produit pour $memberName.'),
          ),
        );
        return;
      }
    }

    final keptMembers = [
      for (final entry in selectedContract?.members ?? const <ContractMember>[])
        if (_selectedMemberIds.contains(entry.memberId))
          entry.copyWith(
            subscriptions: subscriptionsFromKeys(
              _memberSubscriptionKeys[entry.memberId] ?? <String>{},
              subscriptionOptionsFromPrices(productPrices, organization),
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
      producerAccountId: producerAccountId,
      minDeliveryDate: _minDateController.text.trim(),
      maxDeliveryDate: _maxDateController.text.trim(),
      deliveryCount: deliveryCount,
      seasonYear: seasonYear,
      productPrices: productPrices,
      coordinators: coordinators.toList()..sort(),
      status: _selectedStatus,
      deliveryTemplateId: _selectedDeliveryTemplateId,
      members: [
        ...keptMembers,
        for (final memberId in newMemberIds)
          ContractMember(
            memberId: memberId,
            subscriptionInstant: subscriptionInstant,
            status: ContractMemberStatus.active,
            subscriptions: subscriptionsFromKeys(
              _memberSubscriptionKeys[memberId] ?? <String>{},
              subscriptionOptionsFromPrices(productPrices, organization),
            ),
          ),
      ],
    );
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
    final newLabel = plan.newCount > 0
        ? '${plan.newCount} nouvelle${plan.newCount > 1 ? 's' : ''} '
              'livraison${plan.newCount > 1 ? 's' : ''}'
        : null;
    final linkedLabel = plan.linkedCount > 0
        ? '${plan.linkedCount} livraison'
              '${plan.linkedCount > 1 ? 's' : ''} '
              'existante${plan.linkedCount > 1 ? 's' : ''}'
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
                Text(
                  selectedContract == null
                      ? 'Nouveau contrat'
                      : 'Contrat sélectionné',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Nom du contrat *',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nom requis'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      activeProducers.any(
                        (p) => p.producerAccountId == selectedProducerAccountId,
                      )
                      ? selectedProducerAccountId
                      : null,
                  decoration: const InputDecoration(labelText: 'Producteur *'),
                  items: [
                    for (final producer in activeProducers)
                      DropdownMenuItem(
                        value: producer.producerAccountId,
                        child: Text(_producerName(producer.producerAccountId)),
                      ),
                  ],
                  onChanged: saving ? null : onProducerChanged,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Producteur requis'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ContractStatus>(
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
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue:
                      selectedDeliveryTemplateId != null &&
                          deliveryTemplates.any(
                            (t) =>
                                t.deliveryTemplateId ==
                                selectedDeliveryTemplateId,
                          )
                      ? selectedDeliveryTemplateId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Modèle de livraison',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucun')),
                    for (final template in deliveryTemplates)
                      DropdownMenuItem(
                        value: template.deliveryTemplateId,
                        child: Text(template.name),
                      ),
                  ],
                  onChanged: saving ? null : onTemplateChanged,
                ),
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
                  decoration: const InputDecoration(
                    labelText: 'Année de saison *',
                  ),
                  onChanged: (_) => onSeasonYearChanged(),
                  validator: (value) =>
                      int.tryParse(value?.trim() ?? '') == null
                      ? 'Année invalide'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deliveryCountController,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de livraisons *',
                  ),
                  onChanged: (_) => onDeliveryCountChanged(),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    return parsed == null || parsed <= 0
                        ? 'Valeur invalide'
                        : null;
                  },
                ),
                if (selectedProducerAccountId != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Prix par produit',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_producerProducts.isEmpty)
                    Text(
                      'Aucun produit associé à ce producteur.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    for (final product in _producerProducts) ...[
                      CheckboxListTile(
                        value: includedProductTypeIds.contains(
                          product.productTypeId,
                        ),
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
                      if (includedProductTypeIds.contains(
                        product.productTypeId,
                      ))
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
                              controllerKey:
                                  '${product.productTypeId}:${basketSize.name}',
                              priceControllers: priceControllers,
                              saving: saving,
                            ),
                    ],
                ],
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed:
                            saving ||
                                visibleMembers.every(
                                  (member) => selectedMemberIds.contains(
                                    member.memberId,
                                  ),
                                )
                            ? null
                            : () => onSelectAllMembers(visibleMembers),
                        child: const Text('TOUT SÉLECTIONNER'),
                      ),
                    ),
                  if (visibleMembers.isEmpty)
                    const Text('Aucun Amapien ne correspond à ces critères.')
                  else
                    for (final member in visibleMembers) ...[
                      CheckboxListTile(
                        value: selectedMemberIds.contains(member.memberId),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(memberDisplayName(member)),
                        subtitle:
                            member.email != null &&
                                member.email!.trim().isNotEmpty
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
                                    !initialMembersById.containsKey(
                                      member.memberId,
                                    ))
                            ? null
                            : (value) =>
                                  onMemberToggled(member, value ?? false),
                      ),
                      if (selectedMemberIds.contains(member.memberId) &&
                          selectedProducerAccountId != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: _SubscriptionCheckboxes(
                            memberId: member.memberId,
                            memberSubscriptionKeys:
                                memberSubscriptionKeys[member.memberId] ??
                                <String>{},
                            productPrices: priceControllers.keys
                                .map((key) {
                                  final parts = key.split(':');
                                  final productTypeId = parts[0];
                                  final basketSizeName = parts.length > 1
                                      ? parts[1]
                                      : '';
                                  if (!includedProductTypeIds.contains(
                                    productTypeId,
                                  )) {
                                    return null;
                                  }
                                  return ProductPrice(
                                    productTypeId: productTypeId,
                                    basketSize: basketSizeName.isEmpty
                                        ? null
                                        : BasketSize(name: basketSizeName),
                                  );
                                })
                                .whereType<ProductPrice>()
                                .toList(),
                            organization: organization,
                            saving: saving,
                            onSubscriptionToggled: (key, selected) =>
                                onMemberSubscriptionChanged(
                                  member.memberId,
                                  key,
                                  selected,
                                ),
                          ),
                        ),
                    ],
                ],
                const SizedBox(height: 16),
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
              ],
            ),
          ),
        ),
      ),
    );
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
