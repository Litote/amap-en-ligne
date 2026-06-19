// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProducerOrganization {

@JsonKey(name: 'organization_id') String get organizationId;// ISO-8601 instant string, e.g. "2026-05-18T22:23:25.095Z".
@JsonKey(name: 'association_instant') String get associationInstant; OrganizationProducerStatus get status;
/// Create a copy of ProducerOrganization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerOrganizationCopyWith<ProducerOrganization> get copyWith => _$ProducerOrganizationCopyWithImpl<ProducerOrganization>(this as ProducerOrganization, _$identity);

  /// Serializes this ProducerOrganization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerOrganization&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.associationInstant, associationInstant) || other.associationInstant == associationInstant)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationId,associationInstant,status);

@override
String toString() {
  return 'ProducerOrganization(organizationId: $organizationId, associationInstant: $associationInstant, status: $status)';
}


}

/// @nodoc
abstract mixin class $ProducerOrganizationCopyWith<$Res>  {
  factory $ProducerOrganizationCopyWith(ProducerOrganization value, $Res Function(ProducerOrganization) _then) = _$ProducerOrganizationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'association_instant') String associationInstant, OrganizationProducerStatus status
});




}
/// @nodoc
class _$ProducerOrganizationCopyWithImpl<$Res>
    implements $ProducerOrganizationCopyWith<$Res> {
  _$ProducerOrganizationCopyWithImpl(this._self, this._then);

  final ProducerOrganization _self;
  final $Res Function(ProducerOrganization) _then;

/// Create a copy of ProducerOrganization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? associationInstant = null,Object? status = null,}) {
  return _then(_self.copyWith(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,associationInstant: null == associationInstant ? _self.associationInstant : associationInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrganizationProducerStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerOrganization].
extension ProducerOrganizationPatterns on ProducerOrganization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerOrganization value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerOrganization() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerOrganization value)  $default,){
final _that = this;
switch (_that) {
case _ProducerOrganization():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerOrganization value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerOrganization() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'association_instant')  String associationInstant,  OrganizationProducerStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerOrganization() when $default != null:
return $default(_that.organizationId,_that.associationInstant,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'association_instant')  String associationInstant,  OrganizationProducerStatus status)  $default,) {final _that = this;
switch (_that) {
case _ProducerOrganization():
return $default(_that.organizationId,_that.associationInstant,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'association_instant')  String associationInstant,  OrganizationProducerStatus status)?  $default,) {final _that = this;
switch (_that) {
case _ProducerOrganization() when $default != null:
return $default(_that.organizationId,_that.associationInstant,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerOrganization implements ProducerOrganization {
  const _ProducerOrganization({@JsonKey(name: 'organization_id') required this.organizationId, @JsonKey(name: 'association_instant') required this.associationInstant, required this.status});
  factory _ProducerOrganization.fromJson(Map<String, dynamic> json) => _$ProducerOrganizationFromJson(json);

@override@JsonKey(name: 'organization_id') final  String organizationId;
// ISO-8601 instant string, e.g. "2026-05-18T22:23:25.095Z".
@override@JsonKey(name: 'association_instant') final  String associationInstant;
@override final  OrganizationProducerStatus status;

/// Create a copy of ProducerOrganization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerOrganizationCopyWith<_ProducerOrganization> get copyWith => __$ProducerOrganizationCopyWithImpl<_ProducerOrganization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerOrganizationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerOrganization&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.associationInstant, associationInstant) || other.associationInstant == associationInstant)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organizationId,associationInstant,status);

@override
String toString() {
  return 'ProducerOrganization(organizationId: $organizationId, associationInstant: $associationInstant, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ProducerOrganizationCopyWith<$Res> implements $ProducerOrganizationCopyWith<$Res> {
  factory _$ProducerOrganizationCopyWith(_ProducerOrganization value, $Res Function(_ProducerOrganization) _then) = __$ProducerOrganizationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'association_instant') String associationInstant, OrganizationProducerStatus status
});




}
/// @nodoc
class __$ProducerOrganizationCopyWithImpl<$Res>
    implements _$ProducerOrganizationCopyWith<$Res> {
  __$ProducerOrganizationCopyWithImpl(this._self, this._then);

  final _ProducerOrganization _self;
  final $Res Function(_ProducerOrganization) _then;

/// Create a copy of ProducerOrganization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? associationInstant = null,Object? status = null,}) {
  return _then(_ProducerOrganization(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,associationInstant: null == associationInstant ? _self.associationInstant : associationInstant // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrganizationProducerStatus,
  ));
}


}


/// @nodoc
mixin _$ProducerProduct {

 String get name;@JsonKey(name: 'product_type_id') String get productTypeId;@JsonKey(name: 'supported_basket_sizes') List<BasketSize> get supportedBasketSizes; String? get description;
/// Create a copy of ProducerProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerProductCopyWith<ProducerProduct> get copyWith => _$ProducerProductCopyWithImpl<ProducerProduct>(this as ProducerProduct, _$identity);

  /// Serializes this ProducerProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerProduct&&(identical(other.name, name) || other.name == name)&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&const DeepCollectionEquality().equals(other.supportedBasketSizes, supportedBasketSizes)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,productTypeId,const DeepCollectionEquality().hash(supportedBasketSizes),description);

@override
String toString() {
  return 'ProducerProduct(name: $name, productTypeId: $productTypeId, supportedBasketSizes: $supportedBasketSizes, description: $description)';
}


}

/// @nodoc
abstract mixin class $ProducerProductCopyWith<$Res>  {
  factory $ProducerProductCopyWith(ProducerProduct value, $Res Function(ProducerProduct) _then) = _$ProducerProductCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'supported_basket_sizes') List<BasketSize> supportedBasketSizes, String? description
});




}
/// @nodoc
class _$ProducerProductCopyWithImpl<$Res>
    implements $ProducerProductCopyWith<$Res> {
  _$ProducerProductCopyWithImpl(this._self, this._then);

  final ProducerProduct _self;
  final $Res Function(ProducerProduct) _then;

/// Create a copy of ProducerProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? productTypeId = null,Object? supportedBasketSizes = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,supportedBasketSizes: null == supportedBasketSizes ? _self.supportedBasketSizes : supportedBasketSizes // ignore: cast_nullable_to_non_nullable
as List<BasketSize>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerProduct].
extension ProducerProductPatterns on ProducerProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerProduct value)  $default,){
final _that = this;
switch (_that) {
case _ProducerProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerProduct value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerProduct() when $default != null:
return $default(_that.name,_that.productTypeId,_that.supportedBasketSizes,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String? description)  $default,) {final _that = this;
switch (_that) {
case _ProducerProduct():
return $default(_that.name,_that.productTypeId,_that.supportedBasketSizes,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'product_type_id')  String productTypeId, @JsonKey(name: 'supported_basket_sizes')  List<BasketSize> supportedBasketSizes,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _ProducerProduct() when $default != null:
return $default(_that.name,_that.productTypeId,_that.supportedBasketSizes,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerProduct implements ProducerProduct {
  const _ProducerProduct({required this.name, @JsonKey(name: 'product_type_id') required this.productTypeId, @JsonKey(name: 'supported_basket_sizes') final  List<BasketSize> supportedBasketSizes = const [], this.description}): _supportedBasketSizes = supportedBasketSizes;
  factory _ProducerProduct.fromJson(Map<String, dynamic> json) => _$ProducerProductFromJson(json);

@override final  String name;
@override@JsonKey(name: 'product_type_id') final  String productTypeId;
 final  List<BasketSize> _supportedBasketSizes;
@override@JsonKey(name: 'supported_basket_sizes') List<BasketSize> get supportedBasketSizes {
  if (_supportedBasketSizes is EqualUnmodifiableListView) return _supportedBasketSizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedBasketSizes);
}

@override final  String? description;

/// Create a copy of ProducerProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerProductCopyWith<_ProducerProduct> get copyWith => __$ProducerProductCopyWithImpl<_ProducerProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerProduct&&(identical(other.name, name) || other.name == name)&&(identical(other.productTypeId, productTypeId) || other.productTypeId == productTypeId)&&const DeepCollectionEquality().equals(other._supportedBasketSizes, _supportedBasketSizes)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,productTypeId,const DeepCollectionEquality().hash(_supportedBasketSizes),description);

@override
String toString() {
  return 'ProducerProduct(name: $name, productTypeId: $productTypeId, supportedBasketSizes: $supportedBasketSizes, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ProducerProductCopyWith<$Res> implements $ProducerProductCopyWith<$Res> {
  factory _$ProducerProductCopyWith(_ProducerProduct value, $Res Function(_ProducerProduct) _then) = __$ProducerProductCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'product_type_id') String productTypeId,@JsonKey(name: 'supported_basket_sizes') List<BasketSize> supportedBasketSizes, String? description
});




}
/// @nodoc
class __$ProducerProductCopyWithImpl<$Res>
    implements _$ProducerProductCopyWith<$Res> {
  __$ProducerProductCopyWithImpl(this._self, this._then);

  final _ProducerProduct _self;
  final $Res Function(_ProducerProduct) _then;

/// Create a copy of ProducerProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? productTypeId = null,Object? supportedBasketSizes = null,Object? description = freezed,}) {
  return _then(_ProducerProduct(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,productTypeId: null == productTypeId ? _self.productTypeId : productTypeId // ignore: cast_nullable_to_non_nullable
as String,supportedBasketSizes: null == supportedBasketSizes ? _self._supportedBasketSizes : supportedBasketSizes // ignore: cast_nullable_to_non_nullable
as List<BasketSize>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProducerAccount {

@JsonKey(name: 'producer_account_id') String get producerAccountId; String get name;@JsonKey(name: 'contact_email') String? get contactEmail; String? get address; String? get website;@JsonKey(name: 'active_status') bool get activeStatus;// ISO-8601 instant strings (e.g. "2026-05-18T22:23:25.093Z") — matches
// the back's kotlin.time.Instant default serialization.
@JsonKey(name: 'created_instant') String? get createdInstant;@JsonKey(name: 'last_updated_instant') String? get lastUpdatedInstant;@JsonKey(name: 'management_mode') ProducerManagementMode get managementMode;@JsonKey(name: 'linked_producer_account') LinkedProducerAccount? get linkedProducerAccount; List<ProducerProduct> get products; List<ProducerOrganization> get organizations;@JsonKey(name: 'user_preferences') UserPreferences? get userPreferences;
/// Create a copy of ProducerAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerAccountCopyWith<ProducerAccount> get copyWith => _$ProducerAccountCopyWithImpl<ProducerAccount>(this as ProducerAccount, _$identity);

  /// Serializes this ProducerAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerAccount&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.address, address) || other.address == address)&&(identical(other.website, website) || other.website == website)&&(identical(other.activeStatus, activeStatus) || other.activeStatus == activeStatus)&&(identical(other.createdInstant, createdInstant) || other.createdInstant == createdInstant)&&(identical(other.lastUpdatedInstant, lastUpdatedInstant) || other.lastUpdatedInstant == lastUpdatedInstant)&&(identical(other.managementMode, managementMode) || other.managementMode == managementMode)&&(identical(other.linkedProducerAccount, linkedProducerAccount) || other.linkedProducerAccount == linkedProducerAccount)&&const DeepCollectionEquality().equals(other.products, products)&&const DeepCollectionEquality().equals(other.organizations, organizations)&&(identical(other.userPreferences, userPreferences) || other.userPreferences == userPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerAccountId,name,contactEmail,address,website,activeStatus,createdInstant,lastUpdatedInstant,managementMode,linkedProducerAccount,const DeepCollectionEquality().hash(products),const DeepCollectionEquality().hash(organizations),userPreferences);

@override
String toString() {
  return 'ProducerAccount(producerAccountId: $producerAccountId, name: $name, contactEmail: $contactEmail, address: $address, website: $website, activeStatus: $activeStatus, createdInstant: $createdInstant, lastUpdatedInstant: $lastUpdatedInstant, managementMode: $managementMode, linkedProducerAccount: $linkedProducerAccount, products: $products, organizations: $organizations, userPreferences: $userPreferences)';
}


}

/// @nodoc
abstract mixin class $ProducerAccountCopyWith<$Res>  {
  factory $ProducerAccountCopyWith(ProducerAccount value, $Res Function(ProducerAccount) _then) = _$ProducerAccountCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'producer_account_id') String producerAccountId, String name,@JsonKey(name: 'contact_email') String? contactEmail, String? address, String? website,@JsonKey(name: 'active_status') bool activeStatus,@JsonKey(name: 'created_instant') String? createdInstant,@JsonKey(name: 'last_updated_instant') String? lastUpdatedInstant,@JsonKey(name: 'management_mode') ProducerManagementMode managementMode,@JsonKey(name: 'linked_producer_account') LinkedProducerAccount? linkedProducerAccount, List<ProducerProduct> products, List<ProducerOrganization> organizations,@JsonKey(name: 'user_preferences') UserPreferences? userPreferences
});


$LinkedProducerAccountCopyWith<$Res>? get linkedProducerAccount;$UserPreferencesCopyWith<$Res>? get userPreferences;

}
/// @nodoc
class _$ProducerAccountCopyWithImpl<$Res>
    implements $ProducerAccountCopyWith<$Res> {
  _$ProducerAccountCopyWithImpl(this._self, this._then);

  final ProducerAccount _self;
  final $Res Function(ProducerAccount) _then;

/// Create a copy of ProducerAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? producerAccountId = null,Object? name = null,Object? contactEmail = freezed,Object? address = freezed,Object? website = freezed,Object? activeStatus = null,Object? createdInstant = freezed,Object? lastUpdatedInstant = freezed,Object? managementMode = null,Object? linkedProducerAccount = freezed,Object? products = null,Object? organizations = null,Object? userPreferences = freezed,}) {
  return _then(_self.copyWith(
producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,activeStatus: null == activeStatus ? _self.activeStatus : activeStatus // ignore: cast_nullable_to_non_nullable
as bool,createdInstant: freezed == createdInstant ? _self.createdInstant : createdInstant // ignore: cast_nullable_to_non_nullable
as String?,lastUpdatedInstant: freezed == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String?,managementMode: null == managementMode ? _self.managementMode : managementMode // ignore: cast_nullable_to_non_nullable
as ProducerManagementMode,linkedProducerAccount: freezed == linkedProducerAccount ? _self.linkedProducerAccount : linkedProducerAccount // ignore: cast_nullable_to_non_nullable
as LinkedProducerAccount?,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<ProducerProduct>,organizations: null == organizations ? _self.organizations : organizations // ignore: cast_nullable_to_non_nullable
as List<ProducerOrganization>,userPreferences: freezed == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as UserPreferences?,
  ));
}
/// Create a copy of ProducerAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkedProducerAccountCopyWith<$Res>? get linkedProducerAccount {
    if (_self.linkedProducerAccount == null) {
    return null;
  }

  return $LinkedProducerAccountCopyWith<$Res>(_self.linkedProducerAccount!, (value) {
    return _then(_self.copyWith(linkedProducerAccount: value));
  });
}/// Create a copy of ProducerAccount
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


/// Adds pattern-matching-related methods to [ProducerAccount].
extension ProducerAccountPatterns on ProducerAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProducerAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProducerAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProducerAccount value)  $default,){
final _that = this;
switch (_that) {
case _ProducerAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProducerAccount value)?  $default,){
final _that = this;
switch (_that) {
case _ProducerAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_account_id')  String producerAccountId,  String name, @JsonKey(name: 'contact_email')  String? contactEmail,  String? address,  String? website, @JsonKey(name: 'active_status')  bool activeStatus, @JsonKey(name: 'created_instant')  String? createdInstant, @JsonKey(name: 'last_updated_instant')  String? lastUpdatedInstant, @JsonKey(name: 'management_mode')  ProducerManagementMode managementMode, @JsonKey(name: 'linked_producer_account')  LinkedProducerAccount? linkedProducerAccount,  List<ProducerProduct> products,  List<ProducerOrganization> organizations, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProducerAccount() when $default != null:
return $default(_that.producerAccountId,_that.name,_that.contactEmail,_that.address,_that.website,_that.activeStatus,_that.createdInstant,_that.lastUpdatedInstant,_that.managementMode,_that.linkedProducerAccount,_that.products,_that.organizations,_that.userPreferences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_account_id')  String producerAccountId,  String name, @JsonKey(name: 'contact_email')  String? contactEmail,  String? address,  String? website, @JsonKey(name: 'active_status')  bool activeStatus, @JsonKey(name: 'created_instant')  String? createdInstant, @JsonKey(name: 'last_updated_instant')  String? lastUpdatedInstant, @JsonKey(name: 'management_mode')  ProducerManagementMode managementMode, @JsonKey(name: 'linked_producer_account')  LinkedProducerAccount? linkedProducerAccount,  List<ProducerProduct> products,  List<ProducerOrganization> organizations, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences)  $default,) {final _that = this;
switch (_that) {
case _ProducerAccount():
return $default(_that.producerAccountId,_that.name,_that.contactEmail,_that.address,_that.website,_that.activeStatus,_that.createdInstant,_that.lastUpdatedInstant,_that.managementMode,_that.linkedProducerAccount,_that.products,_that.organizations,_that.userPreferences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'producer_account_id')  String producerAccountId,  String name, @JsonKey(name: 'contact_email')  String? contactEmail,  String? address,  String? website, @JsonKey(name: 'active_status')  bool activeStatus, @JsonKey(name: 'created_instant')  String? createdInstant, @JsonKey(name: 'last_updated_instant')  String? lastUpdatedInstant, @JsonKey(name: 'management_mode')  ProducerManagementMode managementMode, @JsonKey(name: 'linked_producer_account')  LinkedProducerAccount? linkedProducerAccount,  List<ProducerProduct> products,  List<ProducerOrganization> organizations, @JsonKey(name: 'user_preferences')  UserPreferences? userPreferences)?  $default,) {final _that = this;
switch (_that) {
case _ProducerAccount() when $default != null:
return $default(_that.producerAccountId,_that.name,_that.contactEmail,_that.address,_that.website,_that.activeStatus,_that.createdInstant,_that.lastUpdatedInstant,_that.managementMode,_that.linkedProducerAccount,_that.products,_that.organizations,_that.userPreferences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProducerAccount implements ProducerAccount {
  const _ProducerAccount({@JsonKey(name: 'producer_account_id') required this.producerAccountId, required this.name, @JsonKey(name: 'contact_email') this.contactEmail, this.address, this.website, @JsonKey(name: 'active_status') this.activeStatus = true, @JsonKey(name: 'created_instant') this.createdInstant, @JsonKey(name: 'last_updated_instant') this.lastUpdatedInstant, @JsonKey(name: 'management_mode') this.managementMode = ProducerManagementMode.accountBacked, @JsonKey(name: 'linked_producer_account') this.linkedProducerAccount, final  List<ProducerProduct> products = const [], final  List<ProducerOrganization> organizations = const [], @JsonKey(name: 'user_preferences') this.userPreferences}): _products = products,_organizations = organizations;
  factory _ProducerAccount.fromJson(Map<String, dynamic> json) => _$ProducerAccountFromJson(json);

@override@JsonKey(name: 'producer_account_id') final  String producerAccountId;
@override final  String name;
@override@JsonKey(name: 'contact_email') final  String? contactEmail;
@override final  String? address;
@override final  String? website;
@override@JsonKey(name: 'active_status') final  bool activeStatus;
// ISO-8601 instant strings (e.g. "2026-05-18T22:23:25.093Z") — matches
// the back's kotlin.time.Instant default serialization.
@override@JsonKey(name: 'created_instant') final  String? createdInstant;
@override@JsonKey(name: 'last_updated_instant') final  String? lastUpdatedInstant;
@override@JsonKey(name: 'management_mode') final  ProducerManagementMode managementMode;
@override@JsonKey(name: 'linked_producer_account') final  LinkedProducerAccount? linkedProducerAccount;
 final  List<ProducerProduct> _products;
@override@JsonKey() List<ProducerProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}

 final  List<ProducerOrganization> _organizations;
@override@JsonKey() List<ProducerOrganization> get organizations {
  if (_organizations is EqualUnmodifiableListView) return _organizations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_organizations);
}

@override@JsonKey(name: 'user_preferences') final  UserPreferences? userPreferences;

/// Create a copy of ProducerAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProducerAccountCopyWith<_ProducerAccount> get copyWith => __$ProducerAccountCopyWithImpl<_ProducerAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProducerAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProducerAccount&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.address, address) || other.address == address)&&(identical(other.website, website) || other.website == website)&&(identical(other.activeStatus, activeStatus) || other.activeStatus == activeStatus)&&(identical(other.createdInstant, createdInstant) || other.createdInstant == createdInstant)&&(identical(other.lastUpdatedInstant, lastUpdatedInstant) || other.lastUpdatedInstant == lastUpdatedInstant)&&(identical(other.managementMode, managementMode) || other.managementMode == managementMode)&&(identical(other.linkedProducerAccount, linkedProducerAccount) || other.linkedProducerAccount == linkedProducerAccount)&&const DeepCollectionEquality().equals(other._products, _products)&&const DeepCollectionEquality().equals(other._organizations, _organizations)&&(identical(other.userPreferences, userPreferences) || other.userPreferences == userPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerAccountId,name,contactEmail,address,website,activeStatus,createdInstant,lastUpdatedInstant,managementMode,linkedProducerAccount,const DeepCollectionEquality().hash(_products),const DeepCollectionEquality().hash(_organizations),userPreferences);

@override
String toString() {
  return 'ProducerAccount(producerAccountId: $producerAccountId, name: $name, contactEmail: $contactEmail, address: $address, website: $website, activeStatus: $activeStatus, createdInstant: $createdInstant, lastUpdatedInstant: $lastUpdatedInstant, managementMode: $managementMode, linkedProducerAccount: $linkedProducerAccount, products: $products, organizations: $organizations, userPreferences: $userPreferences)';
}


}

/// @nodoc
abstract mixin class _$ProducerAccountCopyWith<$Res> implements $ProducerAccountCopyWith<$Res> {
  factory _$ProducerAccountCopyWith(_ProducerAccount value, $Res Function(_ProducerAccount) _then) = __$ProducerAccountCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'producer_account_id') String producerAccountId, String name,@JsonKey(name: 'contact_email') String? contactEmail, String? address, String? website,@JsonKey(name: 'active_status') bool activeStatus,@JsonKey(name: 'created_instant') String? createdInstant,@JsonKey(name: 'last_updated_instant') String? lastUpdatedInstant,@JsonKey(name: 'management_mode') ProducerManagementMode managementMode,@JsonKey(name: 'linked_producer_account') LinkedProducerAccount? linkedProducerAccount, List<ProducerProduct> products, List<ProducerOrganization> organizations,@JsonKey(name: 'user_preferences') UserPreferences? userPreferences
});


@override $LinkedProducerAccountCopyWith<$Res>? get linkedProducerAccount;@override $UserPreferencesCopyWith<$Res>? get userPreferences;

}
/// @nodoc
class __$ProducerAccountCopyWithImpl<$Res>
    implements _$ProducerAccountCopyWith<$Res> {
  __$ProducerAccountCopyWithImpl(this._self, this._then);

  final _ProducerAccount _self;
  final $Res Function(_ProducerAccount) _then;

/// Create a copy of ProducerAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? producerAccountId = null,Object? name = null,Object? contactEmail = freezed,Object? address = freezed,Object? website = freezed,Object? activeStatus = null,Object? createdInstant = freezed,Object? lastUpdatedInstant = freezed,Object? managementMode = null,Object? linkedProducerAccount = freezed,Object? products = null,Object? organizations = null,Object? userPreferences = freezed,}) {
  return _then(_ProducerAccount(
producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,activeStatus: null == activeStatus ? _self.activeStatus : activeStatus // ignore: cast_nullable_to_non_nullable
as bool,createdInstant: freezed == createdInstant ? _self.createdInstant : createdInstant // ignore: cast_nullable_to_non_nullable
as String?,lastUpdatedInstant: freezed == lastUpdatedInstant ? _self.lastUpdatedInstant : lastUpdatedInstant // ignore: cast_nullable_to_non_nullable
as String?,managementMode: null == managementMode ? _self.managementMode : managementMode // ignore: cast_nullable_to_non_nullable
as ProducerManagementMode,linkedProducerAccount: freezed == linkedProducerAccount ? _self.linkedProducerAccount : linkedProducerAccount // ignore: cast_nullable_to_non_nullable
as LinkedProducerAccount?,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<ProducerProduct>,organizations: null == organizations ? _self._organizations : organizations // ignore: cast_nullable_to_non_nullable
as List<ProducerOrganization>,userPreferences: freezed == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as UserPreferences?,
  ));
}

/// Create a copy of ProducerAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkedProducerAccountCopyWith<$Res>? get linkedProducerAccount {
    if (_self.linkedProducerAccount == null) {
    return null;
  }

  return $LinkedProducerAccountCopyWith<$Res>(_self.linkedProducerAccount!, (value) {
    return _then(_self.copyWith(linkedProducerAccount: value));
  });
}/// Create a copy of ProducerAccount
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


/// @nodoc
mixin _$LinkedProducerAccount {

@JsonKey(name: 'producer_account_id') String get producerAccountId; String get name;
/// Create a copy of LinkedProducerAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedProducerAccountCopyWith<LinkedProducerAccount> get copyWith => _$LinkedProducerAccountCopyWithImpl<LinkedProducerAccount>(this as LinkedProducerAccount, _$identity);

  /// Serializes this LinkedProducerAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedProducerAccount&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerAccountId,name);

@override
String toString() {
  return 'LinkedProducerAccount(producerAccountId: $producerAccountId, name: $name)';
}


}

/// @nodoc
abstract mixin class $LinkedProducerAccountCopyWith<$Res>  {
  factory $LinkedProducerAccountCopyWith(LinkedProducerAccount value, $Res Function(LinkedProducerAccount) _then) = _$LinkedProducerAccountCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'producer_account_id') String producerAccountId, String name
});




}
/// @nodoc
class _$LinkedProducerAccountCopyWithImpl<$Res>
    implements $LinkedProducerAccountCopyWith<$Res> {
  _$LinkedProducerAccountCopyWithImpl(this._self, this._then);

  final LinkedProducerAccount _self;
  final $Res Function(LinkedProducerAccount) _then;

/// Create a copy of LinkedProducerAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? producerAccountId = null,Object? name = null,}) {
  return _then(_self.copyWith(
producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedProducerAccount].
extension LinkedProducerAccountPatterns on LinkedProducerAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedProducerAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedProducerAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedProducerAccount value)  $default,){
final _that = this;
switch (_that) {
case _LinkedProducerAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedProducerAccount value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedProducerAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_account_id')  String producerAccountId,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedProducerAccount() when $default != null:
return $default(_that.producerAccountId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'producer_account_id')  String producerAccountId,  String name)  $default,) {final _that = this;
switch (_that) {
case _LinkedProducerAccount():
return $default(_that.producerAccountId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'producer_account_id')  String producerAccountId,  String name)?  $default,) {final _that = this;
switch (_that) {
case _LinkedProducerAccount() when $default != null:
return $default(_that.producerAccountId,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkedProducerAccount implements LinkedProducerAccount {
  const _LinkedProducerAccount({@JsonKey(name: 'producer_account_id') required this.producerAccountId, required this.name});
  factory _LinkedProducerAccount.fromJson(Map<String, dynamic> json) => _$LinkedProducerAccountFromJson(json);

@override@JsonKey(name: 'producer_account_id') final  String producerAccountId;
@override final  String name;

/// Create a copy of LinkedProducerAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedProducerAccountCopyWith<_LinkedProducerAccount> get copyWith => __$LinkedProducerAccountCopyWithImpl<_LinkedProducerAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkedProducerAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedProducerAccount&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,producerAccountId,name);

@override
String toString() {
  return 'LinkedProducerAccount(producerAccountId: $producerAccountId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$LinkedProducerAccountCopyWith<$Res> implements $LinkedProducerAccountCopyWith<$Res> {
  factory _$LinkedProducerAccountCopyWith(_LinkedProducerAccount value, $Res Function(_LinkedProducerAccount) _then) = __$LinkedProducerAccountCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'producer_account_id') String producerAccountId, String name
});




}
/// @nodoc
class __$LinkedProducerAccountCopyWithImpl<$Res>
    implements _$LinkedProducerAccountCopyWith<$Res> {
  __$LinkedProducerAccountCopyWithImpl(this._self, this._then);

  final _LinkedProducerAccount _self;
  final $Res Function(_LinkedProducerAccount) _then;

/// Create a copy of LinkedProducerAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? producerAccountId = null,Object? name = null,}) {
  return _then(_LinkedProducerAccount(
producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
