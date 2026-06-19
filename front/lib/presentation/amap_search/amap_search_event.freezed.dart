// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'amap_search_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AmapSearchEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmapSearchEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AmapSearchEvent()';
}


}

/// @nodoc
class $AmapSearchEventCopyWith<$Res>  {
$AmapSearchEventCopyWith(AmapSearchEvent _, $Res Function(AmapSearchEvent) __);
}


/// Adds pattern-matching-related methods to [AmapSearchEvent].
extension AmapSearchEventPatterns on AmapSearchEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrgsLoadRequested value)?  orgsLoadRequested,TResult Function( OrgSelected value)?  orgSelected,TResult Function( JoinFormSubmitted value)?  joinFormSubmitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrgsLoadRequested() when orgsLoadRequested != null:
return orgsLoadRequested(_that);case OrgSelected() when orgSelected != null:
return orgSelected(_that);case JoinFormSubmitted() when joinFormSubmitted != null:
return joinFormSubmitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrgsLoadRequested value)  orgsLoadRequested,required TResult Function( OrgSelected value)  orgSelected,required TResult Function( JoinFormSubmitted value)  joinFormSubmitted,}){
final _that = this;
switch (_that) {
case OrgsLoadRequested():
return orgsLoadRequested(_that);case OrgSelected():
return orgSelected(_that);case JoinFormSubmitted():
return joinFormSubmitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrgsLoadRequested value)?  orgsLoadRequested,TResult? Function( OrgSelected value)?  orgSelected,TResult? Function( JoinFormSubmitted value)?  joinFormSubmitted,}){
final _that = this;
switch (_that) {
case OrgsLoadRequested() when orgsLoadRequested != null:
return orgsLoadRequested(_that);case OrgSelected() when orgSelected != null:
return orgSelected(_that);case JoinFormSubmitted() when joinFormSubmitted != null:
return joinFormSubmitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  orgsLoadRequested,TResult Function( Organization org)?  orgSelected,TResult Function( String firstName,  String lastName,  String email)?  joinFormSubmitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrgsLoadRequested() when orgsLoadRequested != null:
return orgsLoadRequested();case OrgSelected() when orgSelected != null:
return orgSelected(_that.org);case JoinFormSubmitted() when joinFormSubmitted != null:
return joinFormSubmitted(_that.firstName,_that.lastName,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  orgsLoadRequested,required TResult Function( Organization org)  orgSelected,required TResult Function( String firstName,  String lastName,  String email)  joinFormSubmitted,}) {final _that = this;
switch (_that) {
case OrgsLoadRequested():
return orgsLoadRequested();case OrgSelected():
return orgSelected(_that.org);case JoinFormSubmitted():
return joinFormSubmitted(_that.firstName,_that.lastName,_that.email);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  orgsLoadRequested,TResult? Function( Organization org)?  orgSelected,TResult? Function( String firstName,  String lastName,  String email)?  joinFormSubmitted,}) {final _that = this;
switch (_that) {
case OrgsLoadRequested() when orgsLoadRequested != null:
return orgsLoadRequested();case OrgSelected() when orgSelected != null:
return orgSelected(_that.org);case JoinFormSubmitted() when joinFormSubmitted != null:
return joinFormSubmitted(_that.firstName,_that.lastName,_that.email);case _:
  return null;

}
}

}

/// @nodoc


class OrgsLoadRequested implements AmapSearchEvent {
  const OrgsLoadRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgsLoadRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AmapSearchEvent.orgsLoadRequested()';
}


}




/// @nodoc


class OrgSelected implements AmapSearchEvent {
  const OrgSelected(this.org);
  

 final  Organization org;

/// Create a copy of AmapSearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrgSelectedCopyWith<OrgSelected> get copyWith => _$OrgSelectedCopyWithImpl<OrgSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrgSelected&&(identical(other.org, org) || other.org == org));
}


@override
int get hashCode => Object.hash(runtimeType,org);

@override
String toString() {
  return 'AmapSearchEvent.orgSelected(org: $org)';
}


}

/// @nodoc
abstract mixin class $OrgSelectedCopyWith<$Res> implements $AmapSearchEventCopyWith<$Res> {
  factory $OrgSelectedCopyWith(OrgSelected value, $Res Function(OrgSelected) _then) = _$OrgSelectedCopyWithImpl;
@useResult
$Res call({
 Organization org
});


$OrganizationCopyWith<$Res> get org;

}
/// @nodoc
class _$OrgSelectedCopyWithImpl<$Res>
    implements $OrgSelectedCopyWith<$Res> {
  _$OrgSelectedCopyWithImpl(this._self, this._then);

  final OrgSelected _self;
  final $Res Function(OrgSelected) _then;

/// Create a copy of AmapSearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? org = null,}) {
  return _then(OrgSelected(
null == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as Organization,
  ));
}

/// Create a copy of AmapSearchEvent
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


class JoinFormSubmitted implements AmapSearchEvent {
  const JoinFormSubmitted({required this.firstName, required this.lastName, required this.email});
  

 final  String firstName;
 final  String lastName;
 final  String email;

/// Create a copy of AmapSearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinFormSubmittedCopyWith<JoinFormSubmitted> get copyWith => _$JoinFormSubmittedCopyWithImpl<JoinFormSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinFormSubmitted&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,firstName,lastName,email);

@override
String toString() {
  return 'AmapSearchEvent.joinFormSubmitted(firstName: $firstName, lastName: $lastName, email: $email)';
}


}

/// @nodoc
abstract mixin class $JoinFormSubmittedCopyWith<$Res> implements $AmapSearchEventCopyWith<$Res> {
  factory $JoinFormSubmittedCopyWith(JoinFormSubmitted value, $Res Function(JoinFormSubmitted) _then) = _$JoinFormSubmittedCopyWithImpl;
@useResult
$Res call({
 String firstName, String lastName, String email
});




}
/// @nodoc
class _$JoinFormSubmittedCopyWithImpl<$Res>
    implements $JoinFormSubmittedCopyWith<$Res> {
  _$JoinFormSubmittedCopyWithImpl(this._self, this._then);

  final JoinFormSubmitted _self;
  final $Res Function(JoinFormSubmitted) _then;

/// Create a copy of AmapSearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? firstName = null,Object? lastName = null,Object? email = null,}) {
  return _then(JoinFormSubmitted(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
