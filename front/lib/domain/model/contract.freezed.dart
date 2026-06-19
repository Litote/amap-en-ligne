// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberSubscription {

@JsonKey(name: 'product_type_id') String get productTypeId;@JsonKey(name: 'basket_size') BasketSize? get basketSize;
/// Create a copy of MemberSubscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberSubscriptionCopyWith<MemberSubscription> get copyWith => _$MemberSubscriptionCopyWithImpl<MemberSubscription>(this as MemberSubscription, _$identity);

  /// Serializes this MemberSubscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberSubscription&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSize, basketSize) || other.basketSize == basketSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSize);

@override
String toString() {
  return 'MemberSubscription(productTypeId: $productTypeId, basketSize: $basketSize)';
}


}

/// @nodoc
abstract mixin class $MemberSubscriptionCopyWith<$Res>  {
  factory $MemberSubscriptionCopyWith(MemberSubscription value, $Res Function(MemberSubscription) _then) = _$MemberSubscriptionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'basket_size') BasketSize? basketSize
});


$BasketSizeCopyWith<$Res>? get basketSize;

}
/// @nodoc
class _$MemberSubscriptionCopyWithImpl<$Res>
    implements $MemberSubscriptionCopyWith<$Res> {
  _$MemberSubscriptionCopyWithImpl(this._self, this._then);

  final MemberSubscription _self;
  final $Res Function(MemberSubscription) _then;

/// Create a copy of MemberSubscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productTypeId = null,Object? basketSize = freezed,}) {
  return _then(_self.copyWith(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSize: freezed == basketSize ? _self.basketSize : basketSize // ignore: cast_nullable_to_non_nullable
as BasketSize?,
  ));
}
/// Create a copy of MemberSubscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketSizeCopyWith<$Res>? get basketSize {
    if (_self.basketSize == null) {
    return null;
  }

  return $BasketSizeCopyWith<$Res>(_self.basketSize!, (value) {
    return _then(_self.copyWith(basketSize: value));
  });
}
}


/// Adds pattern-matching-related methods to [MemberSubscription].
extension MemberSubscriptionPatterns on MemberSubscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberSubscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberSubscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberSubscription value)  $default,){
final _that = this;
switch (_that) {
case _MemberSubscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberSubscription value)?  $default,){
final _that = this;
switch (_that) {
case _MemberSubscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size')  BasketSize? basketSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberSubscription() when $default != null:
return $default(_that.productTypeId,_that.basketSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size')  BasketSize? basketSize)  $default,) {final _that = this;
switch (_that) {
case _MemberSubscription():
return $default(_that.productTypeId,_that.basketSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size')  BasketSize? basketSize)?  $default,) {final _that = this;
switch (_that) {
case _MemberSubscription() when $default != null:
return $default(_that.productTypeId,_that.basketSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberSubscription implements MemberSubscription {
  const _MemberSubscription({@JsonKey(name: 'product_type_id') required this.productTypeId, @JsonKey(name: 'basket_size') this.basketSize});
  factory _MemberSubscription.fromJson(Map<String, dynamic> json) => _$MemberSubscriptionFromJson(json);

@override@JsonKey(name: 'product_type_id') final  String productTypeId;
@override@JsonKey(name: 'basket_size') final  BasketSize? basketSize;

/// Create a copy of MemberSubscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberSubscriptionCopyWith<_MemberSubscription> get copyWith => __$MemberSubscriptionCopyWithImpl<_MemberSubscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberSubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberSubscription&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSize, basketSize) || other.basketSize == basketSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSize);

@override
String toString() {
  return 'MemberSubscription(productTypeId: $productTypeId, basketSize: $basketSize)';
}


}

/// @nodoc
abstract mixin class _$MemberSubscriptionCopyWith<$Res> implements $MemberSubscriptionCopyWith<$Res> {
  factory _$MemberSubscriptionCopyWith(_MemberSubscription value, $Res Function(_MemberSubscription) _then) = __$MemberSubscriptionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'basket_size') BasketSize? basketSize
});


@override $BasketSizeCopyWith<$Res>? get basketSize;

}
/// @nodoc
class __$MemberSubscriptionCopyWithImpl<$Res>
    implements _$MemberSubscriptionCopyWith<$Res> {
  __$MemberSubscriptionCopyWithImpl(this._self, this._then);

  final _MemberSubscription _self;
  final $Res Function(_MemberSubscription) _then;

/// Create a copy of MemberSubscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productTypeId = null,Object? basketSize = freezed,}) {
  return _then(_MemberSubscription(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSize: freezed == basketSize ? _self.basketSize : basketSize // ignore: cast_nullable_to_non_nullable
as BasketSize?,
  ));
}

/// Create a copy of MemberSubscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketSizeCopyWith<$Res>? get basketSize {
    if (_self.basketSize == null) {
    return null;
  }

  return $BasketSizeCopyWith<$Res>(_self.basketSize!, (value) {
    return _then(_self.copyWith(basketSize: value));
  });
}
}


/// @nodoc
mixin _$ProductPrice {

@JsonKey(name: 'product_type_id') String get productTypeId;@JsonKey(name: 'basket_size') BasketSize? get basketSize; double? get price;
/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductPriceCopyWith<ProductPrice> get copyWith => _$ProductPriceCopyWithImpl<ProductPrice>(this as ProductPrice, _$identity);

  /// Serializes this ProductPrice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductPrice&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSize, basketSize) || other.basketSize == basketSize)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSize,price);

@override
String toString() {
  return 'ProductPrice(productTypeId: $productTypeId, basketSize: $basketSize, price: $price)';
}


}

/// @nodoc
abstract mixin class $ProductPriceCopyWith<$Res>  {
  factory $ProductPriceCopyWith(ProductPrice value, $Res Function(ProductPrice) _then) = _$ProductPriceCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'basket_size') BasketSize? basketSize, double? price
});


$BasketSizeCopyWith<$Res>? get basketSize;

}
/// @nodoc
class _$ProductPriceCopyWithImpl<$Res>
    implements $ProductPriceCopyWith<$Res> {
  _$ProductPriceCopyWithImpl(this._self, this._then);

  final ProductPrice _self;
  final $Res Function(ProductPrice) _then;

/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productTypeId = null,Object? basketSize = freezed,Object? price = freezed,}) {
  return _then(_self.copyWith(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSize: freezed == basketSize ? _self.basketSize : basketSize // ignore: cast_nullable_to_non_nullable
as BasketSize?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketSizeCopyWith<$Res>? get basketSize {
    if (_self.basketSize == null) {
    return null;
  }

  return $BasketSizeCopyWith<$Res>(_self.basketSize!, (value) {
    return _then(_self.copyWith(basketSize: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductPrice].
extension ProductPricePatterns on ProductPrice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductPrice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductPrice value)  $default,){
final _that = this;
switch (_that) {
case _ProductPrice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductPrice value)?  $default,){
final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size')  BasketSize? basketSize,  double? price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
return $default(_that.productTypeId,_that.basketSize,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size')  BasketSize? basketSize,  double? price)  $default,) {final _that = this;
switch (_that) {
case _ProductPrice():
return $default(_that.productTypeId,_that.basketSize,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'basket_size')  BasketSize? basketSize,  double? price)?  $default,) {final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
return $default(_that.productTypeId,_that.basketSize,_that.price);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductPrice implements ProductPrice {
  const _ProductPrice({@JsonKey(name: 'product_type_id') required this.productTypeId, @JsonKey(name: 'basket_size') this.basketSize, this.price});
  factory _ProductPrice.fromJson(Map<String, dynamic> json) => _$ProductPriceFromJson(json);

@override@JsonKey(name: 'product_type_id') final  String productTypeId;
@override@JsonKey(name: 'basket_size') final  BasketSize? basketSize;
@override final  double? price;

/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductPriceCopyWith<_ProductPrice> get copyWith => __$ProductPriceCopyWithImpl<_ProductPrice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductPriceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductPrice&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&(identical(other.basketSize, basketSize) || other.basketSize == basketSize)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productTypeId,basketSize,price);

@override
String toString() {
  return 'ProductPrice(productTypeId: $productTypeId, basketSize: $basketSize, price: $price)';
}


}

/// @nodoc
abstract mixin class _$ProductPriceCopyWith<$Res> implements $ProductPriceCopyWith<$Res> {
  factory _$ProductPriceCopyWith(_ProductPrice value, $Res Function(_ProductPrice) _then) = __$ProductPriceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'basket_size') BasketSize? basketSize, double? price
});


@override $BasketSizeCopyWith<$Res>? get basketSize;

}
/// @nodoc
class __$ProductPriceCopyWithImpl<$Res>
    implements _$ProductPriceCopyWith<$Res> {
  __$ProductPriceCopyWithImpl(this._self, this._then);

  final _ProductPrice _self;
  final $Res Function(_ProductPrice) _then;

/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productTypeId = null,Object? basketSize = freezed,Object? price = freezed,}) {
  return _then(_ProductPrice(
productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,basketSize: freezed == basketSize ? _self.basketSize : basketSize // ignore: cast_nullable_to_non_nullable
as BasketSize?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketSizeCopyWith<$Res>? get basketSize {
    if (_self.basketSize == null) {
    return null;
  }

  return $BasketSizeCopyWith<$Res>(_self.basketSize!, (value) {
    return _then(_self.copyWith(basketSize: value));
  });
}
}


/// @nodoc
mixin _$ContractMember {

@JsonKey(name: 'member_id') String get memberId;@JsonKey(name: 'subscription_instant') String get subscriptionInstant; ContractMemberStatus get status; List<MemberSubscription> get subscriptions;
/// Create a copy of ContractMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractMemberCopyWith<ContractMember> get copyWith => _$ContractMemberCopyWithImpl<ContractMember>(this as ContractMember, _$identity);

  /// Serializes this ContractMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractMember&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.subscriptionInstant, subscriptionInstant) || other.subscriptionInstant == subscriptionInstant)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.subscriptions, subscriptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,subscriptionInstant,status,const DeepCollectionEquality().hash(subscriptions));

@override
String toString() {
  return 'ContractMember(memberId: $memberId, subscriptionInstant: $subscriptionInstant, status: $status, subscriptions: $subscriptions)';
}


}

/// @nodoc
abstract mixin class $ContractMemberCopyWith<$Res>  {
  factory $ContractMemberCopyWith(ContractMember value, $Res Function(ContractMember) _then) = _$ContractMemberCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'member_id') String memberId,@JsonKey(name: 'subscription_instant') String subscriptionInstant, ContractMemberStatus status, List<MemberSubscription> subscriptions
});




}
/// @nodoc
class _$ContractMemberCopyWithImpl<$Res>
    implements $ContractMemberCopyWith<$Res> {
  _$ContractMemberCopyWithImpl(this._self, this._then);

  final ContractMember _self;
  final $Res Function(ContractMember) _then;

/// Create a copy of ContractMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberId = null,Object? subscriptionInstant = null,Object? status = null,Object? subscriptions = null,}) {
  return _then(_self.copyWith(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,subscriptionInstant: null == subscriptionInstant ? _self.subscriptionInstant : subscriptionInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractMemberStatus,subscriptions: null == subscriptions ? _self.subscriptions : subscriptions // ignore: cast_nullable_to_non_nullable
as List<MemberSubscription>,
  ));
}

}


/// Adds pattern-matching-related methods to [ContractMember].
extension ContractMemberPatterns on ContractMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContractMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContractMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContractMember value)  $default,){
final _that = this;
switch (_that) {
case _ContractMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContractMember value)?  $default,){
final _that = this;
switch (_that) {
case _ContractMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'subscription_instant')  String subscriptionInstant,  ContractMemberStatus status,  List<MemberSubscription> subscriptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContractMember() when $default != null:
return $default(_that.memberId,_that.subscriptionInstant,_that.status,_that.subscriptions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'subscription_instant')  String subscriptionInstant,  ContractMemberStatus status,  List<MemberSubscription> subscriptions)  $default,) {final _that = this;
switch (_that) {
case _ContractMember():
return $default(_that.memberId,_that.subscriptionInstant,_that.status,_that.subscriptions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'member_id')  String memberId, @JsonKey(name: 'subscription_instant')  String subscriptionInstant,  ContractMemberStatus status,  List<MemberSubscription> subscriptions)?  $default,) {final _that = this;
switch (_that) {
case _ContractMember() when $default != null:
return $default(_that.memberId,_that.subscriptionInstant,_that.status,_that.subscriptions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContractMember implements ContractMember {
  const _ContractMember({@JsonKey(name: 'member_id') required this.memberId, @JsonKey(name: 'subscription_instant') required this.subscriptionInstant, required this.status, final  List<MemberSubscription> subscriptions = const []}): _subscriptions = subscriptions;
  factory _ContractMember.fromJson(Map<String, dynamic> json) => _$ContractMemberFromJson(json);

@override@JsonKey(name: 'member_id') final  String memberId;
@override@JsonKey(name: 'subscription_instant') final  String subscriptionInstant;
@override final  ContractMemberStatus status;
 final  List<MemberSubscription> _subscriptions;
@override@JsonKey() List<MemberSubscription> get subscriptions {
  if (_subscriptions is EqualUnmodifiableListView) return _subscriptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subscriptions);
}


/// Create a copy of ContractMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractMemberCopyWith<_ContractMember> get copyWith => __$ContractMemberCopyWithImpl<_ContractMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractMember&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.subscriptionInstant, subscriptionInstant) || other.subscriptionInstant == subscriptionInstant)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._subscriptions, _subscriptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberId,subscriptionInstant,status,const DeepCollectionEquality().hash(_subscriptions));

@override
String toString() {
  return 'ContractMember(memberId: $memberId, subscriptionInstant: $subscriptionInstant, status: $status, subscriptions: $subscriptions)';
}


}

/// @nodoc
abstract mixin class _$ContractMemberCopyWith<$Res> implements $ContractMemberCopyWith<$Res> {
  factory _$ContractMemberCopyWith(_ContractMember value, $Res Function(_ContractMember) _then) = __$ContractMemberCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'member_id') String memberId,@JsonKey(name: 'subscription_instant') String subscriptionInstant, ContractMemberStatus status, List<MemberSubscription> subscriptions
});




}
/// @nodoc
class __$ContractMemberCopyWithImpl<$Res>
    implements _$ContractMemberCopyWith<$Res> {
  __$ContractMemberCopyWithImpl(this._self, this._then);

  final _ContractMember _self;
  final $Res Function(_ContractMember) _then;

/// Create a copy of ContractMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberId = null,Object? subscriptionInstant = null,Object? status = null,Object? subscriptions = null,}) {
  return _then(_ContractMember(
memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,subscriptionInstant: null == subscriptionInstant ? _self.subscriptionInstant : subscriptionInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractMemberStatus,subscriptions: null == subscriptions ? _self._subscriptions : subscriptions // ignore: cast_nullable_to_non_nullable
as List<MemberSubscription>,
  ));
}


}


/// @nodoc
mixin _$SharedBasket {

@JsonKey(name: 'shared_basket_id') String get sharedBasketId;@JsonKey(name: 'member_ids') List<String> get memberIds;@JsonKey(name: 'anchor_delivery_id') String? get anchorDeliveryId;
/// Create a copy of SharedBasket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedBasketCopyWith<SharedBasket> get copyWith => _$SharedBasketCopyWithImpl<SharedBasket>(this as SharedBasket, _$identity);

  /// Serializes this SharedBasket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedBasket&&(identical(other.sharedBasketId, sharedBasketId) || other.sharedBasketId == sharedBasketId)&&const DeepCollectionEquality().equals(other.memberIds, memberIds)&&(identical(other.anchorDeliveryId, anchorDeliveryId) || other.anchorDeliveryId == anchorDeliveryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sharedBasketId,const DeepCollectionEquality().hash(memberIds),anchorDeliveryId);

@override
String toString() {
  return 'SharedBasket(sharedBasketId: $sharedBasketId, memberIds: $memberIds, anchorDeliveryId: $anchorDeliveryId)';
}


}

/// @nodoc
abstract mixin class $SharedBasketCopyWith<$Res>  {
  factory $SharedBasketCopyWith(SharedBasket value, $Res Function(SharedBasket) _then) = _$SharedBasketCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'shared_basket_id') String sharedBasketId,@JsonKey(name: 'member_ids') List<String> memberIds,@JsonKey(name: 'anchor_delivery_id') String? anchorDeliveryId
});




}
/// @nodoc
class _$SharedBasketCopyWithImpl<$Res>
    implements $SharedBasketCopyWith<$Res> {
  _$SharedBasketCopyWithImpl(this._self, this._then);

  final SharedBasket _self;
  final $Res Function(SharedBasket) _then;

/// Create a copy of SharedBasket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sharedBasketId = null,Object? memberIds = null,Object? anchorDeliveryId = freezed,}) {
  return _then(_self.copyWith(
sharedBasketId: null == sharedBasketId ? _self.sharedBasketId : sharedBasketId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,anchorDeliveryId: freezed == anchorDeliveryId ? _self.anchorDeliveryId : anchorDeliveryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedBasket].
extension SharedBasketPatterns on SharedBasket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedBasket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedBasket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedBasket value)  $default,){
final _that = this;
switch (_that) {
case _SharedBasket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedBasket value)?  $default,){
final _that = this;
switch (_that) {
case _SharedBasket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'shared_basket_id')  String sharedBasketId, @JsonKey(name: 'member_ids')  List<String> memberIds, @JsonKey(name: 'anchor_delivery_id')  String? anchorDeliveryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedBasket() when $default != null:
return $default(_that.sharedBasketId,_that.memberIds,_that.anchorDeliveryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'shared_basket_id')  String sharedBasketId, @JsonKey(name: 'member_ids')  List<String> memberIds, @JsonKey(name: 'anchor_delivery_id')  String? anchorDeliveryId)  $default,) {final _that = this;
switch (_that) {
case _SharedBasket():
return $default(_that.sharedBasketId,_that.memberIds,_that.anchorDeliveryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'shared_basket_id')  String sharedBasketId, @JsonKey(name: 'member_ids')  List<String> memberIds, @JsonKey(name: 'anchor_delivery_id')  String? anchorDeliveryId)?  $default,) {final _that = this;
switch (_that) {
case _SharedBasket() when $default != null:
return $default(_that.sharedBasketId,_that.memberIds,_that.anchorDeliveryId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SharedBasket implements SharedBasket {
  const _SharedBasket({@JsonKey(name: 'shared_basket_id') required this.sharedBasketId, @JsonKey(name: 'member_ids') final  List<String> memberIds = const [], @JsonKey(name: 'anchor_delivery_id') this.anchorDeliveryId}): _memberIds = memberIds;
  factory _SharedBasket.fromJson(Map<String, dynamic> json) => _$SharedBasketFromJson(json);

@override@JsonKey(name: 'shared_basket_id') final  String sharedBasketId;
 final  List<String> _memberIds;
@override@JsonKey(name: 'member_ids') List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}

@override@JsonKey(name: 'anchor_delivery_id') final  String? anchorDeliveryId;

/// Create a copy of SharedBasket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedBasketCopyWith<_SharedBasket> get copyWith => __$SharedBasketCopyWithImpl<_SharedBasket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SharedBasketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedBasket&&(identical(other.sharedBasketId, sharedBasketId) || other.sharedBasketId == sharedBasketId)&&const DeepCollectionEquality().equals(other._memberIds, _memberIds)&&(identical(other.anchorDeliveryId, anchorDeliveryId) || other.anchorDeliveryId == anchorDeliveryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sharedBasketId,const DeepCollectionEquality().hash(_memberIds),anchorDeliveryId);

@override
String toString() {
  return 'SharedBasket(sharedBasketId: $sharedBasketId, memberIds: $memberIds, anchorDeliveryId: $anchorDeliveryId)';
}


}

/// @nodoc
abstract mixin class _$SharedBasketCopyWith<$Res> implements $SharedBasketCopyWith<$Res> {
  factory _$SharedBasketCopyWith(_SharedBasket value, $Res Function(_SharedBasket) _then) = __$SharedBasketCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'shared_basket_id') String sharedBasketId,@JsonKey(name: 'member_ids') List<String> memberIds,@JsonKey(name: 'anchor_delivery_id') String? anchorDeliveryId
});




}
/// @nodoc
class __$SharedBasketCopyWithImpl<$Res>
    implements _$SharedBasketCopyWith<$Res> {
  __$SharedBasketCopyWithImpl(this._self, this._then);

  final _SharedBasket _self;
  final $Res Function(_SharedBasket) _then;

/// Create a copy of SharedBasket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sharedBasketId = null,Object? memberIds = null,Object? anchorDeliveryId = freezed,}) {
  return _then(_SharedBasket(
sharedBasketId: null == sharedBasketId ? _self.sharedBasketId : sharedBasketId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,anchorDeliveryId: freezed == anchorDeliveryId ? _self.anchorDeliveryId : anchorDeliveryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Contract {

@JsonKey(name: 'contract_id') String get contractId;@JsonKey(name: 'name') String get name;@JsonKey(name: 'organization_id') String get organizationId;@JsonKey(name: 'producer_account_id') String get producerAccountId;@JsonKey(name: 'min_delivery_date') String get minDeliveryDate;@JsonKey(name: 'max_delivery_date') String get maxDeliveryDate;@JsonKey(name: 'delivery_count') int get deliveryCount;@JsonKey(name: 'season_year') int get seasonYear;@JsonKey(name: 'product_prices') List<ProductPrice> get productPrices; List<String> get coordinators; List<ContractMember> get members; ContractStatus get status;@JsonKey(name: 'delivery_template_id') String? get deliveryTemplateId;@JsonKey(name: 'shared_baskets') List<SharedBasket> get sharedBaskets;
/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractCopyWith<Contract> get copyWith => _$ContractCopyWithImpl<Contract>(this as Contract, _$identity);

  /// Serializes this Contract to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contract&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.minDeliveryDate, minDeliveryDate) || other.minDeliveryDate == minDeliveryDate)&&(identical(other.maxDeliveryDate, maxDeliveryDate) || other.maxDeliveryDate == maxDeliveryDate)&&(identical(other.deliveryCount, deliveryCount) || other.deliveryCount == deliveryCount)&&(identical(other.seasonYear, seasonYear) || other.seasonYear == seasonYear)&&const DeepCollectionEquality().equals(other.productPrices, productPrices)&&const DeepCollectionEquality().equals(other.coordinators, coordinators)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryTemplateId, deliveryTemplateId) || other.deliveryTemplateId == deliveryTemplateId)&&const DeepCollectionEquality().equals(other.sharedBaskets, sharedBaskets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractId,name,organizationId,producerAccountId,minDeliveryDate,maxDeliveryDate,deliveryCount,seasonYear,const DeepCollectionEquality().hash(productPrices),const DeepCollectionEquality().hash(coordinators),const DeepCollectionEquality().hash(members),status,deliveryTemplateId,const DeepCollectionEquality().hash(sharedBaskets));

@override
String toString() {
  return 'Contract(contractId: $contractId, name: $name, organizationId: $organizationId, producerAccountId: $producerAccountId, minDeliveryDate: $minDeliveryDate, maxDeliveryDate: $maxDeliveryDate, deliveryCount: $deliveryCount, seasonYear: $seasonYear, productPrices: $productPrices, coordinators: $coordinators, members: $members, status: $status, deliveryTemplateId: $deliveryTemplateId, sharedBaskets: $sharedBaskets)';
}


}

/// @nodoc
abstract mixin class $ContractCopyWith<$Res>  {
  factory $ContractCopyWith(Contract value, $Res Function(Contract) _then) = _$ContractCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'name') String name,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'min_delivery_date') String minDeliveryDate,@JsonKey(name: 'max_delivery_date') String maxDeliveryDate,@JsonKey(name: 'delivery_count') int deliveryCount,@JsonKey(name: 'season_year') int seasonYear,@JsonKey(name: 'product_prices') List<ProductPrice> productPrices, List<String> coordinators, List<ContractMember> members, ContractStatus status,@JsonKey(name: 'delivery_template_id') String? deliveryTemplateId,@JsonKey(name: 'shared_baskets') List<SharedBasket> sharedBaskets
});




}
/// @nodoc
class _$ContractCopyWithImpl<$Res>
    implements $ContractCopyWith<$Res> {
  _$ContractCopyWithImpl(this._self, this._then);

  final Contract _self;
  final $Res Function(Contract) _then;

/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractId = null,Object? name = null,Object? organizationId = null,Object? producerAccountId = null,Object? minDeliveryDate = null,Object? maxDeliveryDate = null,Object? deliveryCount = null,Object? seasonYear = null,Object? productPrices = null,Object? coordinators = null,Object? members = null,Object? status = null,Object? deliveryTemplateId = freezed,Object? sharedBaskets = null,}) {
  return _then(_self.copyWith(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,minDeliveryDate: null == minDeliveryDate ? _self.minDeliveryDate : minDeliveryDate // ignore: cast_nullable_to_non_nullable
as String,maxDeliveryDate: null == maxDeliveryDate ? _self.maxDeliveryDate : maxDeliveryDate // ignore: cast_nullable_to_non_nullable
as String,deliveryCount: null == deliveryCount ? _self.deliveryCount : deliveryCount // ignore: cast_nullable_to_non_nullable
as int,seasonYear: null == seasonYear ? _self.seasonYear : seasonYear // ignore: cast_nullable_to_non_nullable
as int,productPrices: null == productPrices ? _self.productPrices : productPrices // ignore: cast_nullable_to_non_nullable
as List<ProductPrice>,coordinators: null == coordinators ? _self.coordinators : coordinators // ignore: cast_nullable_to_non_nullable
as List<String>,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<ContractMember>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractStatus,deliveryTemplateId: freezed == deliveryTemplateId ? _self.deliveryTemplateId : deliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String?,sharedBaskets: null == sharedBaskets ? _self.sharedBaskets : sharedBaskets // ignore: cast_nullable_to_non_nullable
as List<SharedBasket>,
  ));
}

}


/// Adds pattern-matching-related methods to [Contract].
extension ContractPatterns on Contract {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Contract value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Contract() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Contract value)  $default,){
final _that = this;
switch (_that) {
case _Contract():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Contract value)?  $default,){
final _that = this;
switch (_that) {
case _Contract() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'name')  String name, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'min_delivery_date')  String minDeliveryDate, @JsonKey(name: 'max_delivery_date')  String maxDeliveryDate, @JsonKey(name: 'delivery_count')  int deliveryCount, @JsonKey(name: 'season_year')  int seasonYear, @JsonKey(name: 'product_prices')  List<ProductPrice> productPrices,  List<String> coordinators,  List<ContractMember> members,  ContractStatus status, @JsonKey(name: 'delivery_template_id')  String? deliveryTemplateId, @JsonKey(name: 'shared_baskets')  List<SharedBasket> sharedBaskets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Contract() when $default != null:
return $default(_that.contractId,_that.name,_that.organizationId,_that.producerAccountId,_that.minDeliveryDate,_that.maxDeliveryDate,_that.deliveryCount,_that.seasonYear,_that.productPrices,_that.coordinators,_that.members,_that.status,_that.deliveryTemplateId,_that.sharedBaskets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'name')  String name, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'min_delivery_date')  String minDeliveryDate, @JsonKey(name: 'max_delivery_date')  String maxDeliveryDate, @JsonKey(name: 'delivery_count')  int deliveryCount, @JsonKey(name: 'season_year')  int seasonYear, @JsonKey(name: 'product_prices')  List<ProductPrice> productPrices,  List<String> coordinators,  List<ContractMember> members,  ContractStatus status, @JsonKey(name: 'delivery_template_id')  String? deliveryTemplateId, @JsonKey(name: 'shared_baskets')  List<SharedBasket> sharedBaskets)  $default,) {final _that = this;
switch (_that) {
case _Contract():
return $default(_that.contractId,_that.name,_that.organizationId,_that.producerAccountId,_that.minDeliveryDate,_that.maxDeliveryDate,_that.deliveryCount,_that.seasonYear,_that.productPrices,_that.coordinators,_that.members,_that.status,_that.deliveryTemplateId,_that.sharedBaskets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'name')  String name, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'producer_account_id')  String producerAccountId, @JsonKey(name: 'min_delivery_date')  String minDeliveryDate, @JsonKey(name: 'max_delivery_date')  String maxDeliveryDate, @JsonKey(name: 'delivery_count')  int deliveryCount, @JsonKey(name: 'season_year')  int seasonYear, @JsonKey(name: 'product_prices')  List<ProductPrice> productPrices,  List<String> coordinators,  List<ContractMember> members,  ContractStatus status, @JsonKey(name: 'delivery_template_id')  String? deliveryTemplateId, @JsonKey(name: 'shared_baskets')  List<SharedBasket> sharedBaskets)?  $default,) {final _that = this;
switch (_that) {
case _Contract() when $default != null:
return $default(_that.contractId,_that.name,_that.organizationId,_that.producerAccountId,_that.minDeliveryDate,_that.maxDeliveryDate,_that.deliveryCount,_that.seasonYear,_that.productPrices,_that.coordinators,_that.members,_that.status,_that.deliveryTemplateId,_that.sharedBaskets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Contract implements Contract {
  const _Contract({@JsonKey(name: 'contract_id') required this.contractId, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'organization_id') required this.organizationId, @JsonKey(name: 'producer_account_id') required this.producerAccountId, @JsonKey(name: 'min_delivery_date') required this.minDeliveryDate, @JsonKey(name: 'max_delivery_date') required this.maxDeliveryDate, @JsonKey(name: 'delivery_count') required this.deliveryCount, @JsonKey(name: 'season_year') required this.seasonYear, @JsonKey(name: 'product_prices') final  List<ProductPrice> productPrices = const [], final  List<String> coordinators = const [], final  List<ContractMember> members = const [], this.status = ContractStatus.inPreparation, @JsonKey(name: 'delivery_template_id') this.deliveryTemplateId, @JsonKey(name: 'shared_baskets') final  List<SharedBasket> sharedBaskets = const []}): _productPrices = productPrices,_coordinators = coordinators,_members = members,_sharedBaskets = sharedBaskets;
  factory _Contract.fromJson(Map<String, dynamic> json) => _$ContractFromJson(json);

@override@JsonKey(name: 'contract_id') final  String contractId;
@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'organization_id') final  String organizationId;
@override@JsonKey(name: 'producer_account_id') final  String producerAccountId;
@override@JsonKey(name: 'min_delivery_date') final  String minDeliveryDate;
@override@JsonKey(name: 'max_delivery_date') final  String maxDeliveryDate;
@override@JsonKey(name: 'delivery_count') final  int deliveryCount;
@override@JsonKey(name: 'season_year') final  int seasonYear;
 final  List<ProductPrice> _productPrices;
@override@JsonKey(name: 'product_prices') List<ProductPrice> get productPrices {
  if (_productPrices is EqualUnmodifiableListView) return _productPrices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productPrices);
}

 final  List<String> _coordinators;
@override@JsonKey() List<String> get coordinators {
  if (_coordinators is EqualUnmodifiableListView) return _coordinators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coordinators);
}

 final  List<ContractMember> _members;
@override@JsonKey() List<ContractMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override@JsonKey() final  ContractStatus status;
@override@JsonKey(name: 'delivery_template_id') final  String? deliveryTemplateId;
 final  List<SharedBasket> _sharedBaskets;
@override@JsonKey(name: 'shared_baskets') List<SharedBasket> get sharedBaskets {
  if (_sharedBaskets is EqualUnmodifiableListView) return _sharedBaskets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sharedBaskets);
}


/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractCopyWith<_Contract> get copyWith => __$ContractCopyWithImpl<_Contract>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contract&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.minDeliveryDate, minDeliveryDate) || other.minDeliveryDate == minDeliveryDate)&&(identical(other.maxDeliveryDate, maxDeliveryDate) || other.maxDeliveryDate == maxDeliveryDate)&&(identical(other.deliveryCount, deliveryCount) || other.deliveryCount == deliveryCount)&&(identical(other.seasonYear, seasonYear) || other.seasonYear == seasonYear)&&const DeepCollectionEquality().equals(other._productPrices, _productPrices)&&const DeepCollectionEquality().equals(other._coordinators, _coordinators)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryTemplateId, deliveryTemplateId) || other.deliveryTemplateId == deliveryTemplateId)&&const DeepCollectionEquality().equals(other._sharedBaskets, _sharedBaskets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractId,name,organizationId,producerAccountId,minDeliveryDate,maxDeliveryDate,deliveryCount,seasonYear,const DeepCollectionEquality().hash(_productPrices),const DeepCollectionEquality().hash(_coordinators),const DeepCollectionEquality().hash(_members),status,deliveryTemplateId,const DeepCollectionEquality().hash(_sharedBaskets));

@override
String toString() {
  return 'Contract(contractId: $contractId, name: $name, organizationId: $organizationId, producerAccountId: $producerAccountId, minDeliveryDate: $minDeliveryDate, maxDeliveryDate: $maxDeliveryDate, deliveryCount: $deliveryCount, seasonYear: $seasonYear, productPrices: $productPrices, coordinators: $coordinators, members: $members, status: $status, deliveryTemplateId: $deliveryTemplateId, sharedBaskets: $sharedBaskets)';
}


}

/// @nodoc
abstract mixin class _$ContractCopyWith<$Res> implements $ContractCopyWith<$Res> {
  factory _$ContractCopyWith(_Contract value, $Res Function(_Contract) _then) = __$ContractCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'name') String name,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'producer_account_id') String producerAccountId,@JsonKey(name: 'min_delivery_date') String minDeliveryDate,@JsonKey(name: 'max_delivery_date') String maxDeliveryDate,@JsonKey(name: 'delivery_count') int deliveryCount,@JsonKey(name: 'season_year') int seasonYear,@JsonKey(name: 'product_prices') List<ProductPrice> productPrices, List<String> coordinators, List<ContractMember> members, ContractStatus status,@JsonKey(name: 'delivery_template_id') String? deliveryTemplateId,@JsonKey(name: 'shared_baskets') List<SharedBasket> sharedBaskets
});




}
/// @nodoc
class __$ContractCopyWithImpl<$Res>
    implements _$ContractCopyWith<$Res> {
  __$ContractCopyWithImpl(this._self, this._then);

  final _Contract _self;
  final $Res Function(_Contract) _then;

/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractId = null,Object? name = null,Object? organizationId = null,Object? producerAccountId = null,Object? minDeliveryDate = null,Object? maxDeliveryDate = null,Object? deliveryCount = null,Object? seasonYear = null,Object? productPrices = null,Object? coordinators = null,Object? members = null,Object? status = null,Object? deliveryTemplateId = freezed,Object? sharedBaskets = null,}) {
  return _then(_Contract(
contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,minDeliveryDate: null == minDeliveryDate ? _self.minDeliveryDate : minDeliveryDate // ignore: cast_nullable_to_non_nullable
as String,maxDeliveryDate: null == maxDeliveryDate ? _self.maxDeliveryDate : maxDeliveryDate // ignore: cast_nullable_to_non_nullable
as String,deliveryCount: null == deliveryCount ? _self.deliveryCount : deliveryCount // ignore: cast_nullable_to_non_nullable
as int,seasonYear: null == seasonYear ? _self.seasonYear : seasonYear // ignore: cast_nullable_to_non_nullable
as int,productPrices: null == productPrices ? _self._productPrices : productPrices // ignore: cast_nullable_to_non_nullable
as List<ProductPrice>,coordinators: null == coordinators ? _self._coordinators : coordinators // ignore: cast_nullable_to_non_nullable
as List<String>,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<ContractMember>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractStatus,deliveryTemplateId: freezed == deliveryTemplateId ? _self.deliveryTemplateId : deliveryTemplateId // ignore: cast_nullable_to_non_nullable
as String?,sharedBaskets: null == sharedBaskets ? _self._sharedBaskets : sharedBaskets // ignore: cast_nullable_to_non_nullable
as List<SharedBasket>,
  ));
}


}

// dart format on
