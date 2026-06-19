// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductTypesTable extends ProductTypes
    with TableInfo<$ProductTypesTable, ProductTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _producerAccountIdMeta = const VerificationMeta(
    'producerAccountId',
  );
  @override
  late final GeneratedColumn<String> producerAccountId =
      GeneratedColumn<String>(
        'producer_account_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _productTypeIdMeta = const VerificationMeta(
    'productTypeId',
  );
  @override
  late final GeneratedColumn<String> productTypeId = GeneratedColumn<String>(
    'product_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<BasketSize>, String>
  supportedBasketSizes =
      GeneratedColumn<String>(
        'supported_basket_sizes',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<BasketSize>>(
        $ProductTypesTable.$convertersupportedBasketSizes,
      );
  @override
  List<GeneratedColumn> get $columns => [
    producerAccountId,
    productTypeId,
    name,
    description,
    supportedBasketSizes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('producer_account_id')) {
      context.handle(
        _producerAccountIdMeta,
        producerAccountId.isAcceptableOrUnknown(
          data['producer_account_id']!,
          _producerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_producerAccountIdMeta);
    }
    if (data.containsKey('product_type_id')) {
      context.handle(
        _productTypeIdMeta,
        productTypeId.isAcceptableOrUnknown(
          data['product_type_id']!,
          _productTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productTypeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {producerAccountId, productTypeId};
  @override
  ProductTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductTypeRow(
      producerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producer_account_id'],
      )!,
      productTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_type_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      supportedBasketSizes: $ProductTypesTable.$convertersupportedBasketSizes
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}supported_basket_sizes'],
            )!,
          ),
    );
  }

  @override
  $ProductTypesTable createAlias(String alias) {
    return $ProductTypesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<BasketSize>, String>
  $convertersupportedBasketSizes = const _BasketSizesConverter();
}

class ProductTypeRow extends DataClass implements Insertable<ProductTypeRow> {
  final String producerAccountId;
  final String productTypeId;
  final String name;
  final String? description;
  final List<BasketSize> supportedBasketSizes;
  const ProductTypeRow({
    required this.producerAccountId,
    required this.productTypeId,
    required this.name,
    this.description,
    required this.supportedBasketSizes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['producer_account_id'] = Variable<String>(producerAccountId);
    map['product_type_id'] = Variable<String>(productTypeId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['supported_basket_sizes'] = Variable<String>(
        $ProductTypesTable.$convertersupportedBasketSizes.toSql(
          supportedBasketSizes,
        ),
      );
    }
    return map;
  }

  ProductTypesCompanion toCompanion(bool nullToAbsent) {
    return ProductTypesCompanion(
      producerAccountId: Value(producerAccountId),
      productTypeId: Value(productTypeId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      supportedBasketSizes: Value(supportedBasketSizes),
    );
  }

  factory ProductTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductTypeRow(
      producerAccountId: serializer.fromJson<String>(json['producerAccountId']),
      productTypeId: serializer.fromJson<String>(json['productTypeId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      supportedBasketSizes: serializer.fromJson<List<BasketSize>>(
        json['supportedBasketSizes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'producerAccountId': serializer.toJson<String>(producerAccountId),
      'productTypeId': serializer.toJson<String>(productTypeId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'supportedBasketSizes': serializer.toJson<List<BasketSize>>(
        supportedBasketSizes,
      ),
    };
  }

  ProductTypeRow copyWith({
    String? producerAccountId,
    String? productTypeId,
    String? name,
    Value<String?> description = const Value.absent(),
    List<BasketSize>? supportedBasketSizes,
  }) => ProductTypeRow(
    producerAccountId: producerAccountId ?? this.producerAccountId,
    productTypeId: productTypeId ?? this.productTypeId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    supportedBasketSizes: supportedBasketSizes ?? this.supportedBasketSizes,
  );
  ProductTypeRow copyWithCompanion(ProductTypesCompanion data) {
    return ProductTypeRow(
      producerAccountId: data.producerAccountId.present
          ? data.producerAccountId.value
          : this.producerAccountId,
      productTypeId: data.productTypeId.present
          ? data.productTypeId.value
          : this.productTypeId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      supportedBasketSizes: data.supportedBasketSizes.present
          ? data.supportedBasketSizes.value
          : this.supportedBasketSizes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductTypeRow(')
          ..write('producerAccountId: $producerAccountId, ')
          ..write('productTypeId: $productTypeId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('supportedBasketSizes: $supportedBasketSizes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    producerAccountId,
    productTypeId,
    name,
    description,
    supportedBasketSizes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductTypeRow &&
          other.producerAccountId == this.producerAccountId &&
          other.productTypeId == this.productTypeId &&
          other.name == this.name &&
          other.description == this.description &&
          other.supportedBasketSizes == this.supportedBasketSizes);
}

class ProductTypesCompanion extends UpdateCompanion<ProductTypeRow> {
  final Value<String> producerAccountId;
  final Value<String> productTypeId;
  final Value<String> name;
  final Value<String?> description;
  final Value<List<BasketSize>> supportedBasketSizes;
  final Value<int> rowid;
  const ProductTypesCompanion({
    this.producerAccountId = const Value.absent(),
    this.productTypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.supportedBasketSizes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductTypesCompanion.insert({
    required String producerAccountId,
    required String productTypeId,
    required String name,
    this.description = const Value.absent(),
    required List<BasketSize> supportedBasketSizes,
    this.rowid = const Value.absent(),
  }) : producerAccountId = Value(producerAccountId),
       productTypeId = Value(productTypeId),
       name = Value(name),
       supportedBasketSizes = Value(supportedBasketSizes);
  static Insertable<ProductTypeRow> custom({
    Expression<String>? producerAccountId,
    Expression<String>? productTypeId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? supportedBasketSizes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (producerAccountId != null) 'producer_account_id': producerAccountId,
      if (productTypeId != null) 'product_type_id': productTypeId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (supportedBasketSizes != null)
        'supported_basket_sizes': supportedBasketSizes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductTypesCompanion copyWith({
    Value<String>? producerAccountId,
    Value<String>? productTypeId,
    Value<String>? name,
    Value<String?>? description,
    Value<List<BasketSize>>? supportedBasketSizes,
    Value<int>? rowid,
  }) {
    return ProductTypesCompanion(
      producerAccountId: producerAccountId ?? this.producerAccountId,
      productTypeId: productTypeId ?? this.productTypeId,
      name: name ?? this.name,
      description: description ?? this.description,
      supportedBasketSizes: supportedBasketSizes ?? this.supportedBasketSizes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (producerAccountId.present) {
      map['producer_account_id'] = Variable<String>(producerAccountId.value);
    }
    if (productTypeId.present) {
      map['product_type_id'] = Variable<String>(productTypeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (supportedBasketSizes.present) {
      map['supported_basket_sizes'] = Variable<String>(
        $ProductTypesTable.$convertersupportedBasketSizes.toSql(
          supportedBasketSizes.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductTypesCompanion(')
          ..write('producerAccountId: $producerAccountId, ')
          ..write('productTypeId: $productTypeId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('supportedBasketSizes: $supportedBasketSizes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [scopeKey, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scopeKey};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String scopeKey;
  final String? cursor;
  const SyncCursor({required this.scopeKey, this.cursor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope_key'] = Variable<String>(scopeKey);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      scopeKey: Value(scopeKey),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
    );
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      cursor: serializer.fromJson<String?>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scopeKey': serializer.toJson<String>(scopeKey),
      'cursor': serializer.toJson<String?>(cursor),
    };
  }

  SyncCursor copyWith({
    String? scopeKey,
    Value<String?> cursor = const Value.absent(),
  }) => SyncCursor(
    scopeKey: scopeKey ?? this.scopeKey,
    cursor: cursor.present ? cursor.value : this.cursor,
  );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('scopeKey: $scopeKey, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scopeKey, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.scopeKey == this.scopeKey &&
          other.cursor == this.cursor);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> scopeKey;
  final Value<String?> cursor;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.scopeKey = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String scopeKey,
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKey = Value(scopeKey);
  static Insertable<SyncCursor> custom({
    Expression<String>? scopeKey,
    Expression<String>? cursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scopeKey != null) 'scope_key': scopeKey,
      if (cursor != null) 'cursor': cursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? scopeKey,
    Value<String?>? cursor,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      scopeKey: scopeKey ?? this.scopeKey,
      cursor: cursor ?? this.cursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('scopeKey: $scopeKey, ')
          ..write('cursor: $cursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMutationsTable extends PendingMutations
    with TableInfo<$PendingMutationsTable, PendingMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientOpIdMeta = const VerificationMeta(
    'clientOpId',
  );
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
    'client_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientOpId,
    scopeKey,
    payloadJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_op_id')) {
      context.handle(
        _clientOpIdMeta,
        clientOpId.isAcceptableOrUnknown(
          data['client_op_id']!,
          _clientOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOpIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientOpId};
  @override
  PendingMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMutation(
      clientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_op_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingMutationsTable createAlias(String alias) {
    return $PendingMutationsTable(attachedDatabase, alias);
  }
}

class PendingMutation extends DataClass implements Insertable<PendingMutation> {
  final String clientOpId;
  final String? scopeKey;
  final String payloadJson;
  final int createdAt;
  const PendingMutation({
    required this.clientOpId,
    this.scopeKey,
    required this.payloadJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_op_id'] = Variable<String>(clientOpId);
    if (!nullToAbsent || scopeKey != null) {
      map['scope_key'] = Variable<String>(scopeKey);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PendingMutationsCompanion toCompanion(bool nullToAbsent) {
    return PendingMutationsCompanion(
      clientOpId: Value(clientOpId),
      scopeKey: scopeKey == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeKey),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory PendingMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMutation(
      clientOpId: serializer.fromJson<String>(json['clientOpId']),
      scopeKey: serializer.fromJson<String?>(json['scopeKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientOpId': serializer.toJson<String>(clientOpId),
      'scopeKey': serializer.toJson<String?>(scopeKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PendingMutation copyWith({
    String? clientOpId,
    Value<String?> scopeKey = const Value.absent(),
    String? payloadJson,
    int? createdAt,
  }) => PendingMutation(
    clientOpId: clientOpId ?? this.clientOpId,
    scopeKey: scopeKey.present ? scopeKey.value : this.scopeKey,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingMutation copyWithCompanion(PendingMutationsCompanion data) {
    return PendingMutation(
      clientOpId: data.clientOpId.present
          ? data.clientOpId.value
          : this.clientOpId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutation(')
          ..write('clientOpId: $clientOpId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clientOpId, scopeKey, payloadJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMutation &&
          other.clientOpId == this.clientOpId &&
          other.scopeKey == this.scopeKey &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt);
}

class PendingMutationsCompanion extends UpdateCompanion<PendingMutation> {
  final Value<String> clientOpId;
  final Value<String?> scopeKey;
  final Value<String> payloadJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PendingMutationsCompanion({
    this.clientOpId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingMutationsCompanion.insert({
    required String clientOpId,
    this.scopeKey = const Value.absent(),
    required String payloadJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : clientOpId = Value(clientOpId),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingMutation> custom({
    Expression<String>? clientOpId,
    Expression<String>? scopeKey,
    Expression<String>? payloadJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingMutationsCompanion copyWith({
    Value<String>? clientOpId,
    Value<String?>? scopeKey,
    Value<String>? payloadJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingMutationsCompanion(
      clientOpId: clientOpId ?? this.clientOpId,
      scopeKey: scopeKey ?? this.scopeKey,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutationsCompanion(')
          ..write('clientOpId: $clientOpId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrganizationsTable extends Organizations
    with TableInfo<$OrganizationsTable, OrganizationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganizationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [organizationId, dataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organizations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrganizationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId};
  @override
  OrganizationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrganizationRow(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $OrganizationsTable createAlias(String alias) {
    return $OrganizationsTable(attachedDatabase, alias);
  }
}

class OrganizationRow extends DataClass implements Insertable<OrganizationRow> {
  final String organizationId;
  final String dataJson;
  const OrganizationRow({required this.organizationId, required this.dataJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  OrganizationsCompanion toCompanion(bool nullToAbsent) {
    return OrganizationsCompanion(
      organizationId: Value(organizationId),
      dataJson: Value(dataJson),
    );
  }

  factory OrganizationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrganizationRow(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  OrganizationRow copyWith({String? organizationId, String? dataJson}) =>
      OrganizationRow(
        organizationId: organizationId ?? this.organizationId,
        dataJson: dataJson ?? this.dataJson,
      );
  OrganizationRow copyWithCompanion(OrganizationsCompanion data) {
    return OrganizationRow(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationRow(')
          ..write('organizationId: $organizationId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrganizationRow &&
          other.organizationId == this.organizationId &&
          other.dataJson == this.dataJson);
}

class OrganizationsCompanion extends UpdateCompanion<OrganizationRow> {
  final Value<String> organizationId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const OrganizationsCompanion({
    this.organizationId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrganizationsCompanion.insert({
    required String organizationId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       dataJson = Value(dataJson);
  static Insertable<OrganizationRow> custom({
    Expression<String>? organizationId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrganizationsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return OrganizationsCompanion(
      organizationId: organizationId ?? this.organizationId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProducerAccountsTable extends ProducerAccounts
    with TableInfo<$ProducerAccountsTable, ProducerAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProducerAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _producerAccountIdMeta = const VerificationMeta(
    'producerAccountId',
  );
  @override
  late final GeneratedColumn<String> producerAccountId =
      GeneratedColumn<String>(
        'producer_account_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    producerAccountId,
    dataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'producer_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProducerAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('producer_account_id')) {
      context.handle(
        _producerAccountIdMeta,
        producerAccountId.isAcceptableOrUnknown(
          data['producer_account_id']!,
          _producerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_producerAccountIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, producerAccountId};
  @override
  ProducerAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProducerAccountRow(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      producerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producer_account_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $ProducerAccountsTable createAlias(String alias) {
    return $ProducerAccountsTable(attachedDatabase, alias);
  }
}

class ProducerAccountRow extends DataClass
    implements Insertable<ProducerAccountRow> {
  final String organizationId;
  final String producerAccountId;
  final String dataJson;
  const ProducerAccountRow({
    required this.organizationId,
    required this.producerAccountId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['producer_account_id'] = Variable<String>(producerAccountId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  ProducerAccountsCompanion toCompanion(bool nullToAbsent) {
    return ProducerAccountsCompanion(
      organizationId: Value(organizationId),
      producerAccountId: Value(producerAccountId),
      dataJson: Value(dataJson),
    );
  }

  factory ProducerAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProducerAccountRow(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      producerAccountId: serializer.fromJson<String>(json['producerAccountId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'producerAccountId': serializer.toJson<String>(producerAccountId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  ProducerAccountRow copyWith({
    String? organizationId,
    String? producerAccountId,
    String? dataJson,
  }) => ProducerAccountRow(
    organizationId: organizationId ?? this.organizationId,
    producerAccountId: producerAccountId ?? this.producerAccountId,
    dataJson: dataJson ?? this.dataJson,
  );
  ProducerAccountRow copyWithCompanion(ProducerAccountsCompanion data) {
    return ProducerAccountRow(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      producerAccountId: data.producerAccountId.present
          ? data.producerAccountId.value
          : this.producerAccountId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProducerAccountRow(')
          ..write('organizationId: $organizationId, ')
          ..write('producerAccountId: $producerAccountId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, producerAccountId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProducerAccountRow &&
          other.organizationId == this.organizationId &&
          other.producerAccountId == this.producerAccountId &&
          other.dataJson == this.dataJson);
}

class ProducerAccountsCompanion extends UpdateCompanion<ProducerAccountRow> {
  final Value<String> organizationId;
  final Value<String> producerAccountId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const ProducerAccountsCompanion({
    this.organizationId = const Value.absent(),
    this.producerAccountId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProducerAccountsCompanion.insert({
    required String organizationId,
    required String producerAccountId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       producerAccountId = Value(producerAccountId),
       dataJson = Value(dataJson);
  static Insertable<ProducerAccountRow> custom({
    Expression<String>? organizationId,
    Expression<String>? producerAccountId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (producerAccountId != null) 'producer_account_id': producerAccountId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProducerAccountsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? producerAccountId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return ProducerAccountsCompanion(
      organizationId: organizationId ?? this.organizationId,
      producerAccountId: producerAccountId ?? this.producerAccountId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (producerAccountId.present) {
      map['producer_account_id'] = Variable<String>(producerAccountId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProducerAccountsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('producerAccountId: $producerAccountId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [organizationId, memberId, dataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, memberId};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String organizationId;
  final String memberId;
  final String dataJson;
  const MemberRow({
    required this.organizationId,
    required this.memberId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['member_id'] = Variable<String>(memberId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      organizationId: Value(organizationId),
      memberId: Value(memberId),
      dataJson: Value(dataJson),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'memberId': serializer.toJson<String>(memberId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  MemberRow copyWith({
    String? organizationId,
    String? memberId,
    String? dataJson,
  }) => MemberRow(
    organizationId: organizationId ?? this.organizationId,
    memberId: memberId ?? this.memberId,
    dataJson: dataJson ?? this.dataJson,
  );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('organizationId: $organizationId, ')
          ..write('memberId: $memberId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, memberId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.organizationId == this.organizationId &&
          other.memberId == this.memberId &&
          other.dataJson == this.dataJson);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> organizationId;
  final Value<String> memberId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const MembersCompanion({
    this.organizationId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String organizationId,
    required String memberId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       memberId = Value(memberId),
       dataJson = Value(dataJson);
  static Insertable<MemberRow> custom({
    Expression<String>? organizationId,
    Expression<String>? memberId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (memberId != null) 'member_id': memberId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? memberId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      organizationId: organizationId ?? this.organizationId,
      memberId: memberId ?? this.memberId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('memberId: $memberId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberInvitationsTable extends MemberInvitations
    with TableInfo<$MemberInvitationsTable, MemberInvitationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberInvitationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invitationIdMeta = const VerificationMeta(
    'invitationId',
  );
  @override
  late final GeneratedColumn<String> invitationId = GeneratedColumn<String>(
    'invitation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    invitationId,
    dataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_invitations';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberInvitationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('invitation_id')) {
      context.handle(
        _invitationIdMeta,
        invitationId.isAcceptableOrUnknown(
          data['invitation_id']!,
          _invitationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invitationIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, invitationId};
  @override
  MemberInvitationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberInvitationRow(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      invitationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invitation_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $MemberInvitationsTable createAlias(String alias) {
    return $MemberInvitationsTable(attachedDatabase, alias);
  }
}

class MemberInvitationRow extends DataClass
    implements Insertable<MemberInvitationRow> {
  final String organizationId;
  final String invitationId;
  final String dataJson;
  const MemberInvitationRow({
    required this.organizationId,
    required this.invitationId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['invitation_id'] = Variable<String>(invitationId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  MemberInvitationsCompanion toCompanion(bool nullToAbsent) {
    return MemberInvitationsCompanion(
      organizationId: Value(organizationId),
      invitationId: Value(invitationId),
      dataJson: Value(dataJson),
    );
  }

  factory MemberInvitationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberInvitationRow(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      invitationId: serializer.fromJson<String>(json['invitationId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'invitationId': serializer.toJson<String>(invitationId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  MemberInvitationRow copyWith({
    String? organizationId,
    String? invitationId,
    String? dataJson,
  }) => MemberInvitationRow(
    organizationId: organizationId ?? this.organizationId,
    invitationId: invitationId ?? this.invitationId,
    dataJson: dataJson ?? this.dataJson,
  );
  MemberInvitationRow copyWithCompanion(MemberInvitationsCompanion data) {
    return MemberInvitationRow(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      invitationId: data.invitationId.present
          ? data.invitationId.value
          : this.invitationId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberInvitationRow(')
          ..write('organizationId: $organizationId, ')
          ..write('invitationId: $invitationId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, invitationId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberInvitationRow &&
          other.organizationId == this.organizationId &&
          other.invitationId == this.invitationId &&
          other.dataJson == this.dataJson);
}

class MemberInvitationsCompanion extends UpdateCompanion<MemberInvitationRow> {
  final Value<String> organizationId;
  final Value<String> invitationId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const MemberInvitationsCompanion({
    this.organizationId = const Value.absent(),
    this.invitationId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberInvitationsCompanion.insert({
    required String organizationId,
    required String invitationId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       invitationId = Value(invitationId),
       dataJson = Value(dataJson);
  static Insertable<MemberInvitationRow> custom({
    Expression<String>? organizationId,
    Expression<String>? invitationId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (invitationId != null) 'invitation_id': invitationId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberInvitationsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? invitationId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return MemberInvitationsCompanion(
      organizationId: organizationId ?? this.organizationId,
      invitationId: invitationId ?? this.invitationId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (invitationId.present) {
      map['invitation_id'] = Variable<String>(invitationId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberInvitationsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('invitationId: $invitationId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberJoinRequestsTable extends MemberJoinRequests
    with TableInfo<$MemberJoinRequestsTable, MemberJoinRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberJoinRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [organizationId, requestId, dataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_join_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberJoinRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, requestId};
  @override
  MemberJoinRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberJoinRequestRow(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $MemberJoinRequestsTable createAlias(String alias) {
    return $MemberJoinRequestsTable(attachedDatabase, alias);
  }
}

class MemberJoinRequestRow extends DataClass
    implements Insertable<MemberJoinRequestRow> {
  final String organizationId;
  final String requestId;
  final String dataJson;
  const MemberJoinRequestRow({
    required this.organizationId,
    required this.requestId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['request_id'] = Variable<String>(requestId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  MemberJoinRequestsCompanion toCompanion(bool nullToAbsent) {
    return MemberJoinRequestsCompanion(
      organizationId: Value(organizationId),
      requestId: Value(requestId),
      dataJson: Value(dataJson),
    );
  }

  factory MemberJoinRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberJoinRequestRow(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      requestId: serializer.fromJson<String>(json['requestId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'requestId': serializer.toJson<String>(requestId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  MemberJoinRequestRow copyWith({
    String? organizationId,
    String? requestId,
    String? dataJson,
  }) => MemberJoinRequestRow(
    organizationId: organizationId ?? this.organizationId,
    requestId: requestId ?? this.requestId,
    dataJson: dataJson ?? this.dataJson,
  );
  MemberJoinRequestRow copyWithCompanion(MemberJoinRequestsCompanion data) {
    return MemberJoinRequestRow(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberJoinRequestRow(')
          ..write('organizationId: $organizationId, ')
          ..write('requestId: $requestId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, requestId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberJoinRequestRow &&
          other.organizationId == this.organizationId &&
          other.requestId == this.requestId &&
          other.dataJson == this.dataJson);
}

class MemberJoinRequestsCompanion
    extends UpdateCompanion<MemberJoinRequestRow> {
  final Value<String> organizationId;
  final Value<String> requestId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const MemberJoinRequestsCompanion({
    this.organizationId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberJoinRequestsCompanion.insert({
    required String organizationId,
    required String requestId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       requestId = Value(requestId),
       dataJson = Value(dataJson);
  static Insertable<MemberJoinRequestRow> custom({
    Expression<String>? organizationId,
    Expression<String>? requestId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (requestId != null) 'request_id': requestId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberJoinRequestsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? requestId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return MemberJoinRequestsCompanion(
      organizationId: organizationId ?? this.organizationId,
      requestId: requestId ?? this.requestId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberJoinRequestsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('requestId: $requestId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContractsTable extends Contracts
    with TableInfo<$ContractsTable, ContractRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [organizationId, contractId, dataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContractRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, contractId};
  @override
  ContractRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContractRow(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $ContractsTable createAlias(String alias) {
    return $ContractsTable(attachedDatabase, alias);
  }
}

class ContractRow extends DataClass implements Insertable<ContractRow> {
  final String organizationId;
  final String contractId;
  final String dataJson;
  const ContractRow({
    required this.organizationId,
    required this.contractId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['contract_id'] = Variable<String>(contractId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  ContractsCompanion toCompanion(bool nullToAbsent) {
    return ContractsCompanion(
      organizationId: Value(organizationId),
      contractId: Value(contractId),
      dataJson: Value(dataJson),
    );
  }

  factory ContractRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContractRow(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      contractId: serializer.fromJson<String>(json['contractId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'contractId': serializer.toJson<String>(contractId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  ContractRow copyWith({
    String? organizationId,
    String? contractId,
    String? dataJson,
  }) => ContractRow(
    organizationId: organizationId ?? this.organizationId,
    contractId: contractId ?? this.contractId,
    dataJson: dataJson ?? this.dataJson,
  );
  ContractRow copyWithCompanion(ContractsCompanion data) {
    return ContractRow(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContractRow(')
          ..write('organizationId: $organizationId, ')
          ..write('contractId: $contractId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, contractId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContractRow &&
          other.organizationId == this.organizationId &&
          other.contractId == this.contractId &&
          other.dataJson == this.dataJson);
}

class ContractsCompanion extends UpdateCompanion<ContractRow> {
  final Value<String> organizationId;
  final Value<String> contractId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const ContractsCompanion({
    this.organizationId = const Value.absent(),
    this.contractId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContractsCompanion.insert({
    required String organizationId,
    required String contractId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       contractId = Value(contractId),
       dataJson = Value(dataJson);
  static Insertable<ContractRow> custom({
    Expression<String>? organizationId,
    Expression<String>? contractId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (contractId != null) 'contract_id': contractId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContractsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? contractId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return ContractsCompanion(
      organizationId: organizationId ?? this.organizationId,
      contractId: contractId ?? this.contractId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContractsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('contractId: $contractId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeliveryTemplatesTable extends DeliveryTemplates
    with TableInfo<$DeliveryTemplatesTable, DeliveryTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryTemplateIdMeta =
      const VerificationMeta('deliveryTemplateId');
  @override
  late final GeneratedColumn<String> deliveryTemplateId =
      GeneratedColumn<String>(
        'delivery_template_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    deliveryTemplateId,
    dataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('delivery_template_id')) {
      context.handle(
        _deliveryTemplateIdMeta,
        deliveryTemplateId.isAcceptableOrUnknown(
          data['delivery_template_id']!,
          _deliveryTemplateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryTemplateIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, deliveryTemplateId};
  @override
  DeliveryTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryTemplateRow(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      deliveryTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_template_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $DeliveryTemplatesTable createAlias(String alias) {
    return $DeliveryTemplatesTable(attachedDatabase, alias);
  }
}

class DeliveryTemplateRow extends DataClass
    implements Insertable<DeliveryTemplateRow> {
  final String organizationId;
  final String deliveryTemplateId;
  final String dataJson;
  const DeliveryTemplateRow({
    required this.organizationId,
    required this.deliveryTemplateId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['delivery_template_id'] = Variable<String>(deliveryTemplateId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  DeliveryTemplatesCompanion toCompanion(bool nullToAbsent) {
    return DeliveryTemplatesCompanion(
      organizationId: Value(organizationId),
      deliveryTemplateId: Value(deliveryTemplateId),
      dataJson: Value(dataJson),
    );
  }

  factory DeliveryTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryTemplateRow(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      deliveryTemplateId: serializer.fromJson<String>(
        json['deliveryTemplateId'],
      ),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'deliveryTemplateId': serializer.toJson<String>(deliveryTemplateId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  DeliveryTemplateRow copyWith({
    String? organizationId,
    String? deliveryTemplateId,
    String? dataJson,
  }) => DeliveryTemplateRow(
    organizationId: organizationId ?? this.organizationId,
    deliveryTemplateId: deliveryTemplateId ?? this.deliveryTemplateId,
    dataJson: dataJson ?? this.dataJson,
  );
  DeliveryTemplateRow copyWithCompanion(DeliveryTemplatesCompanion data) {
    return DeliveryTemplateRow(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      deliveryTemplateId: data.deliveryTemplateId.present
          ? data.deliveryTemplateId.value
          : this.deliveryTemplateId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryTemplateRow(')
          ..write('organizationId: $organizationId, ')
          ..write('deliveryTemplateId: $deliveryTemplateId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, deliveryTemplateId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryTemplateRow &&
          other.organizationId == this.organizationId &&
          other.deliveryTemplateId == this.deliveryTemplateId &&
          other.dataJson == this.dataJson);
}

class DeliveryTemplatesCompanion extends UpdateCompanion<DeliveryTemplateRow> {
  final Value<String> organizationId;
  final Value<String> deliveryTemplateId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const DeliveryTemplatesCompanion({
    this.organizationId = const Value.absent(),
    this.deliveryTemplateId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveryTemplatesCompanion.insert({
    required String organizationId,
    required String deliveryTemplateId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       deliveryTemplateId = Value(deliveryTemplateId),
       dataJson = Value(dataJson);
  static Insertable<DeliveryTemplateRow> custom({
    Expression<String>? organizationId,
    Expression<String>? deliveryTemplateId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (deliveryTemplateId != null)
        'delivery_template_id': deliveryTemplateId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveryTemplatesCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? deliveryTemplateId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return DeliveryTemplatesCompanion(
      organizationId: organizationId ?? this.organizationId,
      deliveryTemplateId: deliveryTemplateId ?? this.deliveryTemplateId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (deliveryTemplateId.present) {
      map['delivery_template_id'] = Variable<String>(deliveryTemplateId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryTemplatesCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('deliveryTemplateId: $deliveryTemplateId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrganizationRequestsTable extends OrganizationRequests
    with TableInfo<$OrganizationRequestsTable, OrganizationRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganizationRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [requestId, dataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organization_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrganizationRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {requestId};
  @override
  OrganizationRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrganizationRequestRow(
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $OrganizationRequestsTable createAlias(String alias) {
    return $OrganizationRequestsTable(attachedDatabase, alias);
  }
}

class OrganizationRequestRow extends DataClass
    implements Insertable<OrganizationRequestRow> {
  final String requestId;
  final String dataJson;
  const OrganizationRequestRow({
    required this.requestId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['request_id'] = Variable<String>(requestId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  OrganizationRequestsCompanion toCompanion(bool nullToAbsent) {
    return OrganizationRequestsCompanion(
      requestId: Value(requestId),
      dataJson: Value(dataJson),
    );
  }

  factory OrganizationRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrganizationRequestRow(
      requestId: serializer.fromJson<String>(json['requestId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'requestId': serializer.toJson<String>(requestId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  OrganizationRequestRow copyWith({String? requestId, String? dataJson}) =>
      OrganizationRequestRow(
        requestId: requestId ?? this.requestId,
        dataJson: dataJson ?? this.dataJson,
      );
  OrganizationRequestRow copyWithCompanion(OrganizationRequestsCompanion data) {
    return OrganizationRequestRow(
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationRequestRow(')
          ..write('requestId: $requestId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(requestId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrganizationRequestRow &&
          other.requestId == this.requestId &&
          other.dataJson == this.dataJson);
}

class OrganizationRequestsCompanion
    extends UpdateCompanion<OrganizationRequestRow> {
  final Value<String> requestId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const OrganizationRequestsCompanion({
    this.requestId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrganizationRequestsCompanion.insert({
    required String requestId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : requestId = Value(requestId),
       dataJson = Value(dataJson);
  static Insertable<OrganizationRequestRow> custom({
    Expression<String>? requestId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (requestId != null) 'request_id': requestId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrganizationRequestsCompanion copyWith({
    Value<String>? requestId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return OrganizationRequestsCompanion(
      requestId: requestId ?? this.requestId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationRequestsCompanion(')
          ..write('requestId: $requestId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProducerRequestsTable extends ProducerRequests
    with TableInfo<$ProducerRequestsTable, ProducerRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProducerRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [requestId, dataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'producer_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProducerRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {requestId};
  @override
  ProducerRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProducerRequestRow(
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $ProducerRequestsTable createAlias(String alias) {
    return $ProducerRequestsTable(attachedDatabase, alias);
  }
}

class ProducerRequestRow extends DataClass
    implements Insertable<ProducerRequestRow> {
  final String requestId;
  final String dataJson;
  const ProducerRequestRow({required this.requestId, required this.dataJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['request_id'] = Variable<String>(requestId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  ProducerRequestsCompanion toCompanion(bool nullToAbsent) {
    return ProducerRequestsCompanion(
      requestId: Value(requestId),
      dataJson: Value(dataJson),
    );
  }

  factory ProducerRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProducerRequestRow(
      requestId: serializer.fromJson<String>(json['requestId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'requestId': serializer.toJson<String>(requestId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  ProducerRequestRow copyWith({String? requestId, String? dataJson}) =>
      ProducerRequestRow(
        requestId: requestId ?? this.requestId,
        dataJson: dataJson ?? this.dataJson,
      );
  ProducerRequestRow copyWithCompanion(ProducerRequestsCompanion data) {
    return ProducerRequestRow(
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProducerRequestRow(')
          ..write('requestId: $requestId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(requestId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProducerRequestRow &&
          other.requestId == this.requestId &&
          other.dataJson == this.dataJson);
}

class ProducerRequestsCompanion extends UpdateCompanion<ProducerRequestRow> {
  final Value<String> requestId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const ProducerRequestsCompanion({
    this.requestId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProducerRequestsCompanion.insert({
    required String requestId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : requestId = Value(requestId),
       dataJson = Value(dataJson);
  static Insertable<ProducerRequestRow> custom({
    Expression<String>? requestId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (requestId != null) 'request_id': requestId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProducerRequestsCompanion copyWith({
    Value<String>? requestId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return ProducerRequestsCompanion(
      requestId: requestId ?? this.requestId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProducerRequestsCompanion(')
          ..write('requestId: $requestId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OwnersTable extends Owners with TableInfo<$OwnersTable, OwnerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountStatusMeta = const VerificationMeta(
    'accountStatus',
  );
  @override
  late final GeneratedColumn<String> accountStatus = GeneratedColumn<String>(
    'account_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registeredAtMeta = const VerificationMeta(
    'registeredAt',
  );
  @override
  late final GeneratedColumn<String> registeredAt = GeneratedColumn<String>(
    'registered_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userPreferencesMeta = const VerificationMeta(
    'userPreferences',
  );
  @override
  late final GeneratedColumn<String> userPreferences = GeneratedColumn<String>(
    'user_preferences',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    firstName,
    lastName,
    email,
    phone,
    accountStatus,
    registeredAt,
    updatedAt,
    userPreferences,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'owners';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('account_status')) {
      context.handle(
        _accountStatusMeta,
        accountStatus.isAcceptableOrUnknown(
          data['account_status']!,
          _accountStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountStatusMeta);
    }
    if (data.containsKey('registered_at')) {
      context.handle(
        _registeredAtMeta,
        registeredAt.isAcceptableOrUnknown(
          data['registered_at']!,
          _registeredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registeredAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_preferences')) {
      context.handle(
        _userPreferencesMeta,
        userPreferences.isAcceptableOrUnknown(
          data['user_preferences']!,
          _userPreferencesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  OwnerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnerRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      accountStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_status'],
      )!,
      registeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registered_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      userPreferences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_preferences'],
      ),
    );
  }

  @override
  $OwnersTable createAlias(String alias) {
    return $OwnersTable(attachedDatabase, alias);
  }
}

class OwnerRow extends DataClass implements Insertable<OwnerRow> {
  final String ownerId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String accountStatus;
  final String registeredAt;
  final String updatedAt;

  /// Nullable JSON blob for [UserPreferences]. Added in schema v11.
  final String? userPreferences;
  const OwnerRow({
    required this.ownerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.accountStatus,
    required this.registeredAt,
    required this.updatedAt,
    this.userPreferences,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['account_status'] = Variable<String>(accountStatus);
    map['registered_at'] = Variable<String>(registeredAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || userPreferences != null) {
      map['user_preferences'] = Variable<String>(userPreferences);
    }
    return map;
  }

  OwnersCompanion toCompanion(bool nullToAbsent) {
    return OwnersCompanion(
      ownerId: Value(ownerId),
      firstName: Value(firstName),
      lastName: Value(lastName),
      email: Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      accountStatus: Value(accountStatus),
      registeredAt: Value(registeredAt),
      updatedAt: Value(updatedAt),
      userPreferences: userPreferences == null && nullToAbsent
          ? const Value.absent()
          : Value(userPreferences),
    );
  }

  factory OwnerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnerRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      accountStatus: serializer.fromJson<String>(json['accountStatus']),
      registeredAt: serializer.fromJson<String>(json['registeredAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      userPreferences: serializer.fromJson<String?>(json['userPreferences']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String?>(phone),
      'accountStatus': serializer.toJson<String>(accountStatus),
      'registeredAt': serializer.toJson<String>(registeredAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'userPreferences': serializer.toJson<String?>(userPreferences),
    };
  }

  OwnerRow copyWith({
    String? ownerId,
    String? firstName,
    String? lastName,
    String? email,
    Value<String?> phone = const Value.absent(),
    String? accountStatus,
    String? registeredAt,
    String? updatedAt,
    Value<String?> userPreferences = const Value.absent(),
  }) => OwnerRow(
    ownerId: ownerId ?? this.ownerId,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    phone: phone.present ? phone.value : this.phone,
    accountStatus: accountStatus ?? this.accountStatus,
    registeredAt: registeredAt ?? this.registeredAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userPreferences: userPreferences.present
        ? userPreferences.value
        : this.userPreferences,
  );
  OwnerRow copyWithCompanion(OwnersCompanion data) {
    return OwnerRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      accountStatus: data.accountStatus.present
          ? data.accountStatus.value
          : this.accountStatus,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userPreferences: data.userPreferences.present
          ? data.userPreferences.value
          : this.userPreferences,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnerRow(')
          ..write('ownerId: $ownerId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('accountStatus: $accountStatus, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userPreferences: $userPreferences')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    firstName,
    lastName,
    email,
    phone,
    accountStatus,
    registeredAt,
    updatedAt,
    userPreferences,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerRow &&
          other.ownerId == this.ownerId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.accountStatus == this.accountStatus &&
          other.registeredAt == this.registeredAt &&
          other.updatedAt == this.updatedAt &&
          other.userPreferences == this.userPreferences);
}

class OwnersCompanion extends UpdateCompanion<OwnerRow> {
  final Value<String> ownerId;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> email;
  final Value<String?> phone;
  final Value<String> accountStatus;
  final Value<String> registeredAt;
  final Value<String> updatedAt;
  final Value<String?> userPreferences;
  final Value<int> rowid;
  const OwnersCompanion({
    this.ownerId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.accountStatus = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userPreferences = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnersCompanion.insert({
    required String ownerId,
    required String firstName,
    required String lastName,
    required String email,
    this.phone = const Value.absent(),
    required String accountStatus,
    required String registeredAt,
    required String updatedAt,
    this.userPreferences = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       firstName = Value(firstName),
       lastName = Value(lastName),
       email = Value(email),
       accountStatus = Value(accountStatus),
       registeredAt = Value(registeredAt),
       updatedAt = Value(updatedAt);
  static Insertable<OwnerRow> custom({
    Expression<String>? ownerId,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? accountStatus,
    Expression<String>? registeredAt,
    Expression<String>? updatedAt,
    Expression<String>? userPreferences,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (accountStatus != null) 'account_status': accountStatus,
      if (registeredAt != null) 'registered_at': registeredAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userPreferences != null) 'user_preferences': userPreferences,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnersCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? email,
    Value<String?>? phone,
    Value<String>? accountStatus,
    Value<String>? registeredAt,
    Value<String>? updatedAt,
    Value<String?>? userPreferences,
    Value<int>? rowid,
  }) {
    return OwnersCompanion(
      ownerId: ownerId ?? this.ownerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      accountStatus: accountStatus ?? this.accountStatus,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userPreferences: userPreferences ?? this.userPreferences,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (accountStatus.present) {
      map['account_status'] = Variable<String>(accountStatus.value);
    }
    if (registeredAt.present) {
      map['registered_at'] = Variable<String>(registeredAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (userPreferences.present) {
      map['user_preferences'] = Variable<String>(userPreferences.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnersCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('accountStatus: $accountStatus, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userPreferences: $userPreferences, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OwnerInvitationsTable extends OwnerInvitations
    with TableInfo<$OwnerInvitationsTable, OwnerInvitationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnerInvitationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _invitationIdMeta = const VerificationMeta(
    'invitationId',
  );
  @override
  late final GeneratedColumn<String> invitationId = GeneratedColumn<String>(
    'invitation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [invitationId, dataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'owner_invitations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnerInvitationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('invitation_id')) {
      context.handle(
        _invitationIdMeta,
        invitationId.isAcceptableOrUnknown(
          data['invitation_id']!,
          _invitationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invitationIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {invitationId};
  @override
  OwnerInvitationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnerInvitationRow(
      invitationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invitation_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $OwnerInvitationsTable createAlias(String alias) {
    return $OwnerInvitationsTable(attachedDatabase, alias);
  }
}

class OwnerInvitationRow extends DataClass
    implements Insertable<OwnerInvitationRow> {
  final String invitationId;
  final String dataJson;
  const OwnerInvitationRow({
    required this.invitationId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['invitation_id'] = Variable<String>(invitationId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  OwnerInvitationsCompanion toCompanion(bool nullToAbsent) {
    return OwnerInvitationsCompanion(
      invitationId: Value(invitationId),
      dataJson: Value(dataJson),
    );
  }

  factory OwnerInvitationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnerInvitationRow(
      invitationId: serializer.fromJson<String>(json['invitationId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'invitationId': serializer.toJson<String>(invitationId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  OwnerInvitationRow copyWith({String? invitationId, String? dataJson}) =>
      OwnerInvitationRow(
        invitationId: invitationId ?? this.invitationId,
        dataJson: dataJson ?? this.dataJson,
      );
  OwnerInvitationRow copyWithCompanion(OwnerInvitationsCompanion data) {
    return OwnerInvitationRow(
      invitationId: data.invitationId.present
          ? data.invitationId.value
          : this.invitationId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnerInvitationRow(')
          ..write('invitationId: $invitationId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(invitationId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerInvitationRow &&
          other.invitationId == this.invitationId &&
          other.dataJson == this.dataJson);
}

class OwnerInvitationsCompanion extends UpdateCompanion<OwnerInvitationRow> {
  final Value<String> invitationId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const OwnerInvitationsCompanion({
    this.invitationId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnerInvitationsCompanion.insert({
    required String invitationId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : invitationId = Value(invitationId),
       dataJson = Value(dataJson);
  static Insertable<OwnerInvitationRow> custom({
    Expression<String>? invitationId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (invitationId != null) 'invitation_id': invitationId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnerInvitationsCompanion copyWith({
    Value<String>? invitationId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return OwnerInvitationsCompanion(
      invitationId: invitationId ?? this.invitationId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (invitationId.present) {
      map['invitation_id'] = Variable<String>(invitationId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnerInvitationsCompanion(')
          ..write('invitationId: $invitationId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BasketExchangesTable extends BasketExchanges
    with TableInfo<$BasketExchangesTable, BasketExchangeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BasketExchangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _basketExchangeIdMeta = const VerificationMeta(
    'basketExchangeId',
  );
  @override
  late final GeneratedColumn<String> basketExchangeId = GeneratedColumn<String>(
    'basket_exchange_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryIdMeta = const VerificationMeta(
    'deliveryId',
  );
  @override
  late final GeneratedColumn<String> deliveryId = GeneratedColumn<String>(
    'delivery_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractIdMeta = const VerificationMeta(
    'contractId',
  );
  @override
  late final GeneratedColumn<String> contractId = GeneratedColumn<String>(
    'contract_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offeringMemberIdMeta = const VerificationMeta(
    'offeringMemberId',
  );
  @override
  late final GeneratedColumn<String> offeringMemberId = GeneratedColumn<String>(
    'offering_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motiveMeta = const VerificationMeta('motive');
  @override
  late final GeneratedColumn<String> motive = GeneratedColumn<String>(
    'motive',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<String> decidedAt = GeneratedColumn<String>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acceptedRequestIdMeta = const VerificationMeta(
    'acceptedRequestId',
  );
  @override
  late final GeneratedColumn<String> acceptedRequestId =
      GeneratedColumn<String>(
        'accepted_request_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _requestsJsonMeta = const VerificationMeta(
    'requestsJson',
  );
  @override
  late final GeneratedColumn<String> requestsJson = GeneratedColumn<String>(
    'requests_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    basketExchangeId,
    organizationId,
    deliveryId,
    contractId,
    offeringMemberId,
    motive,
    status,
    createdAt,
    decidedAt,
    acceptedRequestId,
    requestsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'basket_exchanges';
  @override
  VerificationContext validateIntegrity(
    Insertable<BasketExchangeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('basket_exchange_id')) {
      context.handle(
        _basketExchangeIdMeta,
        basketExchangeId.isAcceptableOrUnknown(
          data['basket_exchange_id']!,
          _basketExchangeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_basketExchangeIdMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('delivery_id')) {
      context.handle(
        _deliveryIdMeta,
        deliveryId.isAcceptableOrUnknown(data['delivery_id']!, _deliveryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deliveryIdMeta);
    }
    if (data.containsKey('contract_id')) {
      context.handle(
        _contractIdMeta,
        contractId.isAcceptableOrUnknown(data['contract_id']!, _contractIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contractIdMeta);
    }
    if (data.containsKey('offering_member_id')) {
      context.handle(
        _offeringMemberIdMeta,
        offeringMemberId.isAcceptableOrUnknown(
          data['offering_member_id']!,
          _offeringMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offeringMemberIdMeta);
    }
    if (data.containsKey('motive')) {
      context.handle(
        _motiveMeta,
        motive.isAcceptableOrUnknown(data['motive']!, _motiveMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('accepted_request_id')) {
      context.handle(
        _acceptedRequestIdMeta,
        acceptedRequestId.isAcceptableOrUnknown(
          data['accepted_request_id']!,
          _acceptedRequestIdMeta,
        ),
      );
    }
    if (data.containsKey('requests_json')) {
      context.handle(
        _requestsJsonMeta,
        requestsJson.isAcceptableOrUnknown(
          data['requests_json']!,
          _requestsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {basketExchangeId};
  @override
  BasketExchangeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BasketExchangeRow(
      basketExchangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basket_exchange_id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      deliveryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_id'],
      )!,
      contractId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_id'],
      )!,
      offeringMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offering_member_id'],
      )!,
      motive: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motive'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_at'],
      ),
      acceptedRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accepted_request_id'],
      ),
      requestsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requests_json'],
      )!,
    );
  }

  @override
  $BasketExchangesTable createAlias(String alias) {
    return $BasketExchangesTable(attachedDatabase, alias);
  }
}

class BasketExchangeRow extends DataClass
    implements Insertable<BasketExchangeRow> {
  final String basketExchangeId;
  final String organizationId;
  final String deliveryId;
  final String contractId;
  final String offeringMemberId;
  final String? motive;
  final String status;
  final String createdAt;
  final String? decidedAt;
  final String? acceptedRequestId;
  final String requestsJson;
  const BasketExchangeRow({
    required this.basketExchangeId,
    required this.organizationId,
    required this.deliveryId,
    required this.contractId,
    required this.offeringMemberId,
    this.motive,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.acceptedRequestId,
    required this.requestsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['basket_exchange_id'] = Variable<String>(basketExchangeId);
    map['organization_id'] = Variable<String>(organizationId);
    map['delivery_id'] = Variable<String>(deliveryId);
    map['contract_id'] = Variable<String>(contractId);
    map['offering_member_id'] = Variable<String>(offeringMemberId);
    if (!nullToAbsent || motive != null) {
      map['motive'] = Variable<String>(motive);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<String>(decidedAt);
    }
    if (!nullToAbsent || acceptedRequestId != null) {
      map['accepted_request_id'] = Variable<String>(acceptedRequestId);
    }
    map['requests_json'] = Variable<String>(requestsJson);
    return map;
  }

  BasketExchangesCompanion toCompanion(bool nullToAbsent) {
    return BasketExchangesCompanion(
      basketExchangeId: Value(basketExchangeId),
      organizationId: Value(organizationId),
      deliveryId: Value(deliveryId),
      contractId: Value(contractId),
      offeringMemberId: Value(offeringMemberId),
      motive: motive == null && nullToAbsent
          ? const Value.absent()
          : Value(motive),
      status: Value(status),
      createdAt: Value(createdAt),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      acceptedRequestId: acceptedRequestId == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedRequestId),
      requestsJson: Value(requestsJson),
    );
  }

  factory BasketExchangeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BasketExchangeRow(
      basketExchangeId: serializer.fromJson<String>(json['basketExchangeId']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      deliveryId: serializer.fromJson<String>(json['deliveryId']),
      contractId: serializer.fromJson<String>(json['contractId']),
      offeringMemberId: serializer.fromJson<String>(json['offeringMemberId']),
      motive: serializer.fromJson<String?>(json['motive']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      decidedAt: serializer.fromJson<String?>(json['decidedAt']),
      acceptedRequestId: serializer.fromJson<String?>(
        json['acceptedRequestId'],
      ),
      requestsJson: serializer.fromJson<String>(json['requestsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'basketExchangeId': serializer.toJson<String>(basketExchangeId),
      'organizationId': serializer.toJson<String>(organizationId),
      'deliveryId': serializer.toJson<String>(deliveryId),
      'contractId': serializer.toJson<String>(contractId),
      'offeringMemberId': serializer.toJson<String>(offeringMemberId),
      'motive': serializer.toJson<String?>(motive),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
      'decidedAt': serializer.toJson<String?>(decidedAt),
      'acceptedRequestId': serializer.toJson<String?>(acceptedRequestId),
      'requestsJson': serializer.toJson<String>(requestsJson),
    };
  }

  BasketExchangeRow copyWith({
    String? basketExchangeId,
    String? organizationId,
    String? deliveryId,
    String? contractId,
    String? offeringMemberId,
    Value<String?> motive = const Value.absent(),
    String? status,
    String? createdAt,
    Value<String?> decidedAt = const Value.absent(),
    Value<String?> acceptedRequestId = const Value.absent(),
    String? requestsJson,
  }) => BasketExchangeRow(
    basketExchangeId: basketExchangeId ?? this.basketExchangeId,
    organizationId: organizationId ?? this.organizationId,
    deliveryId: deliveryId ?? this.deliveryId,
    contractId: contractId ?? this.contractId,
    offeringMemberId: offeringMemberId ?? this.offeringMemberId,
    motive: motive.present ? motive.value : this.motive,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    acceptedRequestId: acceptedRequestId.present
        ? acceptedRequestId.value
        : this.acceptedRequestId,
    requestsJson: requestsJson ?? this.requestsJson,
  );
  BasketExchangeRow copyWithCompanion(BasketExchangesCompanion data) {
    return BasketExchangeRow(
      basketExchangeId: data.basketExchangeId.present
          ? data.basketExchangeId.value
          : this.basketExchangeId,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      deliveryId: data.deliveryId.present
          ? data.deliveryId.value
          : this.deliveryId,
      contractId: data.contractId.present
          ? data.contractId.value
          : this.contractId,
      offeringMemberId: data.offeringMemberId.present
          ? data.offeringMemberId.value
          : this.offeringMemberId,
      motive: data.motive.present ? data.motive.value : this.motive,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      acceptedRequestId: data.acceptedRequestId.present
          ? data.acceptedRequestId.value
          : this.acceptedRequestId,
      requestsJson: data.requestsJson.present
          ? data.requestsJson.value
          : this.requestsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BasketExchangeRow(')
          ..write('basketExchangeId: $basketExchangeId, ')
          ..write('organizationId: $organizationId, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('contractId: $contractId, ')
          ..write('offeringMemberId: $offeringMemberId, ')
          ..write('motive: $motive, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('acceptedRequestId: $acceptedRequestId, ')
          ..write('requestsJson: $requestsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    basketExchangeId,
    organizationId,
    deliveryId,
    contractId,
    offeringMemberId,
    motive,
    status,
    createdAt,
    decidedAt,
    acceptedRequestId,
    requestsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BasketExchangeRow &&
          other.basketExchangeId == this.basketExchangeId &&
          other.organizationId == this.organizationId &&
          other.deliveryId == this.deliveryId &&
          other.contractId == this.contractId &&
          other.offeringMemberId == this.offeringMemberId &&
          other.motive == this.motive &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.decidedAt == this.decidedAt &&
          other.acceptedRequestId == this.acceptedRequestId &&
          other.requestsJson == this.requestsJson);
}

class BasketExchangesCompanion extends UpdateCompanion<BasketExchangeRow> {
  final Value<String> basketExchangeId;
  final Value<String> organizationId;
  final Value<String> deliveryId;
  final Value<String> contractId;
  final Value<String> offeringMemberId;
  final Value<String?> motive;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String?> decidedAt;
  final Value<String?> acceptedRequestId;
  final Value<String> requestsJson;
  final Value<int> rowid;
  const BasketExchangesCompanion({
    this.basketExchangeId = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.deliveryId = const Value.absent(),
    this.contractId = const Value.absent(),
    this.offeringMemberId = const Value.absent(),
    this.motive = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.acceptedRequestId = const Value.absent(),
    this.requestsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BasketExchangesCompanion.insert({
    required String basketExchangeId,
    required String organizationId,
    required String deliveryId,
    required String contractId,
    required String offeringMemberId,
    this.motive = const Value.absent(),
    required String status,
    required String createdAt,
    this.decidedAt = const Value.absent(),
    this.acceptedRequestId = const Value.absent(),
    required String requestsJson,
    this.rowid = const Value.absent(),
  }) : basketExchangeId = Value(basketExchangeId),
       organizationId = Value(organizationId),
       deliveryId = Value(deliveryId),
       contractId = Value(contractId),
       offeringMemberId = Value(offeringMemberId),
       status = Value(status),
       createdAt = Value(createdAt),
       requestsJson = Value(requestsJson);
  static Insertable<BasketExchangeRow> custom({
    Expression<String>? basketExchangeId,
    Expression<String>? organizationId,
    Expression<String>? deliveryId,
    Expression<String>? contractId,
    Expression<String>? offeringMemberId,
    Expression<String>? motive,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? decidedAt,
    Expression<String>? acceptedRequestId,
    Expression<String>? requestsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (basketExchangeId != null) 'basket_exchange_id': basketExchangeId,
      if (organizationId != null) 'organization_id': organizationId,
      if (deliveryId != null) 'delivery_id': deliveryId,
      if (contractId != null) 'contract_id': contractId,
      if (offeringMemberId != null) 'offering_member_id': offeringMemberId,
      if (motive != null) 'motive': motive,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (acceptedRequestId != null) 'accepted_request_id': acceptedRequestId,
      if (requestsJson != null) 'requests_json': requestsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BasketExchangesCompanion copyWith({
    Value<String>? basketExchangeId,
    Value<String>? organizationId,
    Value<String>? deliveryId,
    Value<String>? contractId,
    Value<String>? offeringMemberId,
    Value<String?>? motive,
    Value<String>? status,
    Value<String>? createdAt,
    Value<String?>? decidedAt,
    Value<String?>? acceptedRequestId,
    Value<String>? requestsJson,
    Value<int>? rowid,
  }) {
    return BasketExchangesCompanion(
      basketExchangeId: basketExchangeId ?? this.basketExchangeId,
      organizationId: organizationId ?? this.organizationId,
      deliveryId: deliveryId ?? this.deliveryId,
      contractId: contractId ?? this.contractId,
      offeringMemberId: offeringMemberId ?? this.offeringMemberId,
      motive: motive ?? this.motive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      decidedAt: decidedAt ?? this.decidedAt,
      acceptedRequestId: acceptedRequestId ?? this.acceptedRequestId,
      requestsJson: requestsJson ?? this.requestsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (basketExchangeId.present) {
      map['basket_exchange_id'] = Variable<String>(basketExchangeId.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (deliveryId.present) {
      map['delivery_id'] = Variable<String>(deliveryId.value);
    }
    if (contractId.present) {
      map['contract_id'] = Variable<String>(contractId.value);
    }
    if (offeringMemberId.present) {
      map['offering_member_id'] = Variable<String>(offeringMemberId.value);
    }
    if (motive.present) {
      map['motive'] = Variable<String>(motive.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<String>(decidedAt.value);
    }
    if (acceptedRequestId.present) {
      map['accepted_request_id'] = Variable<String>(acceptedRequestId.value);
    }
    if (requestsJson.present) {
      map['requests_json'] = Variable<String>(requestsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BasketExchangesCompanion(')
          ..write('basketExchangeId: $basketExchangeId, ')
          ..write('organizationId: $organizationId, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('contractId: $contractId, ')
          ..write('offeringMemberId: $offeringMemberId, ')
          ..write('motive: $motive, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('acceptedRequestId: $acceptedRequestId, ')
          ..write('requestsJson: $requestsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, NotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipientScopeMeta = const VerificationMeta(
    'recipientScope',
  );
  @override
  late final GeneratedColumn<String> recipientScope = GeneratedColumn<String>(
    'recipient_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<String> notificationId = GeneratedColumn<String>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recipientScope,
    notificationId,
    dataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipient_scope')) {
      context.handle(
        _recipientScopeMeta,
        recipientScope.isAcceptableOrUnknown(
          data['recipient_scope']!,
          _recipientScopeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientScopeMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipientScope, notificationId};
  @override
  NotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationRow(
      recipientScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_scope'],
      )!,
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class NotificationRow extends DataClass implements Insertable<NotificationRow> {
  final String recipientScope;
  final String notificationId;
  final String dataJson;
  const NotificationRow({
    required this.recipientScope,
    required this.notificationId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipient_scope'] = Variable<String>(recipientScope);
    map['notification_id'] = Variable<String>(notificationId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      recipientScope: Value(recipientScope),
      notificationId: Value(notificationId),
      dataJson: Value(dataJson),
    );
  }

  factory NotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationRow(
      recipientScope: serializer.fromJson<String>(json['recipientScope']),
      notificationId: serializer.fromJson<String>(json['notificationId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipientScope': serializer.toJson<String>(recipientScope),
      'notificationId': serializer.toJson<String>(notificationId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  NotificationRow copyWith({
    String? recipientScope,
    String? notificationId,
    String? dataJson,
  }) => NotificationRow(
    recipientScope: recipientScope ?? this.recipientScope,
    notificationId: notificationId ?? this.notificationId,
    dataJson: dataJson ?? this.dataJson,
  );
  NotificationRow copyWithCompanion(NotificationsCompanion data) {
    return NotificationRow(
      recipientScope: data.recipientScope.present
          ? data.recipientScope.value
          : this.recipientScope,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationRow(')
          ..write('recipientScope: $recipientScope, ')
          ..write('notificationId: $notificationId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipientScope, notificationId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationRow &&
          other.recipientScope == this.recipientScope &&
          other.notificationId == this.notificationId &&
          other.dataJson == this.dataJson);
}

class NotificationsCompanion extends UpdateCompanion<NotificationRow> {
  final Value<String> recipientScope;
  final Value<String> notificationId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.recipientScope = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String recipientScope,
    required String notificationId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : recipientScope = Value(recipientScope),
       notificationId = Value(notificationId),
       dataJson = Value(dataJson);
  static Insertable<NotificationRow> custom({
    Expression<String>? recipientScope,
    Expression<String>? notificationId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipientScope != null) 'recipient_scope': recipientScope,
      if (notificationId != null) 'notification_id': notificationId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith({
    Value<String>? recipientScope,
    Value<String>? notificationId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return NotificationsCompanion(
      recipientScope: recipientScope ?? this.recipientScope,
      notificationId: notificationId ?? this.notificationId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipientScope.present) {
      map['recipient_scope'] = Variable<String>(recipientScope.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<String>(notificationId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('recipientScope: $recipientScope, ')
          ..write('notificationId: $notificationId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceTokensTable extends DeviceTokens
    with TableInfo<$DeviceTokensTable, DeviceTokenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipientScopeMeta = const VerificationMeta(
    'recipientScope',
  );
  @override
  late final GeneratedColumn<String> recipientScope = GeneratedColumn<String>(
    'recipient_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceTokenIdMeta = const VerificationMeta(
    'deviceTokenId',
  );
  @override
  late final GeneratedColumn<String> deviceTokenId = GeneratedColumn<String>(
    'device_token_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recipientScope,
    deviceTokenId,
    dataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceTokenRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipient_scope')) {
      context.handle(
        _recipientScopeMeta,
        recipientScope.isAcceptableOrUnknown(
          data['recipient_scope']!,
          _recipientScopeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientScopeMeta);
    }
    if (data.containsKey('device_token_id')) {
      context.handle(
        _deviceTokenIdMeta,
        deviceTokenId.isAcceptableOrUnknown(
          data['device_token_id']!,
          _deviceTokenIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceTokenIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipientScope, deviceTokenId};
  @override
  DeviceTokenRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceTokenRow(
      recipientScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_scope'],
      )!,
      deviceTokenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_token_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $DeviceTokensTable createAlias(String alias) {
    return $DeviceTokensTable(attachedDatabase, alias);
  }
}

class DeviceTokenRow extends DataClass implements Insertable<DeviceTokenRow> {
  final String recipientScope;
  final String deviceTokenId;
  final String dataJson;
  const DeviceTokenRow({
    required this.recipientScope,
    required this.deviceTokenId,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipient_scope'] = Variable<String>(recipientScope);
    map['device_token_id'] = Variable<String>(deviceTokenId);
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  DeviceTokensCompanion toCompanion(bool nullToAbsent) {
    return DeviceTokensCompanion(
      recipientScope: Value(recipientScope),
      deviceTokenId: Value(deviceTokenId),
      dataJson: Value(dataJson),
    );
  }

  factory DeviceTokenRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceTokenRow(
      recipientScope: serializer.fromJson<String>(json['recipientScope']),
      deviceTokenId: serializer.fromJson<String>(json['deviceTokenId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipientScope': serializer.toJson<String>(recipientScope),
      'deviceTokenId': serializer.toJson<String>(deviceTokenId),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  DeviceTokenRow copyWith({
    String? recipientScope,
    String? deviceTokenId,
    String? dataJson,
  }) => DeviceTokenRow(
    recipientScope: recipientScope ?? this.recipientScope,
    deviceTokenId: deviceTokenId ?? this.deviceTokenId,
    dataJson: dataJson ?? this.dataJson,
  );
  DeviceTokenRow copyWithCompanion(DeviceTokensCompanion data) {
    return DeviceTokenRow(
      recipientScope: data.recipientScope.present
          ? data.recipientScope.value
          : this.recipientScope,
      deviceTokenId: data.deviceTokenId.present
          ? data.deviceTokenId.value
          : this.deviceTokenId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTokenRow(')
          ..write('recipientScope: $recipientScope, ')
          ..write('deviceTokenId: $deviceTokenId, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipientScope, deviceTokenId, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceTokenRow &&
          other.recipientScope == this.recipientScope &&
          other.deviceTokenId == this.deviceTokenId &&
          other.dataJson == this.dataJson);
}

class DeviceTokensCompanion extends UpdateCompanion<DeviceTokenRow> {
  final Value<String> recipientScope;
  final Value<String> deviceTokenId;
  final Value<String> dataJson;
  final Value<int> rowid;
  const DeviceTokensCompanion({
    this.recipientScope = const Value.absent(),
    this.deviceTokenId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceTokensCompanion.insert({
    required String recipientScope,
    required String deviceTokenId,
    required String dataJson,
    this.rowid = const Value.absent(),
  }) : recipientScope = Value(recipientScope),
       deviceTokenId = Value(deviceTokenId),
       dataJson = Value(dataJson);
  static Insertable<DeviceTokenRow> custom({
    Expression<String>? recipientScope,
    Expression<String>? deviceTokenId,
    Expression<String>? dataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipientScope != null) 'recipient_scope': recipientScope,
      if (deviceTokenId != null) 'device_token_id': deviceTokenId,
      if (dataJson != null) 'data_json': dataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceTokensCompanion copyWith({
    Value<String>? recipientScope,
    Value<String>? deviceTokenId,
    Value<String>? dataJson,
    Value<int>? rowid,
  }) {
    return DeviceTokensCompanion(
      recipientScope: recipientScope ?? this.recipientScope,
      deviceTokenId: deviceTokenId ?? this.deviceTokenId,
      dataJson: dataJson ?? this.dataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipientScope.present) {
      map['recipient_scope'] = Variable<String>(recipientScope.value);
    }
    if (deviceTokenId.present) {
      map['device_token_id'] = Variable<String>(deviceTokenId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTokensCompanion(')
          ..write('recipientScope: $recipientScope, ')
          ..write('deviceTokenId: $deviceTokenId, ')
          ..write('dataJson: $dataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceEmailRequestsTable extends AttendanceEmailRequests
    with TableInfo<$AttendanceEmailRequestsTable, AttendanceEmailRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceEmailRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attendanceEmailRequestIdMeta =
      const VerificationMeta('attendanceEmailRequestId');
  @override
  late final GeneratedColumn<String> attendanceEmailRequestId =
      GeneratedColumn<String>(
        'attendance_email_request_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryIdMeta = const VerificationMeta(
    'deliveryId',
  );
  @override
  late final GeneratedColumn<String> deliveryId = GeneratedColumn<String>(
    'delivery_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientEmailMeta = const VerificationMeta(
    'recipientEmail',
  );
  @override
  late final GeneratedColumn<String> recipientEmail = GeneratedColumn<String>(
    'recipient_email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<String> requestedAt = GeneratedColumn<String>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<String> sentAt = GeneratedColumn<String>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    attendanceEmailRequestId,
    organizationId,
    deliveryId,
    recipientEmail,
    requestedAt,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_email_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceEmailRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attendance_email_request_id')) {
      context.handle(
        _attendanceEmailRequestIdMeta,
        attendanceEmailRequestId.isAcceptableOrUnknown(
          data['attendance_email_request_id']!,
          _attendanceEmailRequestIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attendanceEmailRequestIdMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('delivery_id')) {
      context.handle(
        _deliveryIdMeta,
        deliveryId.isAcceptableOrUnknown(data['delivery_id']!, _deliveryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deliveryIdMeta);
    }
    if (data.containsKey('recipient_email')) {
      context.handle(
        _recipientEmailMeta,
        recipientEmail.isAcceptableOrUnknown(
          data['recipient_email']!,
          _recipientEmailMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientEmailMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attendanceEmailRequestId};
  @override
  AttendanceEmailRequestRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceEmailRequestRow(
      attendanceEmailRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attendance_email_request_id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      deliveryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_id'],
      )!,
      recipientEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_email'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requested_at'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sent_at'],
      ),
    );
  }

  @override
  $AttendanceEmailRequestsTable createAlias(String alias) {
    return $AttendanceEmailRequestsTable(attachedDatabase, alias);
  }
}

class AttendanceEmailRequestRow extends DataClass
    implements Insertable<AttendanceEmailRequestRow> {
  final String attendanceEmailRequestId;
  final String organizationId;
  final String deliveryId;
  final String recipientEmail;
  final String requestedAt;
  final String? sentAt;
  const AttendanceEmailRequestRow({
    required this.attendanceEmailRequestId,
    required this.organizationId,
    required this.deliveryId,
    required this.recipientEmail,
    required this.requestedAt,
    this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attendance_email_request_id'] = Variable<String>(
      attendanceEmailRequestId,
    );
    map['organization_id'] = Variable<String>(organizationId);
    map['delivery_id'] = Variable<String>(deliveryId);
    map['recipient_email'] = Variable<String>(recipientEmail);
    map['requested_at'] = Variable<String>(requestedAt);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<String>(sentAt);
    }
    return map;
  }

  AttendanceEmailRequestsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceEmailRequestsCompanion(
      attendanceEmailRequestId: Value(attendanceEmailRequestId),
      organizationId: Value(organizationId),
      deliveryId: Value(deliveryId),
      recipientEmail: Value(recipientEmail),
      requestedAt: Value(requestedAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
    );
  }

  factory AttendanceEmailRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceEmailRequestRow(
      attendanceEmailRequestId: serializer.fromJson<String>(
        json['attendanceEmailRequestId'],
      ),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      deliveryId: serializer.fromJson<String>(json['deliveryId']),
      recipientEmail: serializer.fromJson<String>(json['recipientEmail']),
      requestedAt: serializer.fromJson<String>(json['requestedAt']),
      sentAt: serializer.fromJson<String?>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attendanceEmailRequestId': serializer.toJson<String>(
        attendanceEmailRequestId,
      ),
      'organizationId': serializer.toJson<String>(organizationId),
      'deliveryId': serializer.toJson<String>(deliveryId),
      'recipientEmail': serializer.toJson<String>(recipientEmail),
      'requestedAt': serializer.toJson<String>(requestedAt),
      'sentAt': serializer.toJson<String?>(sentAt),
    };
  }

  AttendanceEmailRequestRow copyWith({
    String? attendanceEmailRequestId,
    String? organizationId,
    String? deliveryId,
    String? recipientEmail,
    String? requestedAt,
    Value<String?> sentAt = const Value.absent(),
  }) => AttendanceEmailRequestRow(
    attendanceEmailRequestId:
        attendanceEmailRequestId ?? this.attendanceEmailRequestId,
    organizationId: organizationId ?? this.organizationId,
    deliveryId: deliveryId ?? this.deliveryId,
    recipientEmail: recipientEmail ?? this.recipientEmail,
    requestedAt: requestedAt ?? this.requestedAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
  );
  AttendanceEmailRequestRow copyWithCompanion(
    AttendanceEmailRequestsCompanion data,
  ) {
    return AttendanceEmailRequestRow(
      attendanceEmailRequestId: data.attendanceEmailRequestId.present
          ? data.attendanceEmailRequestId.value
          : this.attendanceEmailRequestId,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      deliveryId: data.deliveryId.present
          ? data.deliveryId.value
          : this.deliveryId,
      recipientEmail: data.recipientEmail.present
          ? data.recipientEmail.value
          : this.recipientEmail,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceEmailRequestRow(')
          ..write('attendanceEmailRequestId: $attendanceEmailRequestId, ')
          ..write('organizationId: $organizationId, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('recipientEmail: $recipientEmail, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attendanceEmailRequestId,
    organizationId,
    deliveryId,
    recipientEmail,
    requestedAt,
    sentAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceEmailRequestRow &&
          other.attendanceEmailRequestId == this.attendanceEmailRequestId &&
          other.organizationId == this.organizationId &&
          other.deliveryId == this.deliveryId &&
          other.recipientEmail == this.recipientEmail &&
          other.requestedAt == this.requestedAt &&
          other.sentAt == this.sentAt);
}

class AttendanceEmailRequestsCompanion
    extends UpdateCompanion<AttendanceEmailRequestRow> {
  final Value<String> attendanceEmailRequestId;
  final Value<String> organizationId;
  final Value<String> deliveryId;
  final Value<String> recipientEmail;
  final Value<String> requestedAt;
  final Value<String?> sentAt;
  final Value<int> rowid;
  const AttendanceEmailRequestsCompanion({
    this.attendanceEmailRequestId = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.deliveryId = const Value.absent(),
    this.recipientEmail = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceEmailRequestsCompanion.insert({
    required String attendanceEmailRequestId,
    required String organizationId,
    required String deliveryId,
    required String recipientEmail,
    required String requestedAt,
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attendanceEmailRequestId = Value(attendanceEmailRequestId),
       organizationId = Value(organizationId),
       deliveryId = Value(deliveryId),
       recipientEmail = Value(recipientEmail),
       requestedAt = Value(requestedAt);
  static Insertable<AttendanceEmailRequestRow> custom({
    Expression<String>? attendanceEmailRequestId,
    Expression<String>? organizationId,
    Expression<String>? deliveryId,
    Expression<String>? recipientEmail,
    Expression<String>? requestedAt,
    Expression<String>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attendanceEmailRequestId != null)
        'attendance_email_request_id': attendanceEmailRequestId,
      if (organizationId != null) 'organization_id': organizationId,
      if (deliveryId != null) 'delivery_id': deliveryId,
      if (recipientEmail != null) 'recipient_email': recipientEmail,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceEmailRequestsCompanion copyWith({
    Value<String>? attendanceEmailRequestId,
    Value<String>? organizationId,
    Value<String>? deliveryId,
    Value<String>? recipientEmail,
    Value<String>? requestedAt,
    Value<String?>? sentAt,
    Value<int>? rowid,
  }) {
    return AttendanceEmailRequestsCompanion(
      attendanceEmailRequestId:
          attendanceEmailRequestId ?? this.attendanceEmailRequestId,
      organizationId: organizationId ?? this.organizationId,
      deliveryId: deliveryId ?? this.deliveryId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      requestedAt: requestedAt ?? this.requestedAt,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attendanceEmailRequestId.present) {
      map['attendance_email_request_id'] = Variable<String>(
        attendanceEmailRequestId.value,
      );
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (deliveryId.present) {
      map['delivery_id'] = Variable<String>(deliveryId.value);
    }
    if (recipientEmail.present) {
      map['recipient_email'] = Variable<String>(recipientEmail.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<String>(requestedAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<String>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceEmailRequestsCompanion(')
          ..write('attendanceEmailRequestId: $attendanceEmailRequestId, ')
          ..write('organizationId: $organizationId, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('recipientEmail: $recipientEmail, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ErrorReportsTable extends ErrorReports
    with TableInfo<$ErrorReportsTable, ErrorReportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ErrorReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _errorReportIdMeta = const VerificationMeta(
    'errorReportId',
  );
  @override
  late final GeneratedColumn<String> errorReportId = GeneratedColumn<String>(
    'error_report_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportedAtMeta = const VerificationMeta(
    'reportedAt',
  );
  @override
  late final GeneratedColumn<String> reportedAt = GeneratedColumn<String>(
    'reported_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    errorReportId,
    errorMessage,
    reportedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'error_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<ErrorReportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('error_report_id')) {
      context.handle(
        _errorReportIdMeta,
        errorReportId.isAcceptableOrUnknown(
          data['error_report_id']!,
          _errorReportIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_errorReportIdMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_errorMessageMeta);
    }
    if (data.containsKey('reported_at')) {
      context.handle(
        _reportedAtMeta,
        reportedAt.isAcceptableOrUnknown(data['reported_at']!, _reportedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reportedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {errorReportId};
  @override
  ErrorReportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ErrorReportRow(
      errorReportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_report_id'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      )!,
      reportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reported_at'],
      )!,
    );
  }

  @override
  $ErrorReportsTable createAlias(String alias) {
    return $ErrorReportsTable(attachedDatabase, alias);
  }
}

class ErrorReportRow extends DataClass implements Insertable<ErrorReportRow> {
  final String errorReportId;
  final String errorMessage;
  final String reportedAt;
  const ErrorReportRow({
    required this.errorReportId,
    required this.errorMessage,
    required this.reportedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['error_report_id'] = Variable<String>(errorReportId);
    map['error_message'] = Variable<String>(errorMessage);
    map['reported_at'] = Variable<String>(reportedAt);
    return map;
  }

  ErrorReportsCompanion toCompanion(bool nullToAbsent) {
    return ErrorReportsCompanion(
      errorReportId: Value(errorReportId),
      errorMessage: Value(errorMessage),
      reportedAt: Value(reportedAt),
    );
  }

  factory ErrorReportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ErrorReportRow(
      errorReportId: serializer.fromJson<String>(json['errorReportId']),
      errorMessage: serializer.fromJson<String>(json['errorMessage']),
      reportedAt: serializer.fromJson<String>(json['reportedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'errorReportId': serializer.toJson<String>(errorReportId),
      'errorMessage': serializer.toJson<String>(errorMessage),
      'reportedAt': serializer.toJson<String>(reportedAt),
    };
  }

  ErrorReportRow copyWith({
    String? errorReportId,
    String? errorMessage,
    String? reportedAt,
  }) => ErrorReportRow(
    errorReportId: errorReportId ?? this.errorReportId,
    errorMessage: errorMessage ?? this.errorMessage,
    reportedAt: reportedAt ?? this.reportedAt,
  );
  ErrorReportRow copyWithCompanion(ErrorReportsCompanion data) {
    return ErrorReportRow(
      errorReportId: data.errorReportId.present
          ? data.errorReportId.value
          : this.errorReportId,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      reportedAt: data.reportedAt.present
          ? data.reportedAt.value
          : this.reportedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ErrorReportRow(')
          ..write('errorReportId: $errorReportId, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('reportedAt: $reportedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(errorReportId, errorMessage, reportedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorReportRow &&
          other.errorReportId == this.errorReportId &&
          other.errorMessage == this.errorMessage &&
          other.reportedAt == this.reportedAt);
}

class ErrorReportsCompanion extends UpdateCompanion<ErrorReportRow> {
  final Value<String> errorReportId;
  final Value<String> errorMessage;
  final Value<String> reportedAt;
  final Value<int> rowid;
  const ErrorReportsCompanion({
    this.errorReportId = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.reportedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ErrorReportsCompanion.insert({
    required String errorReportId,
    required String errorMessage,
    required String reportedAt,
    this.rowid = const Value.absent(),
  }) : errorReportId = Value(errorReportId),
       errorMessage = Value(errorMessage),
       reportedAt = Value(reportedAt);
  static Insertable<ErrorReportRow> custom({
    Expression<String>? errorReportId,
    Expression<String>? errorMessage,
    Expression<String>? reportedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (errorReportId != null) 'error_report_id': errorReportId,
      if (errorMessage != null) 'error_message': errorMessage,
      if (reportedAt != null) 'reported_at': reportedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ErrorReportsCompanion copyWith({
    Value<String>? errorReportId,
    Value<String>? errorMessage,
    Value<String>? reportedAt,
    Value<int>? rowid,
  }) {
    return ErrorReportsCompanion(
      errorReportId: errorReportId ?? this.errorReportId,
      errorMessage: errorMessage ?? this.errorMessage,
      reportedAt: reportedAt ?? this.reportedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (errorReportId.present) {
      map['error_report_id'] = Variable<String>(errorReportId.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (reportedAt.present) {
      map['reported_at'] = Variable<String>(reportedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ErrorReportsCompanion(')
          ..write('errorReportId: $errorReportId, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductTypesTable productTypes = $ProductTypesTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $PendingMutationsTable pendingMutations = $PendingMutationsTable(
    this,
  );
  late final $OrganizationsTable organizations = $OrganizationsTable(this);
  late final $ProducerAccountsTable producerAccounts = $ProducerAccountsTable(
    this,
  );
  late final $MembersTable members = $MembersTable(this);
  late final $MemberInvitationsTable memberInvitations =
      $MemberInvitationsTable(this);
  late final $MemberJoinRequestsTable memberJoinRequests =
      $MemberJoinRequestsTable(this);
  late final $ContractsTable contracts = $ContractsTable(this);
  late final $DeliveryTemplatesTable deliveryTemplates =
      $DeliveryTemplatesTable(this);
  late final $OrganizationRequestsTable organizationRequests =
      $OrganizationRequestsTable(this);
  late final $ProducerRequestsTable producerRequests = $ProducerRequestsTable(
    this,
  );
  late final $OwnersTable owners = $OwnersTable(this);
  late final $OwnerInvitationsTable ownerInvitations = $OwnerInvitationsTable(
    this,
  );
  late final $BasketExchangesTable basketExchanges = $BasketExchangesTable(
    this,
  );
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final $DeviceTokensTable deviceTokens = $DeviceTokensTable(this);
  late final $AttendanceEmailRequestsTable attendanceEmailRequests =
      $AttendanceEmailRequestsTable(this);
  late final $ErrorReportsTable errorReports = $ErrorReportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productTypes,
    syncCursors,
    pendingMutations,
    organizations,
    producerAccounts,
    members,
    memberInvitations,
    memberJoinRequests,
    contracts,
    deliveryTemplates,
    organizationRequests,
    producerRequests,
    owners,
    ownerInvitations,
    basketExchanges,
    notifications,
    deviceTokens,
    attendanceEmailRequests,
    errorReports,
  ];
}

typedef $$ProductTypesTableCreateCompanionBuilder =
    ProductTypesCompanion Function({
      required String producerAccountId,
      required String productTypeId,
      required String name,
      Value<String?> description,
      required List<BasketSize> supportedBasketSizes,
      Value<int> rowid,
    });
typedef $$ProductTypesTableUpdateCompanionBuilder =
    ProductTypesCompanion Function({
      Value<String> producerAccountId,
      Value<String> productTypeId,
      Value<String> name,
      Value<String?> description,
      Value<List<BasketSize>> supportedBasketSizes,
      Value<int> rowid,
    });

class $$ProductTypesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductTypesTable> {
  $$ProductTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get producerAccountId => $composableBuilder(
    column: $table.producerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productTypeId => $composableBuilder(
    column: $table.productTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<BasketSize>, List<BasketSize>, String>
  get supportedBasketSizes => $composableBuilder(
    column: $table.supportedBasketSizes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$ProductTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductTypesTable> {
  $$ProductTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get producerAccountId => $composableBuilder(
    column: $table.producerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productTypeId => $composableBuilder(
    column: $table.productTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportedBasketSizes => $composableBuilder(
    column: $table.supportedBasketSizes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductTypesTable> {
  $$ProductTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get producerAccountId => $composableBuilder(
    column: $table.producerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productTypeId => $composableBuilder(
    column: $table.productTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<BasketSize>, String>
  get supportedBasketSizes => $composableBuilder(
    column: $table.supportedBasketSizes,
    builder: (column) => column,
  );
}

class $$ProductTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductTypesTable,
          ProductTypeRow,
          $$ProductTypesTableFilterComposer,
          $$ProductTypesTableOrderingComposer,
          $$ProductTypesTableAnnotationComposer,
          $$ProductTypesTableCreateCompanionBuilder,
          $$ProductTypesTableUpdateCompanionBuilder,
          (
            ProductTypeRow,
            BaseReferences<_$AppDatabase, $ProductTypesTable, ProductTypeRow>,
          ),
          ProductTypeRow,
          PrefetchHooks Function()
        > {
  $$ProductTypesTableTableManager(_$AppDatabase db, $ProductTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> producerAccountId = const Value.absent(),
                Value<String> productTypeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<List<BasketSize>> supportedBasketSizes =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductTypesCompanion(
                producerAccountId: producerAccountId,
                productTypeId: productTypeId,
                name: name,
                description: description,
                supportedBasketSizes: supportedBasketSizes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String producerAccountId,
                required String productTypeId,
                required String name,
                Value<String?> description = const Value.absent(),
                required List<BasketSize> supportedBasketSizes,
                Value<int> rowid = const Value.absent(),
              }) => ProductTypesCompanion.insert(
                producerAccountId: producerAccountId,
                productTypeId: productTypeId,
                name: name,
                description: description,
                supportedBasketSizes: supportedBasketSizes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductTypesTable,
      ProductTypeRow,
      $$ProductTypesTableFilterComposer,
      $$ProductTypesTableOrderingComposer,
      $$ProductTypesTableAnnotationComposer,
      $$ProductTypesTableCreateCompanionBuilder,
      $$ProductTypesTableUpdateCompanionBuilder,
      (
        ProductTypeRow,
        BaseReferences<_$AppDatabase, $ProductTypesTable, ProductTypeRow>,
      ),
      ProductTypeRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String scopeKey,
      Value<String?> cursor,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> scopeKey,
      Value<String?> cursor,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scopeKey = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                scopeKey: scopeKey,
                cursor: cursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scopeKey,
                Value<String?> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                scopeKey: scopeKey,
                cursor: cursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$PendingMutationsTableCreateCompanionBuilder =
    PendingMutationsCompanion Function({
      required String clientOpId,
      Value<String?> scopeKey,
      required String payloadJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PendingMutationsTableUpdateCompanionBuilder =
    PendingMutationsCompanion Function({
      Value<String> clientOpId,
      Value<String?> scopeKey,
      Value<String> payloadJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$PendingMutationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingMutationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingMutationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingMutationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingMutationsTable,
          PendingMutation,
          $$PendingMutationsTableFilterComposer,
          $$PendingMutationsTableOrderingComposer,
          $$PendingMutationsTableAnnotationComposer,
          $$PendingMutationsTableCreateCompanionBuilder,
          $$PendingMutationsTableUpdateCompanionBuilder,
          (
            PendingMutation,
            BaseReferences<
              _$AppDatabase,
              $PendingMutationsTable,
              PendingMutation
            >,
          ),
          PendingMutation,
          PrefetchHooks Function()
        > {
  $$PendingMutationsTableTableManager(
    _$AppDatabase db,
    $PendingMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientOpId = const Value.absent(),
                Value<String?> scopeKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMutationsCompanion(
                clientOpId: clientOpId,
                scopeKey: scopeKey,
                payloadJson: payloadJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientOpId,
                Value<String?> scopeKey = const Value.absent(),
                required String payloadJson,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingMutationsCompanion.insert(
                clientOpId: clientOpId,
                scopeKey: scopeKey,
                payloadJson: payloadJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingMutationsTable,
      PendingMutation,
      $$PendingMutationsTableFilterComposer,
      $$PendingMutationsTableOrderingComposer,
      $$PendingMutationsTableAnnotationComposer,
      $$PendingMutationsTableCreateCompanionBuilder,
      $$PendingMutationsTableUpdateCompanionBuilder,
      (
        PendingMutation,
        BaseReferences<_$AppDatabase, $PendingMutationsTable, PendingMutation>,
      ),
      PendingMutation,
      PrefetchHooks Function()
    >;
typedef $$OrganizationsTableCreateCompanionBuilder =
    OrganizationsCompanion Function({
      required String organizationId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$OrganizationsTableUpdateCompanionBuilder =
    OrganizationsCompanion Function({
      Value<String> organizationId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$OrganizationsTableFilterComposer
    extends Composer<_$AppDatabase, $OrganizationsTable> {
  $$OrganizationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrganizationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrganizationsTable> {
  $$OrganizationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrganizationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrganizationsTable> {
  $$OrganizationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$OrganizationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrganizationsTable,
          OrganizationRow,
          $$OrganizationsTableFilterComposer,
          $$OrganizationsTableOrderingComposer,
          $$OrganizationsTableAnnotationComposer,
          $$OrganizationsTableCreateCompanionBuilder,
          $$OrganizationsTableUpdateCompanionBuilder,
          (
            OrganizationRow,
            BaseReferences<_$AppDatabase, $OrganizationsTable, OrganizationRow>,
          ),
          OrganizationRow,
          PrefetchHooks Function()
        > {
  $$OrganizationsTableTableManager(_$AppDatabase db, $OrganizationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganizationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganizationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrganizationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrganizationsCompanion(
                organizationId: organizationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => OrganizationsCompanion.insert(
                organizationId: organizationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrganizationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrganizationsTable,
      OrganizationRow,
      $$OrganizationsTableFilterComposer,
      $$OrganizationsTableOrderingComposer,
      $$OrganizationsTableAnnotationComposer,
      $$OrganizationsTableCreateCompanionBuilder,
      $$OrganizationsTableUpdateCompanionBuilder,
      (
        OrganizationRow,
        BaseReferences<_$AppDatabase, $OrganizationsTable, OrganizationRow>,
      ),
      OrganizationRow,
      PrefetchHooks Function()
    >;
typedef $$ProducerAccountsTableCreateCompanionBuilder =
    ProducerAccountsCompanion Function({
      required String organizationId,
      required String producerAccountId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$ProducerAccountsTableUpdateCompanionBuilder =
    ProducerAccountsCompanion Function({
      Value<String> organizationId,
      Value<String> producerAccountId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$ProducerAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $ProducerAccountsTable> {
  $$ProducerAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get producerAccountId => $composableBuilder(
    column: $table.producerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProducerAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProducerAccountsTable> {
  $$ProducerAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get producerAccountId => $composableBuilder(
    column: $table.producerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProducerAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProducerAccountsTable> {
  $$ProducerAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get producerAccountId => $composableBuilder(
    column: $table.producerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$ProducerAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProducerAccountsTable,
          ProducerAccountRow,
          $$ProducerAccountsTableFilterComposer,
          $$ProducerAccountsTableOrderingComposer,
          $$ProducerAccountsTableAnnotationComposer,
          $$ProducerAccountsTableCreateCompanionBuilder,
          $$ProducerAccountsTableUpdateCompanionBuilder,
          (
            ProducerAccountRow,
            BaseReferences<
              _$AppDatabase,
              $ProducerAccountsTable,
              ProducerAccountRow
            >,
          ),
          ProducerAccountRow,
          PrefetchHooks Function()
        > {
  $$ProducerAccountsTableTableManager(
    _$AppDatabase db,
    $ProducerAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProducerAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProducerAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProducerAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> producerAccountId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProducerAccountsCompanion(
                organizationId: organizationId,
                producerAccountId: producerAccountId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String producerAccountId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => ProducerAccountsCompanion.insert(
                organizationId: organizationId,
                producerAccountId: producerAccountId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProducerAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProducerAccountsTable,
      ProducerAccountRow,
      $$ProducerAccountsTableFilterComposer,
      $$ProducerAccountsTableOrderingComposer,
      $$ProducerAccountsTableAnnotationComposer,
      $$ProducerAccountsTableCreateCompanionBuilder,
      $$ProducerAccountsTableUpdateCompanionBuilder,
      (
        ProducerAccountRow,
        BaseReferences<
          _$AppDatabase,
          $ProducerAccountsTable,
          ProducerAccountRow
        >,
      ),
      ProducerAccountRow,
      PrefetchHooks Function()
    >;
typedef $$MembersTableCreateCompanionBuilder =
    MembersCompanion Function({
      required String organizationId,
      required String memberId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$MembersTableUpdateCompanionBuilder =
    MembersCompanion Function({
      Value<String> organizationId,
      Value<String> memberId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          MemberRow,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
          MemberRow,
          PrefetchHooks Function()
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                organizationId: organizationId,
                memberId: memberId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String memberId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                organizationId: organizationId,
                memberId: memberId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      MemberRow,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
      MemberRow,
      PrefetchHooks Function()
    >;
typedef $$MemberInvitationsTableCreateCompanionBuilder =
    MemberInvitationsCompanion Function({
      required String organizationId,
      required String invitationId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$MemberInvitationsTableUpdateCompanionBuilder =
    MemberInvitationsCompanion Function({
      Value<String> organizationId,
      Value<String> invitationId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$MemberInvitationsTableFilterComposer
    extends Composer<_$AppDatabase, $MemberInvitationsTable> {
  $$MemberInvitationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invitationId => $composableBuilder(
    column: $table.invitationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemberInvitationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemberInvitationsTable> {
  $$MemberInvitationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invitationId => $composableBuilder(
    column: $table.invitationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemberInvitationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemberInvitationsTable> {
  $$MemberInvitationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invitationId => $composableBuilder(
    column: $table.invitationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$MemberInvitationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemberInvitationsTable,
          MemberInvitationRow,
          $$MemberInvitationsTableFilterComposer,
          $$MemberInvitationsTableOrderingComposer,
          $$MemberInvitationsTableAnnotationComposer,
          $$MemberInvitationsTableCreateCompanionBuilder,
          $$MemberInvitationsTableUpdateCompanionBuilder,
          (
            MemberInvitationRow,
            BaseReferences<
              _$AppDatabase,
              $MemberInvitationsTable,
              MemberInvitationRow
            >,
          ),
          MemberInvitationRow,
          PrefetchHooks Function()
        > {
  $$MemberInvitationsTableTableManager(
    _$AppDatabase db,
    $MemberInvitationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberInvitationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberInvitationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberInvitationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> invitationId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberInvitationsCompanion(
                organizationId: organizationId,
                invitationId: invitationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String invitationId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => MemberInvitationsCompanion.insert(
                organizationId: organizationId,
                invitationId: invitationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemberInvitationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemberInvitationsTable,
      MemberInvitationRow,
      $$MemberInvitationsTableFilterComposer,
      $$MemberInvitationsTableOrderingComposer,
      $$MemberInvitationsTableAnnotationComposer,
      $$MemberInvitationsTableCreateCompanionBuilder,
      $$MemberInvitationsTableUpdateCompanionBuilder,
      (
        MemberInvitationRow,
        BaseReferences<
          _$AppDatabase,
          $MemberInvitationsTable,
          MemberInvitationRow
        >,
      ),
      MemberInvitationRow,
      PrefetchHooks Function()
    >;
typedef $$MemberJoinRequestsTableCreateCompanionBuilder =
    MemberJoinRequestsCompanion Function({
      required String organizationId,
      required String requestId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$MemberJoinRequestsTableUpdateCompanionBuilder =
    MemberJoinRequestsCompanion Function({
      Value<String> organizationId,
      Value<String> requestId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$MemberJoinRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $MemberJoinRequestsTable> {
  $$MemberJoinRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemberJoinRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemberJoinRequestsTable> {
  $$MemberJoinRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemberJoinRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemberJoinRequestsTable> {
  $$MemberJoinRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$MemberJoinRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemberJoinRequestsTable,
          MemberJoinRequestRow,
          $$MemberJoinRequestsTableFilterComposer,
          $$MemberJoinRequestsTableOrderingComposer,
          $$MemberJoinRequestsTableAnnotationComposer,
          $$MemberJoinRequestsTableCreateCompanionBuilder,
          $$MemberJoinRequestsTableUpdateCompanionBuilder,
          (
            MemberJoinRequestRow,
            BaseReferences<
              _$AppDatabase,
              $MemberJoinRequestsTable,
              MemberJoinRequestRow
            >,
          ),
          MemberJoinRequestRow,
          PrefetchHooks Function()
        > {
  $$MemberJoinRequestsTableTableManager(
    _$AppDatabase db,
    $MemberJoinRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberJoinRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberJoinRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberJoinRequestsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> requestId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberJoinRequestsCompanion(
                organizationId: organizationId,
                requestId: requestId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String requestId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => MemberJoinRequestsCompanion.insert(
                organizationId: organizationId,
                requestId: requestId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemberJoinRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemberJoinRequestsTable,
      MemberJoinRequestRow,
      $$MemberJoinRequestsTableFilterComposer,
      $$MemberJoinRequestsTableOrderingComposer,
      $$MemberJoinRequestsTableAnnotationComposer,
      $$MemberJoinRequestsTableCreateCompanionBuilder,
      $$MemberJoinRequestsTableUpdateCompanionBuilder,
      (
        MemberJoinRequestRow,
        BaseReferences<
          _$AppDatabase,
          $MemberJoinRequestsTable,
          MemberJoinRequestRow
        >,
      ),
      MemberJoinRequestRow,
      PrefetchHooks Function()
    >;
typedef $$ContractsTableCreateCompanionBuilder =
    ContractsCompanion Function({
      required String organizationId,
      required String contractId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$ContractsTableUpdateCompanionBuilder =
    ContractsCompanion Function({
      Value<String> organizationId,
      Value<String> contractId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$ContractsTableFilterComposer
    extends Composer<_$AppDatabase, $ContractsTable> {
  $$ContractsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContractsTable> {
  $$ContractsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContractsTable> {
  $$ContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$ContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContractsTable,
          ContractRow,
          $$ContractsTableFilterComposer,
          $$ContractsTableOrderingComposer,
          $$ContractsTableAnnotationComposer,
          $$ContractsTableCreateCompanionBuilder,
          $$ContractsTableUpdateCompanionBuilder,
          (
            ContractRow,
            BaseReferences<_$AppDatabase, $ContractsTable, ContractRow>,
          ),
          ContractRow,
          PrefetchHooks Function()
        > {
  $$ContractsTableTableManager(_$AppDatabase db, $ContractsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContractsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> contractId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContractsCompanion(
                organizationId: organizationId,
                contractId: contractId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String contractId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => ContractsCompanion.insert(
                organizationId: organizationId,
                contractId: contractId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContractsTable,
      ContractRow,
      $$ContractsTableFilterComposer,
      $$ContractsTableOrderingComposer,
      $$ContractsTableAnnotationComposer,
      $$ContractsTableCreateCompanionBuilder,
      $$ContractsTableUpdateCompanionBuilder,
      (
        ContractRow,
        BaseReferences<_$AppDatabase, $ContractsTable, ContractRow>,
      ),
      ContractRow,
      PrefetchHooks Function()
    >;
typedef $$DeliveryTemplatesTableCreateCompanionBuilder =
    DeliveryTemplatesCompanion Function({
      required String organizationId,
      required String deliveryTemplateId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$DeliveryTemplatesTableUpdateCompanionBuilder =
    DeliveryTemplatesCompanion Function({
      Value<String> organizationId,
      Value<String> deliveryTemplateId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$DeliveryTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $DeliveryTemplatesTable> {
  $$DeliveryTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryTemplateId => $composableBuilder(
    column: $table.deliveryTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeliveryTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeliveryTemplatesTable> {
  $$DeliveryTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryTemplateId => $composableBuilder(
    column: $table.deliveryTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeliveryTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeliveryTemplatesTable> {
  $$DeliveryTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryTemplateId => $composableBuilder(
    column: $table.deliveryTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$DeliveryTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeliveryTemplatesTable,
          DeliveryTemplateRow,
          $$DeliveryTemplatesTableFilterComposer,
          $$DeliveryTemplatesTableOrderingComposer,
          $$DeliveryTemplatesTableAnnotationComposer,
          $$DeliveryTemplatesTableCreateCompanionBuilder,
          $$DeliveryTemplatesTableUpdateCompanionBuilder,
          (
            DeliveryTemplateRow,
            BaseReferences<
              _$AppDatabase,
              $DeliveryTemplatesTable,
              DeliveryTemplateRow
            >,
          ),
          DeliveryTemplateRow,
          PrefetchHooks Function()
        > {
  $$DeliveryTemplatesTableTableManager(
    _$AppDatabase db,
    $DeliveryTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> deliveryTemplateId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryTemplatesCompanion(
                organizationId: organizationId,
                deliveryTemplateId: deliveryTemplateId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String deliveryTemplateId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => DeliveryTemplatesCompanion.insert(
                organizationId: organizationId,
                deliveryTemplateId: deliveryTemplateId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeliveryTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeliveryTemplatesTable,
      DeliveryTemplateRow,
      $$DeliveryTemplatesTableFilterComposer,
      $$DeliveryTemplatesTableOrderingComposer,
      $$DeliveryTemplatesTableAnnotationComposer,
      $$DeliveryTemplatesTableCreateCompanionBuilder,
      $$DeliveryTemplatesTableUpdateCompanionBuilder,
      (
        DeliveryTemplateRow,
        BaseReferences<
          _$AppDatabase,
          $DeliveryTemplatesTable,
          DeliveryTemplateRow
        >,
      ),
      DeliveryTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$OrganizationRequestsTableCreateCompanionBuilder =
    OrganizationRequestsCompanion Function({
      required String requestId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$OrganizationRequestsTableUpdateCompanionBuilder =
    OrganizationRequestsCompanion Function({
      Value<String> requestId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$OrganizationRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $OrganizationRequestsTable> {
  $$OrganizationRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrganizationRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrganizationRequestsTable> {
  $$OrganizationRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrganizationRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrganizationRequestsTable> {
  $$OrganizationRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$OrganizationRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrganizationRequestsTable,
          OrganizationRequestRow,
          $$OrganizationRequestsTableFilterComposer,
          $$OrganizationRequestsTableOrderingComposer,
          $$OrganizationRequestsTableAnnotationComposer,
          $$OrganizationRequestsTableCreateCompanionBuilder,
          $$OrganizationRequestsTableUpdateCompanionBuilder,
          (
            OrganizationRequestRow,
            BaseReferences<
              _$AppDatabase,
              $OrganizationRequestsTable,
              OrganizationRequestRow
            >,
          ),
          OrganizationRequestRow,
          PrefetchHooks Function()
        > {
  $$OrganizationRequestsTableTableManager(
    _$AppDatabase db,
    $OrganizationRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganizationRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganizationRequestsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OrganizationRequestsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> requestId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrganizationRequestsCompanion(
                requestId: requestId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String requestId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => OrganizationRequestsCompanion.insert(
                requestId: requestId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrganizationRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrganizationRequestsTable,
      OrganizationRequestRow,
      $$OrganizationRequestsTableFilterComposer,
      $$OrganizationRequestsTableOrderingComposer,
      $$OrganizationRequestsTableAnnotationComposer,
      $$OrganizationRequestsTableCreateCompanionBuilder,
      $$OrganizationRequestsTableUpdateCompanionBuilder,
      (
        OrganizationRequestRow,
        BaseReferences<
          _$AppDatabase,
          $OrganizationRequestsTable,
          OrganizationRequestRow
        >,
      ),
      OrganizationRequestRow,
      PrefetchHooks Function()
    >;
typedef $$ProducerRequestsTableCreateCompanionBuilder =
    ProducerRequestsCompanion Function({
      required String requestId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$ProducerRequestsTableUpdateCompanionBuilder =
    ProducerRequestsCompanion Function({
      Value<String> requestId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$ProducerRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $ProducerRequestsTable> {
  $$ProducerRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProducerRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProducerRequestsTable> {
  $$ProducerRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProducerRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProducerRequestsTable> {
  $$ProducerRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$ProducerRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProducerRequestsTable,
          ProducerRequestRow,
          $$ProducerRequestsTableFilterComposer,
          $$ProducerRequestsTableOrderingComposer,
          $$ProducerRequestsTableAnnotationComposer,
          $$ProducerRequestsTableCreateCompanionBuilder,
          $$ProducerRequestsTableUpdateCompanionBuilder,
          (
            ProducerRequestRow,
            BaseReferences<
              _$AppDatabase,
              $ProducerRequestsTable,
              ProducerRequestRow
            >,
          ),
          ProducerRequestRow,
          PrefetchHooks Function()
        > {
  $$ProducerRequestsTableTableManager(
    _$AppDatabase db,
    $ProducerRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProducerRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProducerRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProducerRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> requestId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProducerRequestsCompanion(
                requestId: requestId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String requestId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => ProducerRequestsCompanion.insert(
                requestId: requestId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProducerRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProducerRequestsTable,
      ProducerRequestRow,
      $$ProducerRequestsTableFilterComposer,
      $$ProducerRequestsTableOrderingComposer,
      $$ProducerRequestsTableAnnotationComposer,
      $$ProducerRequestsTableCreateCompanionBuilder,
      $$ProducerRequestsTableUpdateCompanionBuilder,
      (
        ProducerRequestRow,
        BaseReferences<
          _$AppDatabase,
          $ProducerRequestsTable,
          ProducerRequestRow
        >,
      ),
      ProducerRequestRow,
      PrefetchHooks Function()
    >;
typedef $$OwnersTableCreateCompanionBuilder =
    OwnersCompanion Function({
      required String ownerId,
      required String firstName,
      required String lastName,
      required String email,
      Value<String?> phone,
      required String accountStatus,
      required String registeredAt,
      required String updatedAt,
      Value<String?> userPreferences,
      Value<int> rowid,
    });
typedef $$OwnersTableUpdateCompanionBuilder =
    OwnersCompanion Function({
      Value<String> ownerId,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> email,
      Value<String?> phone,
      Value<String> accountStatus,
      Value<String> registeredAt,
      Value<String> updatedAt,
      Value<String?> userPreferences,
      Value<int> rowid,
    });

class $$OwnersTableFilterComposer
    extends Composer<_$AppDatabase, $OwnersTable> {
  $$OwnersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userPreferences => $composableBuilder(
    column: $table.userPreferences,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnersTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnersTable> {
  $$OwnersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userPreferences => $composableBuilder(
    column: $table.userPreferences,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnersTable> {
  $$OwnersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get userPreferences => $composableBuilder(
    column: $table.userPreferences,
    builder: (column) => column,
  );
}

class $$OwnersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OwnersTable,
          OwnerRow,
          $$OwnersTableFilterComposer,
          $$OwnersTableOrderingComposer,
          $$OwnersTableAnnotationComposer,
          $$OwnersTableCreateCompanionBuilder,
          $$OwnersTableUpdateCompanionBuilder,
          (OwnerRow, BaseReferences<_$AppDatabase, $OwnersTable, OwnerRow>),
          OwnerRow,
          PrefetchHooks Function()
        > {
  $$OwnersTableTableManager(_$AppDatabase db, $OwnersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> accountStatus = const Value.absent(),
                Value<String> registeredAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> userPreferences = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnersCompanion(
                ownerId: ownerId,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                accountStatus: accountStatus,
                registeredAt: registeredAt,
                updatedAt: updatedAt,
                userPreferences: userPreferences,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String firstName,
                required String lastName,
                required String email,
                Value<String?> phone = const Value.absent(),
                required String accountStatus,
                required String registeredAt,
                required String updatedAt,
                Value<String?> userPreferences = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnersCompanion.insert(
                ownerId: ownerId,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                accountStatus: accountStatus,
                registeredAt: registeredAt,
                updatedAt: updatedAt,
                userPreferences: userPreferences,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OwnersTable,
      OwnerRow,
      $$OwnersTableFilterComposer,
      $$OwnersTableOrderingComposer,
      $$OwnersTableAnnotationComposer,
      $$OwnersTableCreateCompanionBuilder,
      $$OwnersTableUpdateCompanionBuilder,
      (OwnerRow, BaseReferences<_$AppDatabase, $OwnersTable, OwnerRow>),
      OwnerRow,
      PrefetchHooks Function()
    >;
typedef $$OwnerInvitationsTableCreateCompanionBuilder =
    OwnerInvitationsCompanion Function({
      required String invitationId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$OwnerInvitationsTableUpdateCompanionBuilder =
    OwnerInvitationsCompanion Function({
      Value<String> invitationId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$OwnerInvitationsTableFilterComposer
    extends Composer<_$AppDatabase, $OwnerInvitationsTable> {
  $$OwnerInvitationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get invitationId => $composableBuilder(
    column: $table.invitationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnerInvitationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnerInvitationsTable> {
  $$OwnerInvitationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get invitationId => $composableBuilder(
    column: $table.invitationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnerInvitationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnerInvitationsTable> {
  $$OwnerInvitationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get invitationId => $composableBuilder(
    column: $table.invitationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$OwnerInvitationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OwnerInvitationsTable,
          OwnerInvitationRow,
          $$OwnerInvitationsTableFilterComposer,
          $$OwnerInvitationsTableOrderingComposer,
          $$OwnerInvitationsTableAnnotationComposer,
          $$OwnerInvitationsTableCreateCompanionBuilder,
          $$OwnerInvitationsTableUpdateCompanionBuilder,
          (
            OwnerInvitationRow,
            BaseReferences<
              _$AppDatabase,
              $OwnerInvitationsTable,
              OwnerInvitationRow
            >,
          ),
          OwnerInvitationRow,
          PrefetchHooks Function()
        > {
  $$OwnerInvitationsTableTableManager(
    _$AppDatabase db,
    $OwnerInvitationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnerInvitationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnerInvitationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnerInvitationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> invitationId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnerInvitationsCompanion(
                invitationId: invitationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String invitationId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => OwnerInvitationsCompanion.insert(
                invitationId: invitationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnerInvitationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OwnerInvitationsTable,
      OwnerInvitationRow,
      $$OwnerInvitationsTableFilterComposer,
      $$OwnerInvitationsTableOrderingComposer,
      $$OwnerInvitationsTableAnnotationComposer,
      $$OwnerInvitationsTableCreateCompanionBuilder,
      $$OwnerInvitationsTableUpdateCompanionBuilder,
      (
        OwnerInvitationRow,
        BaseReferences<
          _$AppDatabase,
          $OwnerInvitationsTable,
          OwnerInvitationRow
        >,
      ),
      OwnerInvitationRow,
      PrefetchHooks Function()
    >;
typedef $$BasketExchangesTableCreateCompanionBuilder =
    BasketExchangesCompanion Function({
      required String basketExchangeId,
      required String organizationId,
      required String deliveryId,
      required String contractId,
      required String offeringMemberId,
      Value<String?> motive,
      required String status,
      required String createdAt,
      Value<String?> decidedAt,
      Value<String?> acceptedRequestId,
      required String requestsJson,
      Value<int> rowid,
    });
typedef $$BasketExchangesTableUpdateCompanionBuilder =
    BasketExchangesCompanion Function({
      Value<String> basketExchangeId,
      Value<String> organizationId,
      Value<String> deliveryId,
      Value<String> contractId,
      Value<String> offeringMemberId,
      Value<String?> motive,
      Value<String> status,
      Value<String> createdAt,
      Value<String?> decidedAt,
      Value<String?> acceptedRequestId,
      Value<String> requestsJson,
      Value<int> rowid,
    });

class $$BasketExchangesTableFilterComposer
    extends Composer<_$AppDatabase, $BasketExchangesTable> {
  $$BasketExchangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get basketExchangeId => $composableBuilder(
    column: $table.basketExchangeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offeringMemberId => $composableBuilder(
    column: $table.offeringMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motive => $composableBuilder(
    column: $table.motive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acceptedRequestId => $composableBuilder(
    column: $table.acceptedRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestsJson => $composableBuilder(
    column: $table.requestsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BasketExchangesTableOrderingComposer
    extends Composer<_$AppDatabase, $BasketExchangesTable> {
  $$BasketExchangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get basketExchangeId => $composableBuilder(
    column: $table.basketExchangeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offeringMemberId => $composableBuilder(
    column: $table.offeringMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motive => $composableBuilder(
    column: $table.motive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acceptedRequestId => $composableBuilder(
    column: $table.acceptedRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestsJson => $composableBuilder(
    column: $table.requestsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BasketExchangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BasketExchangesTable> {
  $$BasketExchangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get basketExchangeId => $composableBuilder(
    column: $table.basketExchangeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contractId => $composableBuilder(
    column: $table.contractId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get offeringMemberId => $composableBuilder(
    column: $table.offeringMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motive =>
      $composableBuilder(column: $table.motive, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<String> get acceptedRequestId => $composableBuilder(
    column: $table.acceptedRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestsJson => $composableBuilder(
    column: $table.requestsJson,
    builder: (column) => column,
  );
}

class $$BasketExchangesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BasketExchangesTable,
          BasketExchangeRow,
          $$BasketExchangesTableFilterComposer,
          $$BasketExchangesTableOrderingComposer,
          $$BasketExchangesTableAnnotationComposer,
          $$BasketExchangesTableCreateCompanionBuilder,
          $$BasketExchangesTableUpdateCompanionBuilder,
          (
            BasketExchangeRow,
            BaseReferences<
              _$AppDatabase,
              $BasketExchangesTable,
              BasketExchangeRow
            >,
          ),
          BasketExchangeRow,
          PrefetchHooks Function()
        > {
  $$BasketExchangesTableTableManager(
    _$AppDatabase db,
    $BasketExchangesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BasketExchangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BasketExchangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BasketExchangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> basketExchangeId = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> deliveryId = const Value.absent(),
                Value<String> contractId = const Value.absent(),
                Value<String> offeringMemberId = const Value.absent(),
                Value<String?> motive = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> decidedAt = const Value.absent(),
                Value<String?> acceptedRequestId = const Value.absent(),
                Value<String> requestsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BasketExchangesCompanion(
                basketExchangeId: basketExchangeId,
                organizationId: organizationId,
                deliveryId: deliveryId,
                contractId: contractId,
                offeringMemberId: offeringMemberId,
                motive: motive,
                status: status,
                createdAt: createdAt,
                decidedAt: decidedAt,
                acceptedRequestId: acceptedRequestId,
                requestsJson: requestsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String basketExchangeId,
                required String organizationId,
                required String deliveryId,
                required String contractId,
                required String offeringMemberId,
                Value<String?> motive = const Value.absent(),
                required String status,
                required String createdAt,
                Value<String?> decidedAt = const Value.absent(),
                Value<String?> acceptedRequestId = const Value.absent(),
                required String requestsJson,
                Value<int> rowid = const Value.absent(),
              }) => BasketExchangesCompanion.insert(
                basketExchangeId: basketExchangeId,
                organizationId: organizationId,
                deliveryId: deliveryId,
                contractId: contractId,
                offeringMemberId: offeringMemberId,
                motive: motive,
                status: status,
                createdAt: createdAt,
                decidedAt: decidedAt,
                acceptedRequestId: acceptedRequestId,
                requestsJson: requestsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BasketExchangesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BasketExchangesTable,
      BasketExchangeRow,
      $$BasketExchangesTableFilterComposer,
      $$BasketExchangesTableOrderingComposer,
      $$BasketExchangesTableAnnotationComposer,
      $$BasketExchangesTableCreateCompanionBuilder,
      $$BasketExchangesTableUpdateCompanionBuilder,
      (
        BasketExchangeRow,
        BaseReferences<_$AppDatabase, $BasketExchangesTable, BasketExchangeRow>,
      ),
      BasketExchangeRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableCreateCompanionBuilder =
    NotificationsCompanion Function({
      required String recipientScope,
      required String notificationId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$NotificationsTableUpdateCompanionBuilder =
    NotificationsCompanion Function({
      Value<String> recipientScope,
      Value<String> notificationId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$NotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipientScope => $composableBuilder(
    column: $table.recipientScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipientScope => $composableBuilder(
    column: $table.recipientScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipientScope => $composableBuilder(
    column: $table.recipientScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$NotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTable,
          NotificationRow,
          $$NotificationsTableFilterComposer,
          $$NotificationsTableOrderingComposer,
          $$NotificationsTableAnnotationComposer,
          $$NotificationsTableCreateCompanionBuilder,
          $$NotificationsTableUpdateCompanionBuilder,
          (
            NotificationRow,
            BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>,
          ),
          NotificationRow,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipientScope = const Value.absent(),
                Value<String> notificationId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion(
                recipientScope: recipientScope,
                notificationId: notificationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipientScope,
                required String notificationId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion.insert(
                recipientScope: recipientScope,
                notificationId: notificationId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTable,
      NotificationRow,
      $$NotificationsTableFilterComposer,
      $$NotificationsTableOrderingComposer,
      $$NotificationsTableAnnotationComposer,
      $$NotificationsTableCreateCompanionBuilder,
      $$NotificationsTableUpdateCompanionBuilder,
      (
        NotificationRow,
        BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>,
      ),
      NotificationRow,
      PrefetchHooks Function()
    >;
typedef $$DeviceTokensTableCreateCompanionBuilder =
    DeviceTokensCompanion Function({
      required String recipientScope,
      required String deviceTokenId,
      required String dataJson,
      Value<int> rowid,
    });
typedef $$DeviceTokensTableUpdateCompanionBuilder =
    DeviceTokensCompanion Function({
      Value<String> recipientScope,
      Value<String> deviceTokenId,
      Value<String> dataJson,
      Value<int> rowid,
    });

class $$DeviceTokensTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceTokensTable> {
  $$DeviceTokensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipientScope => $composableBuilder(
    column: $table.recipientScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceTokenId => $composableBuilder(
    column: $table.deviceTokenId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceTokensTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceTokensTable> {
  $$DeviceTokensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipientScope => $composableBuilder(
    column: $table.recipientScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceTokenId => $composableBuilder(
    column: $table.deviceTokenId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceTokensTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceTokensTable> {
  $$DeviceTokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipientScope => $composableBuilder(
    column: $table.recipientScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceTokenId => $composableBuilder(
    column: $table.deviceTokenId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);
}

class $$DeviceTokensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceTokensTable,
          DeviceTokenRow,
          $$DeviceTokensTableFilterComposer,
          $$DeviceTokensTableOrderingComposer,
          $$DeviceTokensTableAnnotationComposer,
          $$DeviceTokensTableCreateCompanionBuilder,
          $$DeviceTokensTableUpdateCompanionBuilder,
          (
            DeviceTokenRow,
            BaseReferences<_$AppDatabase, $DeviceTokensTable, DeviceTokenRow>,
          ),
          DeviceTokenRow,
          PrefetchHooks Function()
        > {
  $$DeviceTokensTableTableManager(_$AppDatabase db, $DeviceTokensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceTokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceTokensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceTokensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipientScope = const Value.absent(),
                Value<String> deviceTokenId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceTokensCompanion(
                recipientScope: recipientScope,
                deviceTokenId: deviceTokenId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipientScope,
                required String deviceTokenId,
                required String dataJson,
                Value<int> rowid = const Value.absent(),
              }) => DeviceTokensCompanion.insert(
                recipientScope: recipientScope,
                deviceTokenId: deviceTokenId,
                dataJson: dataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceTokensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceTokensTable,
      DeviceTokenRow,
      $$DeviceTokensTableFilterComposer,
      $$DeviceTokensTableOrderingComposer,
      $$DeviceTokensTableAnnotationComposer,
      $$DeviceTokensTableCreateCompanionBuilder,
      $$DeviceTokensTableUpdateCompanionBuilder,
      (
        DeviceTokenRow,
        BaseReferences<_$AppDatabase, $DeviceTokensTable, DeviceTokenRow>,
      ),
      DeviceTokenRow,
      PrefetchHooks Function()
    >;
typedef $$AttendanceEmailRequestsTableCreateCompanionBuilder =
    AttendanceEmailRequestsCompanion Function({
      required String attendanceEmailRequestId,
      required String organizationId,
      required String deliveryId,
      required String recipientEmail,
      required String requestedAt,
      Value<String?> sentAt,
      Value<int> rowid,
    });
typedef $$AttendanceEmailRequestsTableUpdateCompanionBuilder =
    AttendanceEmailRequestsCompanion Function({
      Value<String> attendanceEmailRequestId,
      Value<String> organizationId,
      Value<String> deliveryId,
      Value<String> recipientEmail,
      Value<String> requestedAt,
      Value<String?> sentAt,
      Value<int> rowid,
    });

class $$AttendanceEmailRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceEmailRequestsTable> {
  $$AttendanceEmailRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attendanceEmailRequestId => $composableBuilder(
    column: $table.attendanceEmailRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientEmail => $composableBuilder(
    column: $table.recipientEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceEmailRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceEmailRequestsTable> {
  $$AttendanceEmailRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attendanceEmailRequestId => $composableBuilder(
    column: $table.attendanceEmailRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientEmail => $composableBuilder(
    column: $table.recipientEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceEmailRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceEmailRequestsTable> {
  $$AttendanceEmailRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attendanceEmailRequestId => $composableBuilder(
    column: $table.attendanceEmailRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientEmail => $composableBuilder(
    column: $table.recipientEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$AttendanceEmailRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceEmailRequestsTable,
          AttendanceEmailRequestRow,
          $$AttendanceEmailRequestsTableFilterComposer,
          $$AttendanceEmailRequestsTableOrderingComposer,
          $$AttendanceEmailRequestsTableAnnotationComposer,
          $$AttendanceEmailRequestsTableCreateCompanionBuilder,
          $$AttendanceEmailRequestsTableUpdateCompanionBuilder,
          (
            AttendanceEmailRequestRow,
            BaseReferences<
              _$AppDatabase,
              $AttendanceEmailRequestsTable,
              AttendanceEmailRequestRow
            >,
          ),
          AttendanceEmailRequestRow,
          PrefetchHooks Function()
        > {
  $$AttendanceEmailRequestsTableTableManager(
    _$AppDatabase db,
    $AttendanceEmailRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceEmailRequestsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceEmailRequestsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceEmailRequestsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> attendanceEmailRequestId = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> deliveryId = const Value.absent(),
                Value<String> recipientEmail = const Value.absent(),
                Value<String> requestedAt = const Value.absent(),
                Value<String?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceEmailRequestsCompanion(
                attendanceEmailRequestId: attendanceEmailRequestId,
                organizationId: organizationId,
                deliveryId: deliveryId,
                recipientEmail: recipientEmail,
                requestedAt: requestedAt,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attendanceEmailRequestId,
                required String organizationId,
                required String deliveryId,
                required String recipientEmail,
                required String requestedAt,
                Value<String?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceEmailRequestsCompanion.insert(
                attendanceEmailRequestId: attendanceEmailRequestId,
                organizationId: organizationId,
                deliveryId: deliveryId,
                recipientEmail: recipientEmail,
                requestedAt: requestedAt,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceEmailRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceEmailRequestsTable,
      AttendanceEmailRequestRow,
      $$AttendanceEmailRequestsTableFilterComposer,
      $$AttendanceEmailRequestsTableOrderingComposer,
      $$AttendanceEmailRequestsTableAnnotationComposer,
      $$AttendanceEmailRequestsTableCreateCompanionBuilder,
      $$AttendanceEmailRequestsTableUpdateCompanionBuilder,
      (
        AttendanceEmailRequestRow,
        BaseReferences<
          _$AppDatabase,
          $AttendanceEmailRequestsTable,
          AttendanceEmailRequestRow
        >,
      ),
      AttendanceEmailRequestRow,
      PrefetchHooks Function()
    >;
typedef $$ErrorReportsTableCreateCompanionBuilder =
    ErrorReportsCompanion Function({
      required String errorReportId,
      required String errorMessage,
      required String reportedAt,
      Value<int> rowid,
    });
typedef $$ErrorReportsTableUpdateCompanionBuilder =
    ErrorReportsCompanion Function({
      Value<String> errorReportId,
      Value<String> errorMessage,
      Value<String> reportedAt,
      Value<int> rowid,
    });

class $$ErrorReportsTableFilterComposer
    extends Composer<_$AppDatabase, $ErrorReportsTable> {
  $$ErrorReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get errorReportId => $composableBuilder(
    column: $table.errorReportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ErrorReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ErrorReportsTable> {
  $$ErrorReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get errorReportId => $composableBuilder(
    column: $table.errorReportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ErrorReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ErrorReportsTable> {
  $$ErrorReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get errorReportId => $composableBuilder(
    column: $table.errorReportId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => column,
  );
}

class $$ErrorReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ErrorReportsTable,
          ErrorReportRow,
          $$ErrorReportsTableFilterComposer,
          $$ErrorReportsTableOrderingComposer,
          $$ErrorReportsTableAnnotationComposer,
          $$ErrorReportsTableCreateCompanionBuilder,
          $$ErrorReportsTableUpdateCompanionBuilder,
          (
            ErrorReportRow,
            BaseReferences<_$AppDatabase, $ErrorReportsTable, ErrorReportRow>,
          ),
          ErrorReportRow,
          PrefetchHooks Function()
        > {
  $$ErrorReportsTableTableManager(_$AppDatabase db, $ErrorReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ErrorReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ErrorReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ErrorReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> errorReportId = const Value.absent(),
                Value<String> errorMessage = const Value.absent(),
                Value<String> reportedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ErrorReportsCompanion(
                errorReportId: errorReportId,
                errorMessage: errorMessage,
                reportedAt: reportedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String errorReportId,
                required String errorMessage,
                required String reportedAt,
                Value<int> rowid = const Value.absent(),
              }) => ErrorReportsCompanion.insert(
                errorReportId: errorReportId,
                errorMessage: errorMessage,
                reportedAt: reportedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ErrorReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ErrorReportsTable,
      ErrorReportRow,
      $$ErrorReportsTableFilterComposer,
      $$ErrorReportsTableOrderingComposer,
      $$ErrorReportsTableAnnotationComposer,
      $$ErrorReportsTableCreateCompanionBuilder,
      $$ErrorReportsTableUpdateCompanionBuilder,
      (
        ErrorReportRow,
        BaseReferences<_$AppDatabase, $ErrorReportsTable, ErrorReportRow>,
      ),
      ErrorReportRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductTypesTableTableManager get productTypes =>
      $$ProductTypesTableTableManager(_db, _db.productTypes);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$PendingMutationsTableTableManager get pendingMutations =>
      $$PendingMutationsTableTableManager(_db, _db.pendingMutations);
  $$OrganizationsTableTableManager get organizations =>
      $$OrganizationsTableTableManager(_db, _db.organizations);
  $$ProducerAccountsTableTableManager get producerAccounts =>
      $$ProducerAccountsTableTableManager(_db, _db.producerAccounts);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$MemberInvitationsTableTableManager get memberInvitations =>
      $$MemberInvitationsTableTableManager(_db, _db.memberInvitations);
  $$MemberJoinRequestsTableTableManager get memberJoinRequests =>
      $$MemberJoinRequestsTableTableManager(_db, _db.memberJoinRequests);
  $$ContractsTableTableManager get contracts =>
      $$ContractsTableTableManager(_db, _db.contracts);
  $$DeliveryTemplatesTableTableManager get deliveryTemplates =>
      $$DeliveryTemplatesTableTableManager(_db, _db.deliveryTemplates);
  $$OrganizationRequestsTableTableManager get organizationRequests =>
      $$OrganizationRequestsTableTableManager(_db, _db.organizationRequests);
  $$ProducerRequestsTableTableManager get producerRequests =>
      $$ProducerRequestsTableTableManager(_db, _db.producerRequests);
  $$OwnersTableTableManager get owners =>
      $$OwnersTableTableManager(_db, _db.owners);
  $$OwnerInvitationsTableTableManager get ownerInvitations =>
      $$OwnerInvitationsTableTableManager(_db, _db.ownerInvitations);
  $$BasketExchangesTableTableManager get basketExchanges =>
      $$BasketExchangesTableTableManager(_db, _db.basketExchanges);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
  $$DeviceTokensTableTableManager get deviceTokens =>
      $$DeviceTokensTableTableManager(_db, _db.deviceTokens);
  $$AttendanceEmailRequestsTableTableManager get attendanceEmailRequests =>
      $$AttendanceEmailRequestsTableTableManager(
        _db,
        _db.attendanceEmailRequests,
      );
  $$ErrorReportsTableTableManager get errorReports =>
      $$ErrorReportsTableTableManager(_db, _db.errorReports);
}
