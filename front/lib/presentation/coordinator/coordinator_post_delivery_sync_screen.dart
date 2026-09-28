import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_contract_name.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/domain/validation/delivery_rules.dart';
import 'package:amap_en_ligne/presentation/common/french_date_formatting.dart';
import 'package:amap_en_ligne/presentation/coordinator/delivery_navigation.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _kPostDeliveryTitle = 'Finalisation livraison';

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
        title: _kPostDeliveryTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return StreamBuilder<Organization?>(
      stream: context.read<OrganizationRepository>().watch(tenantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ConnectedScaffold(
            title: _kPostDeliveryTitle,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final org = snapshot.data;
        if (org == null) {
          return const ConnectedScaffold(
            title: _kPostDeliveryTitle,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final delivery = org.deliveries
            .where((d) => d.deliveryId == deliveryId)
            .firstOrNull;

        if (delivery == null) {
          return const ConnectedScaffold(
            title: _kPostDeliveryTitle,
            body: Center(child: Text('Livraison introuvable.')),
          );
        }

        final dateStr = frenchDateFormat(
          'd MMM',
        ).format(DateTime.parse(delivery.scheduledDate));

        return ConnectedScaffold(
          title: 'Finalisation livraison $dateStr',
          onBack: () => backToDeliveryTracking(context, delivery.deliveryId),
          // Season contracts only name the links: render without them first.
          body: StreamBuilder<List<Contract>>(
            stream: context.read<ContractRepository>().watch(tenantId),
            initialData: const [],
            builder: (context, contractsSnapshot) => _PostDeliveryBody(
              org: org,
              delivery: delivery,
              contracts: contractsSnapshot.data ?? const [],
            ),
          ),
        );
      },
    );
  }
}

class _PostDeliveryBody extends StatelessWidget {
  const _PostDeliveryBody({
    required this.org,
    required this.delivery,
    required this.contracts,
  });

  final Organization org;
  final Delivery delivery;
  final List<Contract> contracts;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VolunteerSyncSection(delivery: delivery),
        const SizedBox(height: 16),
        _BasketSummarySection(delivery: delivery, contracts: contracts),
        const SizedBox(height: 16),
        _FinalStatsSection(delivery: delivery),
        const SizedBox(height: 16),
        _CloseActionsSection(
          org: org,
          delivery: delivery,
          contracts: contracts,
        ),
      ],
    ),
  );
}

/// Aggregated presence / basket-recovery counters for one delivery, shared by
/// the final-stats section and the PDF report.
typedef PostDeliveryStats = ({
  int totalRegistrations,
  int presentCount,
  int totalBaskets,
  int collectedBaskets,
});

/// Every volunteer registration of [delivery] — the delivery's coordinators
/// are not volunteers (same rule as the tracking screen).
List<MemberRegistration> _volunteerRegistrations(Delivery delivery) {
  final coordinatorIds = deliveryCoordinatorIds(delivery);
  return [
    for (final contract in delivery.contracts)
      for (final slot in contract.slots)
        ...slot.registrations.where(
          (reg) => !coordinatorIds.contains(reg.memberId),
        ),
  ];
}

/// "Taux présence bénévoles" value: "50% (1/2)", or an explicit mention when
/// nobody registered (a bare "0% (0/0)" reads like an absence rate).
String presenceRateLabel(PostDeliveryStats stats) {
  if (stats.totalRegistrations == 0) return '— (aucun bénévole inscrit)';
  final pct = stats.presentCount * 100 ~/ stats.totalRegistrations;
  return '$pct% (${stats.presentCount}/${stats.totalRegistrations})';
}

PostDeliveryStats postDeliveryStats(Delivery delivery) {
  final registrations = _volunteerRegistrations(delivery);
  var totalBaskets = 0;
  var collectedBaskets = 0;
  for (final contract in delivery.contracts) {
    totalBaskets += contract.basketQuantity;
    if (contract.status == DeliveryContractStatus.distributed) {
      collectedBaskets += contract.basketQuantity;
    }
  }

  return (
    totalRegistrations: registrations.length,
    presentCount: registrations
        .where((reg) => isPresentRegistrationStatus(reg.status))
        .length,
    totalBaskets: totalBaskets,
    collectedBaskets: collectedBaskets,
  );
}

class _VolunteerSyncSection extends StatelessWidget {
  const _VolunteerSyncSection({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final registrations = _volunteerRegistrations(delivery);

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
  const _BasketSummarySection({
    required this.delivery,
    required this.contracts,
  });

  final Delivery delivery;
  final List<Contract> contracts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '📦 Récapitulatif récupérations',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      for (final contract in deliveryContractsToCollect(delivery))
        _ContractSummaryCard(
          contract: contract,
          contractName: deliveryContractName(contract, contracts),
        ),
    ],
  );
}

class _ContractSummaryCard extends StatelessWidget {
  const _ContractSummaryCard({
    required this.contract,
    required this.contractName,
  });

  final DeliveryContract contract;
  final String contractName;

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
              contractName,
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
    final stats = postDeliveryStats(delivery);

    final collectPct = stats.totalBaskets > 0
        ? (stats.collectedBaskets * 100 ~/ stats.totalBaskets)
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
                  value: presenceRateLabel(stats),
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Taux récupération paniers',
                  value:
                      '$collectPct% '
                      '(${stats.collectedBaskets}/${stats.totalBaskets})',
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
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class _CloseActionsSection extends StatefulWidget {
  const _CloseActionsSection({
    required this.org,
    required this.delivery,
    required this.contracts,
  });

  final Organization org;
  final Delivery delivery;
  final List<Contract> contracts;

  @override
  State<_CloseActionsSection> createState() => _CloseActionsSectionState();
}

List<List<String>> _volunteerPresenceRows(Delivery delivery) => [
  for (final reg in _volunteerRegistrations(delivery))
    [
      reg.displayName,
      switch (reg.status) {
        RegistrationStatus.confirmed ||
        RegistrationStatus.completed => 'Présent',
        RegistrationStatus.cancelled => 'Absent',
        RegistrationStatus.registered => 'Non confirmé',
      },
    ],
];

List<List<String>> _basketRecoveryRows(
  Delivery delivery,
  List<Contract> contracts,
) => deliveryContractsToCollect(delivery).map((contract) {
  final total = contract.basketQuantity;
  final collected = contract.status == DeliveryContractStatus.distributed
      ? total
      : 0;
  final pct = total > 0 ? (collected * 100 ~/ total) : 0;
  return [
    deliveryContractName(contract, contracts),
    '$collected',
    '$total',
    '$pct%',
  ];
}).toList();

class _CloseActionsSectionState extends State<_CloseActionsSection> {
  bool _busy = false;

  /// Builds a delivery-report PDF (volunteer presence, basket recovery per
  /// contract, final stats) and shares it via the OS share sheet / download.
  Future<void> _exportPdf() async {
    setState(() => _busy = true);
    try {
      final delivery = widget.delivery;
      final dateLabel = frenchDateFormat(
        'd MMMM yyyy',
      ).format(DateTime.parse(delivery.scheduledDate));
      final stats = postDeliveryStats(delivery);
      final collectPct = stats.totalBaskets > 0
          ? (stats.collectedBaskets * 100 ~/ stats.totalBaskets)
          : 0;

      final volunteerRows = _volunteerPresenceRows(delivery);
      final basketRows = _basketRecoveryRows(delivery, widget.contracts);

      final doc = pw.Document()
        ..addPage(
          pw.MultiPage(
            build: (ctx) => [
              pw.Header(level: 0, text: 'Rapport de distribution — $dateLabel'),
              pw.SizedBox(height: 8),
              pw.Header(level: 1, text: 'Bénévoles'),
              pw.TableHelper.fromTextArray(
                headers: ['Nom', 'Présence'],
                data: volunteerRows,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                },
              ),
              pw.SizedBox(height: 16),
              pw.Header(level: 1, text: 'Récupération paniers'),
              pw.TableHelper.fromTextArray(
                headers: ['Contrat', 'Récupérés', 'Total', '%'],
                data: basketRows,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
              ),
              pw.SizedBox(height: 16),
              pw.Header(level: 1, text: 'Statistiques finales'),
              pw.Text('Taux présence bénévoles : ${presenceRateLabel(stats)}'),
              pw.Text(
                'Taux récupération paniers : $collectPct% '
                '(${stats.collectedBaskets}/${stats.totalBaskets})',
              ),
            ],
          ),
        );

      final filename =
          'rapport-livraison-'
          '${delivery.deliveryId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_')}'
          '.pdf';
      await Printing.sharePdf(bytes: await doc.save(), filename: filename);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens a dialog asking for a recipient email, then enqueues the back-sent
  /// attendance-summary email for this delivery.
  Future<void> _sendSummaryEmail() async {
    final emailController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Envoyer par email'),
        semanticLabel: 'Envoyer par email',
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Adresse email destinataire',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final email = emailController.text.trim();
    if (email.isEmpty) return;

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AttendanceEmailRequestRepository>().create(
        organizationId: widget.org.organizationId,
        deliveryId: widget.delivery.deliveryId,
        recipientEmail: email,
      );
      if (mounted) {
        context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Envoi planifié pour $email')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks for confirmation, then marks the delivery COMPLETED and returns to
  /// the previous screen.
  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archiver la distribution ?'),
        semanticLabel: 'Archiver la distribution ?',
        content: const Text('La livraison sera marquée comme terminée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ARCHIVER'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<OrganizationRepository>().updateDeliveryStatus(
        currentOrg: widget.org,
        deliveryId: widget.delivery.deliveryId,
        newStatus: DeliveryStatus.completed,
      );
      if (mounted) {
        context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Distribution archivée.')));
        await Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
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
            onPressed: _busy ? null : _exportPdf,
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: const Text('RÉSUMÉ EMAIL'),
            onPressed: _busy ? null : _sendSummaryEmail,
          ),
          FilledButton.icon(
            icon: const Icon(Icons.archive_outlined),
            label: const Text('ARCHIVER'),
            onPressed: _busy || !_closable ? null : _archive,
          ),
        ],
      ),
      if (!_closable) ...[
        const SizedBox(height: 4),
        Text(
          closableFromLabel(widget.delivery.scheduledDate),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ],
  );

  /// The back refuses completing a delivery before its scheduled day.
  bool get _closable =>
      isDeliveryClosable(widget.delivery.scheduledDate, now: DateTime.now());
}
