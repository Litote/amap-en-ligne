// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scope_sync_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BootstrapScopeSyncResult {

 List<EntityPayload> get items;@JsonKey(name: 'next_cursor') String? get nextCursor;
/// Create a copy of BootstrapScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BootstrapScopeSyncResultCopyWith<BootstrapScopeSyncResult> get copyWith => _$BootstrapScopeSyncResultCopyWithImpl<BootstrapScopeSyncResult>(this as BootstrapScopeSyncResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BootstrapScopeSyncResult&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'BootstrapScopeSyncResult(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $BootstrapScopeSyncResultCopyWith<$Res>  {
  factory $BootstrapScopeSyncResultCopyWith(BootstrapScopeSyncResult value, $Res Function(BootstrapScopeSyncResult) _then) = _$BootstrapScopeSyncResultCopyWithImpl;
@useResult
$Res call({
 List<EntityPayload> items,@JsonKey(name: 'next_cursor') String? nextCursor
});




}
/// @nodoc
class _$BootstrapScopeSyncResultCopyWithImpl<$Res>
    implements $BootstrapScopeSyncResultCopyWith<$Res> {
  _$BootstrapScopeSyncResultCopyWithImpl(this._self, this._then);

  final BootstrapScopeSyncResult _self;
  final $Res Function(BootstrapScopeSyncResult) _then;

/// Create a copy of BootstrapScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<EntityPayload>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BootstrapScopeSyncResult].
extension BootstrapScopeSyncResultPatterns on BootstrapScopeSyncResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BootstrapScopeSyncResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BootstrapScopeSyncResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BootstrapScopeSyncResult value)  $default,){
final _that = this;
switch (_that) {
case _BootstrapScopeSyncResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BootstrapScopeSyncResult value)?  $default,){
final _that = this;
switch (_that) {
case _BootstrapScopeSyncResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<EntityPayload> items, @JsonKey(name: 'next_cursor')  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BootstrapScopeSyncResult() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<EntityPayload> items, @JsonKey(name: 'next_cursor')  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _BootstrapScopeSyncResult():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<EntityPayload> items, @JsonKey(name: 'next_cursor')  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _BootstrapScopeSyncResult() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc


class _BootstrapScopeSyncResult extends BootstrapScopeSyncResult {
  const _BootstrapScopeSyncResult({final  List<EntityPayload> items = const <EntityPayload>[], @JsonKey(name: 'next_cursor') this.nextCursor}): _items = items,super._();
  

 final  List<EntityPayload> _items;
@override@JsonKey() List<EntityPayload> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'next_cursor') final  String? nextCursor;

/// Create a copy of BootstrapScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BootstrapScopeSyncResultCopyWith<_BootstrapScopeSyncResult> get copyWith => __$BootstrapScopeSyncResultCopyWithImpl<_BootstrapScopeSyncResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BootstrapScopeSyncResult&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'BootstrapScopeSyncResult(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$BootstrapScopeSyncResultCopyWith<$Res> implements $BootstrapScopeSyncResultCopyWith<$Res> {
  factory _$BootstrapScopeSyncResultCopyWith(_BootstrapScopeSyncResult value, $Res Function(_BootstrapScopeSyncResult) _then) = __$BootstrapScopeSyncResultCopyWithImpl;
@override @useResult
$Res call({
 List<EntityPayload> items,@JsonKey(name: 'next_cursor') String? nextCursor
});




}
/// @nodoc
class __$BootstrapScopeSyncResultCopyWithImpl<$Res>
    implements _$BootstrapScopeSyncResultCopyWith<$Res> {
  __$BootstrapScopeSyncResultCopyWithImpl(this._self, this._then);

  final _BootstrapScopeSyncResult _self;
  final $Res Function(_BootstrapScopeSyncResult) _then;

/// Create a copy of BootstrapScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_BootstrapScopeSyncResult(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<EntityPayload>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$IncrementalScopeSyncResult {

 List<Change> get changes;@JsonKey(name: 'next_cursor') String? get nextCursor;
/// Create a copy of IncrementalScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncrementalScopeSyncResultCopyWith<IncrementalScopeSyncResult> get copyWith => _$IncrementalScopeSyncResultCopyWithImpl<IncrementalScopeSyncResult>(this as IncrementalScopeSyncResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncrementalScopeSyncResult&&const DeepCollectionEquality().equals(other.changes, changes)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(changes),nextCursor);

@override
String toString() {
  return 'IncrementalScopeSyncResult(changes: $changes, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $IncrementalScopeSyncResultCopyWith<$Res>  {
  factory $IncrementalScopeSyncResultCopyWith(IncrementalScopeSyncResult value, $Res Function(IncrementalScopeSyncResult) _then) = _$IncrementalScopeSyncResultCopyWithImpl;
@useResult
$Res call({
 List<Change> changes,@JsonKey(name: 'next_cursor') String? nextCursor
});




}
/// @nodoc
class _$IncrementalScopeSyncResultCopyWithImpl<$Res>
    implements $IncrementalScopeSyncResultCopyWith<$Res> {
  _$IncrementalScopeSyncResultCopyWithImpl(this._self, this._then);

  final IncrementalScopeSyncResult _self;
  final $Res Function(IncrementalScopeSyncResult) _then;

/// Create a copy of IncrementalScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? changes = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<Change>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IncrementalScopeSyncResult].
extension IncrementalScopeSyncResultPatterns on IncrementalScopeSyncResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncrementalScopeSyncResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncrementalScopeSyncResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncrementalScopeSyncResult value)  $default,){
final _that = this;
switch (_that) {
case _IncrementalScopeSyncResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncrementalScopeSyncResult value)?  $default,){
final _that = this;
switch (_that) {
case _IncrementalScopeSyncResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Change> changes, @JsonKey(name: 'next_cursor')  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncrementalScopeSyncResult() when $default != null:
return $default(_that.changes,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Change> changes, @JsonKey(name: 'next_cursor')  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _IncrementalScopeSyncResult():
return $default(_that.changes,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Change> changes, @JsonKey(name: 'next_cursor')  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _IncrementalScopeSyncResult() when $default != null:
return $default(_that.changes,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc


class _IncrementalScopeSyncResult extends IncrementalScopeSyncResult {
  const _IncrementalScopeSyncResult({final  List<Change> changes = const <Change>[], @JsonKey(name: 'next_cursor') this.nextCursor}): _changes = changes,super._();
  

 final  List<Change> _changes;
@override@JsonKey() List<Change> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}

@override@JsonKey(name: 'next_cursor') final  String? nextCursor;

/// Create a copy of IncrementalScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncrementalScopeSyncResultCopyWith<_IncrementalScopeSyncResult> get copyWith => __$IncrementalScopeSyncResultCopyWithImpl<_IncrementalScopeSyncResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncrementalScopeSyncResult&&const DeepCollectionEquality().equals(other._changes, _changes)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_changes),nextCursor);

@override
String toString() {
  return 'IncrementalScopeSyncResult(changes: $changes, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$IncrementalScopeSyncResultCopyWith<$Res> implements $IncrementalScopeSyncResultCopyWith<$Res> {
  factory _$IncrementalScopeSyncResultCopyWith(_IncrementalScopeSyncResult value, $Res Function(_IncrementalScopeSyncResult) _then) = __$IncrementalScopeSyncResultCopyWithImpl;
@override @useResult
$Res call({
 List<Change> changes,@JsonKey(name: 'next_cursor') String? nextCursor
});




}
/// @nodoc
class __$IncrementalScopeSyncResultCopyWithImpl<$Res>
    implements _$IncrementalScopeSyncResultCopyWith<$Res> {
  __$IncrementalScopeSyncResultCopyWithImpl(this._self, this._then);

  final _IncrementalScopeSyncResult _self;
  final $Res Function(_IncrementalScopeSyncResult) _then;

/// Create a copy of IncrementalScopeSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? changes = null,Object? nextCursor = freezed,}) {
  return _then(_IncrementalScopeSyncResult(
changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<Change>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
