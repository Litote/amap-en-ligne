import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/shared_basket_view.dart';
import 'package:amap_en_ligne/presentation/common/error_feedback.dart';
import 'package:amap_en_ligne/presentation/common/status_badge.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const _kMyContractsTitle = 'Mes contrats';

class MemberContractsScreen extends StatefulWidget {
  const MemberContractsScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  State<MemberContractsScreen> createState() => _MemberContractsScreenState();
}

class _MemberContractsScreenState extends State<MemberContractsScreen> {
  ContractFilter _filter = ContractFilter.all;

  /// Data streams, created once per (tenant, member): re-creating them on a
  /// filter change re-subscribes the StreamBuilders, which flash their
  /// spinner and lose the scroll position.
  String? _streamsKey;
  late Stream<Organization?> _organizationStream;
  late Stream<Member?> _memberStream;
  late Stream<List<Contract>> _contractsStream;
  late Stream<List<ProducerAccount>> _producerAccountsStream;

  void _ensureStreams(BuildContext context, String sub) {
    final key = '${widget.tenantId}|$sub';
    if (_streamsKey == key) return;
    _streamsKey = key;
    _organizationStream = context.read<OrganizationRepository>().watch(
      widget.tenantId,
    );
    _memberStream = context.read<MemberRepository>().watchMyMember(sub);
    _contractsStream = context.read<ContractRepository>().watch(
      widget.tenantId,
    );
    _producerAccountsStream = context
        .read<ProducerAccountRepository>()
        .watchAll();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: _kMyContractsTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final sub = _resolveSub(context);
    if (sub.isEmpty) {
      return const ConnectedScaffold(
        title: _kMyContractsTitle,
        body: Center(child: Text('Impossible de charger votre profil.')),
      );
    }
    _ensureStreams(context, sub);
    return ConnectedScaffold(
      title: _kMyContractsTitle,
      body: StreamBuilder<Organization?>(
        stream: _organizationStream,
        builder: (context, organizationSnapshot) {
          if (organizationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildMemberSection(context, organizationSnapshot.data, sub);
        },
      ),
    );
  }

  Widget _buildMemberSection(
    BuildContext context,
    Organization? organization,
    String sub,
  ) => StreamBuilder<Member?>(
    stream: _memberStream,
    builder: (context, memberSnapshot) {
      if (memberSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final member = memberSnapshot.data;
      if (member == null) {
        return const Center(
          child: Text('Votre profil membre n\'est pas encore disponible.'),
        );
      }
      return _buildContractStream(context, organization, member);
    },
  );

  Widget _buildContractStream(
    BuildContext context,
    Organization? organization,
    Member member,
  ) => StreamBuilder<List<Contract>>(
    stream: _contractsStream,
    builder: (context, contractSnapshot) {
      if (!contractSnapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final contracts = contractSnapshot.data ?? const <Contract>[];
      // Producer accounts give the contract subtitle its producer name.
      return StreamBuilder<List<ProducerAccount>>(
        stream: _producerAccountsStream,
        builder: (context, producerSnapshot) => _buildContractsList(
          context,
          organization,
          member,
          contracts,
          producerSnapshot.data ?? const <ProducerAccount>[],
        ),
      );
    },
  );

  Widget _buildContractsList(
    BuildContext context,
    Organization? organization,
    Member member,
    List<Contract> contracts,
    List<ProducerAccount> producerAccounts,
  ) {
    final mine =
        contracts
            .where(
              (contract) => contract.members.any(
                (entry) => entry.memberId == member.memberId,
              ),
            )
            .toList()
          ..sort((a, b) => a.minDeliveryDate.compareTo(b.minDeliveryDate));
    final visible = mine
        .where(
          (contract) =>
              contractMatchesFilter(contract, _filter) &&
              contractStatusView(contract) != ContractStatusView.inPreparation,
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in ContractFilter.values)
                if (filter != ContractFilter.inPreparation)
                  FilterChip(
                    label: Text(_filterLabel(filter)),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          ..._contractSections(
            organization,
            member,
            mine,
            visible,
            producerAccounts,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.push('/planning'),
                icon: const Icon(Icons.calendar_month),
                label: const Text('PLANNING DES LIVRAISONS'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.history),
                label: const Text('MON HISTORIQUE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _contractSections(
    Organization? organization,
    Member member,
    List<Contract> mine,
    List<Contract> visible,
    List<ProducerAccount> producerAccounts,
  ) {
    if (mine.isEmpty) {
      return const [
        _EmptyContractsState(
          message:
              'Aucun contrat ne vous est actuellement attribué. Contactez votre coordinateur si nécessaire.',
        ),
      ];
    }
    if (visible.isEmpty) {
      return const [
        _EmptyContractsState(message: 'Aucun contrat dans cet état.'),
      ];
    }
    List<Contract> byView(ContractStatusView view) =>
        visible.where((c) => contractStatusView(c) == view).toList();
    final active = byView(ContractStatusView.active);
    final upcoming = byView(ContractStatusView.upcoming);
    final ended = byView(ContractStatusView.ended);
    return [
      if (active.isNotEmpty)
        _ContractSection(
          title: 'Contrats actifs',
          contracts: active,
          organization: organization,
          producerAccounts: producerAccounts,
          currentMemberId: member.memberId,
        ),
      if (upcoming.isNotEmpty)
        _ContractSection(
          title: 'Contrats à venir',
          contracts: upcoming,
          organization: organization,
          producerAccounts: producerAccounts,
          currentMemberId: member.memberId,
        ),
      if (ended.isNotEmpty)
        _ContractSection(
          title: 'Contrats terminés',
          contracts: ended,
          organization: organization,
          producerAccounts: producerAccounts,
          currentMemberId: member.memberId,
        ),
    ];
  }
}

class _ContractSection extends StatelessWidget {
  const _ContractSection({
    required this.title,
    required this.contracts,
    required this.organization,
    required this.producerAccounts,
    required this.currentMemberId,
  });

  final String title;
  final List<Contract> contracts;
  final Organization? organization;
  final List<ProducerAccount> producerAccounts;
  final String currentMemberId;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      for (final contract in contracts) ...[
        _ContractCard(
          contract: contract,
          organization: organization,
          producerAccounts: producerAccounts,
          currentMemberId: currentMemberId,
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.contract,
    required this.organization,
    required this.producerAccounts,
    required this.currentMemberId,
  });

  final Contract contract;
  final Organization? organization;
  final List<ProducerAccount> producerAccounts;
  final String currentMemberId;

  @override
  Widget build(BuildContext context) {
    final status = contractStatusView(contract);
    final memberEntry = contract.members.where(
      (entry) => entry.memberId == currentMemberId,
    );
    final subscriptionInstant = memberEntry.isEmpty
        ? null
        : memberEntry.first.subscriptionInstant;
    final subscriptions = memberEntry.isEmpty
        ? <MemberSubscription>[]
        : memberEntry.first.subscriptions;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contract.name, style: theme.textTheme.titleMedium),
                      Text(
                        contractProductLabel(
                          contract,
                          organization,
                          producerAccounts,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(contractStatusLabel(status), compact: false),
              ],
            ),
            const SizedBox(height: 8),
            Text('Saison : ${contract.seasonYear}'),
            Text(
              'Période : ${formatContractDate(contract.minDeliveryDate)} → ${formatContractDate(contract.maxDeliveryDate)}',
            ),
            Text('Livraisons : ${contract.deliveryCount}'),
            if (subscriptions.isNotEmpty) ...[
              const SizedBox(height: 4),
              _MemberSubscriptionSummary(
                subscriptions: subscriptions,
                organization: organization,
              ),
            ],
            _SharedBasketInfo(
              contract: contract,
              organization: organization,
              currentMemberId: currentMemberId,
            ),
            if (subscriptionInstant != null)
              Text('Souscrit le : ${formatContractDate(subscriptionInstant)}'),
          ],
        ),
      ),
    );
  }
}

/// Informs a member, on their contract card, that this contract's basket is shared in alternation
/// and on how many distributions it is their turn to pick it up.
class _SharedBasketInfo extends StatelessWidget {
  const _SharedBasketInfo({
    required this.contract,
    required this.organization,
    required this.currentMemberId,
  });

  final Contract contract;
  final Organization? organization;
  final String currentMemberId;

  @override
  Widget build(BuildContext context) {
    final basket = sharedBasketForMember(contract, currentMemberId);
    if (basket == null) return const SizedBox.shrink();
    final familyCount = basket.memberIds.length;
    final org = organization;
    final ordered = org == null
        ? const <Delivery>[]
        : contractDeliveriesOrdered(org, contract.contractId);
    final myPickups = org == null
        ? <Delivery>[]
        : pickupDeliveriesFor(contract, ordered, currentMemberId);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🤝 Panier partagé entre $familyCount familles : '
            'vous récupérez 1 distribution sur $familyCount.',
            style: theme.textTheme.bodyMedium,
          ),
          if (myPickups.isNotEmpty)
            Text(
              'Vos distributions : ${myPickups.map((d) => formatContractDate(d.scheduledDate)).join(' • ')}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _EmptyContractsState extends StatelessWidget {
  const _EmptyContractsState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    ),
  );
}

String _resolveSub(BuildContext context) {
  final authService = context.read<AuthService>();
  final state = authService.currentState;
  if (state is! Authenticated) return '';
  try {
    final claims = JwtClaims.decode(state.accessToken);
    return claims.string('sub') ?? '';
  } on Exception catch (e) {
    recordFallbackBreadcrumb('JWT sub decode failed', e);
    return '';
  }
}

String _filterLabel(ContractFilter filter) => switch (filter) {
  ContractFilter.all => 'Tous',
  ContractFilter.inPreparation => 'En préparation',
  ContractFilter.active => 'Actifs',
  ContractFilter.upcoming => 'À venir',
  ContractFilter.ended => 'Terminés',
};

class _MemberSubscriptionSummary extends StatelessWidget {
  const _MemberSubscriptionSummary({
    required this.subscriptions,
    required this.organization,
  });

  final List<MemberSubscription> subscriptions;
  final Organization? organization;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    for (final sub in subscriptions) {
      final product = organization?.products.cast<OrgProduct?>().firstWhere(
        (p) => p?.productTypeId == sub.productTypeId,
        orElse: () => null,
      );
      final productName = product?.name ?? sub.productTypeId;
      if (sub.basketSize != null) {
        labels.add('$productName — ${sub.basketSize?.name}');
      } else {
        labels.add(productName);
      }
    }

    return Text(
      '📦 ${labels.join(' • ')}',
      style: const TextStyle(fontSize: 12),
    );
  }
}
