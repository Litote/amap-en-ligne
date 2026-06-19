// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncResponse {

@JsonKey(name: 'authorized_scopes') List<String> get authorizedScopes; Map<String, ScopeSyncResult> get results; List<MutationOutcome> get mutations;
/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncResponseCopyWith<SyncResponse> get copyWith => _$SyncResponseCopyWithImpl<SyncResponse>(this as SyncResponse, _$identity);

  /// Serializes this SyncResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncResponse&&const DeepCollectionEquality().equals(other.authorizedScopes, authorizedScopes)&&const DeepCollectionEquality().equals(other.results, results)&&const DeepCollectionEquality().equals(other.mutations, mutations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(authorizedScopes),const DeepCollectionEquality().hash(results),const DeepCollectionEquality().hash(mutations));

@override
String toString() {
  return 'SyncResponse(authorizedScopes: $authorizedScopes, results: $results, mutations: $mutations)';
}


}

/// @nodoc
abstract mixin class $SyncResponseCopyWith<$Res>  {
  factory $SyncResponseCopyWith(SyncResponse value, $Res Function(SyncResponse) _then) = _$SyncResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'authorized_scopes') List<String> authorizedScopes, Map<String, ScopeSyncResult> results, List<MutationOutcome> mutations
});




}
/// @nodoc
class _$SyncResponseCopyWithImpl<$Res>
    implements $SyncResponseCopyWith<$Res> {
  _$SyncResponseCopyWithImpl(this._self, this._then);

  final SyncResponse _self;
  final $Res Function(SyncResponse) _then;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authorizedScopes = null,Object? results = null,Object? mutations = null,}) {
  return _then(_self.copyWith(
authorizedScopes: null == authorizedScopes ? _self.authorizedScopes : authorizedScopes // ignore: cast_nullable_to_non_nullable
as List<String>,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as Map<String, ScopeSyncResult>,mutations: null == mutations ? _self.mutations : mutations // ignore: cast_nullable_to_non_nullable
as List<MutationOutcome>,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncResponse].
extension SyncResponsePatterns on SyncResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncResponse value)  $default,){
final _that = this;
switch (_that) {
case _SyncResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'authorized_scopes')  List<String> authorizedScopes,  Map<String, ScopeSyncResult> results,  List<MutationOutcome> mutations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that.authorizedScopes,_that.results,_that.mutations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'authorized_scopes')  List<String> authorizedScopes,  Map<String, ScopeSyncResult> results,  List<MutationOutcome> mutations)  $default,) {final _that = this;
switch (_that) {
case _SyncResponse():
return $default(_that.authorizedScopes,_that.results,_that.mutations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'authorized_scopes')  List<String> authorizedScopes,  Map<String, ScopeSyncResult> results,  List<MutationOutcome> mutations)?  $default,) {final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that.authorizedScopes,_that.results,_that.mutations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncResponse implements SyncResponse {
  const _SyncResponse({@JsonKey(name: 'authorized_scopes') final  List<String> authorizedScopes = const <String>[], final  Map<String, ScopeSyncResult> results = const <String, ScopeSyncResult>{}, final  List<MutationOutcome> mutations = const <MutationOutcome>[]}): _authorizedScopes = authorizedScopes,_results = results,_mutations = mutations;
  factory _SyncResponse.fromJson(Map<String, dynamic> json) => _$SyncResponseFromJson(json);

 final  List<String> _authorizedScopes;
@override@JsonKey(name: 'authorized_scopes') List<String> get authorizedScopes {
  if (_authorizedScopes is EqualUnmodifiableListView) return _authorizedScopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authorizedScopes);
}

 final  Map<String, ScopeSyncResult> _results;
@override@JsonKey() Map<String, ScopeSyncResult> get results {
  if (_results is EqualUnmodifiableMapView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_results);
}

 final  List<MutationOutcome> _mutations;
@override@JsonKey() List<MutationOutcome> get mutations {
  if (_mutations is EqualUnmodifiableListView) return _mutations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mutations);
}


/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncResponseCopyWith<_SyncResponse> get copyWith => __$SyncResponseCopyWithImpl<_SyncResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncResponse&&const DeepCollectionEquality().equals(other._authorizedScopes, _authorizedScopes)&&const DeepCollectionEquality().equals(other._results, _results)&&const DeepCollectionEquality().equals(other._mutations, _mutations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_authorizedScopes),const DeepCollectionEquality().hash(_results),const DeepCollectionEquality().hash(_mutations));

@override
String toString() {
  return 'SyncResponse(authorizedScopes: $authorizedScopes, results: $results, mutations: $mutations)';
}


}

/// @nodoc
abstract mixin class _$SyncResponseCopyWith<$Res> implements $SyncResponseCopyWith<$Res> {
  factory _$SyncResponseCopyWith(_SyncResponse value, $Res Function(_SyncResponse) _then) = __$SyncResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'authorized_scopes') List<String> authorizedScopes, Map<String, ScopeSyncResult> results, List<MutationOutcome> mutations
});




}
/// @nodoc
class __$SyncResponseCopyWithImpl<$Res>
    implements _$SyncResponseCopyWith<$Res> {
  __$SyncResponseCopyWithImpl(this._self, this._then);

  final _SyncResponse _self;
  final $Res Function(_SyncResponse) _then;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authorizedScopes = null,Object? results = null,Object? mutations = null,}) {
  return _then(_SyncResponse(
authorizedScopes: null == authorizedScopes ? _self._authorizedScopes : authorizedScopes // ignore: cast_nullable_to_non_nullable
as List<String>,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as Map<String, ScopeSyncResult>,mutations: null == mutations ? _self._mutations : mutations // ignore: cast_nullable_to_non_nullable
as List<MutationOutcome>,
  ));
}


}

// dart format on
