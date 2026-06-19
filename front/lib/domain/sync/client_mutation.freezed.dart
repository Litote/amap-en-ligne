// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_mutation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClientMutation {

@JsonKey(name: 'client_op_id') String get clientOpId; MutationOp get op;
/// Create a copy of ClientMutation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientMutationCopyWith<ClientMutation> get copyWith => _$ClientMutationCopyWithImpl<ClientMutation>(this as ClientMutation, _$identity);

  /// Serializes this ClientMutation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientMutation&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.op, op) || other.op == op));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientOpId,op);

@override
String toString() {
  return 'ClientMutation(clientOpId: $clientOpId, op: $op)';
}


}

/// @nodoc
abstract mixin class $ClientMutationCopyWith<$Res>  {
  factory $ClientMutationCopyWith(ClientMutation value, $Res Function(ClientMutation) _then) = _$ClientMutationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'client_op_id') String clientOpId, MutationOp op
});




}
/// @nodoc
class _$ClientMutationCopyWithImpl<$Res>
    implements $ClientMutationCopyWith<$Res> {
  _$ClientMutationCopyWithImpl(this._self, this._then);

  final ClientMutation _self;
  final $Res Function(ClientMutation) _then;

/// Create a copy of ClientMutation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? op = null,}) {
  return _then(_self.copyWith(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as MutationOp,
  ));
}

}


/// Adds pattern-matching-related methods to [ClientMutation].
extension ClientMutationPatterns on ClientMutation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientMutation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientMutation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientMutation value)  $default,){
final _that = this;
switch (_that) {
case _ClientMutation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientMutation value)?  $default,){
final _that = this;
switch (_that) {
case _ClientMutation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'client_op_id')  String clientOpId,  MutationOp op)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientMutation() when $default != null:
return $default(_that.clientOpId,_that.op);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'client_op_id')  String clientOpId,  MutationOp op)  $default,) {final _that = this;
switch (_that) {
case _ClientMutation():
return $default(_that.clientOpId,_that.op);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'client_op_id')  String clientOpId,  MutationOp op)?  $default,) {final _that = this;
switch (_that) {
case _ClientMutation() when $default != null:
return $default(_that.clientOpId,_that.op);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClientMutation implements ClientMutation {
  const _ClientMutation({@JsonKey(name: 'client_op_id') required this.clientOpId, required this.op});
  factory _ClientMutation.fromJson(Map<String, dynamic> json) => _$ClientMutationFromJson(json);

@override@JsonKey(name: 'client_op_id') final  String clientOpId;
@override final  MutationOp op;

/// Create a copy of ClientMutation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientMutationCopyWith<_ClientMutation> get copyWith => __$ClientMutationCopyWithImpl<_ClientMutation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientMutationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientMutation&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.op, op) || other.op == op));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientOpId,op);

@override
String toString() {
  return 'ClientMutation(clientOpId: $clientOpId, op: $op)';
}


}

/// @nodoc
abstract mixin class _$ClientMutationCopyWith<$Res> implements $ClientMutationCopyWith<$Res> {
  factory _$ClientMutationCopyWith(_ClientMutation value, $Res Function(_ClientMutation) _then) = __$ClientMutationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'client_op_id') String clientOpId, MutationOp op
});




}
/// @nodoc
class __$ClientMutationCopyWithImpl<$Res>
    implements _$ClientMutationCopyWith<$Res> {
  __$ClientMutationCopyWithImpl(this._self, this._then);

  final _ClientMutation _self;
  final $Res Function(_ClientMutation) _then;

/// Create a copy of ClientMutation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? op = null,}) {
  return _then(_ClientMutation(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as MutationOp,
  ));
}


}

// dart format on
