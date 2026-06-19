import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database_export_save.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Org-wide overview of all current basket exchanges, visible to every member
/// (transparency). Renders a dense table and supports a CSV export ("comme un
/// fichier Excel").
///
/// Route: `/basket-exchange/overview`
class BasketExchangeOverviewScreen extends StatefulWidget {
  const BasketExchangeOverviewScreen({super.key, required this.orgId});

  final String orgId;

  @override
  State<BasketExchangeOverviewScreen> createState() =>
      _BasketExchangeOverviewScreenState();
}

class _BasketExchangeOverviewScreenState
    extends State<BasketExchangeOverviewScreen> {
  StreamSubscription<List<BasketExchange>>? _exchangeSub;
  StreamSubscription<List<Member>>? _membersSub;
  StreamSubscription<Organization?>? _orgSub;

  List<BasketExchange> _exchanges = const [];
  List<Member> _members = const [];
  Organization? _org;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  @override
  void dispose() {
    _exchangeSub?.cancel();
    _membersSub?.cancel();
    _orgSub?.cancel();
    super.dispose();
  }

  void _startStreams() {
    final exchangeRepo = context.read<BasketExchangeRepository>();
    final memberRepo = context.read<MemberRepository>();
    final orgRepo = context.read<OrganizationRepository>();

    _exchangeSub = exchangeRepo.watch(widget.orgId).listen((list) {
      if (!mounted) return;
      setState(() {
        _exchanges = list;
        _loading = false;
      });
    });
    _membersSub = memberRepo.watch(widget.orgId).listen((list) {
      if (!mounted) return;
      setState(() => _members = list);
    });
    _orgSub = orgRepo.watch(widget.orgId).listen((org) {
      if (!mounted) return;
      setState(() => _org = org);
    });
  }

  /// Currently-relevant exchanges: open (proposed) or accepted (confirmed).
  List<_OverviewRow> get _rows {
    final byId = {for (final m in _members) m.memberId: m};
    final ongoing =
        _exchanges
            .where(
              (e) =>
                  e.status == BasketExchangeStatus.open ||
                  e.status == BasketExchangeStatus.accepted,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ongoing.map((e) => _toRow(e, byId)).toList();
  }

  _OverviewRow _toRow(BasketExchange e, Map<String, Member> byId) {
    final acceptedReq = e.acceptedRequestId == null
        ? null
        : e.requests
              .where((r) => r.requestId == e.acceptedRequestId)
              .firstOrNull;
    final pendingCount = e.requests
        .where((r) => r.status == BasketExchangeRequestStatus.pending)
        .length;
    return _OverviewRow(
      offerer: _name(e.offeringMemberId, byId),
      offeredDate: _deliveryDate(e.deliveryId),
      taker: acceptedReq != null
          ? _name(acceptedReq.requesterMemberId, byId)
          : '—',
      counterDate: acceptedReq?.proposedDeliveryId != null
          ? _deliveryDate(acceptedReq!.proposedDeliveryId)
          : '—',
      pendingCount: pendingCount,
      status: e.status == BasketExchangeStatus.accepted ? 'Confirmé' : 'Ouvert',
    );
  }

  String _name(String memberId, Map<String, Member> byId) {
    final m = byId[memberId];
    if (m == null) return memberId;
    final name = [
      m.firstName,
      m.lastName,
    ].where((p) => p != null && p.isNotEmpty).join(' ');
    return name.isEmpty ? memberId : name;
  }

  String _deliveryDate(String? deliveryId) {
    final org = _org;
    if (deliveryId == null || org == null) return '?';
    final delivery = org.deliveries
        .where((d) => d.deliveryId == deliveryId)
        .firstOrNull;
    if (delivery == null) return '?';
    final dt = DateTime.tryParse(delivery.scheduledDate);
    if (dt == null) return '?';
    return DateFormat('dd/MM/yyyy', 'fr').format(dt);
  }

  Future<void> _exportCsv(List<_OverviewRow> rows) async {
    final buffer = StringBuffer()
      ..writeln(
        'Offreur,Panier offert,Demandeur retenu,Panier en retour,'
        'Demandes en attente,Statut',
      );
    for (final r in rows) {
      buffer.writeln(
        [
          r.offerer,
          r.offeredDate,
          r.taker,
          r.counterDate,
          r.pendingCount.toString(),
          r.status,
        ].map(_csvCell).join(','),
      );
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final result = await saveDatabaseExportFile(
      filename: 'echanges-paniers.csv',
      bytes: bytes,
      mimeType: 'text/csv',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export : ${result.filename}')));
  }

  static String _csvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return ConnectedScaffold(
      title: 'Vue d\'ensemble des échanges',
      actions: [
        IconButton(
          tooltip: 'Exporter en CSV',
          onPressed: rows.isEmpty ? null : () => _exportCsv(rows),
          icon: const Icon(Icons.download),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun échange en cours dans votre AMAP.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Offreur')),
                    DataColumn(label: Text('Panier offert')),
                    DataColumn(label: Text('Demandeur retenu')),
                    DataColumn(label: Text('Panier en retour')),
                    DataColumn(label: Text('En attente')),
                    DataColumn(label: Text('Statut')),
                  ],
                  rows: [
                    for (final r in rows)
                      DataRow(
                        cells: [
                          DataCell(Text(r.offerer)),
                          DataCell(Text(r.offeredDate)),
                          DataCell(Text(r.taker)),
                          DataCell(Text(r.counterDate)),
                          DataCell(Text(r.pendingCount.toString())),
                          DataCell(Text(r.status)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _OverviewRow {
  const _OverviewRow({
    required this.offerer,
    required this.offeredDate,
    required this.taker,
    required this.counterDate,
    required this.pendingCount,
    required this.status,
  });

  final String offerer;
  final String offeredDate;
  final String taker;
  final String counterDate;
  final int pendingCount;
  final String status;
}
