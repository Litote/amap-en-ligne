// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'basket_exchange_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BasketExchangeDialogState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchangeDialogState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BasketExchangeDialogState()';
}


}

/// @nodoc
class $BasketExchangeDialogStateCopyWith<$Res>  {
$BasketExchangeDialogStateCopyWith(BasketExchangeDialogState _, $Res Function(BasketExchangeDialogState) __);
}


/// Adds pattern-matching-related methods to [BasketExchangeDialogState].
extension BasketExchangeDialogStatePatterns on BasketExchangeDialogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _None value)?  none,TResult Function( _Propose value)?  propose,TResult Function( _SubmitRequest value)?  submitRequest,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _None() when none != null:
return none(_that);case _Propose() when propose != null:
return propose(_that);case _SubmitRequest() when submitRequest != null:
return submitRequest(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _None value)  none,required TResult Function( _Propose value)  propose,required TResult Function( _SubmitRequest value)  submitRequest,}){
final _that = this;
switch (_that) {
case _None():
return none(_that);case _Propose():
return propose(_that);case _SubmitRequest():
return submitRequest(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _None value)?  none,TResult? Function( _Propose value)?  propose,TResult? Function( _SubmitRequest value)?  submitRequest,}){
final _that = this;
switch (_that) {
case _None() when none != null:
return none(_that);case _Propose() when propose != null:
return propose(_that);case _SubmitRequest() when submitRequest != null:
return submitRequest(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function()?  propose,TResult Function( BasketExchange offer)?  submitRequest,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _None() when none != null:
return none();case _Propose() when propose != null:
return propose();case _SubmitRequest() when submitRequest != null:
return submitRequest(_that.offer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function()  propose,required TResult Function( BasketExchange offer)  submitRequest,}) {final _that = this;
switch (_that) {
case _None():
return none();case _Propose():
return propose();case _SubmitRequest():
return submitRequest(_that.offer);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function()?  propose,TResult? Function( BasketExchange offer)?  submitRequest,}) {final _that = this;
switch (_that) {
case _None() when none != null:
return none();case _Propose() when propose != null:
return propose();case _SubmitRequest() when submitRequest != null:
return submitRequest(_that.offer);case _:
  return null;

}
}

}

/// @nodoc


class _None implements BasketExchangeDialogState {
  const _None();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _None);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BasketExchangeDialogState.none()';
}


}




/// @nodoc


class _Propose implements BasketExchangeDialogState {
  const _Propose();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Propose);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BasketExchangeDialogState.propose()';
}


}




/// @nodoc


class _SubmitRequest implements BasketExchangeDialogState {
  const _SubmitRequest({required this.offer});
  

 final  BasketExchange offer;

/// Create a copy of BasketExchangeDialogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmitRequestCopyWith<_SubmitRequest> get copyWith => __$SubmitRequestCopyWithImpl<_SubmitRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmitRequest&&(identical(other.offer, offer) || other.offer == offer));
}


@override
int get hashCode => Object.hash(runtimeType,offer);

@override
String toString() {
  return 'BasketExchangeDialogState.submitRequest(offer: $offer)';
}


}

/// @nodoc
abstract mixin class _$SubmitRequestCopyWith<$Res> implements $BasketExchangeDialogStateCopyWith<$Res> {
  factory _$SubmitRequestCopyWith(_SubmitRequest value, $Res Function(_SubmitRequest) _then) = __$SubmitRequestCopyWithImpl;
@useResult
$Res call({
 BasketExchange offer
});


$BasketExchangeCopyWith<$Res> get offer;

}
/// @nodoc
class __$SubmitRequestCopyWithImpl<$Res>
    implements _$SubmitRequestCopyWith<$Res> {
  __$SubmitRequestCopyWithImpl(this._self, this._then);

  final _SubmitRequest _self;
  final $Res Function(_SubmitRequest) _then;

/// Create a copy of BasketExchangeDialogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offer = null,}) {
  return _then(_SubmitRequest(
offer: null == offer ? _self.offer : offer // ignore: cast_nullable_to_non_nullable
as BasketExchange,
  ));
}

/// Create a copy of BasketExchangeDialogState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketExchangeCopyWith<$Res> get offer {
  
  return $BasketExchangeCopyWith<$Res>(_self.offer, (value) {
    return _then(_self.copyWith(offer: value));
  });
}
}

/// @nodoc
mixin _$BasketExchangeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchangeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BasketExchangeState()';
}


}

/// @nodoc
class $BasketExchangeStateCopyWith<$Res>  {
$BasketExchangeStateCopyWith(BasketExchangeState _, $Res Function(BasketExchangeState) __);
}


/// Adds pattern-matching-related methods to [BasketExchangeState].
extension BasketExchangeStatePatterns on BasketExchangeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BasketExchangeLoading value)?  loading,TResult Function( BasketExchangeUnauthorized value)?  unauthorized,TResult Function( BasketExchangeReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BasketExchangeLoading() when loading != null:
return loading(_that);case BasketExchangeUnauthorized() when unauthorized != null:
return unauthorized(_that);case BasketExchangeReady() when ready != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BasketExchangeLoading value)  loading,required TResult Function( BasketExchangeUnauthorized value)  unauthorized,required TResult Function( BasketExchangeReady value)  ready,}){
final _that = this;
switch (_that) {
case BasketExchangeLoading():
return loading(_that);case BasketExchangeUnauthorized():
return unauthorized(_that);case BasketExchangeReady():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BasketExchangeLoading value)?  loading,TResult? Function( BasketExchangeUnauthorized value)?  unauthorized,TResult? Function( BasketExchangeReady value)?  ready,}){
final _that = this;
switch (_that) {
case BasketExchangeLoading() when loading != null:
return loading(_that);case BasketExchangeUnauthorized() when unauthorized != null:
return unauthorized(_that);case BasketExchangeReady() when ready != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  unauthorized,TResult Function( Member me,  Organization org,  List<BasketExchange> allExchanges,  List<Member> members,  List<Contract> contracts,  BasketExchangeDialogState dialogState,  BasketExchangeSaveStatus saveStatus,  String? errorMessage)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BasketExchangeLoading() when loading != null:
return loading();case BasketExchangeUnauthorized() when unauthorized != null:
return unauthorized();case BasketExchangeReady() when ready != null:
return ready(_that.me,_that.org,_that.allExchanges,_that.members,_that.contracts,_that.dialogState,_that.saveStatus,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  unauthorized,required TResult Function( Member me,  Organization org,  List<BasketExchange> allExchanges,  List<Member> members,  List<Contract> contracts,  BasketExchangeDialogState dialogState,  BasketExchangeSaveStatus saveStatus,  String? errorMessage)  ready,}) {final _that = this;
switch (_that) {
case BasketExchangeLoading():
return loading();case BasketExchangeUnauthorized():
return unauthorized();case BasketExchangeReady():
return ready(_that.me,_that.org,_that.allExchanges,_that.members,_that.contracts,_that.dialogState,_that.saveStatus,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  unauthorized,TResult? Function( Member me,  Organization org,  List<BasketExchange> allExchanges,  List<Member> members,  List<Contract> contracts,  BasketExchangeDialogState dialogState,  BasketExchangeSaveStatus saveStatus,  String? errorMessage)?  ready,}) {final _that = this;
switch (_that) {
case BasketExchangeLoading() when loading != null:
return loading();case BasketExchangeUnauthorized() when unauthorized != null:
return unauthorized();case BasketExchangeReady() when ready != null:
return ready(_that.me,_that.org,_that.allExchanges,_that.members,_that.contracts,_that.dialogState,_that.saveStatus,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class BasketExchangeLoading implements BasketExchangeState {
  const BasketExchangeLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchangeLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BasketExchangeState.loading()';
}


}




/// @nodoc


class BasketExchangeUnauthorized implements BasketExchangeState {
  const BasketExchangeUnauthorized();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchangeUnauthorized);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BasketExchangeState.unauthorized()';
}


}




/// @nodoc


class BasketExchangeReady implements BasketExchangeState {
  const BasketExchangeReady({required this.me, required this.org, required final  List<BasketExchange> allExchanges, final  List<Member> members = const <Member>[], final  List<Contract> contracts = const <Contract>[], this.dialogState = const BasketExchangeDialogState.none(), this.saveStatus = BasketExchangeSaveStatus.idle, this.errorMessage}): _allExchanges = allExchanges,_members = members,_contracts = contracts;
  

 final  Member me;
 final  Organization org;
 final  List<BasketExchange> _allExchanges;
 List<BasketExchange> get allExchanges {
  if (_allExchanges is EqualUnmodifiableListView) return _allExchanges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allExchanges);
}

 final  List<Member> _members;
@JsonKey() List<Member> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<Contract> _contracts;
@JsonKey() List<Contract> get contracts {
  if (_contracts is EqualUnmodifiableListView) return _contracts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contracts);
}

@JsonKey() final  BasketExchangeDialogState dialogState;
@JsonKey() final  BasketExchangeSaveStatus saveStatus;
 final  String? errorMessage;

/// Create a copy of BasketExchangeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketExchangeReadyCopyWith<BasketExchangeReady> get copyWith => _$BasketExchangeReadyCopyWithImpl<BasketExchangeReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchangeReady&&(identical(other.me, me) || other.me == me)&&(identical(other.org, org) || other.org == org)&&const DeepCollectionEquality().equals(other._allExchanges, _allExchanges)&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._contracts, _contracts)&&(identical(other.dialogState, dialogState) || other.dialogState == dialogState)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,me,org,const DeepCollectionEquality().hash(_allExchanges),const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_contracts),dialogState,saveStatus,errorMessage);

@override
String toString() {
  return 'BasketExchangeState.ready(me: $me, org: $org, allExchanges: $allExchanges, members: $members, contracts: $contracts, dialogState: $dialogState, saveStatus: $saveStatus, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $BasketExchangeReadyCopyWith<$Res> implements $BasketExchangeStateCopyWith<$Res> {
  factory $BasketExchangeReadyCopyWith(BasketExchangeReady value, $Res Function(BasketExchangeReady) _then) = _$BasketExchangeReadyCopyWithImpl;
@useResult
$Res call({
 Member me, Organization org, List<BasketExchange> allExchanges, List<Member> members, List<Contract> contracts, BasketExchangeDialogState dialogState, BasketExchangeSaveStatus saveStatus, String? errorMessage
});


$MemberCopyWith<$Res> get me;$OrganizationCopyWith<$Res> get org;$BasketExchangeDialogStateCopyWith<$Res> get dialogState;

}
/// @nodoc
class _$BasketExchangeReadyCopyWithImpl<$Res>
    implements $BasketExchangeReadyCopyWith<$Res> {
  _$BasketExchangeReadyCopyWithImpl(this._self, this._then);

  final BasketExchangeReady _self;
  final $Res Function(BasketExchangeReady) _then;

/// Create a copy of BasketExchangeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? me = null,Object? org = null,Object? allExchanges = null,Object? members = null,Object? contracts = null,Object? dialogState = null,Object? saveStatus = null,Object? errorMessage = freezed,}) {
  return _then(BasketExchangeReady(
me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as Member,org: null == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as Organization,allExchanges: null == allExchanges ? _self._allExchanges : allExchanges // ignore: cast_nullable_to_non_nullable
as List<BasketExchange>,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<Member>,contracts: null == contracts ? _self._contracts : contracts // ignore: cast_nullable_to_non_nullable
as List<Contract>,dialogState: null == dialogState ? _self.dialogState : dialogState // ignore: cast_nullable_to_non_nullable
as BasketExchangeDialogState,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as BasketExchangeSaveStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BasketExchangeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberCopyWith<$Res> get me {
  
  return $MemberCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}/// Create a copy of BasketExchangeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get org {
  
  return $OrganizationCopyWith<$Res>(_self.org, (value) {
    return _then(_self.copyWith(org: value));
  });
}/// Create a copy of BasketExchangeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketExchangeDialogStateCopyWith<$Res> get dialogState {
  
  return $BasketExchangeDialogStateCopyWith<$Res>(_self.dialogState, (value) {
    return _then(_self.copyWith(dialogState: value));
  });
}
}

// dart format on
