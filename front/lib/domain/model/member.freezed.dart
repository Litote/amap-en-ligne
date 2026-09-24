// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberContract {

@JsonKey(name: 'contract_id') String get contractId;@JsonKey(name: 'subscription_instant') String get subscriptionInstant; MemberContractStatus get status;
/// Create a copy of MemberContract
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberContractCopyWith<MemberContract> get copyWith => _$MemberContractCopyWithImpl<MemberContract>(this as MemberContract, _$identity);

  /// Serializes this MemberContract to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberContract;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberContract&&(identical(other.contractId, _this.contractId) || other.contractId == _this.contractId)&&(identical(other.subscriptionInstant, _this.subscriptionInstant) || other.subscriptionInstant == _this.subscriptionInstant)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberContract;
  return Object.hash(runtimeType,_this.contractId,_this.subscriptionInstant,_this.status);
}

@override
String toString() {
  final _this = this as MemberContract;
  return 'MemberContract(contractId: ${_this.contractId}, subscriptionInstant: ${_this.subscriptionInstant}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $MemberContractCopyWith<$Res>  {
  factory $MemberContractCopyWith(MemberContract value, $Res Function(MemberContract) _then) = _$MemberContractCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'subscription_instant') String subscriptionInstant, MemberContractStatus status
});




}
/// @nodoc
class _$MemberContractCopyWithImpl<$Res>
    implements $MemberContractCopyWith<$Res> {
  _$MemberContractCopyWithImpl(this._self, this._then);

  final MemberContract _self;
  final $Res Function(MemberContract) _then;

/// Create a copy of MemberContract
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractId = null,Object? subscriptionInstant = null,Object? status = null,}) {
  return _then(MemberContract(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,subscriptionInstant: null == subscriptionInstant ? _self.subscriptionInstant : subscriptionInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberContractStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberContract].
extension MemberContractPatterns on MemberContract {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberContract value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberContract() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberContract value)  $default,){
final _that = this;
switch (_that) {
case _MemberContract():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberContract value)?  $default,){
final _that = this;
switch (_that) {
case _MemberContract() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'subscription_instant')  String subscriptionInstant,  MemberContractStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberContract() when $default != null:
return $default(_that.contractId,_that.subscriptionInstant,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'subscription_instant')  String subscriptionInstant,  MemberContractStatus status)  $default,) {final _that = this;
switch (_that) {
case _MemberContract():
return $default(_that.contractId,_that.subscriptionInstant,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'subscription_instant')  String subscriptionInstant,  MemberContractStatus status)?  $default,) {final _that = this;
switch (_that) {
case _MemberContract() when $default != null:
return $default(_that.contractId,_that.subscriptionInstant,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberContract implements MemberContract {
  const _MemberContract({@JsonKey(name: 'contract_id') required this.contractId, @JsonKey(name: 'subscription_instant') required this.subscriptionInstant, required this.status});
  factory _MemberContract.fromJson(Map<String, dynamic> json) => _$MemberContractFromJson(json);

@override@JsonKey(name: 'contract_id') final  String contractId;
@override@JsonKey(name: 'subscription_instant') final  String subscriptionInstant;
@override final  MemberContractStatus status;

/// Create a copy of MemberContract
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberContractCopyWith<_MemberContract> get copyWith => __$MemberContractCopyWithImpl<_MemberContract>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberContractToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberContract&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.subscriptionInstant, subscriptionInstant) || other.subscriptionInstant == subscriptionInstant)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,contractId,subscriptionInstant,status);
}

@override
String toString() {
    return 'MemberContract(contractId: $contractId, subscriptionInstant: $subscriptionInstant, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MemberContractCopyWith<$Res> implements $MemberContractCopyWith<$Res> {
  factory _$MemberContractCopyWith(_MemberContract value, $Res Function(_MemberContract) _then) = __$MemberContractCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'subscription_instant') String subscriptionInstant, MemberContractStatus status
});




}
/// @nodoc
class __$MemberContractCopyWithImpl<$Res>
    implements _$MemberContractCopyWith<$Res> {
  __$MemberContractCopyWithImpl(this._self, this._then);

  final _MemberContract _self;
  final $Res Function(_MemberContract) _then;

/// Create a copy of MemberContract
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractId = null,Object? subscriptionInstant = null,Object? status = null,}) {
  return _then(_MemberContract(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,subscriptionInstant: null == subscriptionInstant ? _self.subscriptionInstant : subscriptionInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MemberContractStatus,
  ));
}


}


/// @nodoc
mixin _$Member {

@JsonKey(name: 'member_id') String get memberId;@JsonKey(name: 'organization_id') String get organizationId; Set<Role> get roles;@JsonKey(name: 'first_name') String? get firstName;@JsonKey(name: 'last_name') String? get lastName; String? get email; String? get phone;@JsonKey(name: 'account_status') MemberAccountStatus get accountStatus; List<MemberContract> get contracts;@JsonKey(name: 'member_preferences') MemberPreferences? get memberPreferences;@JsonKey(name: 'user_preferences') UserPreferences? get userPreferences;@JsonKey(name: 'user_settings') Map<String, dynamic>? get userSettings;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Member;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&const DeepCollectionEquality().equals(other.roles, _this.roles)&&(identical(other.firstName, _this.firstName) || other.firstName == _this.firstName)&&(identical(other.lastName, _this.lastName) || other.lastName == _this.lastName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.accountStatus, _this.accountStatus) || other.accountStatus == _this.accountStatus)&&const DeepCollectionEquality().equals(other.contracts, _this.contracts)&&(identical(other.memberPreferences, _this.memberPreferences) || other.memberPreferences == _this.memberPreferences)&&(identical(other.userPreferences, _this.userPreferences) || other.userPreferences == _this.userPreferences)&&const DeepCollectionEquality().equals(other.userSettings, _this.userSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Member;
  return Object.hash(runtimeType,_this.memberId,_this.organizationId,const DeepCollectionEquality().hash(_this.roles),_this.firstName,_this.lastName,_this.email,_this.phone,_this.accountStatus,const DeepCollectionEquality().hash(_this.contracts),_this.memberPreferences,_this.userPreferences,const DeepCollectionEquality().hash(_this.userSettings));
}

@override
String toString() {
  final _this = this as Member;
  return 'Member(memberId: ${_this.memberId}, organizationId: ${_this.organizationId}, roles: ${_this.roles}, firstName: ${_this.firstName}, lastName: ${_this.lastName}, email: ${_this.email}, phone: ${_this.phone}, accountStatus: ${_this.accountStatus}, contracts: ${_this.contracts}, memberPreferences: ${_this.memberPreferences}, userPreferences: ${_this.userPreferences}, userSettings: ${_this.userSettings})';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'member_id') String memberId,@JsonKey(name: 'organization_id') String organizationId, Set<Role> roles,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName, String? email, String? phone,@JsonKey(name: 'account_status') MemberAccountStatus accountStatus, List<MemberContract> contracts,@JsonKey(name: 'member_preferences') MemberPreferences? memberPreferences,@JsonKey(name: 'user_preferences') UserPreferences? userPreferences,@JsonKey(name: 'user_settings') Map<String, dynamic>? userSettings
});


$MemberPreferencesCopyWith<$Res>? get memberPreferences;$UserPreferencesCopyWith<$Res>? get userPreferences;

}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberId = null,Object? organizationId = null,Object? roles = null,Object? firstName = freezed,Object? lastName = freezed,Object? email = freezed,Object? phone = freezed,Object? accountStatus = null,Object? contracts = null,Object? memberPreferences = freezed,Object? userPreferences = freezed,Object? userSettings = freezed,}) {
  return _then(Member(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Set<Role>,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,accountStatus: null == accountStatus ? _self.accountStatus : accountStatus // ignore: cast_nullable_to_non_nullable
as MemberAccountStatus,contracts: null == contracts ? _self.contracts : contracts // ignore: cast_nullable_to_non_nullable
as List<MemberContract>,memberPreferences: freezed == memberPreferences ? _self.memberPreferences : memberPreferences // ignore: cast_nullable_to_non_nullable
as MemberPreferences?,userPreferences: freezed == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as UserPreferences?,userSettings: freezed == userSettings ? _self.userSettings : userSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberPreferencesCopyWith<$Res>? get memberPreferences {
    if (_self.memberPreferences == null) {
    return null;
  }

  return $MemberPreferencesCopyWith<$Res>(_self.memberPreferences!, (value) {
    return _then(_self.copyWith(memberPreferences: value));
  });
}/// Create a copy of Member
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


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'organization_id')  String organizationId,  Set<Role> roles, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName,  String? email,  String? phone, @JsonKey(name: 'account_status')  MemberAccountStatus accountStatus,  List<MemberContract> contracts, @JsonKey(name: 'member_preferences')  MemberPreferences? memberPreferences, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences, @JsonKey(name: 'user_settings')  Map<String, dynamic>? userSettings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.memberId,_that.organizationId,_that.roles,_that.firstName,_that.lastName,_that.email,_that.phone,_that.accountStatus,_that.contracts,_that.memberPreferences,_that.userPreferences,_that.userSettings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'organization_id')  String organizationId,  Set<Role> roles, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName,  String? email,  String? phone, @JsonKey(name: 'account_status')  MemberAccountStatus accountStatus,  List<MemberContract> contracts, @JsonKey(name: 'member_preferences')  MemberPreferences? memberPreferences, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences, @JsonKey(name: 'user_settings')  Map<String, dynamic>? userSettings)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.memberId,_that.organizationId,_that.roles,_that.firstName,_that.lastName,_that.email,_that.phone,_that.accountStatus,_that.contracts,_that.memberPreferences,_that.userPreferences,_that.userSettings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'organization_id')  String organizationId,  Set<Role> roles, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName,  String? email,  String? phone, @JsonKey(name: 'account_status')  MemberAccountStatus accountStatus,  List<MemberContract> contracts, @JsonKey(name: 'member_preferences')  MemberPreferences? memberPreferences, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences, @JsonKey(name: 'user_settings')  Map<String, dynamic>? userSettings)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.memberId,_that.organizationId,_that.roles,_that.firstName,_that.lastName,_that.email,_that.phone,_that.accountStatus,_that.contracts,_that.memberPreferences,_that.userPreferences,_that.userSettings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member implements Member {
  const _Member({@JsonKey(name: 'member_id') required this.memberId, @JsonKey(name: 'organization_id') required this.organizationId,  Set<Role> roles = const {Role.volunteer}, @JsonKey(name: 'first_name') this.firstName, @JsonKey(name: 'last_name') this.lastName, this.email, this.phone, @JsonKey(name: 'account_status') this.accountStatus = MemberAccountStatus.active,  List<MemberContract> contracts = const [], @JsonKey(name: 'member_preferences') this.memberPreferences, @JsonKey(name: 'user_preferences') this.userPreferences, @JsonKey(name: 'user_settings')  Map<String, dynamic>? userSettings}): _roles = roles,_contracts = contracts,_userSettings = userSettings;
  factory _Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

@override@JsonKey(name: 'member_id') final  String memberId;
@override@JsonKey(name: 'organization_id') final  String organizationId;
 final  Set<Role> _roles;
@override@JsonKey() Set<Role> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}

@override@JsonKey(name: 'first_name') final  String? firstName;
@override@JsonKey(name: 'last_name') final  String? lastName;
@override final  String? email;
@override final  String? phone;
@override@JsonKey(name: 'account_status') final  MemberAccountStatus accountStatus;
 final  List<MemberContract> _contracts;
@override@JsonKey() List<MemberContract> get contracts {
  if (_contracts is EqualUnmodifiableListView) return _contracts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contracts);
}

@override@JsonKey(name: 'member_preferences') final  MemberPreferences? memberPreferences;
@override@JsonKey(name: 'user_preferences') final  UserPreferences? userPreferences;
 final  Map<String, dynamic>? _userSettings;
@override@JsonKey(name: 'user_settings') Map<String, dynamic>? get userSettings {
  final value = _userSettings;
  if (value == null) return null;
  if (_userSettings is EqualUnmodifiableMapView) return _userSettings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other.roles, _roles)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.accountStatus, accountStatus) || other.accountStatus == accountStatus)&&const DeepCollectionEquality().equals(other.contracts, _contracts)&&(identical(other.memberPreferences, memberPreferences) || other.memberPreferences == memberPreferences)&&(identical(other.userPreferences, userPreferences) || other.userPreferences == userPreferences)&&const DeepCollectionEquality().equals(other.userSettings, _userSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,memberId,organizationId,const DeepCollectionEquality().hash(_roles),firstName,lastName,email,phone,accountStatus,const DeepCollectionEquality().hash(_contracts),memberPreferences,userPreferences,const DeepCollectionEquality().hash(_userSettings));
}

@override
String toString() {
    return 'Member(memberId: $memberId, organizationId: $organizationId, roles: $roles, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, accountStatus: $accountStatus, contracts: $contracts, memberPreferences: $memberPreferences, userPreferences: $userPreferences, userSettings: $userSettings)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'member_id') String memberId,@JsonKey(name: 'organization_id') String organizationId, Set<Role> roles,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName, String? email, String? phone,@JsonKey(name: 'account_status') MemberAccountStatus accountStatus, List<MemberContract> contracts,@JsonKey(name: 'member_preferences') MemberPreferences? memberPreferences,@JsonKey(name: 'user_preferences') UserPreferences? userPreferences,@JsonKey(name: 'user_settings') Map<String, dynamic>? userSettings
});


@override $MemberPreferencesCopyWith<$Res>? get memberPreferences;@override $UserPreferencesCopyWith<$Res>? get userPreferences;

}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? organizationId = null,Object? roles = null,Object? firstName = freezed,Object? lastName = freezed,Object? email = freezed,Object? phone = freezed,Object? accountStatus = null,Object? contracts = null,Object? memberPreferences = freezed,Object? userPreferences = freezed,Object? userSettings = freezed,}) {
  return _then(_Member(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<Role>,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,accountStatus: null == accountStatus ? _self.accountStatus : accountStatus // ignore: cast_nullable_to_non_nullable
as MemberAccountStatus,contracts: null == contracts ? _self._contracts : contracts // ignore: cast_nullable_to_non_nullable
as List<MemberContract>,memberPreferences: freezed == memberPreferences ? _self.memberPreferences : memberPreferences // ignore: cast_nullable_to_non_nullable
as MemberPreferences?,userPreferences: freezed == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as UserPreferences?,userSettings: freezed == userSettings ? _self._userSettings : userSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberPreferencesCopyWith<$Res>? get memberPreferences {
    if (_self.memberPreferences == null) {
    return null;
  }

  return $MemberPreferencesCopyWith<$Res>(_self.memberPreferences!, (value) {
    return _then(_self.copyWith(memberPreferences: value));
  });
}/// Create a copy of Member
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
