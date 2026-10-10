import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange_view.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:amap_en_ligne/domain/validation/input_rules.dart';
import 'package:amap_en_ligne/presentation/common/french_date_formatting.dart';
import 'package:amap_en_ligne/presentation/coordinator/attendance/attendance_sheets_bloc.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_display.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Screen 03 — Coordinator: attendance sheets for deliveries.
///
/// Allows the coordinator to select a delivery and view:
/// - "Bénévoles" tab: list of registered volunteers.
/// - "Paniers" tab: list of active contract members grouped by product.
///
/// When a delivery is selected, action buttons for PDF export and email
/// sending are displayed via a [BottomAppBar].
/// File name of a delivery's attendance sheet: `emargement-YYYY-MM-DD.pdf`.
/// The date is unique per organization (the back rejects two deliveries on
/// the same day) and, unlike the delivery id, meaningful to the user.
@visibleForTesting
String attendanceSheetFilename(Delivery delivery) {
  final date = DateTime.tryParse(delivery.scheduledDate);
  final day = date == null
      ? delivery.deliveryId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_')
      : DateFormat('yyyy-MM-dd').format(date);
  return 'emargement-$day.pdf';
}

const _kNoVolunteerRegistered = 'Aucun bénévole inscrit.';

/// Replaces the volunteer table of the PDF when nobody registered (a bare
/// header row reads like a printing error); null otherwise.
@visibleForTesting
String? attendanceVolunteerSheetEmptyNote(int volunteerCount) =>
    volunteerCount == 0 ? _kNoVolunteerRegistered : null;

/// Header of the volunteer attendance PDF page.
@visibleForTesting
String attendanceVolunteerSheetTitle(Delivery delivery) =>
    'Émargement bénévoles - ${_formatPdfDate(delivery.scheduledDate)}';

/// Header of a basket pick-up PDF page for the basket group [groupLabel].
@visibleForTesting
String attendanceBasketSheetTitle(String groupLabel, Delivery delivery) =>
    _pdfText(
      'Récupération paniers - $groupLabel - '
      '${_formatPdfDate(delivery.scheduledDate)}',
    );

String _formatPdfDate(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  return date == null ? isoDate : frenchDateFormat('d MMMM yyyy').format(date);
}

/// The default PDF font (Helvetica, Latin-1) has no em/en dash: the glyph
/// would silently vanish from the document.
String _pdfText(String text) => text.replaceAll(RegExp('[—–]'), '-');

class AttendanceSheetsScreen extends StatelessWidget {
  const AttendanceSheetsScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    if (tenantId.isEmpty) {
      return const ConnectedScaffold(
        title: "Feuilles d'émargement",
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return BlocProvider(
      create: (_) => _AttendanceSheetsBloc(),
      child: _AttendanceSheetsView(tenantId: tenantId),
    );
  }
}

class _AttendanceSheetsBloc
    extends Bloc<AttendanceSheetsEvent, AttendanceSheetsState> {
  _AttendanceSheetsBloc() : super(const AttendanceSheetsState.idle()) {
    on<AttendanceSheetsDeliverySelected>(_onDeliverySelected);
  }

  Organization? _org;
  bool _defaultSelected = false;

  void setOrg(Organization org) {
    _org = org;
    // Open on the delivery the coordinator most likely wants: a season holds
    // dozens of deliveries and the list starts with the oldest one.
    if (!_defaultSelected && state is AttendanceSheetsIdle) {
      _defaultSelected = true;
      final initial = _defaultDelivery(org.deliveries, DateTime.now());
      if (initial != null) {
        add(
          AttendanceSheetsEvent.deliverySelected(
            deliveryId: initial.deliveryId,
          ),
        );
        return;
      }
    }
    // If a delivery was selected and the org changed, keep the selection
    // up to date.
    final current = state;
    if (current is AttendanceSheetsDeliveryShown) {
      final updated = org.deliveries
          .where((d) => d.deliveryId == current.deliveryId)
          .firstOrNull;
      if (updated != null && updated != current.delivery) {
        add(
          AttendanceSheetsEvent.deliverySelected(
            deliveryId: current.deliveryId,
          ),
        );
      }
    }
  }

  /// The next non-cancelled delivery from today on, else the most recent one.
  static Delivery? _defaultDelivery(List<Delivery> deliveries, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final sorted =
        deliveries.where((d) => d.status != DeliveryStatus.cancelled).toList()
          ..sort(
            (a, b) => DateTime.parse(
              a.scheduledDate,
            ).compareTo(DateTime.parse(b.scheduledDate)),
          );
    return sorted
            .where((d) => !DateTime.parse(d.scheduledDate).isBefore(today))
            .firstOrNull ??
        sorted.lastOrNull;
  }

  Future<void> _onDeliverySelected(
    AttendanceSheetsDeliverySelected event,
    Emitter<AttendanceSheetsState> emit,
  ) async {
    final org = _org;
    if (org == null) return;
    final delivery = org.deliveries
        .where((d) => d.deliveryId == event.deliveryId)
        .firstOrNull;
    if (delivery == null) {
      emit(const AttendanceSheetsState.idle());
      return;
    }
    emit(
      AttendanceSheetsState.deliverySelected(
        deliveryId: delivery.deliveryId,
        delivery: delivery,
      ),
    );
  }
}

class _AttendanceSheetsView extends StatelessWidget {
  const _AttendanceSheetsView({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) => ConnectedScaffold(
    title: "Feuilles d'émargement",
    actions: const [SyncButton()],
    body: StreamBuilder<Organization?>(
      stream: context.read<OrganizationRepository>().watch(tenantId),
      builder: (context, orgSnapshot) {
        if (!orgSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final org = orgSnapshot.data;
        if (org == null) {
          return const Center(child: CircularProgressIndicator());
        }
        context.read<_AttendanceSheetsBloc>().setOrg(org);
        return StreamBuilder<List<Contract>>(
          stream: context.read<ContractRepository>().watch(tenantId),
          builder: (context, contractsSnapshot) => StreamBuilder<List<Member>>(
            stream: context.read<MemberRepository>().watch(tenantId),
            builder: (context, membersSnapshot) =>
                StreamBuilder<List<BasketExchange>>(
                  stream: context.read<BasketExchangeRepository>().watch(
                    tenantId,
                  ),
                  builder: (context, exchangesSnapshot) {
                    final contracts = contractsSnapshot.data ?? [];
                    final members = membersSnapshot.data ?? [];
                    final membersById = {
                      for (final m in members) m.memberId: m,
                    };
                    final exchanges = exchangesSnapshot.data ?? [];
                    return _AttendanceSheetsBody(
                      org: org,
                      contracts: contracts,
                      membersById: membersById,
                      exchanges: exchanges,
                    );
                  },
                ),
          ),
        );
      },
    ),
  );
}

class _AttendanceSheetsBody extends StatelessWidget {
  const _AttendanceSheetsBody({
    required this.org,
    required this.contracts,
    required this.membersById,
    required this.exchanges,
  });

  final Organization org;
  final List<Contract> contracts;
  final Map<String, Member> membersById;
  final List<BasketExchange> exchanges;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<_AttendanceSheetsBloc, AttendanceSheetsState>(
        builder: (context, state) {
          final selectedDelivery = switch (state) {
            AttendanceSheetsDeliveryShown(:final delivery) => delivery,
            _ => null,
          };

          return Column(
            children: [
              _DeliverySelector(
                org: org,
                selectedDeliveryId: switch (state) {
                  AttendanceSheetsDeliveryShown(:final deliveryId) =>
                    deliveryId,
                  _ => null,
                },
              ),
              Expanded(
                child: switch (state) {
                  AttendanceSheetsIdle() => const Center(
                    child: Text('Sélectionnez une livraison.'),
                  ),
                  AttendanceSheetsDeliveryShown(:final delivery) =>
                    _DeliveryAttendanceDetail(
                      delivery: delivery,
                      contracts: contracts,
                      org: org,
                      membersById: membersById,
                      exchanges: exchanges,
                    ),
                },
              ),
              if (selectedDelivery != null)
                _AttendanceActionBar(
                  delivery: selectedDelivery,
                  contracts: contracts,
                  org: org,
                  membersById: membersById,
                  exchanges: exchanges,
                ),
            ],
          );
        },
      );
}

// ---------------------------------------------------------------------------
// Bottom action bar: PDF export + email sending
// ---------------------------------------------------------------------------

class _AttendanceActionBar extends StatelessWidget {
  const _AttendanceActionBar({
    required this.delivery,
    required this.contracts,
    required this.org,
    required this.membersById,
    required this.exchanges,
  });

  final Delivery delivery;
  final List<Contract> contracts;
  final Organization org;
  final Map<String, Member> membersById;
  final List<BasketExchange> exchanges;

  /// Collects volunteer registrations for the delivery, excluding coordinators.
  List<_VolunteerEntry> _buildVolunteerRows() {
    final coordinatorIds = deliveryCoordinatorIds(delivery);
    final rows = <_VolunteerEntry>[];
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (coordinatorIds.contains(reg.memberId)) continue;
          // Absent volunteers (CANCELLED) are left out; registered, present
          // (CONFIRMED) and imported/legacy COMPLETED ones are listed.
          if (reg.status != RegistrationStatus.cancelled) {
            rows.add(
              _VolunteerEntry(registration: reg, slotStartTime: slot.startTime),
            );
          }
        }
      }
    }
    return rows;
  }

  /// Builds a simple attendance PDF document and shares it via the OS share
  /// sheet / download dialog.
  Future<void> _exportPdf(BuildContext context) async {
    final doc = pw.Document();

    // Page 1 — Volunteers (the delivery's coordinators are not volunteers and
    // must not appear on the volunteer sheet, even if registered on a slot).
    final volunteerRows = _buildVolunteerRows();

    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, text: attendanceVolunteerSheetTitle(delivery)),
          pw.SizedBox(height: 8),
          if (attendanceVolunteerSheetEmptyNote(volunteerRows.length)
              case final note?)
            pw.Text(note)
          else
            pw.TableHelper.fromTextArray(
              headers: ['Nom', 'Email', 'Arrivée'],
              data: volunteerRows
                  .map(
                    (e) => [
                      registrationDisplayName(e.registration),
                      e.registration.memberEmail,
                      _formatTime(e.slotStartTime),
                    ],
                  )
                  .toList(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
              },
            ),
        ],
      ),
    );

    // Pages — one per basket type group
    final groups = _groupByBasketType(
      delivery,
      contracts,
      org,
      membersById,
      exchanges,
    );

    for (final group in groups) {
      final rows = group.rows;
      doc.addPage(
        pw.MultiPage(
          build: (ctx) => [
            pw.Header(
              level: 0,
              text: attendanceBasketSheetTitle(group.label, delivery),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: [
                'Membre',
                'Format panier',
                'Récupéré par',
                // No '☐': missing from the default PDF font.
                'Récupéré',
              ],
              data: rows
                  .map(
                    (r) => [
                      r.memberName,
                      r.basketSizeName,
                      r.pickedUpBy ?? '',
                      '',
                    ],
                  )
                  .toList(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
              },
            ),
          ],
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: attendanceSheetFilename(delivery),
    );
  }

  /// Opens a dialog asking for a recipient email, then calls the coordinator
  /// API to send the attendance sheet by email.
  Future<void> _sendEmail(BuildContext context) async {
    final email = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _RecipientEmailDialog(),
    );
    if (email == null) return;

    // Use the mounted check to avoid using context after async gap.
    if (!context.mounted) return;

    await context.read<AttendanceEmailRequestRepository>().create(
      organizationId: org.organizationId,
      deliveryId: delivery.deliveryId,
      recipientEmail: email,
    );
    if (context.mounted) {
      context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Envoi planifié pour $email')));
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return DateFormat("HH'h'mm", 'fr').format(dt);
    } on Object {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) => BottomAppBar(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Télécharger PDF'),
          onPressed: () => _exportPdf(context),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.email_outlined),
          label: const Text('Envoyer email'),
          onPressed: () => _sendEmail(context),
        ),
      ],
    ),
  );
}

class _DeliverySelector extends StatelessWidget {
  const _DeliverySelector({required this.org, this.selectedDeliveryId});

  final Organization org;
  final String? selectedDeliveryId;

  @override
  Widget build(BuildContext context) {
    final deliveries = org.deliveries.toList()
      ..sort(
        (a, b) => DateTime.parse(
          a.scheduledDate,
        ).compareTo(DateTime.parse(b.scheduledDate)),
      );

    if (deliveries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Aucune livraison.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Livraison',
          border: OutlineInputBorder(),
        ),
        initialValue: selectedDeliveryId,
        items: deliveries.map((d) {
          final date = DateTime.parse(d.scheduledDate);
          final label = frenchDateFormat("d MMMM yyyy • HH'h'mm").format(date);
          return DropdownMenuItem(value: d.deliveryId, child: Text(label));
        }).toList(),
        onChanged: (id) {
          if (id != null) {
            context.read<_AttendanceSheetsBloc>().add(
              AttendanceSheetsEvent.deliverySelected(deliveryId: id),
            );
          }
        },
      ),
    );
  }
}

class _DeliveryAttendanceDetail extends StatelessWidget {
  const _DeliveryAttendanceDetail({
    required this.delivery,
    required this.contracts,
    required this.org,
    required this.membersById,
    required this.exchanges,
  });

  final Delivery delivery;
  final List<Contract> contracts;
  final Organization org;
  final Map<String, Member> membersById;
  final List<BasketExchange> exchanges;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Bénévoles'),
            Tab(text: 'Paniers'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _VolunteersTab(delivery: delivery),
              _BasketsTab(
                delivery: delivery,
                contracts: contracts,
                org: org,
                membersById: membersById,
                exchanges: exchanges,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Tab 1: Volunteers
// ---------------------------------------------------------------------------

class _VolunteersTab extends StatelessWidget {
  const _VolunteersTab({required this.delivery});

  final Delivery delivery;

  List<_VolunteerEntry> _buildEntries() {
    // The delivery's coordinators are not volunteers: exclude them from the
    // attendance list even if registered on a slot (consistent with the
    // tracking screen and the volunteer counter).
    final coordinatorIds = deliveryCoordinatorIds(delivery);
    final entries = <_VolunteerEntry>[];
    for (final contract in delivery.contracts) {
      for (final slot in contract.slots) {
        for (final reg in slot.registrations) {
          if (coordinatorIds.contains(reg.memberId)) continue;
          // Absent volunteers (CANCELLED) are left out; registered, present
          // (CONFIRMED) and imported/legacy COMPLETED ones are listed.
          if (reg.status != RegistrationStatus.cancelled) {
            entries.add(
              _VolunteerEntry(registration: reg, slotStartTime: slot.startTime),
            );
          }
        }
      }
    }
    return entries;
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return DateFormat("HH'h'mm", 'fr').format(dt);
    } on Object {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    if (entries.isEmpty) {
      return const Center(child: Text(_kNoVolunteerRegistered));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final reg = entry.registration;
        return ListTile(
          title: Text(registrationDisplayName(reg)),
          subtitle: Text(
            '${reg.memberEmail} • Arrivée: ${_formatTime(entry.slotStartTime)}',
          ),
        );
      },
    );
  }
}

class _VolunteerEntry {
  const _VolunteerEntry({
    required this.registration,
    required this.slotStartTime,
  });

  final MemberRegistration registration;
  final String slotStartTime;
}

// ---------------------------------------------------------------------------
// Tab 2: Baskets — one section per product, one row per active member
// ---------------------------------------------------------------------------

class _BasketsTab extends StatelessWidget {
  const _BasketsTab({
    required this.delivery,
    required this.contracts,
    required this.org,
    required this.membersById,
    required this.exchanges,
  });

  final Delivery delivery;
  final List<Contract> contracts;
  final Organization org;
  final Map<String, Member> membersById;
  final List<BasketExchange> exchanges;

  @override
  Widget build(BuildContext context) {
    if (delivery.contracts.isEmpty) {
      return const Center(child: Text('Aucun contrat.'));
    }

    final groups = _groupByBasketType(
      delivery,
      contracts,
      org,
      membersById,
      exchanges,
    );

    if (groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = <Widget>[];
    for (final group in groups) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            group.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (final row in group.rows) {
        final pickedUpBy = row.pickedUpBy;
        items.add(
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: ListTile(
              title: Text(row.memberName),
              subtitle: Text(
                pickedUpBy == null
                    ? row.basketSizeName
                    : '${row.basketSizeName}\n🔄 Échange — à remettre à $pickedUpBy',
              ),
              isThreeLine: pickedUpBy != null,
            ),
          ),
        );
      }
    }

    return ListView(padding: const EdgeInsets.only(bottom: 8), children: items);
  }
}

// ---------------------------------------------------------------------------
// Helper: groups delivery contracts by basket type — one group per distinct
// member subscription (product type + basket size, e.g. "Légumes de saison —
// Panier 3kg"), with one [_BasketRow] per active member subscription. Active
// members without any subscription fall back to a group named after their
// producer's product so they are never dropped from the sheet. A row whose
// basket is collected by another member (confirmed basket exchange on this
// delivery) carries the collector's name in [pickedUpBy].
// ---------------------------------------------------------------------------

class _BasketGroup {
  _BasketGroup(this.label);

  /// Group header, e.g. "Légumes de saison — Panier 3kg" (one PDF page each).
  final String label;
  final List<_BasketRow> rows = [];
}

class _BasketRow {
  const _BasketRow({
    required this.memberName,
    required this.basketSizeName,
    this.pickedUpBy,
  });

  final String memberName;
  final String basketSizeName;

  /// Name of the member who collects this basket instead of its owner, or null.
  final String? pickedUpBy;
}

String _memberDisplayName(String memberId, Map<String, Member> membersById) {
  final member = membersById[memberId];
  if (member == null) return memberId;
  final name = '${member.firstName ?? ''} ${member.lastName ?? ''}'.trim();
  return name.isEmpty ? memberId : name;
}

/// Appends the attendance rows for one [contract]'s active members into the
/// shared [groups] map, keyed by basket label.
void _addContractMemberRows(
  Contract contract,
  String fallbackName,
  Map<String, String> productNameById,
  Map<String, Member> membersById,
  Map<String, String> pickups,
  Map<String, _BasketGroup> groups,
) {
  _BasketGroup groupFor(String label) =>
      groups.putIfAbsent(label, () => _BasketGroup(label));

  for (final cm in contract.members) {
    if (cm.status != ContractMemberStatus.active) continue;
    final collectorId = pickups[cm.memberId];
    final memberName = _memberDisplayName(cm.memberId, membersById);
    final pickedUpBy = collectorId == null
        ? null
        : _memberDisplayName(collectorId, membersById);

    if (cm.subscriptions.isEmpty) {
      groupFor(fallbackName).rows.add(
        _BasketRow(
          memberName: memberName,
          basketSizeName: fallbackName,
          pickedUpBy: pickedUpBy,
        ),
      );
      continue;
    }

    for (final sub in cm.subscriptions) {
      final productName = productNameById[sub.productTypeId] ?? fallbackName;
      final sizeName = sub.basketSize?.name;
      final label = sizeName == null ? productName : '$productName — $sizeName';
      groupFor(label).rows.add(
        _BasketRow(
          memberName: memberName,
          basketSizeName: sizeName ?? productName,
          pickedUpBy: pickedUpBy,
        ),
      );
    }
  }
}

List<_BasketGroup> _groupByBasketType(
  Delivery delivery,
  List<Contract> contracts,
  Organization org,
  Map<String, Member> membersById,
  List<BasketExchange> exchanges,
) {
  final contractsById = {for (final c in contracts) c.contractId: c};
  final productNameById = {
    for (final p in org.products) p.productTypeId: p.name,
  };
  final groups = <String, _BasketGroup>{};

  for (final dc in delivery.contracts) {
    final contract = contractsById[dc.contractId];
    if (contract == null) continue;
    final producerProduct = org.products
        .where((p) => p.producerAccountId == contract.producerAccountId)
        .firstOrNull;
    final fallbackName = producerProduct?.name ?? dc.deliveryDescription;
    _addContractMemberRows(
      contract,
      fallbackName,
      productNameById,
      membersById,
      // An exchange swaps the basket of one contract only.
      basketPickupsForDelivery(
        exchanges,
        delivery.deliveryId,
        contract.contractId,
      ),
      groups,
    );
  }

  final sorted = groups.values.toList()
    ..sort((a, b) => a.label.compareTo(b.label));
  for (final group in sorted) {
    group.rows.sort((a, b) => a.memberName.compareTo(b.memberName));
  }
  return sorted;
}

/// Asks for the attendance sheet recipient; pops the trimmed address, or null
/// when cancelled. The address is validated before closing (the back rejects a
/// malformed one with `INVALID_PAYLOAD`).
class _RecipientEmailDialog extends StatefulWidget {
  const _RecipientEmailDialog();

  @override
  State<_RecipientEmailDialog> createState() => _RecipientEmailDialogState();
}

class _RecipientEmailDialogState extends State<_RecipientEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Envoyer par email'),
    semanticLabel: 'Envoyer par email',
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Adresse email destinataire',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        validator: requiredEmail,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annuler'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Envoyer')),
    ],
  );
}
