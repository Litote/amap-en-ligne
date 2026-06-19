// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entity_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EntitySnapshot {

 List<EntityPayload> get items; String get cursor;
/// Create a copy of EntitySnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntitySnapshotCopyWith<EntitySnapshot> get copyWith => _$EntitySnapshotCopyWithImpl<EntitySnapshot>(this as EntitySnapshot, _$identity);

  /// Serializes this EntitySnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntitySnapshot&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.cursor, cursor) || other.cursor == cursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),cursor);

@override
String toString() {
  return 'EntitySnapshot(items: $items, cursor: $cursor)';
}


}

/// @nodoc
abstract mixin class $EntitySnapshotCopyWith<$Res>  {
  factory $EntitySnapshotCopyWith(EntitySnapshot value, $Res Function(EntitySnapshot) _then) = _$EntitySnapshotCopyWithImpl;
@useResult
$Res call({
 List<EntityPayload> items, String cursor
});




}
/// @nodoc
class _$EntitySnapshotCopyWithImpl<$Res>
    implements $EntitySnapshotCopyWith<$Res> {
  _$EntitySnapshotCopyWithImpl(this._self, this._then);

  final EntitySnapshot _self;
  final $Res Function(EntitySnapshot) _then;

/// Create a copy of EntitySnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? cursor = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<EntityPayload>,cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EntitySnapshot].
extension EntitySnapshotPatterns on EntitySnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntitySnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntitySnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntitySnapshot value)  $default,){
final _that = this;
switch (_that) {
case _EntitySnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntitySnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _EntitySnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<EntityPayload> items,  String cursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntitySnapshot() when $default != null:
return $default(_that.items,_that.cursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<EntityPayload> items,  String cursor)  $default,) {final _that = this;
switch (_that) {
case _EntitySnapshot():
return $default(_that.items,_that.cursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<EntityPayload> items,  String cursor)?  $default,) {final _that = this;
switch (_that) {
case _EntitySnapshot() when $default != null:
return $default(_that.items,_that.cursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EntitySnapshot implements EntitySnapshot {
  const _EntitySnapshot({final  List<EntityPayload> items = const <EntityPayload>[], required this.cursor}): _items = items;
  factory _EntitySnapshot.fromJson(Map<String, dynamic> json) => _$EntitySnapshotFromJson(json);

 final  List<EntityPayload> _items;
@override@JsonKey() List<EntityPayload> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String cursor;

/// Create a copy of EntitySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntitySnapshotCopyWith<_EntitySnapshot> get copyWith => __$EntitySnapshotCopyWithImpl<_EntitySnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntitySnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntitySnapshot&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.cursor, cursor) || other.cursor == cursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),cursor);

@override
String toString() {
  return 'EntitySnapshot(items: $items, cursor: $cursor)';
}


}

/// @nodoc
abstract mixin class _$EntitySnapshotCopyWith<$Res> implements $EntitySnapshotCopyWith<$Res> {
  factory _$EntitySnapshotCopyWith(_EntitySnapshot value, $Res Function(_EntitySnapshot) _then) = __$EntitySnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<EntityPayload> items, String cursor
});




}
/// @nodoc
class __$EntitySnapshotCopyWithImpl<$Res>
    implements _$EntitySnapshotCopyWith<$Res> {
  __$EntitySnapshotCopyWithImpl(this._self, this._then);

  final _EntitySnapshot _self;
  final $Res Function(_EntitySnapshot) _then;

/// Create a copy of EntitySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? cursor = null,}) {
  return _then(_EntitySnapshot(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<EntityPayload>,cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
