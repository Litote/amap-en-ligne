part of '../database.dart';

mixin _BasketExchangeQueries on _$AppDatabase {
  /// Reactive stream of all [BasketExchange] rows for the given organization.
  Stream<List<BasketExchange>> watchBasketExchangesByOrg(
    String organizationId,
  ) =>
      (select(basketExchanges)
            ..where((t) => t.organizationId.equals(organizationId)))
          .watch()
          .map((rows) => rows.map(_basketExchangeRowToDomain).toList());

  /// Inserts or replaces a [BasketExchange] row.
  Future<void> upsertBasketExchange(BasketExchange exchange) => into(
    basketExchanges,
  ).insertOnConflictUpdate(_basketExchangeDomainToRow(exchange));

  /// Deletes the [BasketExchange] row identified by [basketExchangeId].
  ///
  /// Note: the back returns FORBIDDEN for BasketExchange DELETE mutations.
  /// This method exists to mirror the protocol locally in case a tombstone
  /// arrives in a future protocol revision.
  Future<void> deleteBasketExchange(String basketExchangeId) => (delete(
    basketExchanges,
  )..where((t) => t.basketExchangeId.equals(basketExchangeId))).go();

  /// Clears all [BasketExchange] rows for the given organization. Used when
  /// applying a bootstrap [ScopeSyncResult] for an `organization:{id}` scope.
  Future<void> clearBasketExchangesForOrg(String organizationId) => (delete(
    basketExchanges,
  )..where((t) => t.organizationId.equals(organizationId))).go();

  /// Remaps the primary key of a [BasketExchange] row from a `tmp_*` id to the
  /// server-allocated real id. Done as a delete + insert inside a transaction
  /// because [basketExchangeId] is the PK.
  Future<void> remapBasketExchangeId({
    required String oldId,
    required String newId,
  }) async {
    final existing = await (select(
      basketExchanges,
    )..where((t) => t.basketExchangeId.equals(oldId))).getSingleOrNull();
    if (existing == null) return;
    final exchange = _basketExchangeRowToDomain(existing);
    await (delete(
      basketExchanges,
    )..where((t) => t.basketExchangeId.equals(oldId))).go();
    await upsertBasketExchange(exchange.copyWith(basketExchangeId: newId));
  }
}

BasketExchange _basketExchangeRowToDomain(BasketExchangeRow row) {
  final requests = (jsonDecode(row.requestsJson) as List<dynamic>)
      .map((e) => BasketExchangeRequest.fromJson(e as Map<String, dynamic>))
      .toList();
  return BasketExchange(
    basketExchangeId: row.basketExchangeId,
    organizationId: row.organizationId,
    deliveryId: row.deliveryId,
    contractId: row.contractId,
    offeringMemberId: row.offeringMemberId,
    motive: row.motive,
    status: BasketExchangeStatus.values.firstWhere(
      (s) => s.name.toUpperCase() == row.status,
    ),
    createdAt: row.createdAt,
    decidedAt: row.decidedAt,
    acceptedRequestId: row.acceptedRequestId,
    requests: requests,
  );
}

BasketExchangesCompanion _basketExchangeDomainToRow(BasketExchange exchange) =>
    BasketExchangesCompanion.insert(
      basketExchangeId: exchange.basketExchangeId,
      organizationId: exchange.organizationId,
      deliveryId: exchange.deliveryId,
      contractId: exchange.contractId,
      offeringMemberId: exchange.offeringMemberId,
      motive: Value(exchange.motive),
      status: exchange.status.name.toUpperCase(),
      createdAt: exchange.createdAt,
      decidedAt: Value(exchange.decidedAt),
      acceptedRequestId: Value(exchange.acceptedRequestId),
      requestsJson: jsonEncode(
        exchange.requests.map((r) => r.toJson()).toList(),
      ),
    );
