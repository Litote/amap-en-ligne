// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Change {

 String? get cursor;@JsonKey(name: 'entity_type') EntityType get entityType;@JsonKey(name: 'entity_id') String get entityId;@JsonKey(name: 'producer_account_id') String? get producerAccountId; ChangeOp get op; EntityPayload? get payload;@JsonKey(name: 'produced_at') int get producedAt;
/// Create a copy of Change
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangeCopyWith<Change> get copyWith => _$ChangeCopyWithImpl<Change>(this as Change, _$identity);

  /// Serializes this Change to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Change&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.op, op) || other.op == op)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.producedAt, producedAt) || other.producedAt == producedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cursor,entityType,entityId,producerAccountId,op,payload,producedAt);

@override
String toString() {
  return 'Change(cursor: $cursor, entityType: $entityType, entityId: $entityId, producerAccountId: $producerAccountId, op: $op, payload: $payload, producedAt: $producedAt)';
}


}

/// @nodoc
abstract mixin class $ChangeCopyWith<$Res>  {
  factory $ChangeCopyWith(Change value, $Res Function(Change) _then) = _$ChangeCopyWithImpl;
@useResult
$Res call({
 String? cursor,@JsonKey(name: 'entity_type') EntityType entityType,@JsonKey(name: 'entity_id') String entityId,@JsonKey(name: 'producer_account_id') String? producerAccountId, ChangeOp op, EntityPayload? payload,@JsonKey(name: 'produced_at') int producedAt
});




}
/// @nodoc
class _$ChangeCopyWithImpl<$Res>
    implements $ChangeCopyWith<$Res> {
  _$ChangeCopyWithImpl(this._self, this._then);

  final Change _self;
  final $Res Function(Change) _then;

/// Create a copy of Change
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cursor = freezed,Object? entityType = null,Object? entityId = null,Object? producerAccountId = freezed,Object? op = null,Object? payload = freezed,Object? producedAt = null,}) {
  return _then(_self.copyWith(
cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: freezed == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String?,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as ChangeOp,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as EntityPayload?,producedAt: null == producedAt ? _self.producedAt : producedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Change].
extension ChangePatterns on Change {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Change value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Change() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Change value)  $default,){
final _that = this;
switch (_that) {
case _Change():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Change value)?  $default,){
final _that = this;
switch (_that) {
case _Change() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? cursor, @JsonKey(name: 'entity_type')  EntityType entityType, @JsonKey(name: 'entity_id')  String entityId, @JsonKey(name: 'producer_account_id')  String? producerAccountId,  ChangeOp op,  EntityPayload? payload, @JsonKey(name: 'produced_at')  int producedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Change() when $default != null:
return $default(_that.cursor,_that.entityType,_that.entityId,_that.producerAccountId,_that.op,_that.payload,_that.producedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? cursor, @JsonKey(name: 'entity_type')  EntityType entityType, @JsonKey(name: 'entity_id')  String entityId, @JsonKey(name: 'producer_account_id')  String? producerAccountId,  ChangeOp op,  EntityPayload? payload, @JsonKey(name: 'produced_at')  int producedAt)  $default,) {final _that = this;
switch (_that) {
case _Change():
return $default(_that.cursor,_that.entityType,_that.entityId,_that.producerAccountId,_that.op,_that.payload,_that.producedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? cursor, @JsonKey(name: 'entity_type')  EntityType entityType, @JsonKey(name: 'entity_id')  String entityId, @JsonKey(name: 'producer_account_id')  String? producerAccountId,  ChangeOp op,  EntityPayload? payload, @JsonKey(name: 'produced_at')  int producedAt)?  $default,) {final _that = this;
switch (_that) {
case _Change() when $default != null:
return $default(_that.cursor,_that.entityType,_that.entityId,_that.producerAccountId,_that.op,_that.payload,_that.producedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Change implements Change {
  const _Change({this.cursor, @JsonKey(name: 'entity_type') required this.entityType, @JsonKey(name: 'entity_id') required this.entityId, @JsonKey(name: 'producer_account_id') this.producerAccountId, required this.op, this.payload, @JsonKey(name: 'produced_at') required this.producedAt});
  factory _Change.fromJson(Map<String, dynamic> json) => _$ChangeFromJson(json);

@override final  String? cursor;
@override@JsonKey(name: 'entity_type') final  EntityType entityType;
@override@JsonKey(name: 'entity_id') final  String entityId;
@override@JsonKey(name: 'producer_account_id') final  String? producerAccountId;
@override final  ChangeOp op;
@override final  EntityPayload? payload;
@override@JsonKey(name: 'produced_at') final  int producedAt;

/// Create a copy of Change
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangeCopyWith<_Change> get copyWith => __$ChangeCopyWithImpl<_Change>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Change&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.op, op) || other.op == op)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.producedAt, producedAt) || other.producedAt == producedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cursor,entityType,entityId,producerAccountId,op,payload,producedAt);

@override
String toString() {
  return 'Change(cursor: $cursor, entityType: $entityType, entityId: $entityId, producerAccountId: $producerAccountId, op: $op, payload: $payload, producedAt: $producedAt)';
}


}

/// @nodoc
abstract mixin class _$ChangeCopyWith<$Res> implements $ChangeCopyWith<$Res> {
  factory _$ChangeCopyWith(_Change value, $Res Function(_Change) _then) = __$ChangeCopyWithImpl;
@override @useResult
$Res call({
 String? cursor,@JsonKey(name: 'entity_type') EntityType entityType,@JsonKey(name: 'entity_id') String entityId,@JsonKey(name: 'producer_account_id') String? producerAccountId, ChangeOp op, EntityPayload? payload,@JsonKey(name: 'produced_at') int producedAt
});




}
/// @nodoc
class __$ChangeCopyWithImpl<$Res>
    implements _$ChangeCopyWith<$Res> {
  __$ChangeCopyWithImpl(this._self, this._then);

  final _Change _self;
  final $Res Function(_Change) _then;

/// Create a copy of Change
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursor = freezed,Object? entityType = null,Object? entityId = null,Object? producerAccountId = freezed,Object? op = null,Object? payload = freezed,Object? producedAt = null,}) {
  return _then(_Change(
cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: freezed == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String?,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as ChangeOp,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as EntityPayload?,producedAt: null == producedAt ? _self.producedAt : producedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
