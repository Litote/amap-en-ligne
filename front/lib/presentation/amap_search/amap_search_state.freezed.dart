// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'amap_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AmapSearchState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AmapSearchState()';
}


}

/// @nodoc
class $AmapSearchStateCopyWith<$Res>  {
$AmapSearchStateCopyWith(AmapSearchState _, $Res Function(AmapSearchState) __);
}


/// Adds pattern-matching-related methods to [AmapSearchState].
extension AmapSearchStatePatterns on AmapSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AmapSearchInitial value)?  initial,TResult Function( AmapSearchLoadingOrgs value)?  loadingOrgs,TResult Function( AmapSearchOrgsLoaded value)?  orgsLoaded,TResult Function( AmapSearchSubmitting value)?  submitting,TResult Function( AmapSearchSuccess value)?  success,TResult Function( AmapSearchError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AmapSearchInitial() when initial != null:
return initial(_that);case AmapSearchLoadingOrgs() when loadingOrgs != null:
return loadingOrgs(_that);case AmapSearchOrgsLoaded() when orgsLoaded != null:
return orgsLoaded(_that);case AmapSearchSubmitting() when submitting != null:
return submitting(_that);case AmapSearchSuccess() when success != null:
return success(_that);case AmapSearchError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AmapSearchInitial value)  initial,required TResult Function( AmapSearchLoadingOrgs value)  loadingOrgs,required TResult Function( AmapSearchOrgsLoaded value)  orgsLoaded,required TResult Function( AmapSearchSubmitting value)  submitting,required TResult Function( AmapSearchSuccess value)  success,required TResult Function( AmapSearchError value)  error,}){
final _that = this;
switch (_that) {
case AmapSearchInitial():
return initial(_that);case AmapSearchLoadingOrgs():
return loadingOrgs(_that);case AmapSearchOrgsLoaded():
return orgsLoaded(_that);case AmapSearchSubmitting():
return submitting(_that);case AmapSearchSuccess():
return success(_that);case AmapSearchError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AmapSearchInitial value)?  initial,TResult? Function( AmapSearchLoadingOrgs value)?  loadingOrgs,TResult? Function( AmapSearchOrgsLoaded value)?  orgsLoaded,TResult? Function( AmapSearchSubmitting value)?  submitting,TResult? Function( AmapSearchSuccess value)?  success,TResult? Function( AmapSearchError value)?  error,}){
final _that = this;
switch (_that) {
case AmapSearchInitial() when initial != null:
return initial(_that);case AmapSearchLoadingOrgs() when loadingOrgs != null:
return loadingOrgs(_that);case AmapSearchOrgsLoaded() when orgsLoaded != null:
return orgsLoaded(_that);case AmapSearchSubmitting() when submitting != null:
return submitting(_that);case AmapSearchSuccess() when success != null:
return success(_that);case AmapSearchError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loadingOrgs,TResult Function( List<Organization> orgs,  Organization? selectedOrg,  String searchQuery)?  orgsLoaded,TResult Function( Organization org)?  submitting,TResult Function( String requestId,  String organizationName)?  success,TResult Function( String message,  Organization? selectedOrg)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AmapSearchInitial() when initial != null:
return initial();case AmapSearchLoadingOrgs() when loadingOrgs != null:
return loadingOrgs();case AmapSearchOrgsLoaded() when orgsLoaded != null:
return orgsLoaded(_that.orgs,_that.selectedOrg,_that.searchQuery);case AmapSearchSubmitting() when submitting != null:
return submitting(_that.org);case AmapSearchSuccess() when success != null:
return success(_that.requestId,_that.organizationName);case AmapSearchError() when error != null:
return error(_that.message,_that.selectedOrg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loadingOrgs,required TResult Function( List<Organization> orgs,  Organization? selectedOrg,  String searchQuery)  orgsLoaded,required TResult Function( Organization org)  submitting,required TResult Function( String requestId,  String organizationName)  success,required TResult Function( String message,  Organization? selectedOrg)  error,}) {final _that = this;
switch (_that) {
case AmapSearchInitial():
return initial();case AmapSearchLoadingOrgs():
return loadingOrgs();case AmapSearchOrgsLoaded():
return orgsLoaded(_that.orgs,_that.selectedOrg,_that.searchQuery);case AmapSearchSubmitting():
return submitting(_that.org);case AmapSearchSuccess():
return success(_that.requestId,_that.organizationName);case AmapSearchError():
return error(_that.message,_that.selectedOrg);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loadingOrgs,TResult? Function( List<Organization> orgs,  Organization? selectedOrg,  String searchQuery)?  orgsLoaded,TResult? Function( Organization org)?  submitting,TResult? Function( String requestId,  String organizationName)?  success,TResult? Function( String message,  Organization? selectedOrg)?  error,}) {final _that = this;
switch (_that) {
case AmapSearchInitial() when initial != null:
return initial();case AmapSearchLoadingOrgs() when loadingOrgs != null:
return loadingOrgs();case AmapSearchOrgsLoaded() when orgsLoaded != null:
return orgsLoaded(_that.orgs,_that.selectedOrg,_that.searchQuery);case AmapSearchSubmitting() when submitting != null:
return submitting(_that.org);case AmapSearchSuccess() when success != null:
return success(_that.requestId,_that.organizationName);case AmapSearchError() when error != null:
return error(_that.message,_that.selectedOrg);case _:
  return null;

}
}

}

/// @nodoc


class AmapSearchInitial implements AmapSearchState {
  const AmapSearchInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AmapSearchState.initial()';
}


}




/// @nodoc


class AmapSearchLoadingOrgs implements AmapSearchState {
  const AmapSearchLoadingOrgs();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchLoadingOrgs);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AmapSearchState.loadingOrgs()';
}


}




/// @nodoc


class AmapSearchOrgsLoaded implements AmapSearchState {
  const AmapSearchOrgsLoaded({required final  List<Organization> orgs, this.selectedOrg, this.searchQuery = ''}): _orgs = orgs;
  

 final  List<Organization> _orgs;
 List<Organization> get orgs {
  if (_orgs is EqualUnmodifiableListView) return _orgs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orgs);
}

 final  Organization? selectedOrg;
@JsonKey() final  String searchQuery;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmapSearchOrgsLoadedCopyWith<AmapSearchOrgsLoaded> get copyWith => _$AmapSearchOrgsLoadedCopyWithImpl<AmapSearchOrgsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchOrgsLoaded&&const DeepCollectionEquality().equals(other._orgs, _orgs)&&(identical(other.selectedOrg, selectedOrg) || other.selectedOrg == selectedOrg)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_orgs),selectedOrg,searchQuery);

@override
String toString() {
  return 'AmapSearchState.orgsLoaded(orgs: $orgs, selectedOrg: $selectedOrg, searchQuery: $searchQuery)';
}


}

/// @nodoc
abstract mixin class $AmapSearchOrgsLoadedCopyWith<$Res> implements $AmapSearchStateCopyWith<$Res> {
  factory $AmapSearchOrgsLoadedCopyWith(AmapSearchOrgsLoaded value, $Res Function(AmapSearchOrgsLoaded) _then) = _$AmapSearchOrgsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Organization> orgs, Organization? selectedOrg, String searchQuery
});


$OrganizationCopyWith<$Res>? get selectedOrg;

}
/// @nodoc
class _$AmapSearchOrgsLoadedCopyWithImpl<$Res>
    implements $AmapSearchOrgsLoadedCopyWith<$Res> {
  _$AmapSearchOrgsLoadedCopyWithImpl(this._self, this._then);

  final AmapSearchOrgsLoaded _self;
  final $Res Function(AmapSearchOrgsLoaded) _then;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? orgs = null,Object? selectedOrg = freezed,Object? searchQuery = null,}) {
  return _then(AmapSearchOrgsLoaded(
orgs: null == orgs ? _self._orgs : orgs // ignore: cast_nullable_to_non_nullable
as List<Organization>,selectedOrg: freezed == selectedOrg ? _self.selectedOrg : selectedOrg // ignore: cast_nullable_to_non_nullable
as Organization?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get selectedOrg {
    if (_self.selectedOrg == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.selectedOrg!, (value) {
    return _then(_self.copyWith(selectedOrg: value));
  });
}
}

/// @nodoc


class AmapSearchSubmitting implements AmapSearchState {
  const AmapSearchSubmitting({required this.org});
  

 final  Organization org;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmapSearchSubmittingCopyWith<AmapSearchSubmitting> get copyWith => _$AmapSearchSubmittingCopyWithImpl<AmapSearchSubmitting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchSubmitting&&(identical(other.org, org) || other.org == org));
}


@override
int get hashCode => Object.hash(runtimeType,org);

@override
String toString() {
  return 'AmapSearchState.submitting(org: $org)';
}


}

/// @nodoc
abstract mixin class $AmapSearchSubmittingCopyWith<$Res> implements $AmapSearchStateCopyWith<$Res> {
  factory $AmapSearchSubmittingCopyWith(AmapSearchSubmitting value, $Res Function(AmapSearchSubmitting) _then) = _$AmapSearchSubmittingCopyWithImpl;
@useResult
$Res call({
 Organization org
});


$OrganizationCopyWith<$Res> get org;

}
/// @nodoc
class _$AmapSearchSubmittingCopyWithImpl<$Res>
    implements $AmapSearchSubmittingCopyWith<$Res> {
  _$AmapSearchSubmittingCopyWithImpl(this._self, this._then);

  final AmapSearchSubmitting _self;
  final $Res Function(AmapSearchSubmitting) _then;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? org = null,}) {
  return _then(AmapSearchSubmitting(
org: null == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as Organization,
  ));
}

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get org {
  
  return $OrganizationCopyWith<$Res>(_self.org, (value) {
    return _then(_self.copyWith(org: value));
  });
}
}

/// @nodoc


class AmapSearchSuccess implements AmapSearchState {
  const AmapSearchSuccess({required this.requestId, required this.organizationName});
  

 final  String requestId;
 final  String organizationName;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmapSearchSuccessCopyWith<AmapSearchSuccess> get copyWith => _$AmapSearchSuccessCopyWithImpl<AmapSearchSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchSuccess&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,organizationName);

@override
String toString() {
  return 'AmapSearchState.success(requestId: $requestId, organizationName: $organizationName)';
}


}

/// @nodoc
abstract mixin class $AmapSearchSuccessCopyWith<$Res> implements $AmapSearchStateCopyWith<$Res> {
  factory $AmapSearchSuccessCopyWith(AmapSearchSuccess value, $Res Function(AmapSearchSuccess) _then) = _$AmapSearchSuccessCopyWithImpl;
@useResult
$Res call({
 String requestId, String organizationName
});




}
/// @nodoc
class _$AmapSearchSuccessCopyWithImpl<$Res>
    implements $AmapSearchSuccessCopyWith<$Res> {
  _$AmapSearchSuccessCopyWithImpl(this._self, this._then);

  final AmapSearchSuccess _self;
  final $Res Function(AmapSearchSuccess) _then;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? organizationName = null,}) {
  return _then(AmapSearchSuccess(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AmapSearchError implements AmapSearchState {
  const AmapSearchError({required this.message, this.selectedOrg});
  

 final  String message;
 final  Organization? selectedOrg;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmapSearchErrorCopyWith<AmapSearchError> get copyWith => _$AmapSearchErrorCopyWithImpl<AmapSearchError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchError&&(identical(other.message, message) || other.message == message)&&(identical(other.selectedOrg, selectedOrg) || other.selectedOrg == selectedOrg));
}


@override
int get hashCode => Object.hash(runtimeType,message,selectedOrg);

@override
String toString() {
  return 'AmapSearchState.error(message: $message, selectedOrg: $selectedOrg)';
}


}

/// @nodoc
abstract mixin class $AmapSearchErrorCopyWith<$Res> implements $AmapSearchStateCopyWith<$Res> {
  factory $AmapSearchErrorCopyWith(AmapSearchError value, $Res Function(AmapSearchError) _then) = _$AmapSearchErrorCopyWithImpl;
@useResult
$Res call({
 String message, Organization? selectedOrg
});


$OrganizationCopyWith<$Res>? get selectedOrg;

}
/// @nodoc
class _$AmapSearchErrorCopyWithImpl<$Res>
    implements $AmapSearchErrorCopyWith<$Res> {
  _$AmapSearchErrorCopyWithImpl(this._self, this._then);

  final AmapSearchError _self;
  final $Res Function(AmapSearchError) _then;

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? selectedOrg = freezed,}) {
  return _then(AmapSearchError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,selectedOrg: freezed == selectedOrg ? _self.selectedOrg : selectedOrg // ignore: cast_nullable_to_non_nullable
as Organization?,
  ));
}

/// Create a copy of AmapSearchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get selectedOrg {
    if (_self.selectedOrg == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.selectedOrg!, (value) {
    return _then(_self.copyWith(selectedOrg: value));
  });
}
}

// dart format on
