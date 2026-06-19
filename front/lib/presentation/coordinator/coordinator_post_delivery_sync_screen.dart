import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CoordinatorPostDeliverySyncScreen extends StatelessWidget {
  const CoordinatorPostDeliverySyncScreen({
    super.key,
    required this.tenantId,
    required this.deliveryId,
  });

  final String tenantId;
  final String deliveryId;

  @override
  Widget build(BuildContext context) {
    if (tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: 'Finalisation livraison',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return StreamBuilder<Organization?>(
      stream: context.read<OrganizationRepository>().watch(tenantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ConnectedScaffold(
            title: 'Finalisation livraison',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final org = snapshot.data;
        if (org == null) {
          return const ConnectedScaffold(
            title: 'Finalisation livraison',
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final delivery = org.deliveries
            .where((d) => d.deliveryId == deliveryId)
            .firstOrNull;

        if (delivery == null) {
          return const ConnectedScaffold(
            title: 'Finalisation livraison',
            body: Center(child: Text('Livraison introuvable.')),
          );
        }

        final dateStr = DateFormat(
          "d MMM",
          'fr',
        ).format(DateTime.parse(delivery.scheduledDate));

        return ConnectedScaffold(
          title: 'Finalisation livraison $dateStr',
          body: _PostDeliveryBody(delivery: delivery),
        );
      },
    );
  }
}

class _PostDeliveryBody extends StatelessWidget {
  const _PostDeliveryBody({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VolunteerSyncSection(delivery: delivery),
          const SizedBox(height: 16),
          _BasketSummarySection(delivery: delivery),
          const SizedBox(height: 16),
          _FinalStatsSection(delivery: delivery),
          const SizedBox(height: 16),
          _CloseActionsSection(),
        ],
      ),
    );
  }
}

class _VolunteerSyncSection extends StatelessWidget {
  const _VolunteerSyncSection({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final registrations = <MemberRegistration>[];
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        registrations.addAll(slot.registrations);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✅ Synchronisation émargement bénévoles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: registrations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun bénévole enregistré.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: registrations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) =>
                      _RegistrationRow(reg: registrations[index]),
                ),
        ),
      ],
    );
  }
}

class _RegistrationRow extends StatelessWidget {
  const _RegistrationRow({required this.reg});

  final MemberRegistration reg;

  @override
  Widget build(BuildContext context) {
    final (icon, color, subtitle) = switch (reg.status) {
      RegistrationStatus.confirmed || RegistrationStatus.completed => (
        Icons.check_circle,
        Colors.green,
        '✅ Présent',
      ),
      RegistrationStatus.cancelled => (Icons.cancel, Colors.red, '❌ Absent'),
      RegistrationStatus.registered => (
        Icons.schedule,
        Colors.orange,
        '⏳ Non confirmé',
      ),
    };

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(reg.displayName),
      subtitle: Text(subtitle),
    );
  }
}

class _BasketSummarySection extends StatelessWidget {
  const _BasketSummarySection({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📦 Récapitulatif récupérations',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final contract in delivery.contracts)
          _ContractSummaryCard(contract: contract),
      ],
    );
  }
}

class _ContractSummaryCard extends StatelessWidget {
  const _ContractSummaryCard({required this.contract});

  final DeliveryContract contract;

  @override
  Widget build(BuildContext context) {
    final total = contract.basketQuantity;
    final collected = contract.status == DeliveryContractStatus.distributed
        ? total
        : 0;
    final allCollected = collected == total && total > 0;
    final pct = total > 0 ? (collected * 100 ~/ total) : 0;
    final progress = total > 0 ? collected / total : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contract.deliveryDescription,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  allCollected ? Icons.check_circle : Icons.warning_amber,
                  color: allCollected ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('$collected/$total récupérés ($pct%)'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: allCollected ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalStatsSection extends StatelessWidget {
  const _FinalStatsSection({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    var totalRegistrations = 0;
    var presentCount = 0;
    var totalBaskets = 0;
    var collectedBaskets = 0;

    for (final contract in delivery.contracts) {
      totalBaskets += contract.basketQuantity;
      if (contract.status == DeliveryContractStatus.distributed) {
        collectedBaskets += contract.basketQuantity;
      }
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          totalRegistrations++;
          if (reg.status == RegistrationStatus.confirmed ||
              reg.status == RegistrationStatus.completed) {
            presentCount++;
          }
        }
      }
    }

    final presencePct = totalRegistrations > 0
        ? (presentCount * 100 ~/ totalRegistrations)
        : 0;
    final collectPct = totalBaskets > 0
        ? (collectedBaskets * 100 ~/ totalBaskets)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Statistiques finales',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _StatRow(
                  label: 'Taux présence bénévoles',
                  value: '$presencePct% ($presentCount/$totalRegistrations)',
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Taux récupération paniers',
                  value: '$collectPct% ($collectedBaskets/$totalBaskets)',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CloseActionsSection extends StatelessWidget {
  const _CloseActionsSection();

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('à venir')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📄 Actions de clôture',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('GÉNÉRER RAPPORT'),
              onPressed: () => _showComingSoon(context),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: const Text('RÉSUMÉ EMAIL'),
              onPressed: () => _showComingSoon(context),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.archive_outlined),
              label: const Text('ARCHIVER'),
              onPressed: () => _showComingSoon(context),
            ),
          ],
        ),
      ],
    );
  }
}
