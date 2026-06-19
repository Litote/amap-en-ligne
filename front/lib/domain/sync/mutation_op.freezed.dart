// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mutation_op.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Upsert {

 EntityPayload get payload;
/// Create a copy of Upsert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpsertCopyWith<Upsert> get copyWith => _$UpsertCopyWithImpl<Upsert>(this as Upsert, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Upsert&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'Upsert(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $UpsertCopyWith<$Res>  {
  factory $UpsertCopyWith(Upsert value, $Res Function(Upsert) _then) = _$UpsertCopyWithImpl;
@useResult
$Res call({
 EntityPayload payload
});




}
/// @nodoc
class _$UpsertCopyWithImpl<$Res>
    implements $UpsertCopyWith<$Res> {
  _$UpsertCopyWithImpl(this._self, this._then);

  final Upsert _self;
  final $Res Function(Upsert) _then;

/// Create a copy of Upsert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? payload = null,}) {
  return _then(_self.copyWith(
payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as EntityPayload,
  ));
}

}


/// Adds pattern-matching-related methods to [Upsert].
extension UpsertPatterns on Upsert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Upsert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Upsert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Upsert value)  $default,){
final _that = this;
switch (_that) {
case _Upsert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Upsert value)?  $default,){
final _that = this;
switch (_that) {
case _Upsert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EntityPayload payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Upsert() when $default != null:
return $default(_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EntityPayload payload)  $default,) {final _that = this;
switch (_that) {
case _Upsert():
return $default(_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EntityPayload payload)?  $default,) {final _that = this;
switch (_that) {
case _Upsert() when $default != null:
return $default(_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class _Upsert extends Upsert {
  const _Upsert({required this.payload}): super._();
  

@override final  EntityPayload payload;

/// Create a copy of Upsert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpsertCopyWith<_Upsert> get copyWith => __$UpsertCopyWithImpl<_Upsert>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Upsert&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'Upsert(payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$UpsertCopyWith<$Res> implements $UpsertCopyWith<$Res> {
  factory _$UpsertCopyWith(_Upsert value, $Res Function(_Upsert) _then) = __$UpsertCopyWithImpl;
@override @useResult
$Res call({
 EntityPayload payload
});




}
/// @nodoc
class __$UpsertCopyWithImpl<$Res>
    implements _$UpsertCopyWith<$Res> {
  __$UpsertCopyWithImpl(this._self, this._then);

  final _Upsert _self;
  final $Res Function(_Upsert) _then;

/// Create a copy of Upsert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(_Upsert(
payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as EntityPayload,
  ));
}


}

/// @nodoc
mixin _$Delete {

 EntityType get entityType; String get entityId;
/// Create a copy of Delete
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteCopyWith<Delete> get copyWith => _$DeleteCopyWithImpl<Delete>(this as Delete, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Delete&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId));
}


@override
int get hashCode => Object.hash(runtimeType,entityType,entityId);

@override
String toString() {
  return 'Delete(entityType: $entityType, entityId: $entityId)';
}


}

/// @nodoc
abstract mixin class $DeleteCopyWith<$Res>  {
  factory $DeleteCopyWith(Delete value, $Res Function(Delete) _then) = _$DeleteCopyWithImpl;
@useResult
$Res call({
 EntityType entityType, String entityId
});




}
/// @nodoc
class _$DeleteCopyWithImpl<$Res>
    implements $DeleteCopyWith<$Res> {
  _$DeleteCopyWithImpl(this._self, this._then);

  final Delete _self;
  final $Res Function(Delete) _then;

/// Create a copy of Delete
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityType = null,Object? entityId = null,}) {
  return _then(_self.copyWith(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Delete].
extension DeletePatterns on Delete {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Delete value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Delete() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Delete value)  $default,){
final _that = this;
switch (_that) {
case _Delete():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Delete value)?  $default,){
final _that = this;
switch (_that) {
case _Delete() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EntityType entityType,  String entityId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Delete() when $default != null:
return $default(_that.entityType,_that.entityId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EntityType entityType,  String entityId)  $default,) {final _that = this;
switch (_that) {
case _Delete():
return $default(_that.entityType,_that.entityId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EntityType entityType,  String entityId)?  $default,) {final _that = this;
switch (_that) {
case _Delete() when $default != null:
return $default(_that.entityType,_that.entityId);case _:
  return null;

}
}

}

/// @nodoc


class _Delete extends Delete {
  const _Delete({required this.entityType, required this.entityId}): super._();
  

@override final  EntityType entityType;
@override final  String entityId;

/// Create a copy of Delete
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteCopyWith<_Delete> get copyWith => __$DeleteCopyWithImpl<_Delete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Delete&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId));
}


@override
int get hashCode => Object.hash(runtimeType,entityType,entityId);

@override
String toString() {
  return 'Delete(entityType: $entityType, entityId: $entityId)';
}


}

/// @nodoc
abstract mixin class _$DeleteCopyWith<$Res> implements $DeleteCopyWith<$Res> {
  factory _$DeleteCopyWith(_Delete value, $Res Function(_Delete) _then) = __$DeleteCopyWithImpl;
@override @useResult
$Res call({
 EntityType entityType, String entityId
});




}
/// @nodoc
class __$DeleteCopyWithImpl<$Res>
    implements _$DeleteCopyWith<$Res> {
  __$DeleteCopyWithImpl(this._self, this._then);

  final _Delete _self;
  final $Res Function(_Delete) _then;

/// Create a copy of Delete
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? entityId = null,}) {
  return _then(_Delete(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
