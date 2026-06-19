// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entity_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductTypePayload {

 ProductType get productType;
/// Create a copy of ProductTypePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductTypePayloadCopyWith<ProductTypePayload> get copyWith => _$ProductTypePayloadCopyWithImpl<ProductTypePayload>(this as ProductTypePayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductTypePayload&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hash(runtimeType,productType);

@override
String toString() {
  return 'ProductTypePayload(productType: $productType)';
}


}

/// @nodoc
abstract mixin class $ProductTypePayloadCopyWith<$Res>  {
  factory $ProductTypePayloadCopyWith(ProductTypePayload value, $Res Function(ProductTypePayload) _then) = _$ProductTypePayloadCopyWithImpl;
@useResult
$Res call({
 ProductType productType
});


$ProductTypeCopyWith<$Res> get productType;

}
/// @nodoc
class _$ProductTypePayloadCopyWithImpl<$Res>
    implements $ProductTypePayloadCopyWith<$Res> {
  _$ProductTypePayloadCopyWithImpl(this._self, this._then);

  final ProductTypePayload _self;
  final $Res Function(ProductTypePayload) _then;

/// Create a copy of ProductTypePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productType = null,}) {
  return _then(_self.copyWith(
productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}
/// Create a copy of ProductTypePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductTypeCopyWith<$Res> get productType {
  
  return $ProductTypeCopyWith<$Res>(_self.productType, (value) {
    return _then(_self.copyWith(productType: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductTypePayload].
extension ProductTypePayloadPatterns on ProductTypePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductTypePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductTypePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductTypePayload value)  $default,){
final _that = this;
switch (_that) {
case _ProductTypePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductTypePayload value)?  $default,){
final _that = this;
switch (_that) {
case _ProductTypePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProductType productType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductTypePayload() when $default != null:
return $default(_that.productType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProductType productType)  $default,) {final _that = this;
switch (_that) {
case _ProductTypePayload():
return $default(_that.productType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProductType productType)?  $default,) {final _that = this;
switch (_that) {
case _ProductTypePayload() when $default != null:
return $default(_that.productType);case _:
  return null;

}
}

}

/// @nodoc


class _ProductTypePayload extends ProductTypePayload {
  const _ProductTypePayload({required this.productType}): super._();
  

@override final  ProductType productType;

/// Create a copy of ProductTypePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductTypePayloadCopyWith<_ProductTypePayload> get copyWith => __$ProductTypePayloadCopyWithImpl<_ProductTypePayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductTypePayload&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hash(runtimeType,productType);

@override
String toString() {
  return 'ProductTypePayload(productType: $productType)';
}


}

/// @nodoc
abstract mixin class _$ProductTypePayloadCopyWith<$Res> implements $ProductTypePayloadCopyWith<$Res> {
  factory _$ProductTypePayloadCopyWith(_ProductTypePayload value, $Res Function(_ProductTypePayload) _then) = __$ProductTypePayloadCopyWithImpl;
@override @useResult
$Res call({
 ProductType productType
});


@override $ProductTypeCopyWith<$Res> get productType;

}
/// @nodoc
class __$ProductTypePayloadCopyWithImpl<$Res>
    implements _$ProductTypePayloadCopyWith<$Res> {
  __$ProductTypePayloadCopyWithImpl(this._self, this._then);

  final _ProductTypePayload _self;
  final $Res Function(_ProductTypePayload) _then;

/// Create a copy of ProductTypePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productType = null,}) {
  return _then(_ProductTypePayload(
productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}

/// Create a copy of ProductTypePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductTypeCopyWith<$Res> get productType {
  
  return $ProductTypeCopyWith<$Res>(_self.productType, (value) {
    return _then(_self.copyWith(productType: value));
  });
}
}

/// @nodoc
mixin _$OrganizationPayload {

 Organization get organization;
/// Create a copy of OrganizationPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationPayloadCopyWith<OrganizationPayload> get copyWith => _$OrganizationPayloadCopyWithImpl<OrganizationPayload>(this as OrganizationPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationPayload&&(identical(other.organization, organization) || other.organization == organization));
}


@override
int get hashCode => Object.hash(runtimeType,organization);

@override
String toString() {
  return 'OrganizationPayload(organization: $organization)';
}


}

/// @nodoc
abstract mixin class $OrganizationPayloadCopyWith<$Res>  {
  factory $OrganizationPayloadCopyWith(OrganizationPayload value, $Res Function(OrganizationPayload) _then) = _$OrganizationPayloadCopyWithImpl;
@useResult
$Res call({
 Organization organization
});


$OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class _$OrganizationPayloadCopyWithImpl<$Res>
    implements $OrganizationPayloadCopyWith<$Res> {
  _$OrganizationPayloadCopyWithImpl(this._self, this._then);

  final OrganizationPayload _self;
  final $Res Function(OrganizationPayload) _then;

/// Create a copy of OrganizationPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organization = null,}) {
  return _then(_self.copyWith(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,
  ));
}
/// Create a copy of OrganizationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get organization {
  
  return $OrganizationCopyWith<$Res>(_self.organization, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrganizationPayload].
extension OrganizationPayloadPatterns on OrganizationPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationPayload value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationPayload value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Organization organization)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationPayload() when $default != null:
return $default(_that.organization);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Organization organization)  $default,) {final _that = this;
switch (_that) {
case _OrganizationPayload():
return $default(_that.organization);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Organization organization)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationPayload() when $default != null:
return $default(_that.organization);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationPayload extends OrganizationPayload {
  const _OrganizationPayload({required this.organization}): super._();
  

@override final  Organization organization;

/// Create a copy of OrganizationPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationPayloadCopyWith<_OrganizationPayload> get copyWith => __$OrganizationPayloadCopyWithImpl<_OrganizationPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationPayload&&(identical(other.organization, organization) || other.organization == organization));
}


@override
int get hashCode => Object.hash(runtimeType,organization);

@override
String toString() {
  return 'OrganizationPayload(organization: $organization)';
}


}

/// @nodoc
abstract mixin class _$OrganizationPayloadCopyWith<$Res> implements $OrganizationPayloadCopyWith<$Res> {
  factory _$OrganizationPayloadCopyWith(_OrganizationPayload value, $Res Function(_OrganizationPayload) _then) = __$OrganizationPayloadCopyWithImpl;
@override @useResult
$Res call({
 Organization organization
});


@override $OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class __$OrganizationPayloadCopyWithImpl<$Res>
    implements _$OrganizationPayloadCopyWith<$Res> {
  __$OrganizationPayloadCopyWithImpl(this._self, this._then);

  final _OrganizationPayload _self;
  final $Res Function(_OrganizationPayload) _then;

/// Create a copy of OrganizationPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organization = null,}) {
  return _then(_OrganizationPayload(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,
  ));
}

/// Create a copy of OrganizationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get organization {
  
  return $OrganizationCopyWith<$Res>(_self.organization, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}

/// @nodoc
mixin _$ProducerAccountPayload {

 ProducerAccount get producerAccount;
/// Create a copy of ProducerAccountPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerAccountPayloadCopyWith<ProducerAccountPayload> get copyWith => _$ProducerAccountPayloadCopyWithImpl<ProducerAccountPayload>(this as ProducerAccountPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerAccountPayload&&(identical(other.producerAccount, producerAccount) || other.producerAccount == producerAccount));
}


@override
int get hashCode => Object.hash(runtimeType,producerAccount);

@override
String toString() {
  return 'ProducerAccountPayload(producerAccount: $producerAccount)';
}


}

/// @nodoc
abstract mixin class $ProducerAccountPayloadCopyWith<$Res>  {
  factory $ProducerAccountPayloadCopyWith(ProducerAccountPayload value, $Res Function(ProducerAccountPayload) _then) = _$ProducerAccountPayloadCopyWithImpl;
@useResult
$Res call({
 ProducerAccount producerAccount
});


$ProducerAccountCopyWith<$Res> get producerAccount;

}
/// @nodoc
class _$ProducerAccountPayloadCopyWithImpl<$Res>
    implements $ProducerAccountPayloadCopyWith<$Res> {
  _$ProducerAccountPayloadCopyWithImpl(this._self, this._then);

  final ProducerAccountPayload _self;
  final $Res Function(ProducerAccountPayload) _then;

/// Create a copy of ProducerAccountPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? producerAccount = null,}) {
  return _then(_self.copyWith(
producerAccount: null == producerAccount ? _self.producerAccount : producerAccount // ignore: cast_nullable_to_non_nullable
as ProducerAccount,
  ));
}
/// Create a copy of ProducerAccountPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProducerAccountCopyWith<$Res> get producerAccount {
  
  return $ProducerAccountCopyWith<$Res>(_self.producerAccount, (value) {
    return _then(_self.copyWith(producerAccount: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProducerAccountPayload].
extension ProducerAccountPayloadPatterns on ProducerAccountPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerAccountPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerAccountPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerAccountPayload value)  $default,){
final _that = this;
switch (_that) {
case _ProducerAccountPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerAccountPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerAccountPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProducerAccount producerAccount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerAccountPayload() when $default != null:
return $default(_that.producerAccount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProducerAccount producerAccount)  $default,) {final _that = this;
switch (_that) {
case _ProducerAccountPayload():
return $default(_that.producerAccount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProducerAccount producerAccount)?  $default,) {final _that = this;
switch (_that) {
case _ProducerAccountPayload() when $default != null:
return $default(_that.producerAccount);case _:
  return null;

}
}

}

/// @nodoc


class _ProducerAccountPayload extends ProducerAccountPayload {
  const _ProducerAccountPayload({required this.producerAccount}): super._();
  

@override final  ProducerAccount producerAccount;

/// Create a copy of ProducerAccountPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerAccountPayloadCopyWith<_ProducerAccountPayload> get copyWith => __$ProducerAccountPayloadCopyWithImpl<_ProducerAccountPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerAccountPayload&&(identical(other.producerAccount, producerAccount) || other.producerAccount == producerAccount));
}


@override
int get hashCode => Object.hash(runtimeType,producerAccount);

@override
String toString() {
  return 'ProducerAccountPayload(producerAccount: $producerAccount)';
}


}

/// @nodoc
abstract mixin class _$ProducerAccountPayloadCopyWith<$Res> implements $ProducerAccountPayloadCopyWith<$Res> {
  factory _$ProducerAccountPayloadCopyWith(_ProducerAccountPayload value, $Res Function(_ProducerAccountPayload) _then) = __$ProducerAccountPayloadCopyWithImpl;
@override @useResult
$Res call({
 ProducerAccount producerAccount
});


@override $ProducerAccountCopyWith<$Res> get producerAccount;

}
/// @nodoc
class __$ProducerAccountPayloadCopyWithImpl<$Res>
    implements _$ProducerAccountPayloadCopyWith<$Res> {
  __$ProducerAccountPayloadCopyWithImpl(this._self, this._then);

  final _ProducerAccountPayload _self;
  final $Res Function(_ProducerAccountPayload) _then;

/// Create a copy of ProducerAccountPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? producerAccount = null,}) {
  return _then(_ProducerAccountPayload(
producerAccount: null == producerAccount ? _self.producerAccount : producerAccount // ignore: cast_nullable_to_non_nullable
as ProducerAccount,
  ));
}

/// Create a copy of ProducerAccountPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProducerAccountCopyWith<$Res> get producerAccount {
  
  return $ProducerAccountCopyWith<$Res>(_self.producerAccount, (value) {
    return _then(_self.copyWith(producerAccount: value));
  });
}
}

/// @nodoc
mixin _$MemberPayload {

 Member get member;
/// Create a copy of MemberPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberPayloadCopyWith<MemberPayload> get copyWith => _$MemberPayloadCopyWithImpl<MemberPayload>(this as MemberPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberPayload&&(identical(other.member, member) || other.member == member));
}


@override
int get hashCode => Object.hash(runtimeType,member);

@override
String toString() {
  return 'MemberPayload(member: $member)';
}


}

/// @nodoc
abstract mixin class $MemberPayloadCopyWith<$Res>  {
  factory $MemberPayloadCopyWith(MemberPayload value, $Res Function(MemberPayload) _then) = _$MemberPayloadCopyWithImpl;
@useResult
$Res call({
 Member member
});


$MemberCopyWith<$Res> get member;

}
/// @nodoc
class _$MemberPayloadCopyWithImpl<$Res>
    implements $MemberPayloadCopyWith<$Res> {
  _$MemberPayloadCopyWithImpl(this._self, this._then);

  final MemberPayload _self;
  final $Res Function(MemberPayload) _then;

/// Create a copy of MemberPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? member = null,}) {
  return _then(_self.copyWith(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as Member,
  ));
}
/// Create a copy of MemberPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberCopyWith<$Res> get member {
  
  return $MemberCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}
}


/// Adds pattern-matching-related methods to [MemberPayload].
extension MemberPayloadPatterns on MemberPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberPayload value)  $default,){
final _that = this;
switch (_that) {
case _MemberPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberPayload value)?  $default,){
final _that = this;
switch (_that) {
case _MemberPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Member member)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberPayload() when $default != null:
return $default(_that.member);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Member member)  $default,) {final _that = this;
switch (_that) {
case _MemberPayload():
return $default(_that.member);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Member member)?  $default,) {final _that = this;
switch (_that) {
case _MemberPayload() when $default != null:
return $default(_that.member);case _:
  return null;

}
}

}

/// @nodoc


class _MemberPayload extends MemberPayload {
  const _MemberPayload({required this.member}): super._();
  

@override final  Member member;

/// Create a copy of MemberPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberPayloadCopyWith<_MemberPayload> get copyWith => __$MemberPayloadCopyWithImpl<_MemberPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberPayload&&(identical(other.member, member) || other.member == member));
}


@override
int get hashCode => Object.hash(runtimeType,member);

@override
String toString() {
  return 'MemberPayload(member: $member)';
}


}

/// @nodoc
abstract mixin class _$MemberPayloadCopyWith<$Res> implements $MemberPayloadCopyWith<$Res> {
  factory _$MemberPayloadCopyWith(_MemberPayload value, $Res Function(_MemberPayload) _then) = __$MemberPayloadCopyWithImpl;
@override @useResult
$Res call({
 Member member
});


@override $MemberCopyWith<$Res> get member;

}
/// @nodoc
class __$MemberPayloadCopyWithImpl<$Res>
    implements _$MemberPayloadCopyWith<$Res> {
  __$MemberPayloadCopyWithImpl(this._self, this._then);

  final _MemberPayload _self;
  final $Res Function(_MemberPayload) _then;

/// Create a copy of MemberPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? member = null,}) {
  return _then(_MemberPayload(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as Member,
  ));
}

/// Create a copy of MemberPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberCopyWith<$Res> get member {
  
  return $MemberCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}
}

/// @nodoc
mixin _$MemberJoinRequestPayload {

 AdminMemberJoinRequest get memberJoinRequest;
/// Create a copy of MemberJoinRequestPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberJoinRequestPayloadCopyWith<MemberJoinRequestPayload> get copyWith => _$MemberJoinRequestPayloadCopyWithImpl<MemberJoinRequestPayload>(this as MemberJoinRequestPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberJoinRequestPayload&&(identical(other.memberJoinRequest, memberJoinRequest) || other.memberJoinRequest == memberJoinRequest));
}


@override
int get hashCode => Object.hash(runtimeType,memberJoinRequest);

@override
String toString() {
  return 'MemberJoinRequestPayload(memberJoinRequest: $memberJoinRequest)';
}


}

/// @nodoc
abstract mixin class $MemberJoinRequestPayloadCopyWith<$Res>  {
  factory $MemberJoinRequestPayloadCopyWith(MemberJoinRequestPayload value, $Res Function(MemberJoinRequestPayload) _then) = _$MemberJoinRequestPayloadCopyWithImpl;
@useResult
$Res call({
 AdminMemberJoinRequest memberJoinRequest
});


$AdminMemberJoinRequestCopyWith<$Res> get memberJoinRequest;

}
/// @nodoc
class _$MemberJoinRequestPayloadCopyWithImpl<$Res>
    implements $MemberJoinRequestPayloadCopyWith<$Res> {
  _$MemberJoinRequestPayloadCopyWithImpl(this._self, this._then);

  final MemberJoinRequestPayload _self;
  final $Res Function(MemberJoinRequestPayload) _then;

/// Create a copy of MemberJoinRequestPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberJoinRequest = null,}) {
  return _then(_self.copyWith(
memberJoinRequest: null == memberJoinRequest ? _self.memberJoinRequest : memberJoinRequest // ignore: cast_nullable_to_non_nullable
as AdminMemberJoinRequest,
  ));
}
/// Create a copy of MemberJoinRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminMemberJoinRequestCopyWith<$Res> get memberJoinRequest {
  
  return $AdminMemberJoinRequestCopyWith<$Res>(_self.memberJoinRequest, (value) {
    return _then(_self.copyWith(memberJoinRequest: value));
  });
}
}


/// Adds pattern-matching-related methods to [MemberJoinRequestPayload].
extension MemberJoinRequestPayloadPatterns on MemberJoinRequestPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberJoinRequestPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberJoinRequestPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberJoinRequestPayload value)  $default,){
final _that = this;
switch (_that) {
case _MemberJoinRequestPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberJoinRequestPayload value)?  $default,){
final _that = this;
switch (_that) {
case _MemberJoinRequestPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdminMemberJoinRequest memberJoinRequest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberJoinRequestPayload() when $default != null:
return $default(_that.memberJoinRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdminMemberJoinRequest memberJoinRequest)  $default,) {final _that = this;
switch (_that) {
case _MemberJoinRequestPayload():
return $default(_that.memberJoinRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdminMemberJoinRequest memberJoinRequest)?  $default,) {final _that = this;
switch (_that) {
case _MemberJoinRequestPayload() when $default != null:
return $default(_that.memberJoinRequest);case _:
  return null;

}
}

}

/// @nodoc


class _MemberJoinRequestPayload extends MemberJoinRequestPayload {
  const _MemberJoinRequestPayload({required this.memberJoinRequest}): super._();
  

@override final  AdminMemberJoinRequest memberJoinRequest;

/// Create a copy of MemberJoinRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberJoinRequestPayloadCopyWith<_MemberJoinRequestPayload> get copyWith => __$MemberJoinRequestPayloadCopyWithImpl<_MemberJoinRequestPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberJoinRequestPayload&&(identical(other.memberJoinRequest, memberJoinRequest) || other.memberJoinRequest == memberJoinRequest));
}


@override
int get hashCode => Object.hash(runtimeType,memberJoinRequest);

@override
String toString() {
  return 'MemberJoinRequestPayload(memberJoinRequest: $memberJoinRequest)';
}


}

/// @nodoc
abstract mixin class _$MemberJoinRequestPayloadCopyWith<$Res> implements $MemberJoinRequestPayloadCopyWith<$Res> {
  factory _$MemberJoinRequestPayloadCopyWith(_MemberJoinRequestPayload value, $Res Function(_MemberJoinRequestPayload) _then) = __$MemberJoinRequestPayloadCopyWithImpl;
@override @useResult
$Res call({
 AdminMemberJoinRequest memberJoinRequest
});


@override $AdminMemberJoinRequestCopyWith<$Res> get memberJoinRequest;

}
/// @nodoc
class __$MemberJoinRequestPayloadCopyWithImpl<$Res>
    implements _$MemberJoinRequestPayloadCopyWith<$Res> {
  __$MemberJoinRequestPayloadCopyWithImpl(this._self, this._then);

  final _MemberJoinRequestPayload _self;
  final $Res Function(_MemberJoinRequestPayload) _then;

/// Create a copy of MemberJoinRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberJoinRequest = null,}) {
  return _then(_MemberJoinRequestPayload(
memberJoinRequest: null == memberJoinRequest ? _self.memberJoinRequest : memberJoinRequest // ignore: cast_nullable_to_non_nullable
as AdminMemberJoinRequest,
  ));
}

/// Create a copy of MemberJoinRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminMemberJoinRequestCopyWith<$Res> get memberJoinRequest {
  
  return $AdminMemberJoinRequestCopyWith<$Res>(_self.memberJoinRequest, (value) {
    return _then(_self.copyWith(memberJoinRequest: value));
  });
}
}

/// @nodoc
mixin _$ContractPayload {

 Contract get contract;
/// Create a copy of ContractPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractPayloadCopyWith<ContractPayload> get copyWith => _$ContractPayloadCopyWithImpl<ContractPayload>(this as ContractPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractPayload&&(identical(other.contract, contract) || other.contract == contract));
}


@override
int get hashCode => Object.hash(runtimeType,contract);

@override
String toString() {
  return 'ContractPayload(contract: $contract)';
}


}

/// @nodoc
abstract mixin class $ContractPayloadCopyWith<$Res>  {
  factory $ContractPayloadCopyWith(ContractPayload value, $Res Function(ContractPayload) _then) = _$ContractPayloadCopyWithImpl;
@useResult
$Res call({
 Contract contract
});


$ContractCopyWith<$Res> get contract;

}
/// @nodoc
class _$ContractPayloadCopyWithImpl<$Res>
    implements $ContractPayloadCopyWith<$Res> {
  _$ContractPayloadCopyWithImpl(this._self, this._then);

  final ContractPayload _self;
  final $Res Function(ContractPayload) _then;

/// Create a copy of ContractPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contract = null,}) {
  return _then(_self.copyWith(
contract: null == contract ? _self.contract : contract // ignore: cast_nullable_to_non_nullable
as Contract,
  ));
}
/// Create a copy of ContractPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContractCopyWith<$Res> get contract {
  
  return $ContractCopyWith<$Res>(_self.contract, (value) {
    return _then(_self.copyWith(contract: value));
  });
}
}


/// Adds pattern-matching-related methods to [ContractPayload].
extension ContractPayloadPatterns on ContractPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContractPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContractPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContractPayload value)  $default,){
final _that = this;
switch (_that) {
case _ContractPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContractPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ContractPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Contract contract)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContractPayload() when $default != null:
return $default(_that.contract);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Contract contract)  $default,) {final _that = this;
switch (_that) {
case _ContractPayload():
return $default(_that.contract);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Contract contract)?  $default,) {final _that = this;
switch (_that) {
case _ContractPayload() when $default != null:
return $default(_that.contract);case _:
  return null;

}
}

}

/// @nodoc


class _ContractPayload extends ContractPayload {
  const _ContractPayload({required this.contract}): super._();
  

@override final  Contract contract;

/// Create a copy of ContractPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractPayloadCopyWith<_ContractPayload> get copyWith => __$ContractPayloadCopyWithImpl<_ContractPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractPayload&&(identical(other.contract, contract) || other.contract == contract));
}


@override
int get hashCode => Object.hash(runtimeType,contract);

@override
String toString() {
  return 'ContractPayload(contract: $contract)';
}


}

/// @nodoc
abstract mixin class _$ContractPayloadCopyWith<$Res> implements $ContractPayloadCopyWith<$Res> {
  factory _$ContractPayloadCopyWith(_ContractPayload value, $Res Function(_ContractPayload) _then) = __$ContractPayloadCopyWithImpl;
@override @useResult
$Res call({
 Contract contract
});


@override $ContractCopyWith<$Res> get contract;

}
/// @nodoc
class __$ContractPayloadCopyWithImpl<$Res>
    implements _$ContractPayloadCopyWith<$Res> {
  __$ContractPayloadCopyWithImpl(this._self, this._then);

  final _ContractPayload _self;
  final $Res Function(_ContractPayload) _then;

/// Create a copy of ContractPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contract = null,}) {
  return _then(_ContractPayload(
contract: null == contract ? _self.contract : contract // ignore: cast_nullable_to_non_nullable
as Contract,
  ));
}

/// Create a copy of ContractPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContractCopyWith<$Res> get contract {
  
  return $ContractCopyWith<$Res>(_self.contract, (value) {
    return _then(_self.copyWith(contract: value));
  });
}
}

/// @nodoc
mixin _$DeliveryTemplatePayload {

 DeliveryTemplate get deliveryTemplate;
/// Create a copy of DeliveryTemplatePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryTemplatePayloadCopyWith<DeliveryTemplatePayload> get copyWith => _$DeliveryTemplatePayloadCopyWithImpl<DeliveryTemplatePayload>(this as DeliveryTemplatePayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplatePayload&&(identical(other.deliveryTemplate, deliveryTemplate) || other.deliveryTemplate == deliveryTemplate));
}


@override
int get hashCode => Object.hash(runtimeType,deliveryTemplate);

@override
String toString() {
  return 'DeliveryTemplatePayload(deliveryTemplate: $deliveryTemplate)';
}


}

/// @nodoc
abstract mixin class $DeliveryTemplatePayloadCopyWith<$Res>  {
  factory $DeliveryTemplatePayloadCopyWith(DeliveryTemplatePayload value, $Res Function(DeliveryTemplatePayload) _then) = _$DeliveryTemplatePayloadCopyWithImpl;
@useResult
$Res call({
 DeliveryTemplate deliveryTemplate
});


$DeliveryTemplateCopyWith<$Res> get deliveryTemplate;

}
/// @nodoc
class _$DeliveryTemplatePayloadCopyWithImpl<$Res>
    implements $DeliveryTemplatePayloadCopyWith<$Res> {
  _$DeliveryTemplatePayloadCopyWithImpl(this._self, this._then);

  final DeliveryTemplatePayload _self;
  final $Res Function(DeliveryTemplatePayload) _then;

/// Create a copy of DeliveryTemplatePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deliveryTemplate = null,}) {
  return _then(_self.copyWith(
deliveryTemplate: null == deliveryTemplate ? _self.deliveryTemplate : deliveryTemplate // ignore: cast_nullable_to_non_nullable
as DeliveryTemplate,
  ));
}
/// Create a copy of DeliveryTemplatePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryTemplateCopyWith<$Res> get deliveryTemplate {
  
  return $DeliveryTemplateCopyWith<$Res>(_self.deliveryTemplate, (value) {
    return _then(_self.copyWith(deliveryTemplate: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeliveryTemplatePayload].
extension DeliveryTemplatePayloadPatterns on DeliveryTemplatePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryTemplatePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryTemplatePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryTemplatePayload value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryTemplatePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryTemplatePayload value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryTemplatePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeliveryTemplate deliveryTemplate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryTemplatePayload() when $default != null:
return $default(_that.deliveryTemplate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeliveryTemplate deliveryTemplate)  $default,) {final _that = this;
switch (_that) {
case _DeliveryTemplatePayload():
return $default(_that.deliveryTemplate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeliveryTemplate deliveryTemplate)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryTemplatePayload() when $default != null:
return $default(_that.deliveryTemplate);case _:
  return null;

}
}

}

/// @nodoc


class _DeliveryTemplatePayload extends DeliveryTemplatePayload {
  const _DeliveryTemplatePayload({required this.deliveryTemplate}): super._();
  

@override final  DeliveryTemplate deliveryTemplate;

/// Create a copy of DeliveryTemplatePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryTemplatePayloadCopyWith<_DeliveryTemplatePayload> get copyWith => __$DeliveryTemplatePayloadCopyWithImpl<_DeliveryTemplatePayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryTemplatePayload&&(identical(other.deliveryTemplate, deliveryTemplate) || other.deliveryTemplate == deliveryTemplate));
}


@override
int get hashCode => Object.hash(runtimeType,deliveryTemplate);

@override
String toString() {
  return 'DeliveryTemplatePayload(deliveryTemplate: $deliveryTemplate)';
}


}

/// @nodoc
abstract mixin class _$DeliveryTemplatePayloadCopyWith<$Res> implements $DeliveryTemplatePayloadCopyWith<$Res> {
  factory _$DeliveryTemplatePayloadCopyWith(_DeliveryTemplatePayload value, $Res Function(_DeliveryTemplatePayload) _then) = __$DeliveryTemplatePayloadCopyWithImpl;
@override @useResult
$Res call({
 DeliveryTemplate deliveryTemplate
});


@override $DeliveryTemplateCopyWith<$Res> get deliveryTemplate;

}
/// @nodoc
class __$DeliveryTemplatePayloadCopyWithImpl<$Res>
    implements _$DeliveryTemplatePayloadCopyWith<$Res> {
  __$DeliveryTemplatePayloadCopyWithImpl(this._self, this._then);

  final _DeliveryTemplatePayload _self;
  final $Res Function(_DeliveryTemplatePayload) _then;

/// Create a copy of DeliveryTemplatePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deliveryTemplate = null,}) {
  return _then(_DeliveryTemplatePayload(
deliveryTemplate: null == deliveryTemplate ? _self.deliveryTemplate : deliveryTemplate // ignore: cast_nullable_to_non_nullable
as DeliveryTemplate,
  ));
}

/// Create a copy of DeliveryTemplatePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryTemplateCopyWith<$Res> get deliveryTemplate {
  
  return $DeliveryTemplateCopyWith<$Res>(_self.deliveryTemplate, (value) {
    return _then(_self.copyWith(deliveryTemplate: value));
  });
}
}

/// @nodoc
mixin _$OrganizationRequestPayload {

 AdminOrganizationRequest get organizationRequest;
/// Create a copy of OrganizationRequestPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationRequestPayloadCopyWith<OrganizationRequestPayload> get copyWith => _$OrganizationRequestPayloadCopyWithImpl<OrganizationRequestPayload>(this as OrganizationRequestPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationRequestPayload&&(identical(other.organizationRequest, organizationRequest) || other.organizationRequest == organizationRequest));
}


@override
int get hashCode => Object.hash(runtimeType,organizationRequest);

@override
String toString() {
  return 'OrganizationRequestPayload(organizationRequest: $organizationRequest)';
}


}

/// @nodoc
abstract mixin class $OrganizationRequestPayloadCopyWith<$Res>  {
  factory $OrganizationRequestPayloadCopyWith(OrganizationRequestPayload value, $Res Function(OrganizationRequestPayload) _then) = _$OrganizationRequestPayloadCopyWithImpl;
@useResult
$Res call({
 AdminOrganizationRequest organizationRequest
});


$AdminOrganizationRequestCopyWith<$Res> get organizationRequest;

}
/// @nodoc
class _$OrganizationRequestPayloadCopyWithImpl<$Res>
    implements $OrganizationRequestPayloadCopyWith<$Res> {
  _$OrganizationRequestPayloadCopyWithImpl(this._self, this._then);

  final OrganizationRequestPayload _self;
  final $Res Function(OrganizationRequestPayload) _then;

/// Create a copy of OrganizationRequestPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationRequest = null,}) {
  return _then(_self.copyWith(
organizationRequest: null == organizationRequest ? _self.organizationRequest : organizationRequest // ignore: cast_nullable_to_non_nullable
as AdminOrganizationRequest,
  ));
}
/// Create a copy of OrganizationRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminOrganizationRequestCopyWith<$Res> get organizationRequest {
  
  return $AdminOrganizationRequestCopyWith<$Res>(_self.organizationRequest, (value) {
    return _then(_self.copyWith(organizationRequest: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrganizationRequestPayload].
extension OrganizationRequestPayloadPatterns on OrganizationRequestPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationRequestPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationRequestPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationRequestPayload value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationRequestPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationRequestPayload value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationRequestPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdminOrganizationRequest organizationRequest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationRequestPayload() when $default != null:
return $default(_that.organizationRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdminOrganizationRequest organizationRequest)  $default,) {final _that = this;
switch (_that) {
case _OrganizationRequestPayload():
return $default(_that.organizationRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdminOrganizationRequest organizationRequest)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationRequestPayload() when $default != null:
return $default(_that.organizationRequest);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationRequestPayload extends OrganizationRequestPayload {
  const _OrganizationRequestPayload({required this.organizationRequest}): super._();
  

@override final  AdminOrganizationRequest organizationRequest;

/// Create a copy of OrganizationRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationRequestPayloadCopyWith<_OrganizationRequestPayload> get copyWith => __$OrganizationRequestPayloadCopyWithImpl<_OrganizationRequestPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationRequestPayload&&(identical(other.organizationRequest, organizationRequest) || other.organizationRequest == organizationRequest));
}


@override
int get hashCode => Object.hash(runtimeType,organizationRequest);

@override
String toString() {
  return 'OrganizationRequestPayload(organizationRequest: $organizationRequest)';
}


}

/// @nodoc
abstract mixin class _$OrganizationRequestPayloadCopyWith<$Res> implements $OrganizationRequestPayloadCopyWith<$Res> {
  factory _$OrganizationRequestPayloadCopyWith(_OrganizationRequestPayload value, $Res Function(_OrganizationRequestPayload) _then) = __$OrganizationRequestPayloadCopyWithImpl;
@override @useResult
$Res call({
 AdminOrganizationRequest organizationRequest
});


@override $AdminOrganizationRequestCopyWith<$Res> get organizationRequest;

}
/// @nodoc
class __$OrganizationRequestPayloadCopyWithImpl<$Res>
    implements _$OrganizationRequestPayloadCopyWith<$Res> {
  __$OrganizationRequestPayloadCopyWithImpl(this._self, this._then);

  final _OrganizationRequestPayload _self;
  final $Res Function(_OrganizationRequestPayload) _then;

/// Create a copy of OrganizationRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationRequest = null,}) {
  return _then(_OrganizationRequestPayload(
organizationRequest: null == organizationRequest ? _self.organizationRequest : organizationRequest // ignore: cast_nullable_to_non_nullable
as AdminOrganizationRequest,
  ));
}

/// Create a copy of OrganizationRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminOrganizationRequestCopyWith<$Res> get organizationRequest {
  
  return $AdminOrganizationRequestCopyWith<$Res>(_self.organizationRequest, (value) {
    return _then(_self.copyWith(organizationRequest: value));
  });
}
}

/// @nodoc
mixin _$ProducerRequestPayload {

 AdminProducerRequest get producerRequest;
/// Create a copy of ProducerRequestPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestPayloadCopyWith<ProducerRequestPayload> get copyWith => _$ProducerRequestPayloadCopyWithImpl<ProducerRequestPayload>(this as ProducerRequestPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestPayload&&(identical(other.producerRequest, producerRequest) || other.producerRequest == producerRequest));
}


@override
int get hashCode => Object.hash(runtimeType,producerRequest);

@override
String toString() {
  return 'ProducerRequestPayload(producerRequest: $producerRequest)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestPayloadCopyWith<$Res>  {
  factory $ProducerRequestPayloadCopyWith(ProducerRequestPayload value, $Res Function(ProducerRequestPayload) _then) = _$ProducerRequestPayloadCopyWithImpl;
@useResult
$Res call({
 AdminProducerRequest producerRequest
});


$AdminProducerRequestCopyWith<$Res> get producerRequest;

}
/// @nodoc
class _$ProducerRequestPayloadCopyWithImpl<$Res>
    implements $ProducerRequestPayloadCopyWith<$Res> {
  _$ProducerRequestPayloadCopyWithImpl(this._self, this._then);

  final ProducerRequestPayload _self;
  final $Res Function(ProducerRequestPayload) _then;

/// Create a copy of ProducerRequestPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? producerRequest = null,}) {
  return _then(_self.copyWith(
producerRequest: null == producerRequest ? _self.producerRequest : producerRequest // ignore: cast_nullable_to_non_nullable
as AdminProducerRequest,
  ));
}
/// Create a copy of ProducerRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminProducerRequestCopyWith<$Res> get producerRequest {
  
  return $AdminProducerRequestCopyWith<$Res>(_self.producerRequest, (value) {
    return _then(_self.copyWith(producerRequest: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProducerRequestPayload].
extension ProducerRequestPayloadPatterns on ProducerRequestPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerRequestPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerRequestPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerRequestPayload value)  $default,){
final _that = this;
switch (_that) {
case _ProducerRequestPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerRequestPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerRequestPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdminProducerRequest producerRequest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerRequestPayload() when $default != null:
return $default(_that.producerRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdminProducerRequest producerRequest)  $default,) {final _that = this;
switch (_that) {
case _ProducerRequestPayload():
return $default(_that.producerRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdminProducerRequest producerRequest)?  $default,) {final _that = this;
switch (_that) {
case _ProducerRequestPayload() when $default != null:
return $default(_that.producerRequest);case _:
  return null;

}
}

}

/// @nodoc


class _ProducerRequestPayload extends ProducerRequestPayload {
  const _ProducerRequestPayload({required this.producerRequest}): super._();
  

@override final  AdminProducerRequest producerRequest;

/// Create a copy of ProducerRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerRequestPayloadCopyWith<_ProducerRequestPayload> get copyWith => __$ProducerRequestPayloadCopyWithImpl<_ProducerRequestPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerRequestPayload&&(identical(other.producerRequest, producerRequest) || other.producerRequest == producerRequest));
}


@override
int get hashCode => Object.hash(runtimeType,producerRequest);

@override
String toString() {
  return 'ProducerRequestPayload(producerRequest: $producerRequest)';
}


}

/// @nodoc
abstract mixin class _$ProducerRequestPayloadCopyWith<$Res> implements $ProducerRequestPayloadCopyWith<$Res> {
  factory _$ProducerRequestPayloadCopyWith(_ProducerRequestPayload value, $Res Function(_ProducerRequestPayload) _then) = __$ProducerRequestPayloadCopyWithImpl;
@override @useResult
$Res call({
 AdminProducerRequest producerRequest
});


@override $AdminProducerRequestCopyWith<$Res> get producerRequest;

}
/// @nodoc
class __$ProducerRequestPayloadCopyWithImpl<$Res>
    implements _$ProducerRequestPayloadCopyWith<$Res> {
  __$ProducerRequestPayloadCopyWithImpl(this._self, this._then);

  final _ProducerRequestPayload _self;
  final $Res Function(_ProducerRequestPayload) _then;

/// Create a copy of ProducerRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? producerRequest = null,}) {
  return _then(_ProducerRequestPayload(
producerRequest: null == producerRequest ? _self.producerRequest : producerRequest // ignore: cast_nullable_to_non_nullable
as AdminProducerRequest,
  ));
}

/// Create a copy of ProducerRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminProducerRequestCopyWith<$Res> get producerRequest {
  
  return $AdminProducerRequestCopyWith<$Res>(_self.producerRequest, (value) {
    return _then(_self.copyWith(producerRequest: value));
  });
}
}

/// @nodoc
mixin _$OwnerPayload {

 Owner get owner;
/// Create a copy of OwnerPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnerPayloadCopyWith<OwnerPayload> get copyWith => _$OwnerPayloadCopyWithImpl<OwnerPayload>(this as OwnerPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnerPayload&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,owner);

@override
String toString() {
  return 'OwnerPayload(owner: $owner)';
}


}

/// @nodoc
abstract mixin class $OwnerPayloadCopyWith<$Res>  {
  factory $OwnerPayloadCopyWith(OwnerPayload value, $Res Function(OwnerPayload) _then) = _$OwnerPayloadCopyWithImpl;
@useResult
$Res call({
 Owner owner
});


$OwnerCopyWith<$Res> get owner;

}
/// @nodoc
class _$OwnerPayloadCopyWithImpl<$Res>
    implements $OwnerPayloadCopyWith<$Res> {
  _$OwnerPayloadCopyWithImpl(this._self, this._then);

  final OwnerPayload _self;
  final $Res Function(OwnerPayload) _then;

/// Create a copy of OwnerPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,}) {
  return _then(_self.copyWith(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as Owner,
  ));
}
/// Create a copy of OwnerPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerCopyWith<$Res> get owner {
  
  return $OwnerCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [OwnerPayload].
extension OwnerPayloadPatterns on OwnerPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnerPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnerPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnerPayload value)  $default,){
final _that = this;
switch (_that) {
case _OwnerPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnerPayload value)?  $default,){
final _that = this;
switch (_that) {
case _OwnerPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Owner owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnerPayload() when $default != null:
return $default(_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Owner owner)  $default,) {final _that = this;
switch (_that) {
case _OwnerPayload():
return $default(_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Owner owner)?  $default,) {final _that = this;
switch (_that) {
case _OwnerPayload() when $default != null:
return $default(_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _OwnerPayload extends OwnerPayload {
  const _OwnerPayload({required this.owner}): super._();
  

@override final  Owner owner;

/// Create a copy of OwnerPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnerPayloadCopyWith<_OwnerPayload> get copyWith => __$OwnerPayloadCopyWithImpl<_OwnerPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnerPayload&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,owner);

@override
String toString() {
  return 'OwnerPayload(owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$OwnerPayloadCopyWith<$Res> implements $OwnerPayloadCopyWith<$Res> {
  factory _$OwnerPayloadCopyWith(_OwnerPayload value, $Res Function(_OwnerPayload) _then) = __$OwnerPayloadCopyWithImpl;
@override @useResult
$Res call({
 Owner owner
});


@override $OwnerCopyWith<$Res> get owner;

}
/// @nodoc
class __$OwnerPayloadCopyWithImpl<$Res>
    implements _$OwnerPayloadCopyWith<$Res> {
  __$OwnerPayloadCopyWithImpl(this._self, this._then);

  final _OwnerPayload _self;
  final $Res Function(_OwnerPayload) _then;

/// Create a copy of OwnerPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,}) {
  return _then(_OwnerPayload(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as Owner,
  ));
}

/// Create a copy of OwnerPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerCopyWith<$Res> get owner {
  
  return $OwnerCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$MemberInvitationPayload {

 MemberInvitation get memberInvitation;
/// Create a copy of MemberInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberInvitationPayloadCopyWith<MemberInvitationPayload> get copyWith => _$MemberInvitationPayloadCopyWithImpl<MemberInvitationPayload>(this as MemberInvitationPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberInvitationPayload&&(identical(other.memberInvitation, memberInvitation) || other.memberInvitation == memberInvitation));
}


@override
int get hashCode => Object.hash(runtimeType,memberInvitation);

@override
String toString() {
  return 'MemberInvitationPayload(memberInvitation: $memberInvitation)';
}


}

/// @nodoc
abstract mixin class $MemberInvitationPayloadCopyWith<$Res>  {
  factory $MemberInvitationPayloadCopyWith(MemberInvitationPayload value, $Res Function(MemberInvitationPayload) _then) = _$MemberInvitationPayloadCopyWithImpl;
@useResult
$Res call({
 MemberInvitation memberInvitation
});


$MemberInvitationCopyWith<$Res> get memberInvitation;

}
/// @nodoc
class _$MemberInvitationPayloadCopyWithImpl<$Res>
    implements $MemberInvitationPayloadCopyWith<$Res> {
  _$MemberInvitationPayloadCopyWithImpl(this._self, this._then);

  final MemberInvitationPayload _self;
  final $Res Function(MemberInvitationPayload) _then;

/// Create a copy of MemberInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberInvitation = null,}) {
  return _then(_self.copyWith(
memberInvitation: null == memberInvitation ? _self.memberInvitation : memberInvitation // ignore: cast_nullable_to_non_nullable
as MemberInvitation,
  ));
}
/// Create a copy of MemberInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberInvitationCopyWith<$Res> get memberInvitation {
  
  return $MemberInvitationCopyWith<$Res>(_self.memberInvitation, (value) {
    return _then(_self.copyWith(memberInvitation: value));
  });
}
}


/// Adds pattern-matching-related methods to [MemberInvitationPayload].
extension MemberInvitationPayloadPatterns on MemberInvitationPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberInvitationPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberInvitationPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberInvitationPayload value)  $default,){
final _that = this;
switch (_that) {
case _MemberInvitationPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberInvitationPayload value)?  $default,){
final _that = this;
switch (_that) {
case _MemberInvitationPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MemberInvitation memberInvitation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberInvitationPayload() when $default != null:
return $default(_that.memberInvitation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MemberInvitation memberInvitation)  $default,) {final _that = this;
switch (_that) {
case _MemberInvitationPayload():
return $default(_that.memberInvitation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MemberInvitation memberInvitation)?  $default,) {final _that = this;
switch (_that) {
case _MemberInvitationPayload() when $default != null:
return $default(_that.memberInvitation);case _:
  return null;

}
}

}

/// @nodoc


class _MemberInvitationPayload extends MemberInvitationPayload {
  const _MemberInvitationPayload({required this.memberInvitation}): super._();
  

@override final  MemberInvitation memberInvitation;

/// Create a copy of MemberInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberInvitationPayloadCopyWith<_MemberInvitationPayload> get copyWith => __$MemberInvitationPayloadCopyWithImpl<_MemberInvitationPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberInvitationPayload&&(identical(other.memberInvitation, memberInvitation) || other.memberInvitation == memberInvitation));
}


@override
int get hashCode => Object.hash(runtimeType,memberInvitation);

@override
String toString() {
  return 'MemberInvitationPayload(memberInvitation: $memberInvitation)';
}


}

/// @nodoc
abstract mixin class _$MemberInvitationPayloadCopyWith<$Res> implements $MemberInvitationPayloadCopyWith<$Res> {
  factory _$MemberInvitationPayloadCopyWith(_MemberInvitationPayload value, $Res Function(_MemberInvitationPayload) _then) = __$MemberInvitationPayloadCopyWithImpl;
@override @useResult
$Res call({
 MemberInvitation memberInvitation
});


@override $MemberInvitationCopyWith<$Res> get memberInvitation;

}
/// @nodoc
class __$MemberInvitationPayloadCopyWithImpl<$Res>
    implements _$MemberInvitationPayloadCopyWith<$Res> {
  __$MemberInvitationPayloadCopyWithImpl(this._self, this._then);

  final _MemberInvitationPayload _self;
  final $Res Function(_MemberInvitationPayload) _then;

/// Create a copy of MemberInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberInvitation = null,}) {
  return _then(_MemberInvitationPayload(
memberInvitation: null == memberInvitation ? _self.memberInvitation : memberInvitation // ignore: cast_nullable_to_non_nullable
as MemberInvitation,
  ));
}

/// Create a copy of MemberInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberInvitationCopyWith<$Res> get memberInvitation {
  
  return $MemberInvitationCopyWith<$Res>(_self.memberInvitation, (value) {
    return _then(_self.copyWith(memberInvitation: value));
  });
}
}

/// @nodoc
mixin _$OwnerInvitationPayload {

 OwnerInvitation get ownerInvitation;
/// Create a copy of OwnerInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnerInvitationPayloadCopyWith<OwnerInvitationPayload> get copyWith => _$OwnerInvitationPayloadCopyWithImpl<OwnerInvitationPayload>(this as OwnerInvitationPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnerInvitationPayload&&(identical(other.ownerInvitation, ownerInvitation) || other.ownerInvitation == ownerInvitation));
}


@override
int get hashCode => Object.hash(runtimeType,ownerInvitation);

@override
String toString() {
  return 'OwnerInvitationPayload(ownerInvitation: $ownerInvitation)';
}


}

/// @nodoc
abstract mixin class $OwnerInvitationPayloadCopyWith<$Res>  {
  factory $OwnerInvitationPayloadCopyWith(OwnerInvitationPayload value, $Res Function(OwnerInvitationPayload) _then) = _$OwnerInvitationPayloadCopyWithImpl;
@useResult
$Res call({
 OwnerInvitation ownerInvitation
});


$OwnerInvitationCopyWith<$Res> get ownerInvitation;

}
/// @nodoc
class _$OwnerInvitationPayloadCopyWithImpl<$Res>
    implements $OwnerInvitationPayloadCopyWith<$Res> {
  _$OwnerInvitationPayloadCopyWithImpl(this._self, this._then);

  final OwnerInvitationPayload _self;
  final $Res Function(OwnerInvitationPayload) _then;

/// Create a copy of OwnerInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ownerInvitation = null,}) {
  return _then(_self.copyWith(
ownerInvitation: null == ownerInvitation ? _self.ownerInvitation : ownerInvitation // ignore: cast_nullable_to_non_nullable
as OwnerInvitation,
  ));
}
/// Create a copy of OwnerInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerInvitationCopyWith<$Res> get ownerInvitation {
  
  return $OwnerInvitationCopyWith<$Res>(_self.ownerInvitation, (value) {
    return _then(_self.copyWith(ownerInvitation: value));
  });
}
}


/// Adds pattern-matching-related methods to [OwnerInvitationPayload].
extension OwnerInvitationPayloadPatterns on OwnerInvitationPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnerInvitationPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnerInvitationPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnerInvitationPayload value)  $default,){
final _that = this;
switch (_that) {
case _OwnerInvitationPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnerInvitationPayload value)?  $default,){
final _that = this;
switch (_that) {
case _OwnerInvitationPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OwnerInvitation ownerInvitation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnerInvitationPayload() when $default != null:
return $default(_that.ownerInvitation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OwnerInvitation ownerInvitation)  $default,) {final _that = this;
switch (_that) {
case _OwnerInvitationPayload():
return $default(_that.ownerInvitation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OwnerInvitation ownerInvitation)?  $default,) {final _that = this;
switch (_that) {
case _OwnerInvitationPayload() when $default != null:
return $default(_that.ownerInvitation);case _:
  return null;

}
}

}

/// @nodoc


class _OwnerInvitationPayload extends OwnerInvitationPayload {
  const _OwnerInvitationPayload({required this.ownerInvitation}): super._();
  

@override final  OwnerInvitation ownerInvitation;

/// Create a copy of OwnerInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnerInvitationPayloadCopyWith<_OwnerInvitationPayload> get copyWith => __$OwnerInvitationPayloadCopyWithImpl<_OwnerInvitationPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnerInvitationPayload&&(identical(other.ownerInvitation, ownerInvitation) || other.ownerInvitation == ownerInvitation));
}


@override
int get hashCode => Object.hash(runtimeType,ownerInvitation);

@override
String toString() {
  return 'OwnerInvitationPayload(ownerInvitation: $ownerInvitation)';
}


}

/// @nodoc
abstract mixin class _$OwnerInvitationPayloadCopyWith<$Res> implements $OwnerInvitationPayloadCopyWith<$Res> {
  factory _$OwnerInvitationPayloadCopyWith(_OwnerInvitationPayload value, $Res Function(_OwnerInvitationPayload) _then) = __$OwnerInvitationPayloadCopyWithImpl;
@override @useResult
$Res call({
 OwnerInvitation ownerInvitation
});


@override $OwnerInvitationCopyWith<$Res> get ownerInvitation;

}
/// @nodoc
class __$OwnerInvitationPayloadCopyWithImpl<$Res>
    implements _$OwnerInvitationPayloadCopyWith<$Res> {
  __$OwnerInvitationPayloadCopyWithImpl(this._self, this._then);

  final _OwnerInvitationPayload _self;
  final $Res Function(_OwnerInvitationPayload) _then;

/// Create a copy of OwnerInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ownerInvitation = null,}) {
  return _then(_OwnerInvitationPayload(
ownerInvitation: null == ownerInvitation ? _self.ownerInvitation : ownerInvitation // ignore: cast_nullable_to_non_nullable
as OwnerInvitation,
  ));
}

/// Create a copy of OwnerInvitationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OwnerInvitationCopyWith<$Res> get ownerInvitation {
  
  return $OwnerInvitationCopyWith<$Res>(_self.ownerInvitation, (value) {
    return _then(_self.copyWith(ownerInvitation: value));
  });
}
}

/// @nodoc
mixin _$BasketExchangePayload {

 BasketExchange get basketExchange;
/// Create a copy of BasketExchangePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketExchangePayloadCopyWith<BasketExchangePayload> get copyWith => _$BasketExchangePayloadCopyWithImpl<BasketExchangePayload>(this as BasketExchangePayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchangePayload&&(identical(other.basketExchange, basketExchange) || other.basketExchange == basketExchange));
}


@override
int get hashCode => Object.hash(runtimeType,basketExchange);

@override
String toString() {
  return 'BasketExchangePayload(basketExchange: $basketExchange)';
}


}

/// @nodoc
abstract mixin class $BasketExchangePayloadCopyWith<$Res>  {
  factory $BasketExchangePayloadCopyWith(BasketExchangePayload value, $Res Function(BasketExchangePayload) _then) = _$BasketExchangePayloadCopyWithImpl;
@useResult
$Res call({
 BasketExchange basketExchange
});


$BasketExchangeCopyWith<$Res> get basketExchange;

}
/// @nodoc
class _$BasketExchangePayloadCopyWithImpl<$Res>
    implements $BasketExchangePayloadCopyWith<$Res> {
  _$BasketExchangePayloadCopyWithImpl(this._self, this._then);

  final BasketExchangePayload _self;
  final $Res Function(BasketExchangePayload) _then;

/// Create a copy of BasketExchangePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? basketExchange = null,}) {
  return _then(_self.copyWith(
basketExchange: null == basketExchange ? _self.basketExchange : basketExchange // ignore: cast_nullable_to_non_nullable
as BasketExchange,
  ));
}
/// Create a copy of BasketExchangePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketExchangeCopyWith<$Res> get basketExchange {
  
  return $BasketExchangeCopyWith<$Res>(_self.basketExchange, (value) {
    return _then(_self.copyWith(basketExchange: value));
  });
}
}


/// Adds pattern-matching-related methods to [BasketExchangePayload].
extension BasketExchangePayloadPatterns on BasketExchangePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketExchangePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketExchangePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketExchangePayload value)  $default,){
final _that = this;
switch (_that) {
case _BasketExchangePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketExchangePayload value)?  $default,){
final _that = this;
switch (_that) {
case _BasketExchangePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BasketExchange basketExchange)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketExchangePayload() when $default != null:
return $default(_that.basketExchange);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BasketExchange basketExchange)  $default,) {final _that = this;
switch (_that) {
case _BasketExchangePayload():
return $default(_that.basketExchange);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BasketExchange basketExchange)?  $default,) {final _that = this;
switch (_that) {
case _BasketExchangePayload() when $default != null:
return $default(_that.basketExchange);case _:
  return null;

}
}

}

/// @nodoc


class _BasketExchangePayload extends BasketExchangePayload {
  const _BasketExchangePayload({required this.basketExchange}): super._();
  

@override final  BasketExchange basketExchange;

/// Create a copy of BasketExchangePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketExchangePayloadCopyWith<_BasketExchangePayload> get copyWith => __$BasketExchangePayloadCopyWithImpl<_BasketExchangePayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketExchangePayload&&(identical(other.basketExchange, basketExchange) || other.basketExchange == basketExchange));
}


@override
int get hashCode => Object.hash(runtimeType,basketExchange);

@override
String toString() {
  return 'BasketExchangePayload(basketExchange: $basketExchange)';
}


}

/// @nodoc
abstract mixin class _$BasketExchangePayloadCopyWith<$Res> implements $BasketExchangePayloadCopyWith<$Res> {
  factory _$BasketExchangePayloadCopyWith(_BasketExchangePayload value, $Res Function(_BasketExchangePayload) _then) = __$BasketExchangePayloadCopyWithImpl;
@override @useResult
$Res call({
 BasketExchange basketExchange
});


@override $BasketExchangeCopyWith<$Res> get basketExchange;

}
/// @nodoc
class __$BasketExchangePayloadCopyWithImpl<$Res>
    implements _$BasketExchangePayloadCopyWith<$Res> {
  __$BasketExchangePayloadCopyWithImpl(this._self, this._then);

  final _BasketExchangePayload _self;
  final $Res Function(_BasketExchangePayload) _then;

/// Create a copy of BasketExchangePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? basketExchange = null,}) {
  return _then(_BasketExchangePayload(
basketExchange: null == basketExchange ? _self.basketExchange : basketExchange // ignore: cast_nullable_to_non_nullable
as BasketExchange,
  ));
}

/// Create a copy of BasketExchangePayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketExchangeCopyWith<$Res> get basketExchange {
  
  return $BasketExchangeCopyWith<$Res>(_self.basketExchange, (value) {
    return _then(_self.copyWith(basketExchange: value));
  });
}
}

/// @nodoc
mixin _$NotificationPayload {

 AppNotification get notification;
/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPayloadCopyWith<NotificationPayload> get copyWith => _$NotificationPayloadCopyWithImpl<NotificationPayload>(this as NotificationPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPayload&&(identical(other.notification, notification) || other.notification == notification));
}


@override
int get hashCode => Object.hash(runtimeType,notification);

@override
String toString() {
  return 'NotificationPayload(notification: $notification)';
}


}

/// @nodoc
abstract mixin class $NotificationPayloadCopyWith<$Res>  {
  factory $NotificationPayloadCopyWith(NotificationPayload value, $Res Function(NotificationPayload) _then) = _$NotificationPayloadCopyWithImpl;
@useResult
$Res call({
 AppNotification notification
});


$AppNotificationCopyWith<$Res> get notification;

}
/// @nodoc
class _$NotificationPayloadCopyWithImpl<$Res>
    implements $NotificationPayloadCopyWith<$Res> {
  _$NotificationPayloadCopyWithImpl(this._self, this._then);

  final NotificationPayload _self;
  final $Res Function(NotificationPayload) _then;

/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notification = null,}) {
  return _then(_self.copyWith(
notification: null == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as AppNotification,
  ));
}
/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<$Res> get notification {
  
  return $AppNotificationCopyWith<$Res>(_self.notification, (value) {
    return _then(_self.copyWith(notification: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationPayload].
extension NotificationPayloadPatterns on NotificationPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPayload value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPayload value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppNotification notification)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
return $default(_that.notification);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppNotification notification)  $default,) {final _that = this;
switch (_that) {
case _NotificationPayload():
return $default(_that.notification);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppNotification notification)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPayload() when $default != null:
return $default(_that.notification);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationPayload extends NotificationPayload {
  const _NotificationPayload({required this.notification}): super._();
  

@override final  AppNotification notification;

/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPayloadCopyWith<_NotificationPayload> get copyWith => __$NotificationPayloadCopyWithImpl<_NotificationPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPayload&&(identical(other.notification, notification) || other.notification == notification));
}


@override
int get hashCode => Object.hash(runtimeType,notification);

@override
String toString() {
  return 'NotificationPayload(notification: $notification)';
}


}

/// @nodoc
abstract mixin class _$NotificationPayloadCopyWith<$Res> implements $NotificationPayloadCopyWith<$Res> {
  factory _$NotificationPayloadCopyWith(_NotificationPayload value, $Res Function(_NotificationPayload) _then) = __$NotificationPayloadCopyWithImpl;
@override @useResult
$Res call({
 AppNotification notification
});


@override $AppNotificationCopyWith<$Res> get notification;

}
/// @nodoc
class __$NotificationPayloadCopyWithImpl<$Res>
    implements _$NotificationPayloadCopyWith<$Res> {
  __$NotificationPayloadCopyWithImpl(this._self, this._then);

  final _NotificationPayload _self;
  final $Res Function(_NotificationPayload) _then;

/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notification = null,}) {
  return _then(_NotificationPayload(
notification: null == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as AppNotification,
  ));
}

/// Create a copy of NotificationPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<$Res> get notification {
  
  return $AppNotificationCopyWith<$Res>(_self.notification, (value) {
    return _then(_self.copyWith(notification: value));
  });
}
}

/// @nodoc
mixin _$DeviceTokenPayload {

 DeviceToken get deviceToken;
/// Create a copy of DeviceTokenPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceTokenPayloadCopyWith<DeviceTokenPayload> get copyWith => _$DeviceTokenPayloadCopyWithImpl<DeviceTokenPayload>(this as DeviceTokenPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceTokenPayload&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken));
}


@override
int get hashCode => Object.hash(runtimeType,deviceToken);

@override
String toString() {
  return 'DeviceTokenPayload(deviceToken: $deviceToken)';
}


}

/// @nodoc
abstract mixin class $DeviceTokenPayloadCopyWith<$Res>  {
  factory $DeviceTokenPayloadCopyWith(DeviceTokenPayload value, $Res Function(DeviceTokenPayload) _then) = _$DeviceTokenPayloadCopyWithImpl;
@useResult
$Res call({
 DeviceToken deviceToken
});


$DeviceTokenCopyWith<$Res> get deviceToken;

}
/// @nodoc
class _$DeviceTokenPayloadCopyWithImpl<$Res>
    implements $DeviceTokenPayloadCopyWith<$Res> {
  _$DeviceTokenPayloadCopyWithImpl(this._self, this._then);

  final DeviceTokenPayload _self;
  final $Res Function(DeviceTokenPayload) _then;

/// Create a copy of DeviceTokenPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceToken = null,}) {
  return _then(_self.copyWith(
deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as DeviceToken,
  ));
}
/// Create a copy of DeviceTokenPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceTokenCopyWith<$Res> get deviceToken {
  
  return $DeviceTokenCopyWith<$Res>(_self.deviceToken, (value) {
    return _then(_self.copyWith(deviceToken: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeviceTokenPayload].
extension DeviceTokenPayloadPatterns on DeviceTokenPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceTokenPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceTokenPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceTokenPayload value)  $default,){
final _that = this;
switch (_that) {
case _DeviceTokenPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceTokenPayload value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceTokenPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeviceToken deviceToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceTokenPayload() when $default != null:
return $default(_that.deviceToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeviceToken deviceToken)  $default,) {final _that = this;
switch (_that) {
case _DeviceTokenPayload():
return $default(_that.deviceToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeviceToken deviceToken)?  $default,) {final _that = this;
switch (_that) {
case _DeviceTokenPayload() when $default != null:
return $default(_that.deviceToken);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceTokenPayload extends DeviceTokenPayload {
  const _DeviceTokenPayload({required this.deviceToken}): super._();
  

@override final  DeviceToken deviceToken;

/// Create a copy of DeviceTokenPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceTokenPayloadCopyWith<_DeviceTokenPayload> get copyWith => __$DeviceTokenPayloadCopyWithImpl<_DeviceTokenPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceTokenPayload&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken));
}


@override
int get hashCode => Object.hash(runtimeType,deviceToken);

@override
String toString() {
  return 'DeviceTokenPayload(deviceToken: $deviceToken)';
}


}

/// @nodoc
abstract mixin class _$DeviceTokenPayloadCopyWith<$Res> implements $DeviceTokenPayloadCopyWith<$Res> {
  factory _$DeviceTokenPayloadCopyWith(_DeviceTokenPayload value, $Res Function(_DeviceTokenPayload) _then) = __$DeviceTokenPayloadCopyWithImpl;
@override @useResult
$Res call({
 DeviceToken deviceToken
});


@override $DeviceTokenCopyWith<$Res> get deviceToken;

}
/// @nodoc
class __$DeviceTokenPayloadCopyWithImpl<$Res>
    implements _$DeviceTokenPayloadCopyWith<$Res> {
  __$DeviceTokenPayloadCopyWithImpl(this._self, this._then);

  final _DeviceTokenPayload _self;
  final $Res Function(_DeviceTokenPayload) _then;

/// Create a copy of DeviceTokenPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceToken = null,}) {
  return _then(_DeviceTokenPayload(
deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as DeviceToken,
  ));
}

/// Create a copy of DeviceTokenPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceTokenCopyWith<$Res> get deviceToken {
  
  return $DeviceTokenCopyWith<$Res>(_self.deviceToken, (value) {
    return _then(_self.copyWith(deviceToken: value));
  });
}
}

/// @nodoc
mixin _$AttendanceEmailRequestPayload {

 AttendanceEmailRequest get attendanceEmailRequest;
/// Create a copy of AttendanceEmailRequestPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceEmailRequestPayloadCopyWith<AttendanceEmailRequestPayload> get copyWith => _$AttendanceEmailRequestPayloadCopyWithImpl<AttendanceEmailRequestPayload>(this as AttendanceEmailRequestPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceEmailRequestPayload&&(identical(other.attendanceEmailRequest, attendanceEmailRequest) || other.attendanceEmailRequest == attendanceEmailRequest));
}


@override
int get hashCode => Object.hash(runtimeType,attendanceEmailRequest);

@override
String toString() {
  return 'AttendanceEmailRequestPayload(attendanceEmailRequest: $attendanceEmailRequest)';
}


}

/// @nodoc
abstract mixin class $AttendanceEmailRequestPayloadCopyWith<$Res>  {
  factory $AttendanceEmailRequestPayloadCopyWith(AttendanceEmailRequestPayload value, $Res Function(AttendanceEmailRequestPayload) _then) = _$AttendanceEmailRequestPayloadCopyWithImpl;
@useResult
$Res call({
 AttendanceEmailRequest attendanceEmailRequest
});


$AttendanceEmailRequestCopyWith<$Res> get attendanceEmailRequest;

}
/// @nodoc
class _$AttendanceEmailRequestPayloadCopyWithImpl<$Res>
    implements $AttendanceEmailRequestPayloadCopyWith<$Res> {
  _$AttendanceEmailRequestPayloadCopyWithImpl(this._self, this._then);

  final AttendanceEmailRequestPayload _self;
  final $Res Function(AttendanceEmailRequestPayload) _then;

/// Create a copy of AttendanceEmailRequestPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attendanceEmailRequest = null,}) {
  return _then(_self.copyWith(
attendanceEmailRequest: null == attendanceEmailRequest ? _self.attendanceEmailRequest : attendanceEmailRequest // ignore: cast_nullable_to_non_nullable
as AttendanceEmailRequest,
  ));
}
/// Create a copy of AttendanceEmailRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AttendanceEmailRequestCopyWith<$Res> get attendanceEmailRequest {
  
  return $AttendanceEmailRequestCopyWith<$Res>(_self.attendanceEmailRequest, (value) {
    return _then(_self.copyWith(attendanceEmailRequest: value));
  });
}
}


/// Adds pattern-matching-related methods to [AttendanceEmailRequestPayload].
extension AttendanceEmailRequestPayloadPatterns on AttendanceEmailRequestPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceEmailRequestPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceEmailRequestPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceEmailRequestPayload value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceEmailRequestPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceEmailRequestPayload value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceEmailRequestPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AttendanceEmailRequest attendanceEmailRequest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceEmailRequestPayload() when $default != null:
return $default(_that.attendanceEmailRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AttendanceEmailRequest attendanceEmailRequest)  $default,) {final _that = this;
switch (_that) {
case _AttendanceEmailRequestPayload():
return $default(_that.attendanceEmailRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AttendanceEmailRequest attendanceEmailRequest)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceEmailRequestPayload() when $default != null:
return $default(_that.attendanceEmailRequest);case _:
  return null;

}
}

}

/// @nodoc


class _AttendanceEmailRequestPayload extends AttendanceEmailRequestPayload {
  const _AttendanceEmailRequestPayload({required this.attendanceEmailRequest}): super._();
  

@override final  AttendanceEmailRequest attendanceEmailRequest;

/// Create a copy of AttendanceEmailRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceEmailRequestPayloadCopyWith<_AttendanceEmailRequestPayload> get copyWith => __$AttendanceEmailRequestPayloadCopyWithImpl<_AttendanceEmailRequestPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceEmailRequestPayload&&(identical(other.attendanceEmailRequest, attendanceEmailRequest) || other.attendanceEmailRequest == attendanceEmailRequest));
}


@override
int get hashCode => Object.hash(runtimeType,attendanceEmailRequest);

@override
String toString() {
  return 'AttendanceEmailRequestPayload(attendanceEmailRequest: $attendanceEmailRequest)';
}


}

/// @nodoc
abstract mixin class _$AttendanceEmailRequestPayloadCopyWith<$Res> implements $AttendanceEmailRequestPayloadCopyWith<$Res> {
  factory _$AttendanceEmailRequestPayloadCopyWith(_AttendanceEmailRequestPayload value, $Res Function(_AttendanceEmailRequestPayload) _then) = __$AttendanceEmailRequestPayloadCopyWithImpl;
@override @useResult
$Res call({
 AttendanceEmailRequest attendanceEmailRequest
});


@override $AttendanceEmailRequestCopyWith<$Res> get attendanceEmailRequest;

}
/// @nodoc
class __$AttendanceEmailRequestPayloadCopyWithImpl<$Res>
    implements _$AttendanceEmailRequestPayloadCopyWith<$Res> {
  __$AttendanceEmailRequestPayloadCopyWithImpl(this._self, this._then);

  final _AttendanceEmailRequestPayload _self;
  final $Res Function(_AttendanceEmailRequestPayload) _then;

/// Create a copy of AttendanceEmailRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attendanceEmailRequest = null,}) {
  return _then(_AttendanceEmailRequestPayload(
attendanceEmailRequest: null == attendanceEmailRequest ? _self.attendanceEmailRequest : attendanceEmailRequest // ignore: cast_nullable_to_non_nullable
as AttendanceEmailRequest,
  ));
}

/// Create a copy of AttendanceEmailRequestPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AttendanceEmailRequestCopyWith<$Res> get attendanceEmailRequest {
  
  return $AttendanceEmailRequestCopyWith<$Res>(_self.attendanceEmailRequest, (value) {
    return _then(_self.copyWith(attendanceEmailRequest: value));
  });
}
}

/// @nodoc
mixin _$ErrorReportPayload {

 ErrorReport get errorReport;
/// Create a copy of ErrorReportPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorReportPayloadCopyWith<ErrorReportPayload> get copyWith => _$ErrorReportPayloadCopyWithImpl<ErrorReportPayload>(this as ErrorReportPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorReportPayload&&(identical(other.errorReport, errorReport) || other.errorReport == errorReport));
}


@override
int get hashCode => Object.hash(runtimeType,errorReport);

@override
String toString() {
  return 'ErrorReportPayload(errorReport: $errorReport)';
}


}

/// @nodoc
abstract mixin class $ErrorReportPayloadCopyWith<$Res>  {
  factory $ErrorReportPayloadCopyWith(ErrorReportPayload value, $Res Function(ErrorReportPayload) _then) = _$ErrorReportPayloadCopyWithImpl;
@useResult
$Res call({
 ErrorReport errorReport
});


$ErrorReportCopyWith<$Res> get errorReport;

}
/// @nodoc
class _$ErrorReportPayloadCopyWithImpl<$Res>
    implements $ErrorReportPayloadCopyWith<$Res> {
  _$ErrorReportPayloadCopyWithImpl(this._self, this._then);

  final ErrorReportPayload _self;
  final $Res Function(ErrorReportPayload) _then;

/// Create a copy of ErrorReportPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? errorReport = null,}) {
  return _then(_self.copyWith(
errorReport: null == errorReport ? _self.errorReport : errorReport // ignore: cast_nullable_to_non_nullable
as ErrorReport,
  ));
}
/// Create a copy of ErrorReportPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorReportCopyWith<$Res> get errorReport {
  
  return $ErrorReportCopyWith<$Res>(_self.errorReport, (value) {
    return _then(_self.copyWith(errorReport: value));
  });
}
}


/// Adds pattern-matching-related methods to [ErrorReportPayload].
extension ErrorReportPayloadPatterns on ErrorReportPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorReportPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorReportPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorReportPayload value)  $default,){
final _that = this;
switch (_that) {
case _ErrorReportPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorReportPayload value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorReportPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ErrorReport errorReport)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorReportPayload() when $default != null:
return $default(_that.errorReport);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ErrorReport errorReport)  $default,) {final _that = this;
switch (_that) {
case _ErrorReportPayload():
return $default(_that.errorReport);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ErrorReport errorReport)?  $default,) {final _that = this;
switch (_that) {
case _ErrorReportPayload() when $default != null:
return $default(_that.errorReport);case _:
  return null;

}
}

}

/// @nodoc


class _ErrorReportPayload extends ErrorReportPayload {
  const _ErrorReportPayload({required this.errorReport}): super._();
  

@override final  ErrorReport errorReport;

/// Create a copy of ErrorReportPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorReportPayloadCopyWith<_ErrorReportPayload> get copyWith => __$ErrorReportPayloadCopyWithImpl<_ErrorReportPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorReportPayload&&(identical(other.errorReport, errorReport) || other.errorReport == errorReport));
}


@override
int get hashCode => Object.hash(runtimeType,errorReport);

@override
String toString() {
  return 'ErrorReportPayload(errorReport: $errorReport)';
}


}

/// @nodoc
abstract mixin class _$ErrorReportPayloadCopyWith<$Res> implements $ErrorReportPayloadCopyWith<$Res> {
  factory _$ErrorReportPayloadCopyWith(_ErrorReportPayload value, $Res Function(_ErrorReportPayload) _then) = __$ErrorReportPayloadCopyWithImpl;
@override @useResult
$Res call({
 ErrorReport errorReport
});


@override $ErrorReportCopyWith<$Res> get errorReport;

}
/// @nodoc
class __$ErrorReportPayloadCopyWithImpl<$Res>
    implements _$ErrorReportPayloadCopyWith<$Res> {
  __$ErrorReportPayloadCopyWithImpl(this._self, this._then);

  final _ErrorReportPayload _self;
  final $Res Function(_ErrorReportPayload) _then;

/// Create a copy of ErrorReportPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? errorReport = null,}) {
  return _then(_ErrorReportPayload(
errorReport: null == errorReport ? _self.errorReport : errorReport // ignore: cast_nullable_to_non_nullable
as ErrorReport,
  ));
}

/// Create a copy of ErrorReportPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorReportCopyWith<$Res> get errorReport {
  
  return $ErrorReportCopyWith<$Res>(_self.errorReport, (value) {
    return _then(_self.copyWith(errorReport: value));
  });
}
}

// dart format on
