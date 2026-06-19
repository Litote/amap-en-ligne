import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/shared_basket_view.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_ended_listener.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CoordinatorMemberContractsScreen extends StatefulWidget {
  const CoordinatorMemberContractsScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  State<CoordinatorMemberContractsScreen> createState() =>
      _CoordinatorMemberContractsScreenState();
}

class _CoordinatorMemberContractsScreenState
    extends State<CoordinatorMemberContractsScreen> {
  static const _desktopBreakpoint = 800.0;
  String? _selectedMemberId;
  final Set<String> _selectedContractIds = <String>{};
  final Map<String, Set<String>> _subscriptionKeysByContract =
      <String, Set<String>>{};
  String? _editingAssignedContractId;
  Set<String> _editingSubscriptionKeys = {};
  final TextEditingController _searchController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: 'Contrats par Amapien',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ConnectedScaffold(
      title: 'Contrats par Amapien',
      actions: const [SyncButton()],
      body: StreamBuilder<Organization?>(
        stream: context.read<OrganizationRepository>().watch(widget.tenantId),
        builder: (context, organizationSnapshot) {
          if (organizationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final organization = organizationSnapshot.data;
          if (organization == null) {
            return const Center(child: Text('Synchronisation en cours...'));
          }
          return StreamBuilder<List<Member>>(
            stream: context.read<MemberRepository>().watch(widget.tenantId),
            builder: (context, memberSnapshot) {
              if (!memberSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<List<Contract>>(
                stream: context.read<ContractRepository>().watch(
                  widget.tenantId,
                ),
                builder: (context, contractSnapshot) {
                  if (!contractSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = [...memberSnapshot.data ?? const <Member>[]]
                    ..sort(
                      (a, b) =>
                          memberDisplayName(a).compareTo(memberDisplayName(b)),
                    );
                  final search = _searchController.text.trim().toLowerCase();
                  final filteredMembers = members.where((member) {
                    if (search.isEmpty) return true;
                    return memberDisplayName(
                          member,
                        ).toLowerCase().contains(search) ||
                        (member.email?.toLowerCase().contains(search) ?? false);
                  }).toList();
                  final contracts = contractSnapshot.data ?? const <Contract>[];
                  final selectedMember = _resolveSelectedMember(
                    filteredMembers,
                  );
                  final activeAssignments = contracts
                      .where(
                        (contract) =>
                            contract.members.any(
                              (entry) =>
                                  entry.memberId == selectedMember?.memberId,
                            ) &&
                            contractStatusView(contract) ==
                                ContractStatusView.active,
                      )
                      .length;
                  final upcomingAssignments = contracts
                      .where(
                        (contract) =>
                            contract.members.any(
                              (entry) =>
                                  entry.memberId == selectedMember?.memberId,
                            ) &&
                            contractStatusView(contract) ==
                                ContractStatusView.upcoming,
                      )
                      .length;
                  return ContractEndedListener(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final list = _MemberList(
                          members: filteredMembers,
                          contracts: contracts,
                          selectedMemberId:
                              _selectedMemberId ?? selectedMember?.memberId,
                          searchController: _searchController,
                          shrinkWrap: false,
                          onSelected: (member) {
                            setState(() {
                              _selectedMemberId = member.memberId;
                              _selectedContractIds.clear();
                            });
                          },
                          onSearchChanged: (_) => setState(() {}),
                        );
                        final detail = selectedMember == null
                            ? const _NoMemberSelected()
                            : _MemberContractDetail(
                                member: selectedMember,
                                contracts: contracts,
                                organization: organization,
                                allMembers: members,
                                onManageSharedBasket: (contract) =>
                                    _manageSharedBasket(
                                      context,
                                      member: selectedMember,
                                      contract: contract,
                                      organization: organization,
                                      allMembers: members,
                                    ),
                                saving: _saving,
                                selectedContractIds: _selectedContractIds,
                                activeAssignments: activeAssignments,
                                upcomingAssignments: upcomingAssignments,
                                shrinkWrap: false,
                                subscriptionKeysByContract:
                                    _subscriptionKeysByContract,
                                editingAssignedContractId:
                                    _editingAssignedContractId,
                                editingSubscriptionKeys:
                                    _editingSubscriptionKeys,
                                onSelectionChanged: (contractId, selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedContractIds.add(contractId);
                                      if (!_subscriptionKeysByContract
                                              .containsKey(contractId) ||
                                          _subscriptionKeysByContract[contractId]!
                                              .isEmpty) {
                                        final contract = contracts.firstWhere(
                                          (c) => c.contractId == contractId,
                                        );
                                        final options =
                                            subscriptionOptionsFromPrices(
                                              contract.productPrices,
                                              organization,
                                            );
                                        if (options.length == 1) {
                                          _subscriptionKeysByContract[contractId] =
                                              {options.first.key};
                                        }
                                      }
                                    } else {
                                      _selectedContractIds.remove(contractId);
                                      _subscriptionKeysByContract.remove(
                                        contractId,
                                      );
                                    }
                                  });
                                },
                                onSubscriptionChanged: (contractId, keys) {
                                  setState(() {
                                    _subscriptionKeysByContract[contractId] =
                                        keys;
                                  });
                                },
                                onAssignSelection: () => _assignSelection(
                                  context,
                                  member: selectedMember,
                                  contracts: contracts,
                                  organization: organization,
                                ),
                                onRemove: (contract) => _removeAssignment(
                                  context,
                                  member: selectedMember,
                                  contract: contract,
                                  organization: organization,
                                ),
                                onStartEdit: _startEditSubscription,
                                onEditSubscriptionChanged: (keys) {
                                  setState(
                                    () => _editingSubscriptionKeys = keys,
                                  );
                                },
                                onSaveEdit: () => _saveEditSubscription(
                                  context,
                                  member: selectedMember,
                                  contract: contracts.firstWhere(
                                    (c) =>
                                        c.contractId ==
                                        _editingAssignedContractId,
                                  ),
                                  organization: organization,
                                ),
                                onCancelEdit: () {
                                  setState(
                                    () => _editingAssignedContractId = null,
                                  );
                                },
                              );
                        if (constraints.maxWidth >= _desktopBreakpoint) {
                          return Row(
                            children: [
                              SizedBox(width: 340, child: list),
                              const VerticalDivider(width: 1),
                              Expanded(child: detail),
                            ],
                          );
                        }
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MemberList(
                                members: filteredMembers,
                                contracts: contracts,
                                selectedMemberId:
                                    _selectedMemberId ??
                                    selectedMember?.memberId,
                                searchController: _searchController,
                                shrinkWrap: true,
                                onSelected: (member) {
                                  setState(() {
                                    _selectedMemberId = member.memberId;
                                    _selectedContractIds.clear();
                                  });
                                },
                                onSearchChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              if (selectedMember == null)
                                const _NoMemberSelected()
                              else
                                _MemberContractDetail(
                                  member: selectedMember,
                                  contracts: contracts,
                                  organization: organization,
                                  allMembers: members,
                                  onManageSharedBasket: (contract) =>
                                      _manageSharedBasket(
                                        context,
                                        member: selectedMember,
                                        contract: contract,
                                        organization: organization,
                                        allMembers: members,
                                      ),
                                  saving: _saving,
                                  selectedContractIds: _selectedContractIds,
                                  activeAssignments: activeAssignments,
                                  upcomingAssignments: upcomingAssignments,
                                  shrinkWrap: true,
                                  subscriptionKeysByContract:
                                      _subscriptionKeysByContract,
                                  editingAssignedContractId:
                                      _editingAssignedContractId,
                                  editingSubscriptionKeys:
                                      _editingSubscriptionKeys,
                                  onSelectionChanged: (contractId, selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedContractIds.add(contractId);
                                        if (!_subscriptionKeysByContract
                                                .containsKey(contractId) ||
                                            _subscriptionKeysByContract[contractId]!
                                                .isEmpty) {
                                          final contract = contracts.firstWhere(
                                            (c) => c.contractId == contractId,
                                          );
                                          final options =
                                              subscriptionOptionsFromPrices(
                                                contract.productPrices,
                                                organization,
                                              );
                                          if (options.length == 1) {
                                            _subscriptionKeysByContract[contractId] =
                                                {options.first.key};
                                          }
                                        }
                                      } else {
                                        _selectedContractIds.remove(contractId);
                                        _subscriptionKeysByContract.remove(
                                          contractId,
                                        );
                                      }
                                    });
                                  },
                                  onSubscriptionChanged: (contractId, keys) {
                                    setState(() {
                                      _subscriptionKeysByContract[contractId] =
                                          keys;
                                    });
                                  },
                                  onAssignSelection: () => _assignSelection(
                                    context,
                                    member: selectedMember,
                                    contracts: contracts,
                                    organization: organization,
                                  ),
                                  onRemove: (contract) => _removeAssignment(
                                    context,
                                    member: selectedMember,
                                    contract: contract,
                                    organization: organization,
                                  ),
                                  onStartEdit: _startEditSubscription,
                                  onEditSubscriptionChanged: (keys) {
                                    setState(
                                      () => _editingSubscriptionKeys = keys,
                                    );
                                  },
                                  onSaveEdit: () => _saveEditSubscription(
                                    context,
                                    member: selectedMember,
                                    contract: contracts.firstWhere(
                                      (c) =>
                                          c.contractId ==
                                          _editingAssignedContractId,
                                    ),
                                    organization: organization,
                                  ),
                                  onCancelEdit: () {
                                    setState(
                                      () => _editingAssignedContractId = null,
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Member? _resolveSelectedMember(List<Member> members) {
    for (final member in members) {
      if (member.memberId == _selectedMemberId) return member;
    }
    return members.isEmpty ? null : members.first;
  }

  Future<void> _assignSelection(
    BuildContext context, {
    required Member member,
    required List<Contract> contracts,
    required Organization organization,
  }) async {
    if (_saving || _selectedContractIds.isEmpty) return;
    final repository = context.read<ContractRepository>();
    final syncBloc = context.read<SyncBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final selectedContracts = contracts
        .where((contract) => _selectedContractIds.contains(contract.contractId))
        .toList();

    for (final contract in selectedContracts) {
      final keys = _subscriptionKeysByContract[contract.contractId] ?? {};
      if (keys.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Sélectionnez au moins un produit pour ${memberDisplayName(member)}.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      for (final contract in selectedContracts) {
        final nextMembers = [...contract.members];
        final alreadyAssigned = nextMembers.any(
          (entry) => entry.memberId == member.memberId,
        );
        if (alreadyAssigned) continue;

        final keys = _subscriptionKeysByContract[contract.contractId] ?? {};
        final options = subscriptionOptionsFromPrices(
          contract.productPrices,
          organization,
        );
        final subscriptions = subscriptionsFromKeys(keys, options);

        nextMembers.add(
          ContractMember(
            memberId: member.memberId,
            subscriptionInstant: DateTime.now().toUtc().toIso8601String(),
            status: ContractMemberStatus.active,
            subscriptions: subscriptions,
          ),
        );
        await repository.update(contract.copyWith(members: nextMembers));
      }
      if (!mounted) return;
      syncBloc.add(const SyncEvent.mutationApplied());
      setState(() {
        _selectedContractIds.clear();
        _subscriptionKeysByContract.clear();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${selectedContracts.length} contrat(s) ajouté(s) à ${memberDisplayName(member)}.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _removeAssignment(
    BuildContext context, {
    required Member member,
    required Contract contract,
    required Organization organization,
  }) async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le contrat ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Retirer ce contrat de ${memberDisplayName(member)} ?'),
            const SizedBox(height: 8),
            Text(
              contractProductLabel(contract, organization),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text('${contract.minDeliveryDate} → ${contract.maxDeliveryDate}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final nextMembers = contract.members
        .where((entry) => entry.memberId != member.memberId)
        .toList();
    setState(() => _saving = true);
    try {
      final repository = context.read<ContractRepository>();
      final syncBloc = context.read<SyncBloc>();
      final messenger = ScaffoldMessenger.of(context);
      await repository.update(contract.copyWith(members: nextMembers));
      if (!mounted) return;
      syncBloc.add(const SyncEvent.mutationApplied());
      messenger.showSnackBar(
        const SnackBar(content: Text('Le contrat a été retiré.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _startEditSubscription(Contract contract, ContractMember memberEntry) {
    setState(() {
      _editingAssignedContractId = contract.contractId;
      _editingSubscriptionKeys = keysFromSubscriptions(
        memberEntry.subscriptions,
      );
    });
  }

  Future<void> _saveEditSubscription(
    BuildContext context, {
    required Member member,
    required Contract contract,
    required Organization organization,
  }) async {
    if (_editingSubscriptionKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un produit.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final options = subscriptionOptionsFromPrices(
        contract.productPrices,
        organization,
      );
      final subscriptions = subscriptionsFromKeys(
        _editingSubscriptionKeys,
        options,
      );
      final nextMembers = contract.members
          .map(
            (entry) => entry.memberId == member.memberId
                ? entry.copyWith(subscriptions: subscriptions)
                : entry,
          )
          .toList();
      await context.read<ContractRepository>().update(
        contract.copyWith(members: nextMembers),
      );
      if (!context.mounted) return;
      context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
      setState(() => _editingAssignedContractId = null);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _manageSharedBasket(
    BuildContext context, {
    required Member member,
    required Contract contract,
    required Organization organization,
    required List<Member> allMembers,
  }) async {
    if (_saving) return;
    final result = await showDialog<SharedBasketDialogResult>(
      context: context,
      builder: (context) => _SharedBasketDialog(
        contract: contract,
        anchorMember: member,
        allMembers: allMembers,
      ),
    );
    if (result == null || !context.mounted) return;

    // Drop any existing shared basket that overlaps the affected members, then add the new one.
    final affected = {member.memberId, ...result.memberIds};
    final nextBaskets = contract.sharedBaskets
        .where((b) => b.memberIds.every((id) => !affected.contains(id)))
        .toList();
    if (!result.remove && result.memberIds.length >= 2) {
      nextBaskets.add(
        SharedBasket(
          sharedBasketId: '${ClientMutation.tmpIdPrefix}sb-'
              '${DateTime.now().microsecondsSinceEpoch}',
          memberIds: result.memberIds,
        ),
      );
    }

    setState(() => _saving = true);
    try {
      final repository = context.read<ContractRepository>();
      final syncBloc = context.read<SyncBloc>();
      final messenger = ScaffoldMessenger.of(context);
      await repository.update(contract.copyWith(sharedBaskets: nextBaskets));
      if (!mounted) return;
      syncBloc.add(const SyncEvent.mutationApplied());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.remove || result.memberIds.length < 2
                ? 'Le partage de panier a été supprimé.'
                : 'Le panier partagé a été enregistré.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.members,
    required this.contracts,
    required this.selectedMemberId,
    required this.searchController,
    required this.shrinkWrap,
    required this.onSelected,
    required this.onSearchChanged,
  });

  final List<Member> members;
  final List<Contract> contracts;
  final String? selectedMemberId;
  final TextEditingController searchController;
  final bool shrinkWrap;
  final ValueChanged<Member> onSelected;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Amapiens', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher un Amapien',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Aucun Amapien ne correspond à ces critères.'),
                ),
              )
            else if (shrinkWrap)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final count = contracts.where((contract) {
                    return contract.members.any(
                      (entry) => entry.memberId == member.memberId,
                    );
                  }).length;
                  return ListTile(
                    selected: member.memberId == selectedMemberId,
                    title: Text(memberDisplayName(member)),
                    subtitle: Text('$count contrat(s)'),
                    onTap: () => onSelected(member),
                  );
                },
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final count = contracts.where((contract) {
                      return contract.members.any(
                        (entry) => entry.memberId == member.memberId,
                      );
                    }).length;
                    return ListTile(
                      selected: member.memberId == selectedMemberId,
                      title: Text(memberDisplayName(member)),
                      subtitle: Text('$count contrat(s)'),
                      onTap: () => onSelected(member),
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

class _MemberContractDetail extends StatelessWidget {
  const _MemberContractDetail({
    required this.member,
    required this.contracts,
    required this.organization,
    required this.saving,
    required this.selectedContractIds,
    required this.activeAssignments,
    required this.upcomingAssignments,
    required this.shrinkWrap,
    required this.onSelectionChanged,
    required this.onAssignSelection,
    required this.onRemove,
    required this.subscriptionKeysByContract,
    required this.onSubscriptionChanged,
    required this.editingAssignedContractId,
    required this.editingSubscriptionKeys,
    required this.onStartEdit,
    required this.onEditSubscriptionChanged,
    required this.onSaveEdit,
    required this.onCancelEdit,
    required this.allMembers,
    required this.onManageSharedBasket,
  });

  final Member member;
  final List<Contract> contracts;
  final List<Member> allMembers;
  final ValueChanged<Contract> onManageSharedBasket;
  final Organization organization;
  final bool saving;
  final Set<String> selectedContractIds;
  final int activeAssignments;
  final int upcomingAssignments;
  final bool shrinkWrap;
  final void Function(String contractId, bool selected) onSelectionChanged;
  final VoidCallback onAssignSelection;
  final ValueChanged<Contract> onRemove;
  final Map<String, Set<String>> subscriptionKeysByContract;
  final void Function(String contractId, Set<String> keys)
  onSubscriptionChanged;
  final String? editingAssignedContractId;
  final Set<String> editingSubscriptionKeys;
  final void Function(Contract, ContractMember) onStartEdit;
  final ValueChanged<Set<String>> onEditSubscriptionChanged;
  final VoidCallback onSaveEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final assignedContracts =
        contracts
            .where(
              (contract) => contract.members.any(
                (entry) => entry.memberId == member.memberId,
              ),
            )
            .toList()
          ..sort(
            (a, b) => contractProductLabel(
              a,
              organization,
            ).compareTo(contractProductLabel(b, organization)),
          );
    final availableContracts =
        contracts
            .where(
              (contract) =>
                  !contract.members.any(
                    (entry) => entry.memberId == member.memberId,
                  ) &&
                  !isContractEffectivelyEnded(contract),
            )
            .toList()
          ..sort(
            (a, b) => contractProductLabel(
              a,
              organization,
            ).compareTo(contractProductLabel(b, organization)),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              memberDisplayName(member),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '🟢 $activeAssignments contrats actifs • 🔵 $upcomingAssignments à venir',
            ),
            if (member.email != null && member.email!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(member.email!),
              ),
            const SizedBox(height: 16),
            Text(
              'Contrats attribués',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (assignedContracts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Aucun contrat attribué pour le moment.'),
              )
            else
              ...assignedContracts.map((contract) {
                final memberEntry = contract.members.firstWhere(
                  (entry) => entry.memberId == member.memberId,
                  orElse: () => ContractMember(
                    memberId: member.memberId,
                    subscriptionInstant: '',
                    status: ContractMemberStatus.active,
                  ),
                );
                final isEditing =
                    editingAssignedContractId == contract.contractId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card.outlined(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            contractProductLabel(contract, organization),
                          ),
                          subtitle: Text(
                            '${contractStatusLabel(contractStatusView(contract))} • ${contract.seasonYear}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: saving
                                    ? null
                                    : () => onStartEdit(contract, memberEntry),
                                child: const Text('MODIFIER'),
                              ),
                              TextButton(
                                onPressed: saving
                                    ? null
                                    : () => onRemove(contract),
                                child: const Text('RETIRER'),
                              ),
                            ],
                          ),
                        ),
                        _SharedBasketRow(
                          contract: contract,
                          member: member,
                          allMembers: allMembers,
                          saving: saving,
                          onManage: () => onManageSharedBasket(contract),
                        ),
                        if (isEditing) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final option
                                    in subscriptionOptionsFromPrices(
                                      contract.productPrices,
                                      organization,
                                    ))
                                  CheckboxListTile(
                                    value: editingSubscriptionKeys.contains(
                                      option.key,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: saving
                                        ? null
                                        : (value) {
                                            final updated = Set<String>.from(
                                              editingSubscriptionKeys,
                                            );
                                            if (value ?? false) {
                                              updated.add(option.key);
                                            } else {
                                              updated.remove(option.key);
                                            }
                                            onEditSubscriptionChanged(updated);
                                          },
                                    title: Text(
                                      option.label,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: onCancelEdit,
                                        child: const Text('ANNULER'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: saving ? null : onSaveEdit,
                                        child: Text(
                                          saving
                                              ? 'Enregistrement...'
                                              : 'ENREGISTRER',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (memberEntry.subscriptions.isNotEmpty)
                          _SubscriptionSummary(
                            subscriptions: memberEntry.subscriptions,
                            organization: organization,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
            Text(
              'Contrats disponibles à l\'affectation',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (availableContracts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucun autre contrat disponible pour cet Amapien.',
                  ),
                ),
              )
            else if (shrinkWrap)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableContracts.length,
                itemBuilder: (context, index) {
                  final contract = availableContracts[index];
                  final selected = selectedContractIds.contains(
                    contract.contractId,
                  );
                  final subscriptionKeys =
                      subscriptionKeysByContract[contract.contractId] ?? {};
                  final options = subscriptionOptionsFromPrices(
                    contract.productPrices,
                    organization,
                  );
                  return Column(
                    children: [
                      CheckboxListTile(
                        value: selected,
                        controlAffinity: ListTileControlAffinity.trailing,
                        onChanged: saving
                            ? null
                            : (value) => onSelectionChanged(
                                contract.contractId,
                                value ?? false,
                              ),
                        title: Text(
                          contractProductLabel(contract, organization),
                        ),
                        subtitle: Text('${contract.seasonYear}'),
                      ),
                      if (selected && options.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 48,
                            right: 16,
                            bottom: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final option in options)
                                CheckboxListTile(
                                  value: subscriptionKeys.contains(option.key),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: saving
                                      ? null
                                      : (value) {
                                          final updated = Set<String>.from(
                                            subscriptionKeys,
                                          );
                                          if (value ?? false) {
                                            updated.add(option.key);
                                          } else {
                                            updated.remove(option.key);
                                          }
                                          onSubscriptionChanged(
                                            contract.contractId,
                                            updated,
                                          );
                                        },
                                  title: Text(
                                    option.label,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const Divider(),
                    ],
                  );
                },
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availableContracts.length,
                  itemBuilder: (context, index) {
                    final contract = availableContracts[index];
                    final selected = selectedContractIds.contains(
                      contract.contractId,
                    );
                    final subscriptionKeys =
                        subscriptionKeysByContract[contract.contractId] ?? {};
                    final options = subscriptionOptionsFromPrices(
                      contract.productPrices,
                      organization,
                    );
                    return Column(
                      children: [
                        CheckboxListTile(
                          value: selected,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: saving
                              ? null
                              : (value) => onSelectionChanged(
                                  contract.contractId,
                                  value ?? false,
                                ),
                          title: Text(
                            contractProductLabel(contract, organization),
                          ),
                          subtitle: Text('${contract.seasonYear}'),
                        ),
                        if (selected && options.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 48,
                              right: 16,
                              bottom: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final option in options)
                                  CheckboxListTile(
                                    value: subscriptionKeys.contains(
                                      option.key,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: saving
                                        ? null
                                        : (value) {
                                            final updated = Set<String>.from(
                                              subscriptionKeys,
                                            );
                                            if (value ?? false) {
                                              updated.add(option.key);
                                            } else {
                                              updated.remove(option.key);
                                            }
                                            onSubscriptionChanged(
                                              contract.contractId,
                                              updated,
                                            );
                                          },
                                    title: Text(
                                      option.label,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const Divider(),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: saving || selectedContractIds.isEmpty
                    ? null
                    : onAssignSelection,
                child: Text(
                  saving ? 'Enregistrement...' : 'AFFECTER LA SÉLECTION',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMemberSelected extends StatelessWidget {
  const _NoMemberSelected();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Sélectionnez un Amapien pour consulter et gérer ses contrats.',
          ),
        ),
      ),
    );
  }
}

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({
    required this.subscriptions,
    required this.organization,
  });

  final List<MemberSubscription> subscriptions;
  final Organization organization;

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return const SizedBox.shrink();
    }
    final options = subscriptionOptionsFromPrices(
      subscriptions
          .map(
            (sub) => ProductPrice(
              productTypeId: sub.productTypeId,
              basketSize: sub.basketSize,
            ),
          )
          .toList(),
      organization,
    );
    final labels = [
      for (final sub in subscriptions)
        options
            .firstWhere(
              (opt) =>
                  opt.key == subscriptionKey(sub.productTypeId, sub.basketSize),
              orElse: () => (
                key: subscriptionKey(sub.productTypeId, sub.basketSize),
                label: productTypeName(sub.productTypeId, organization),
                productTypeId: sub.productTypeId,
                basketSize: sub.basketSize,
              ),
            )
            .label,
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Text(
        '📦 ${labels.join(' • ')}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Result of [_SharedBasketDialog]: the ordered member ids forming the shared basket (the anchor
/// member first), or [remove] = true to clear the share.
class SharedBasketDialogResult {
  const SharedBasketDialogResult({required this.memberIds, this.remove = false});

  final List<String> memberIds;
  final bool remove;
}

/// Lets a coordinator group the [anchorMember] with other contract members who share an identical
/// subscription into a single shared basket (alternating pickup). The anchor member always picks
/// up the first distribution.
class _SharedBasketDialog extends StatefulWidget {
  const _SharedBasketDialog({
    required this.contract,
    required this.anchorMember,
    required this.allMembers,
  });

  final Contract contract;
  final Member anchorMember;
  final List<Member> allMembers;

  @override
  State<_SharedBasketDialog> createState() => _SharedBasketDialogState();
}

class _SharedBasketDialogState extends State<_SharedBasketDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final existing = sharedBasketForMember(
      widget.contract,
      widget.anchorMember.memberId,
    );
    _selected = {
      ...?existing?.memberIds.where((id) => id != widget.anchorMember.memberId),
    };
  }

  Set<String> _subscriptionKey(ContractMember entry) => entry.subscriptions
      .map((s) => '${s.productTypeId}|${s.basketSize?.name ?? ''}')
      .toSet();

  Member? _memberById(String id) {
    for (final m in widget.allMembers) {
      if (m.memberId == id) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final anchorEntry = widget.contract.members.firstWhere(
      (e) => e.memberId == widget.anchorMember.memberId,
      orElse: () => ContractMember(
        memberId: widget.anchorMember.memberId,
        subscriptionInstant: '',
        status: ContractMemberStatus.active,
      ),
    );
    final anchorKey = _subscriptionKey(anchorEntry);
    // Eligible co-sharers: other active contract members with an identical subscription.
    final candidates = widget.contract.members
        .where(
          (e) =>
              e.memberId != widget.anchorMember.memberId &&
              e.status == ContractMemberStatus.active &&
              _subscriptionKey(e).isNotEmpty &&
              _subscriptionKey(e).containsAll(anchorKey) &&
              anchorKey.containsAll(_subscriptionKey(e)),
        )
        .toList();
    final hasExisting =
        sharedBasketForMember(widget.contract, widget.anchorMember.memberId) !=
        null;

    return AlertDialog(
      title: const Text('Panier partagé'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Les familles sélectionnées se partagent un seul panier en '
              'alternance (une distribution chacune à tour de rôle). '
              '${memberDisplayName(widget.anchorMember)} récupère la première '
              'distribution.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (candidates.isEmpty)
              const Text(
                'Aucune autre famille de ce contrat ne souscrit au même '
                'produit et à la même taille de panier.',
              )
            else
              ...candidates.map((entry) {
                final candidate = _memberById(entry.memberId);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _selected.contains(entry.memberId),
                  title: Text(
                    candidate != null
                        ? memberDisplayName(candidate)
                        : entry.memberId,
                  ),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _selected.add(entry.memberId);
                    } else {
                      _selected.remove(entry.memberId);
                    }
                  }),
                );
              }),
            const SizedBox(height: 8),
            Text(
              'Un panier partagé compte pour un seul panier physique : pensez à '
              'ajuster le nombre de paniers de la distribution en conséquence.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        if (hasExisting)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const SharedBasketDialogResult(memberIds: [], remove: true),
            ),
            child: const Text('SUPPRIMER LE PARTAGE'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  SharedBasketDialogResult(
                    memberIds: [
                      widget.anchorMember.memberId,
                      ..._selected,
                    ],
                  ),
                ),
          child: const Text('ENREGISTRER'),
        ),
      ],
    );
  }
}

/// Shows, on a coordinator's assigned-contract card, whether [member] shares this contract's basket
/// with other families and offers a button to manage the shared basket.
class _SharedBasketRow extends StatelessWidget {
  const _SharedBasketRow({
    required this.contract,
    required this.member,
    required this.allMembers,
    required this.saving,
    required this.onManage,
  });

  final Contract contract;
  final Member member;
  final List<Member> allMembers;
  final bool saving;
  final VoidCallback onManage;

  String _nameOf(String memberId) {
    for (final m in allMembers) {
      if (m.memberId == memberId) return memberDisplayName(m);
    }
    return memberId;
  }

  @override
  Widget build(BuildContext context) {
    final coSharers = coSharersFor(contract, member.memberId);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              coSharers.isEmpty
                  ? 'Panier partagé : non'
                  : '🤝 Panier partagé avec ${coSharers.map(_nameOf).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: saving ? null : onManage,
            child: const Text('PANIER PARTAGÉ'),
          ),
        ],
      ),
    );
  }
}
