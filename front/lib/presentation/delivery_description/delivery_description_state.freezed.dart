// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_description_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveryDescriptionState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryDescriptionState()';
}


}

/// @nodoc
class $DeliveryDescriptionStateCopyWith<$Res>  {
$DeliveryDescriptionStateCopyWith(DeliveryDescriptionState _, $Res Function(DeliveryDescriptionState) __);
}


/// Adds pattern-matching-related methods to [DeliveryDescriptionState].
extension DeliveryDescriptionStatePatterns on DeliveryDescriptionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeliveryDescriptionInitial value)?  initial,TResult Function( DeliveryDescriptionLoaded value)?  loaded,TResult Function( DeliveryDescriptionSaving value)?  saving,TResult Function( DeliveryDescriptionSaved value)?  saved,TResult Function( DeliveryDescriptionError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeliveryDescriptionInitial() when initial != null:
return initial(_that);case DeliveryDescriptionLoaded() when loaded != null:
return loaded(_that);case DeliveryDescriptionSaving() when saving != null:
return saving(_that);case DeliveryDescriptionSaved() when saved != null:
return saved(_that);case DeliveryDescriptionError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeliveryDescriptionInitial value)  initial,required TResult Function( DeliveryDescriptionLoaded value)  loaded,required TResult Function( DeliveryDescriptionSaving value)  saving,required TResult Function( DeliveryDescriptionSaved value)  saved,required TResult Function( DeliveryDescriptionError value)  error,}){
final _that = this;
switch (_that) {
case DeliveryDescriptionInitial():
return initial(_that);case DeliveryDescriptionLoaded():
return loaded(_that);case DeliveryDescriptionSaving():
return saving(_that);case DeliveryDescriptionSaved():
return saved(_that);case DeliveryDescriptionError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeliveryDescriptionInitial value)?  initial,TResult? Function( DeliveryDescriptionLoaded value)?  loaded,TResult? Function( DeliveryDescriptionSaving value)?  saving,TResult? Function( DeliveryDescriptionSaved value)?  saved,TResult? Function( DeliveryDescriptionError value)?  error,}){
final _that = this;
switch (_that) {
case DeliveryDescriptionInitial() when initial != null:
return initial(_that);case DeliveryDescriptionLoaded() when loaded != null:
return loaded(_that);case DeliveryDescriptionSaving() when saving != null:
return saving(_that);case DeliveryDescriptionSaved() when saved != null:
return saved(_that);case DeliveryDescriptionError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( Organization org,  Delivery delivery,  List<ProductType> productTypes,  List<BasketDeliveryDescription> localDescriptions)?  loaded,TResult Function()?  saving,TResult Function()?  saved,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeliveryDescriptionInitial() when initial != null:
return initial();case DeliveryDescriptionLoaded() when loaded != null:
return loaded(_that.org,_that.delivery,_that.productTypes,_that.localDescriptions);case DeliveryDescriptionSaving() when saving != null:
return saving();case DeliveryDescriptionSaved() when saved != null:
return saved();case DeliveryDescriptionError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( Organization org,  Delivery delivery,  List<ProductType> productTypes,  List<BasketDeliveryDescription> localDescriptions)  loaded,required TResult Function()  saving,required TResult Function()  saved,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case DeliveryDescriptionInitial():
return initial();case DeliveryDescriptionLoaded():
return loaded(_that.org,_that.delivery,_that.productTypes,_that.localDescriptions);case DeliveryDescriptionSaving():
return saving();case DeliveryDescriptionSaved():
return saved();case DeliveryDescriptionError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( Organization org,  Delivery delivery,  List<ProductType> productTypes,  List<BasketDeliveryDescription> localDescriptions)?  loaded,TResult? Function()?  saving,TResult? Function()?  saved,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case DeliveryDescriptionInitial() when initial != null:
return initial();case DeliveryDescriptionLoaded() when loaded != null:
return loaded(_that.org,_that.delivery,_that.productTypes,_that.localDescriptions);case DeliveryDescriptionSaving() when saving != null:
return saving();case DeliveryDescriptionSaved() when saved != null:
return saved();case DeliveryDescriptionError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class DeliveryDescriptionInitial implements DeliveryDescriptionState {
  const DeliveryDescriptionInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryDescriptionState.initial()';
}


}




/// @nodoc


class DeliveryDescriptionLoaded implements DeliveryDescriptionState {
  const DeliveryDescriptionLoaded({required this.org, required this.delivery, required final  List<ProductType> productTypes, required final  List<BasketDeliveryDescription> localDescriptions}): _productTypes = productTypes,_localDescriptions = localDescriptions;
  

 final  Organization org;
 final  Delivery delivery;
 final  List<ProductType> _productTypes;
 List<ProductType> get productTypes {
  if (_productTypes is EqualUnmodifiableListView) return _productTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productTypes);
}

 final  List<BasketDeliveryDescription> _localDescriptions;
 List<BasketDeliveryDescription> get localDescriptions {
  if (_localDescriptions is EqualUnmodifiableListView) return _localDescriptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_localDescriptions);
}


/// Create a copy of DeliveryDescriptionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryDescriptionLoadedCopyWith<DeliveryDescriptionLoaded> get copyWith => _$DeliveryDescriptionLoadedCopyWithImpl<DeliveryDescriptionLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionLoaded&&(identical(other.org, org) || other.org == org)&&(identical(other.delivery, delivery) || other.delivery == delivery)&&const DeepCollectionEquality().equals(other._productTypes, _productTypes)&&const DeepCollectionEquality().equals(other._localDescriptions, _localDescriptions));
}


@override
int get hashCode => Object.hash(runtimeType,org,delivery,const DeepCollectionEquality().hash(_productTypes),const DeepCollectionEquality().hash(_localDescriptions));

@override
String toString() {
  return 'DeliveryDescriptionState.loaded(org: $org, delivery: $delivery, productTypes: $productTypes, localDescriptions: $localDescriptions)';
}


}

/// @nodoc
abstract mixin class $DeliveryDescriptionLoadedCopyWith<$Res> implements $DeliveryDescriptionStateCopyWith<$Res> {
  factory $DeliveryDescriptionLoadedCopyWith(DeliveryDescriptionLoaded value, $Res Function(DeliveryDescriptionLoaded) _then) = _$DeliveryDescriptionLoadedCopyWithImpl;
@useResult
$Res call({
 Organization org, Delivery delivery, List<ProductType> productTypes, List<BasketDeliveryDescription> localDescriptions
});


$OrganizationCopyWith<$Res> get org;$DeliveryCopyWith<$Res> get delivery;

}
/// @nodoc
class _$DeliveryDescriptionLoadedCopyWithImpl<$Res>
    implements $DeliveryDescriptionLoadedCopyWith<$Res> {
  _$DeliveryDescriptionLoadedCopyWithImpl(this._self, this._then);

  final DeliveryDescriptionLoaded _self;
  final $Res Function(DeliveryDescriptionLoaded) _then;

/// Create a copy of DeliveryDescriptionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? org = null,Object? delivery = null,Object? productTypes = null,Object? localDescriptions = null,}) {
  return _then(DeliveryDescriptionLoaded(
org: null == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as Organization,delivery: null == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as Delivery,productTypes: null == productTypes ? _self._productTypes : productTypes // ignore: cast_nullable_to_non_nullable
as List<ProductType>,localDescriptions: null == localDescriptions ? _self._localDescriptions : localDescriptions // ignore: cast_nullable_to_non_nullable
as List<BasketDeliveryDescription>,
  ));
}

/// Create a copy of DeliveryDescriptionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get org {
  
  return $OrganizationCopyWith<$Res>(_self.org, (value) {
    return _then(_self.copyWith(org: value));
  });
}/// Create a copy of DeliveryDescriptionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryCopyWith<$Res> get delivery {
  
  return $DeliveryCopyWith<$Res>(_self.delivery, (value) {
    return _then(_self.copyWith(delivery: value));
  });
}
}

/// @nodoc


class DeliveryDescriptionSaving implements DeliveryDescriptionState {
  const DeliveryDescriptionSaving();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionSaving);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryDescriptionState.saving()';
}


}




/// @nodoc


class DeliveryDescriptionSaved implements DeliveryDescriptionState {
  const DeliveryDescriptionSaved();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionSaved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryDescriptionState.saved()';
}


}




/// @nodoc


class DeliveryDescriptionError implements DeliveryDescriptionState {
  const DeliveryDescriptionError({required this.message});
  

 final  String message;

/// Create a copy of DeliveryDescriptionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryDescriptionErrorCopyWith<DeliveryDescriptionError> get copyWith => _$DeliveryDescriptionErrorCopyWithImpl<DeliveryDescriptionError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryDescriptionError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DeliveryDescriptionState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $DeliveryDescriptionErrorCopyWith<$Res> implements $DeliveryDescriptionStateCopyWith<$Res> {
  factory $DeliveryDescriptionErrorCopyWith(DeliveryDescriptionError value, $Res Function(DeliveryDescriptionError) _then) = _$DeliveryDescriptionErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$DeliveryDescriptionErrorCopyWithImpl<$Res>
    implements $DeliveryDescriptionErrorCopyWith<$Res> {
  _$DeliveryDescriptionErrorCopyWithImpl(this._self, this._then);

  final DeliveryDescriptionError _self;
  final $Res Function(DeliveryDescriptionError) _then;

/// Create a copy of DeliveryDescriptionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(DeliveryDescriptionError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
