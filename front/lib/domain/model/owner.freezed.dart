// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'owner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Owner {

@JsonKey(name: 'owner_id') String get ownerId;@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'last_name') String get lastName; String get email; String? get phone;@JsonKey(name: 'account_status') AccountStatus get accountStatus;@JsonKey(name: 'registered_at') String get registeredAt;@JsonKey(name: 'updated_at') String get updatedAt;@JsonKey(name: 'user_preferences') UserPreferences? get userPreferences;
/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnerCopyWith<Owner> get copyWith => _$OwnerCopyWithImpl<Owner>(this as Owner, _$identity);

  /// Serializes this Owner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Owner&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.accountStatus, accountStatus) || other.accountStatus == accountStatus)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userPreferences, userPreferences) || other.userPreferences == userPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ownerId,firstName,lastName,email,phone,accountStatus,registeredAt,updatedAt,userPreferences);

@override
String toString() {
  return 'Owner(ownerId: $ownerId, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, accountStatus: $accountStatus, registeredAt: $registeredAt, updatedAt: $updatedAt, userPreferences: $userPreferences)';
}


}

/// @nodoc
abstract mixin class $OwnerCopyWith<$Res>  {
  factory $OwnerCopyWith(Owner value, $Res Function(Owner) _then) = _$OwnerCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, String email, String? phone,@JsonKey(name: 'account_status') AccountStatus accountStatus,@JsonKey(name: 'registered_at') String registeredAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'user_preferences') UserPreferences? userPreferences
});


$UserPreferencesCopyWith<$Res>? get userPreferences;

}
/// @nodoc
class _$OwnerCopyWithImpl<$Res>
    implements $OwnerCopyWith<$Res> {
  _$OwnerCopyWithImpl(this._self, this._then);

  final Owner _self;
  final $Res Function(Owner) _then;

/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ownerId = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? phone = freezed,Object? accountStatus = null,Object? registeredAt = null,Object? updatedAt = null,Object? userPreferences = freezed,}) {
  return _then(_self.copyWith(
ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,accountStatus: null == accountStatus ? _self.accountStatus : accountStatus // ignore: cast_nullable_to_non_nullable
as AccountStatus,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,userPreferences: freezed == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as UserPreferences?,
  ));
}
/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserPreferencesCopyWith<$Res>? get userPreferences {
    if (_self.userPreferences == null) {
    return null;
  }

  return $UserPreferencesCopyWith<$Res>(_self.userPreferences!, (value) {
    return _then(_self.copyWith(userPreferences: value));
  });
}
}


/// Adds pattern-matching-related methods to [Owner].
extension OwnerPatterns on Owner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Owner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Owner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Owner value)  $default,){
final _that = this;
switch (_that) {
case _Owner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Owner value)?  $default,){
final _that = this;
switch (_that) {
case _Owner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String email,  String? phone, @JsonKey(name: 'account_status')  AccountStatus accountStatus, @JsonKey(name: 'registered_at')  String registeredAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Owner() when $default != null:
return $default(_that.ownerId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.accountStatus,_that.registeredAt,_that.updatedAt,_that.userPreferences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String email,  String? phone, @JsonKey(name: 'account_status')  AccountStatus accountStatus, @JsonKey(name: 'registered_at')  String registeredAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences)  $default,) {final _that = this;
switch (_that) {
case _Owner():
return $default(_that.ownerId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.accountStatus,_that.registeredAt,_that.updatedAt,_that.userPreferences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String email,  String? phone, @JsonKey(name: 'account_status')  AccountStatus accountStatus, @JsonKey(name: 'registered_at')  String registeredAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences)?  $default,) {final _that = this;
switch (_that) {
case _Owner() when $default != null:
return $default(_that.ownerId,_that.firstName,_that.lastName,_that.email,_that.phone,_that.accountStatus,_that.registeredAt,_that.updatedAt,_that.userPreferences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Owner implements Owner {
  const _Owner({@JsonKey(name: 'owner_id') required this.ownerId, @JsonKey(name: 'first_name') required this.firstName, @JsonKey(name: 'last_name') required this.lastName, required this.email, this.phone, @JsonKey(name: 'account_status') this.accountStatus = AccountStatus.active, @JsonKey(name: 'registered_at') required this.registeredAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'user_preferences') this.userPreferences});
  factory _Owner.fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);

@override@JsonKey(name: 'owner_id') final  String ownerId;
@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'last_name') final  String lastName;
@override final  String email;
@override final  String? phone;
@override@JsonKey(name: 'account_status') final  AccountStatus accountStatus;
@override@JsonKey(name: 'registered_at') final  String registeredAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;
@override@JsonKey(name: 'user_preferences') final  UserPreferences? userPreferences;

/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnerCopyWith<_Owner> get copyWith => __$OwnerCopyWithImpl<_Owner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Owner&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.accountStatus, accountStatus) || other.accountStatus == accountStatus)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userPreferences, userPreferences) || other.userPreferences == userPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ownerId,firstName,lastName,email,phone,accountStatus,registeredAt,updatedAt,userPreferences);

@override
String toString() {
  return 'Owner(ownerId: $ownerId, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, accountStatus: $accountStatus, registeredAt: $registeredAt, updatedAt: $updatedAt, userPreferences: $userPreferences)';
}


}

/// @nodoc
abstract mixin class _$OwnerCopyWith<$Res> implements $OwnerCopyWith<$Res> {
  factory _$OwnerCopyWith(_Owner value, $Res Function(_Owner) _then) = __$OwnerCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, String email, String? phone,@JsonKey(name: 'account_status') AccountStatus accountStatus,@JsonKey(name: 'registered_at') String registeredAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'user_preferences') UserPreferences? userPreferences
});


@override $UserPreferencesCopyWith<$Res>? get userPreferences;

}
/// @nodoc
class __$OwnerCopyWithImpl<$Res>
    implements _$OwnerCopyWith<$Res> {
  __$OwnerCopyWithImpl(this._self, this._then);

  final _Owner _self;
  final $Res Function(_Owner) _then;

/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ownerId = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? phone = freezed,Object? accountStatus = null,Object? registeredAt = null,Object? updatedAt = null,Object? userPreferences = freezed,}) {
  return _then(_Owner(
ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,accountStatus: null == accountStatus ? _self.accountStatus : accountStatus // ignore: cast_nullable_to_non_nullable
as AccountStatus,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,userPreferences: freezed == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as UserPreferences?,
  ));
}

/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserPreferencesCopyWith<$Res>? get userPreferences {
    if (_self.userPreferences == null) {
    return null;
  }

  return $UserPreferencesCopyWith<$Res>(_self.userPreferences!, (value) {
    return _then(_self.copyWith(userPreferences: value));
  });
}
}

// dart format on
