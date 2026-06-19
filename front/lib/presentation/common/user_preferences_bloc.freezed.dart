// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserPreferencesEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferencesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPreferencesEvent()';
}


}

/// @nodoc
class $UserPreferencesEventCopyWith<$Res>  {
$UserPreferencesEventCopyWith(UserPreferencesEvent _, $Res Function(UserPreferencesEvent) __);
}


/// Adds pattern-matching-related methods to [UserPreferencesEvent].
extension UserPreferencesEventPatterns on UserPreferencesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _UserPreferencesLoaded value)?  loaded,TResult Function( _UserPreferencesOwnerLoaded value)?  ownerLoaded,TResult Function( _UserPreferencesProducerLoaded value)?  producerLoaded,TResult Function( _UserPreferencesReminderToggled value)?  reminderToggled,TResult Function( _UserPreferencesAlertToggled value)?  alertToggled,TResult Function( _UserPreferencesChannelToggled value)?  channelToggled,TResult Function( _UserPreferencesSaved value)?  saved,TResult Function( _UserPreferencesProfileSaved value)?  profileSaved,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPreferencesLoaded() when loaded != null:
return loaded(_that);case _UserPreferencesOwnerLoaded() when ownerLoaded != null:
return ownerLoaded(_that);case _UserPreferencesProducerLoaded() when producerLoaded != null:
return producerLoaded(_that);case _UserPreferencesReminderToggled() when reminderToggled != null:
return reminderToggled(_that);case _UserPreferencesAlertToggled() when alertToggled != null:
return alertToggled(_that);case _UserPreferencesChannelToggled() when channelToggled != null:
return channelToggled(_that);case _UserPreferencesSaved() when saved != null:
return saved(_that);case _UserPreferencesProfileSaved() when profileSaved != null:
return profileSaved(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _UserPreferencesLoaded value)  loaded,required TResult Function( _UserPreferencesOwnerLoaded value)  ownerLoaded,required TResult Function( _UserPreferencesProducerLoaded value)  producerLoaded,required TResult Function( _UserPreferencesReminderToggled value)  reminderToggled,required TResult Function( _UserPreferencesAlertToggled value)  alertToggled,required TResult Function( _UserPreferencesChannelToggled value)  channelToggled,required TResult Function( _UserPreferencesSaved value)  saved,required TResult Function( _UserPreferencesProfileSaved value)  profileSaved,}){
final _that = this;
switch (_that) {
case _UserPreferencesLoaded():
return loaded(_that);case _UserPreferencesOwnerLoaded():
return ownerLoaded(_that);case _UserPreferencesProducerLoaded():
return producerLoaded(_that);case _UserPreferencesReminderToggled():
return reminderToggled(_that);case _UserPreferencesAlertToggled():
return alertToggled(_that);case _UserPreferencesChannelToggled():
return channelToggled(_that);case _UserPreferencesSaved():
return saved(_that);case _UserPreferencesProfileSaved():
return profileSaved(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _UserPreferencesLoaded value)?  loaded,TResult? Function( _UserPreferencesOwnerLoaded value)?  ownerLoaded,TResult? Function( _UserPreferencesProducerLoaded value)?  producerLoaded,TResult? Function( _UserPreferencesReminderToggled value)?  reminderToggled,TResult? Function( _UserPreferencesAlertToggled value)?  alertToggled,TResult? Function( _UserPreferencesChannelToggled value)?  channelToggled,TResult? Function( _UserPreferencesSaved value)?  saved,TResult? Function( _UserPreferencesProfileSaved value)?  profileSaved,}){
final _that = this;
switch (_that) {
case _UserPreferencesLoaded() when loaded != null:
return loaded(_that);case _UserPreferencesOwnerLoaded() when ownerLoaded != null:
return ownerLoaded(_that);case _UserPreferencesProducerLoaded() when producerLoaded != null:
return producerLoaded(_that);case _UserPreferencesReminderToggled() when reminderToggled != null:
return reminderToggled(_that);case _UserPreferencesAlertToggled() when alertToggled != null:
return alertToggled(_that);case _UserPreferencesChannelToggled() when channelToggled != null:
return channelToggled(_that);case _UserPreferencesSaved() when saved != null:
return saved(_that);case _UserPreferencesProfileSaved() when profileSaved != null:
return profileSaved(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Member? member)?  loaded,TResult Function( Owner? owner)?  ownerLoaded,TResult Function( ProducerAccount? producerAccount)?  producerLoaded,TResult Function( ReminderField field,  bool value)?  reminderToggled,TResult Function( AlertField field,  bool value)?  alertToggled,TResult Function( ChannelField field,  bool value)?  channelToggled,TResult Function()?  saved,TResult Function( String? firstName,  String? lastName,  String? email,  String? phone,  String? producerName,  String? contactEmail,  String? address,  String? website)?  profileSaved,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPreferencesLoaded() when loaded != null:
return loaded(_that.member);case _UserPreferencesOwnerLoaded() when ownerLoaded != null:
return ownerLoaded(_that.owner);case _UserPreferencesProducerLoaded() when producerLoaded != null:
return producerLoaded(_that.producerAccount);case _UserPreferencesReminderToggled() when reminderToggled != null:
return reminderToggled(_that.field,_that.value);case _UserPreferencesAlertToggled() when alertToggled != null:
return alertToggled(_that.field,_that.value);case _UserPreferencesChannelToggled() when channelToggled != null:
return channelToggled(_that.field,_that.value);case _UserPreferencesSaved() when saved != null:
return saved();case _UserPreferencesProfileSaved() when profileSaved != null:
return profileSaved(_that.firstName,_that.lastName,_that.email,_that.phone,_that.producerName,_that.contactEmail,_that.address,_that.website);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Member? member)  loaded,required TResult Function( Owner? owner)  ownerLoaded,required TResult Function( ProducerAccount? producerAccount)  producerLoaded,required TResult Function( ReminderField field,  bool value)  reminderToggled,required TResult Function( AlertField field,  bool value)  alertToggled,required TResult Function( ChannelField field,  bool value)  channelToggled,required TResult Function()  saved,required TResult Function( String? firstName,  String? lastName,  String? email,  String? phone,  String? producerName,  String? contactEmail,  String? address,  String? website)  profileSaved,}) {final _that = this;
switch (_that) {
case _UserPreferencesLoaded():
return loaded(_that.member);case _UserPreferencesOwnerLoaded():
return ownerLoaded(_that.owner);case _UserPreferencesProducerLoaded():
return producerLoaded(_that.producerAccount);case _UserPreferencesReminderToggled():
return reminderToggled(_that.field,_that.value);case _UserPreferencesAlertToggled():
return alertToggled(_that.field,_that.value);case _UserPreferencesChannelToggled():
return channelToggled(_that.field,_that.value);case _UserPreferencesSaved():
return saved();case _UserPreferencesProfileSaved():
return profileSaved(_that.firstName,_that.lastName,_that.email,_that.phone,_that.producerName,_that.contactEmail,_that.address,_that.website);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Member? member)?  loaded,TResult? Function( Owner? owner)?  ownerLoaded,TResult? Function( ProducerAccount? producerAccount)?  producerLoaded,TResult? Function( ReminderField field,  bool value)?  reminderToggled,TResult? Function( AlertField field,  bool value)?  alertToggled,TResult? Function( ChannelField field,  bool value)?  channelToggled,TResult? Function()?  saved,TResult? Function( String? firstName,  String? lastName,  String? email,  String? phone,  String? producerName,  String? contactEmail,  String? address,  String? website)?  profileSaved,}) {final _that = this;
switch (_that) {
case _UserPreferencesLoaded() when loaded != null:
return loaded(_that.member);case _UserPreferencesOwnerLoaded() when ownerLoaded != null:
return ownerLoaded(_that.owner);case _UserPreferencesProducerLoaded() when producerLoaded != null:
return producerLoaded(_that.producerAccount);case _UserPreferencesReminderToggled() when reminderToggled != null:
return reminderToggled(_that.field,_that.value);case _UserPreferencesAlertToggled() when alertToggled != null:
return alertToggled(_that.field,_that.value);case _UserPreferencesChannelToggled() when channelToggled != null:
return channelToggled(_that.field,_that.value);case _UserPreferencesSaved() when saved != null:
return saved();case _UserPreferencesProfileSaved() when profileSaved != null:
return profileSaved(_that.firstName,_that.lastName,_that.email,_that.phone,_that.producerName,_that.contactEmail,_that.address,_that.website);case _:
  return null;

}
}

}

/// @nodoc


class _UserPreferencesLoaded implements UserPreferencesEvent {
  const _UserPreferencesLoaded(this.member);
  

 final  Member? member;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesLoadedCopyWith<_UserPreferencesLoaded> get copyWith => __$UserPreferencesLoadedCopyWithImpl<_UserPreferencesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesLoaded&&(identical(other.member, member) || other.member == member));
}


@override
int get hashCode => Object.hash(runtimeType,member);

@override
String toString() {
  return 'UserPreferencesEvent.loaded(member: $member)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesLoadedCopyWith<$Res> implements $UserPreferencesEventCopyWith<$Res> {
  factory _$UserPreferencesLoadedCopyWith(_UserPreferencesLoaded value, $Res Function(_UserPreferencesLoaded) _then) = __$UserPreferencesLoadedCopyWithImpl;
@useResult
$Res call({
 Member? member
});


$MemberCopyWith<$Res>? get member;

}
/// @nodoc
class __$UserPreferencesLoadedCopyWithImpl<$Res>
    implements _$UserPreferencesLoadedCopyWith<$Res> {
  __$UserPreferencesLoadedCopyWithImpl(this._self, this._then);

  final _UserPreferencesLoaded _self;
  final $Res Function(_UserPreferencesLoaded) _then;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? member = freezed,}) {
  return _then(_UserPreferencesLoaded(
freezed == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as Member?,
  ));
}

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberCopyWith<$Res>? get member {
    if (_self.member == null) {
    return null;
  }

  return $MemberCopyWith<$Res>(_self.member!, (value) {
    return _then(_self.copyWith(member: value));
  });
}
}

/// @nodoc


class _UserPreferencesOwnerLoaded implements UserPreferencesEvent {
  const _UserPreferencesOwnerLoaded(this.owner);
  

 final  Owner? owner;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesOwnerLoadedCopyWith<_UserPreferencesOwnerLoaded> get copyWith => __$UserPreferencesOwnerLoadedCopyWithImpl<_UserPreferencesOwnerLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesOwnerLoaded&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,owner);

@override
String toString() {
  return 'UserPreferencesEvent.ownerLoaded(owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesOwnerLoadedCopyWith<$Res> implements $UserPreferencesEventCopyWith<$Res> {
  factory _$UserPreferencesOwnerLoadedCopyWith(_UserPreferencesOwnerLoaded value, $Res Function(_UserPreferencesOwnerLoaded) _then) = __$UserPreferencesOwnerLoadedCopyWithImpl;
@useResult
$Res call({
 Owner? owner
});


$OwnerCopyWith<$Res>? get owner;

}
/// @nodoc
class __$UserPreferencesOwnerLoadedCopyWithImpl<$Res>
    implements _$UserPreferencesOwnerLoadedCopyWith<$Res> {
  __$UserPreferencesOwnerLoadedCopyWithImpl(this._self, this._then);

  final _UserPreferencesOwnerLoaded _self;
  final $Res Function(_UserPreferencesOwnerLoaded) _then;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? owner = freezed,}) {
  return _then(_UserPreferencesOwnerLoaded(
freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as Owner?,
  ));
}

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $OwnerCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc


class _UserPreferencesProducerLoaded implements UserPreferencesEvent {
  const _UserPreferencesProducerLoaded(this.producerAccount);
  

 final  ProducerAccount? producerAccount;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesProducerLoadedCopyWith<_UserPreferencesProducerLoaded> get copyWith => __$UserPreferencesProducerLoadedCopyWithImpl<_UserPreferencesProducerLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesProducerLoaded&&(identical(other.producerAccount, producerAccount) || other.producerAccount == producerAccount));
}


@override
int get hashCode => Object.hash(runtimeType,producerAccount);

@override
String toString() {
  return 'UserPreferencesEvent.producerLoaded(producerAccount: $producerAccount)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesProducerLoadedCopyWith<$Res> implements $UserPreferencesEventCopyWith<$Res> {
  factory _$UserPreferencesProducerLoadedCopyWith(_UserPreferencesProducerLoaded value, $Res Function(_UserPreferencesProducerLoaded) _then) = __$UserPreferencesProducerLoadedCopyWithImpl;
@useResult
$Res call({
 ProducerAccount? producerAccount
});


$ProducerAccountCopyWith<$Res>? get producerAccount;

}
/// @nodoc
class __$UserPreferencesProducerLoadedCopyWithImpl<$Res>
    implements _$UserPreferencesProducerLoadedCopyWith<$Res> {
  __$UserPreferencesProducerLoadedCopyWithImpl(this._self, this._then);

  final _UserPreferencesProducerLoaded _self;
  final $Res Function(_UserPreferencesProducerLoaded) _then;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? producerAccount = freezed,}) {
  return _then(_UserPreferencesProducerLoaded(
freezed == producerAccount ? _self.producerAccount : producerAccount // ignore: cast_nullable_to_non_nullable
as ProducerAccount?,
  ));
}

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProducerAccountCopyWith<$Res>? get producerAccount {
    if (_self.producerAccount == null) {
    return null;
  }

  return $ProducerAccountCopyWith<$Res>(_self.producerAccount!, (value) {
    return _then(_self.copyWith(producerAccount: value));
  });
}
}

/// @nodoc


class _UserPreferencesReminderToggled implements UserPreferencesEvent {
  const _UserPreferencesReminderToggled(this.field, this.value);
  

 final  ReminderField field;
 final  bool value;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesReminderToggledCopyWith<_UserPreferencesReminderToggled> get copyWith => __$UserPreferencesReminderToggledCopyWithImpl<_UserPreferencesReminderToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesReminderToggled&&(identical(other.field, field) || other.field == field)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,field,value);

@override
String toString() {
  return 'UserPreferencesEvent.reminderToggled(field: $field, value: $value)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesReminderToggledCopyWith<$Res> implements $UserPreferencesEventCopyWith<$Res> {
  factory _$UserPreferencesReminderToggledCopyWith(_UserPreferencesReminderToggled value, $Res Function(_UserPreferencesReminderToggled) _then) = __$UserPreferencesReminderToggledCopyWithImpl;
@useResult
$Res call({
 ReminderField field, bool value
});




}
/// @nodoc
class __$UserPreferencesReminderToggledCopyWithImpl<$Res>
    implements _$UserPreferencesReminderToggledCopyWith<$Res> {
  __$UserPreferencesReminderToggledCopyWithImpl(this._self, this._then);

  final _UserPreferencesReminderToggled _self;
  final $Res Function(_UserPreferencesReminderToggled) _then;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? value = null,}) {
  return _then(_UserPreferencesReminderToggled(
null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as ReminderField,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _UserPreferencesAlertToggled implements UserPreferencesEvent {
  const _UserPreferencesAlertToggled(this.field, this.value);
  

 final  AlertField field;
 final  bool value;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesAlertToggledCopyWith<_UserPreferencesAlertToggled> get copyWith => __$UserPreferencesAlertToggledCopyWithImpl<_UserPreferencesAlertToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesAlertToggled&&(identical(other.field, field) || other.field == field)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,field,value);

@override
String toString() {
  return 'UserPreferencesEvent.alertToggled(field: $field, value: $value)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesAlertToggledCopyWith<$Res> implements $UserPreferencesEventCopyWith<$Res> {
  factory _$UserPreferencesAlertToggledCopyWith(_UserPreferencesAlertToggled value, $Res Function(_UserPreferencesAlertToggled) _then) = __$UserPreferencesAlertToggledCopyWithImpl;
@useResult
$Res call({
 AlertField field, bool value
});




}
/// @nodoc
class __$UserPreferencesAlertToggledCopyWithImpl<$Res>
    implements _$UserPreferencesAlertToggledCopyWith<$Res> {
  __$UserPreferencesAlertToggledCopyWithImpl(this._self, this._then);

  final _UserPreferencesAlertToggled _self;
  final $Res Function(_UserPreferencesAlertToggled) _then;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? value = null,}) {
  return _then(_UserPreferencesAlertToggled(
null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as AlertField,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _UserPreferencesChannelToggled implements UserPreferencesEvent {
  const _UserPreferencesChannelToggled(this.field, this.value);
  

 final  ChannelField field;
 final  bool value;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesChannelToggledCopyWith<_UserPreferencesChannelToggled> get copyWith => __$UserPreferencesChannelToggledCopyWithImpl<_UserPreferencesChannelToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesChannelToggled&&(identical(other.field, field) || other.field == field)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,field,value);

@override
String toString() {
  return 'UserPreferencesEvent.channelToggled(field: $field, value: $value)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesChannelToggledCopyWith<$Res> implements $UserPreferencesEventCopyWith<$Res> {
  factory _$UserPreferencesChannelToggledCopyWith(_UserPreferencesChannelToggled value, $Res Function(_UserPreferencesChannelToggled) _then) = __$UserPreferencesChannelToggledCopyWithImpl;
@useResult
$Res call({
 ChannelField field, bool value
});




}
/// @nodoc
class __$UserPreferencesChannelToggledCopyWithImpl<$Res>
    implements _$UserPreferencesChannelToggledCopyWith<$Res> {
  __$UserPreferencesChannelToggledCopyWithImpl(this._self, this._then);

  final _UserPreferencesChannelToggled _self;
  final $Res Function(_UserPreferencesChannelToggled) _then;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? value = null,}) {
  return _then(_UserPreferencesChannelToggled(
null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as ChannelField,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _UserPreferencesSaved implements UserPreferencesEvent {
  const _UserPreferencesSaved();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesSaved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPreferencesEvent.saved()';
}


}




/// @nodoc


class _UserPreferencesProfileSaved implements UserPreferencesEvent {
  const _UserPreferencesProfileSaved({this.firstName, this.lastName, this.email, this.phone, this.producerName, this.contactEmail, this.address, this.website});
  

 final  String? firstName;
 final  String? lastName;
 final  String? email;
 final  String? phone;
 final  String? producerName;
 final  String? contactEmail;
 final  String? address;
 final  String? website;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesProfileSavedCopyWith<_UserPreferencesProfileSaved> get copyWith => __$UserPreferencesProfileSavedCopyWithImpl<_UserPreferencesProfileSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesProfileSaved&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.producerName, producerName) || other.producerName == producerName)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.address, address) || other.address == address)&&(identical(other.website, website) || other.website == website));
}


@override
int get hashCode => Object.hash(runtimeType,firstName,lastName,email,phone,producerName,contactEmail,address,website);

@override
String toString() {
  return 'UserPreferencesEvent.profileSaved(firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, producerName: $producerName, contactEmail: $contactEmail, address: $address, website: $website)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesProfileSavedCopyWith<$Res> implements $UserPreferencesEventCopyWith<$Res> {
  factory _$UserPreferencesProfileSavedCopyWith(_UserPreferencesProfileSaved value, $Res Function(_UserPreferencesProfileSaved) _then) = __$UserPreferencesProfileSavedCopyWithImpl;
@useResult
$Res call({
 String? firstName, String? lastName, String? email, String? phone, String? producerName, String? contactEmail, String? address, String? website
});




}
/// @nodoc
class __$UserPreferencesProfileSavedCopyWithImpl<$Res>
    implements _$UserPreferencesProfileSavedCopyWith<$Res> {
  __$UserPreferencesProfileSavedCopyWithImpl(this._self, this._then);

  final _UserPreferencesProfileSaved _self;
  final $Res Function(_UserPreferencesProfileSaved) _then;

/// Create a copy of UserPreferencesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? firstName = freezed,Object? lastName = freezed,Object? email = freezed,Object? phone = freezed,Object? producerName = freezed,Object? contactEmail = freezed,Object? address = freezed,Object? website = freezed,}) {
  return _then(_UserPreferencesProfileSaved(
firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,producerName: freezed == producerName ? _self.producerName : producerName // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$UserPreferencesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferencesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPreferencesState()';
}


}

/// @nodoc
class $UserPreferencesStateCopyWith<$Res>  {
$UserPreferencesStateCopyWith(UserPreferencesState _, $Res Function(UserPreferencesState) __);
}


/// Adds pattern-matching-related methods to [UserPreferencesState].
extension UserPreferencesStatePatterns on UserPreferencesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserPreferencesLoading value)?  loading,TResult Function( UserPreferencesMissing value)?  missing,TResult Function( UserPreferencesReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserPreferencesLoading() when loading != null:
return loading(_that);case UserPreferencesMissing() when missing != null:
return missing(_that);case UserPreferencesReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserPreferencesLoading value)  loading,required TResult Function( UserPreferencesMissing value)  missing,required TResult Function( UserPreferencesReady value)  ready,}){
final _that = this;
switch (_that) {
case UserPreferencesLoading():
return loading(_that);case UserPreferencesMissing():
return missing(_that);case UserPreferencesReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserPreferencesLoading value)?  loading,TResult? Function( UserPreferencesMissing value)?  missing,TResult? Function( UserPreferencesReady value)?  ready,}){
final _that = this;
switch (_that) {
case UserPreferencesLoading() when loading != null:
return loading(_that);case UserPreferencesMissing() when missing != null:
return missing(_that);case UserPreferencesReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  missing,TResult Function( Member? member,  Owner? owner,  ProducerAccount? producerAccount,  MemberPreferences memberPreferences,  UserPreferences userPreferences,  bool dirty,  SaveStatus saveStatus,  String? saveErrorMessage,  SaveStatus profileSaveStatus,  String? profileSaveErrorMessage)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserPreferencesLoading() when loading != null:
return loading();case UserPreferencesMissing() when missing != null:
return missing();case UserPreferencesReady() when ready != null:
return ready(_that.member,_that.owner,_that.producerAccount,_that.memberPreferences,_that.userPreferences,_that.dirty,_that.saveStatus,_that.saveErrorMessage,_that.profileSaveStatus,_that.profileSaveErrorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  missing,required TResult Function( Member? member,  Owner? owner,  ProducerAccount? producerAccount,  MemberPreferences memberPreferences,  UserPreferences userPreferences,  bool dirty,  SaveStatus saveStatus,  String? saveErrorMessage,  SaveStatus profileSaveStatus,  String? profileSaveErrorMessage)  ready,}) {final _that = this;
switch (_that) {
case UserPreferencesLoading():
return loading();case UserPreferencesMissing():
return missing();case UserPreferencesReady():
return ready(_that.member,_that.owner,_that.producerAccount,_that.memberPreferences,_that.userPreferences,_that.dirty,_that.saveStatus,_that.saveErrorMessage,_that.profileSaveStatus,_that.profileSaveErrorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  missing,TResult? Function( Member? member,  Owner? owner,  ProducerAccount? producerAccount,  MemberPreferences memberPreferences,  UserPreferences userPreferences,  bool dirty,  SaveStatus saveStatus,  String? saveErrorMessage,  SaveStatus profileSaveStatus,  String? profileSaveErrorMessage)?  ready,}) {final _that = this;
switch (_that) {
case UserPreferencesLoading() when loading != null:
return loading();case UserPreferencesMissing() when missing != null:
return missing();case UserPreferencesReady() when ready != null:
return ready(_that.member,_that.owner,_that.producerAccount,_that.memberPreferences,_that.userPreferences,_that.dirty,_that.saveStatus,_that.saveErrorMessage,_that.profileSaveStatus,_that.profileSaveErrorMessage);case _:
  return null;

}
}

}

/// @nodoc


class UserPreferencesLoading implements UserPreferencesState {
  const UserPreferencesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferencesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPreferencesState.loading()';
}


}




/// @nodoc


class UserPreferencesMissing implements UserPreferencesState {
  const UserPreferencesMissing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferencesMissing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPreferencesState.missing()';
}


}




/// @nodoc


class UserPreferencesReady implements UserPreferencesState {
  const UserPreferencesReady({this.member, this.owner, this.producerAccount, required this.memberPreferences, required this.userPreferences, this.dirty = false, this.saveStatus = SaveStatus.idle, this.saveErrorMessage, this.profileSaveStatus = SaveStatus.idle, this.profileSaveErrorMessage});
  

 final  Member? member;
 final  Owner? owner;
 final  ProducerAccount? producerAccount;
 final  MemberPreferences memberPreferences;
 final  UserPreferences userPreferences;
@JsonKey() final  bool dirty;
@JsonKey() final  SaveStatus saveStatus;
 final  String? saveErrorMessage;
@JsonKey() final  SaveStatus profileSaveStatus;
 final  String? profileSaveErrorMessage;

/// Create a copy of UserPreferencesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPreferencesReadyCopyWith<UserPreferencesReady> get copyWith => _$UserPreferencesReadyCopyWithImpl<UserPreferencesReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferencesReady&&(identical(other.member, member) || other.member == member)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.producerAccount, producerAccount) || other.producerAccount == producerAccount)&&(identical(other.memberPreferences, memberPreferences) || other.memberPreferences == memberPreferences)&&(identical(other.userPreferences, userPreferences) || other.userPreferences == userPreferences)&&(identical(other.dirty, dirty) || other.dirty == dirty)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&(identical(other.saveErrorMessage, saveErrorMessage) || other.saveErrorMessage == saveErrorMessage)&&(identical(other.profileSaveStatus, profileSaveStatus) || other.profileSaveStatus == profileSaveStatus)&&(identical(other.profileSaveErrorMessage, profileSaveErrorMessage) || other.profileSaveErrorMessage == profileSaveErrorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,member,owner,producerAccount,memberPreferences,userPreferences,dirty,saveStatus,saveErrorMessage,profileSaveStatus,profileSaveErrorMessage);

@override
String toString() {
  return 'UserPreferencesState.ready(member: $member, owner: $owner, producerAccount: $producerAccount, memberPreferences: $memberPreferences, userPreferences: $userPreferences, dirty: $dirty, saveStatus: $saveStatus, saveErrorMessage: $saveErrorMessage, profileSaveStatus: $profileSaveStatus, profileSaveErrorMessage: $profileSaveErrorMessage)';
}


}

/// @nodoc
abstract mixin class $UserPreferencesReadyCopyWith<$Res> implements $UserPreferencesStateCopyWith<$Res> {
  factory $UserPreferencesReadyCopyWith(UserPreferencesReady value, $Res Function(UserPreferencesReady) _then) = _$UserPreferencesReadyCopyWithImpl;
@useResult
$Res call({
 Member? member, Owner? owner, ProducerAccount? producerAccount, MemberPreferences memberPreferences, UserPreferences userPreferences, bool dirty, SaveStatus saveStatus, String? saveErrorMessage, SaveStatus profileSaveStatus, String? profileSaveErrorMessage
});


$MemberCopyWith<$Res>? get member;$OwnerCopyWith<$Res>? get owner;$ProducerAccountCopyWith<$Res>? get producerAccount;$MemberPreferencesCopyWith<$Res> get memberPreferences;$UserPreferencesCopyWith<$Res> get userPreferences;

}
/// @nodoc
class _$UserPreferencesReadyCopyWithImpl<$Res>
    implements $UserPreferencesReadyCopyWith<$Res> {
  _$UserPreferencesReadyCopyWithImpl(this._self, this._then);

  final UserPreferencesReady _self;
  final $Res Function(UserPreferencesReady) _then;

/// Create a copy of UserPreferencesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? member = freezed,Object? owner = freezed,Object? producerAccount = freezed,Object? memberPreferences = null,Object? userPreferences = null,Object? dirty = null,Object? saveStatus = null,Object? saveErrorMessage = freezed,Object? profileSaveStatus = null,Object? profileSaveErrorMessage = freezed,}) {
  return _then(UserPreferencesReady(
member: freezed == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as Member?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as Owner?,producerAccount: freezed == producerAccount ? _self.producerAccount : producerAccount // ignore: cast_nullable_to_non_nullable
as ProducerAccount?,memberPreferences: null == memberPreferences ? _self.memberPreferences : memberPreferences // ignore: cast_nullable_to_non_nullable
as MemberPreferences,userPreferences: null == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as UserPreferences,dirty: null == dirty ? _self.dirty : dirty // ignore: cast_nullable_to_non_nullable
as bool,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as SaveStatus,saveErrorMessage: freezed == saveErrorMessage ? _self.saveErrorMessage : saveErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,profileSaveStatus: null == profileSaveStatus ? _self.profileSaveStatus : profileSaveStatus // ignore: cast_nullable_to_non_nullable
as SaveStatus,profileSaveErrorMessage: freezed == profileSaveErrorMessage ? _self.profileSaveErrorMessage : profileSaveErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of UserPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberCopyWith<$Res>? get member {
    if (_self.member == null) {
    return null;
  }

  return $MemberCopyWith<$Res>(_self.member!, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of UserPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $OwnerCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of UserPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProducerAccountCopyWith<$Res>? get producerAccount {
    if (_self.producerAccount == null) {
    return null;
  }

  return $ProducerAccountCopyWith<$Res>(_self.producerAccount!, (value) {
    return _then(_self.copyWith(producerAccount: value));
  });
}/// Create a copy of UserPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberPreferencesCopyWith<$Res> get memberPreferences {
  
  return $MemberPreferencesCopyWith<$Res>(_self.memberPreferences, (value) {
    return _then(_self.copyWith(memberPreferences: value));
  });
}/// Create a copy of UserPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserPreferencesCopyWith<$Res> get userPreferences {
  
  return $UserPreferencesCopyWith<$Res>(_self.userPreferences, (value) {
    return _then(_self.copyWith(userPreferences: value));
  });
}
}

// dart format on
