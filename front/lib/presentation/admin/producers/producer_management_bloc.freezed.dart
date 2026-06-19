// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_management_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProducerManagementEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerManagementEvent()';
}


}

/// @nodoc
class $ProducerManagementEventCopyWith<$Res>  {
$ProducerManagementEventCopyWith(ProducerManagementEvent _, $Res Function(ProducerManagementEvent) __);
}


/// Adds pattern-matching-related methods to [ProducerManagementEvent].
extension ProducerManagementEventPatterns on ProducerManagementEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadRequested value)?  loadRequested,TResult Function( _StatusFilterChanged value)?  statusFilterChanged,TResult Function( _DetailRequested value)?  detailRequested,TResult Function( _BackToListRequested value)?  backToListRequested,TResult Function( _UpdateStatusRequested value)?  updateStatusRequested,TResult Function( _EnrollSearchChanged value)?  enrollSearchChanged,TResult Function( _EnrollProducerSelected value)?  enrollProducerSelected,TResult Function( _EnrollNoAccountStarted value)?  enrollNoAccountStarted,TResult Function( _EnrollConfirmed value)?  enrollConfirmed,TResult Function( _EnrollNoAccountConfirmed value)?  enrollNoAccountConfirmed,TResult Function( _UpdateProductsRequested value)?  updateProductsRequested,TResult Function( _UpdateNoAccountProductsRequested value)?  updateNoAccountProductsRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested(_that);case _StatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case _DetailRequested() when detailRequested != null:
return detailRequested(_that);case _BackToListRequested() when backToListRequested != null:
return backToListRequested(_that);case _UpdateStatusRequested() when updateStatusRequested != null:
return updateStatusRequested(_that);case _EnrollSearchChanged() when enrollSearchChanged != null:
return enrollSearchChanged(_that);case _EnrollProducerSelected() when enrollProducerSelected != null:
return enrollProducerSelected(_that);case _EnrollNoAccountStarted() when enrollNoAccountStarted != null:
return enrollNoAccountStarted(_that);case _EnrollConfirmed() when enrollConfirmed != null:
return enrollConfirmed(_that);case _EnrollNoAccountConfirmed() when enrollNoAccountConfirmed != null:
return enrollNoAccountConfirmed(_that);case _UpdateProductsRequested() when updateProductsRequested != null:
return updateProductsRequested(_that);case _UpdateNoAccountProductsRequested() when updateNoAccountProductsRequested != null:
return updateNoAccountProductsRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadRequested value)  loadRequested,required TResult Function( _StatusFilterChanged value)  statusFilterChanged,required TResult Function( _DetailRequested value)  detailRequested,required TResult Function( _BackToListRequested value)  backToListRequested,required TResult Function( _UpdateStatusRequested value)  updateStatusRequested,required TResult Function( _EnrollSearchChanged value)  enrollSearchChanged,required TResult Function( _EnrollProducerSelected value)  enrollProducerSelected,required TResult Function( _EnrollNoAccountStarted value)  enrollNoAccountStarted,required TResult Function( _EnrollConfirmed value)  enrollConfirmed,required TResult Function( _EnrollNoAccountConfirmed value)  enrollNoAccountConfirmed,required TResult Function( _UpdateProductsRequested value)  updateProductsRequested,required TResult Function( _UpdateNoAccountProductsRequested value)  updateNoAccountProductsRequested,}){
final _that = this;
switch (_that) {
case _LoadRequested():
return loadRequested(_that);case _StatusFilterChanged():
return statusFilterChanged(_that);case _DetailRequested():
return detailRequested(_that);case _BackToListRequested():
return backToListRequested(_that);case _UpdateStatusRequested():
return updateStatusRequested(_that);case _EnrollSearchChanged():
return enrollSearchChanged(_that);case _EnrollProducerSelected():
return enrollProducerSelected(_that);case _EnrollNoAccountStarted():
return enrollNoAccountStarted(_that);case _EnrollConfirmed():
return enrollConfirmed(_that);case _EnrollNoAccountConfirmed():
return enrollNoAccountConfirmed(_that);case _UpdateProductsRequested():
return updateProductsRequested(_that);case _UpdateNoAccountProductsRequested():
return updateNoAccountProductsRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadRequested value)?  loadRequested,TResult? Function( _StatusFilterChanged value)?  statusFilterChanged,TResult? Function( _DetailRequested value)?  detailRequested,TResult? Function( _BackToListRequested value)?  backToListRequested,TResult? Function( _UpdateStatusRequested value)?  updateStatusRequested,TResult? Function( _EnrollSearchChanged value)?  enrollSearchChanged,TResult? Function( _EnrollProducerSelected value)?  enrollProducerSelected,TResult? Function( _EnrollNoAccountStarted value)?  enrollNoAccountStarted,TResult? Function( _EnrollConfirmed value)?  enrollConfirmed,TResult? Function( _EnrollNoAccountConfirmed value)?  enrollNoAccountConfirmed,TResult? Function( _UpdateProductsRequested value)?  updateProductsRequested,TResult? Function( _UpdateNoAccountProductsRequested value)?  updateNoAccountProductsRequested,}){
final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested(_that);case _StatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case _DetailRequested() when detailRequested != null:
return detailRequested(_that);case _BackToListRequested() when backToListRequested != null:
return backToListRequested(_that);case _UpdateStatusRequested() when updateStatusRequested != null:
return updateStatusRequested(_that);case _EnrollSearchChanged() when enrollSearchChanged != null:
return enrollSearchChanged(_that);case _EnrollProducerSelected() when enrollProducerSelected != null:
return enrollProducerSelected(_that);case _EnrollNoAccountStarted() when enrollNoAccountStarted != null:
return enrollNoAccountStarted(_that);case _EnrollConfirmed() when enrollConfirmed != null:
return enrollConfirmed(_that);case _EnrollNoAccountConfirmed() when enrollNoAccountConfirmed != null:
return enrollNoAccountConfirmed(_that);case _UpdateProductsRequested() when updateProductsRequested != null:
return updateProductsRequested(_that);case _UpdateNoAccountProductsRequested() when updateNoAccountProductsRequested != null:
return updateNoAccountProductsRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadRequested,TResult Function( OrganizationProducerStatus? status)?  statusFilterChanged,TResult Function( String producerAccountId)?  detailRequested,TResult Function()?  backToListRequested,TResult Function( String producerAccountId,  OrganizationProducerStatus newStatus)?  updateStatusRequested,TResult Function( String query)?  enrollSearchChanged,TResult Function( ProducerAccount producer)?  enrollProducerSelected,TResult Function()?  enrollNoAccountStarted,TResult Function( List<OrgProduct> products)?  enrollConfirmed,TResult Function( String name,  String? contactEmail,  String? address,  String? website,  List<ProducerProduct> products)?  enrollNoAccountConfirmed,TResult Function( ProducerAccount producerAccount,  List<OrgProduct> products)?  updateProductsRequested,TResult Function( ProducerAccount producerAccount,  List<ProducerProduct> products)?  updateNoAccountProductsRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested();case _StatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case _DetailRequested() when detailRequested != null:
return detailRequested(_that.producerAccountId);case _BackToListRequested() when backToListRequested != null:
return backToListRequested();case _UpdateStatusRequested() when updateStatusRequested != null:
return updateStatusRequested(_that.producerAccountId,_that.newStatus);case _EnrollSearchChanged() when enrollSearchChanged != null:
return enrollSearchChanged(_that.query);case _EnrollProducerSelected() when enrollProducerSelected != null:
return enrollProducerSelected(_that.producer);case _EnrollNoAccountStarted() when enrollNoAccountStarted != null:
return enrollNoAccountStarted();case _EnrollConfirmed() when enrollConfirmed != null:
return enrollConfirmed(_that.products);case _EnrollNoAccountConfirmed() when enrollNoAccountConfirmed != null:
return enrollNoAccountConfirmed(_that.name,_that.contactEmail,_that.address,_that.website,_that.products);case _UpdateProductsRequested() when updateProductsRequested != null:
return updateProductsRequested(_that.producerAccount,_that.products);case _UpdateNoAccountProductsRequested() when updateNoAccountProductsRequested != null:
return updateNoAccountProductsRequested(_that.producerAccount,_that.products);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadRequested,required TResult Function( OrganizationProducerStatus? status)  statusFilterChanged,required TResult Function( String producerAccountId)  detailRequested,required TResult Function()  backToListRequested,required TResult Function( String producerAccountId,  OrganizationProducerStatus newStatus)  updateStatusRequested,required TResult Function( String query)  enrollSearchChanged,required TResult Function( ProducerAccount producer)  enrollProducerSelected,required TResult Function()  enrollNoAccountStarted,required TResult Function( List<OrgProduct> products)  enrollConfirmed,required TResult Function( String name,  String? contactEmail,  String? address,  String? website,  List<ProducerProduct> products)  enrollNoAccountConfirmed,required TResult Function( ProducerAccount producerAccount,  List<OrgProduct> products)  updateProductsRequested,required TResult Function( ProducerAccount producerAccount,  List<ProducerProduct> products)  updateNoAccountProductsRequested,}) {final _that = this;
switch (_that) {
case _LoadRequested():
return loadRequested();case _StatusFilterChanged():
return statusFilterChanged(_that.status);case _DetailRequested():
return detailRequested(_that.producerAccountId);case _BackToListRequested():
return backToListRequested();case _UpdateStatusRequested():
return updateStatusRequested(_that.producerAccountId,_that.newStatus);case _EnrollSearchChanged():
return enrollSearchChanged(_that.query);case _EnrollProducerSelected():
return enrollProducerSelected(_that.producer);case _EnrollNoAccountStarted():
return enrollNoAccountStarted();case _EnrollConfirmed():
return enrollConfirmed(_that.products);case _EnrollNoAccountConfirmed():
return enrollNoAccountConfirmed(_that.name,_that.contactEmail,_that.address,_that.website,_that.products);case _UpdateProductsRequested():
return updateProductsRequested(_that.producerAccount,_that.products);case _UpdateNoAccountProductsRequested():
return updateNoAccountProductsRequested(_that.producerAccount,_that.products);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadRequested,TResult? Function( OrganizationProducerStatus? status)?  statusFilterChanged,TResult? Function( String producerAccountId)?  detailRequested,TResult? Function()?  backToListRequested,TResult? Function( String producerAccountId,  OrganizationProducerStatus newStatus)?  updateStatusRequested,TResult? Function( String query)?  enrollSearchChanged,TResult? Function( ProducerAccount producer)?  enrollProducerSelected,TResult? Function()?  enrollNoAccountStarted,TResult? Function( List<OrgProduct> products)?  enrollConfirmed,TResult? Function( String name,  String? contactEmail,  String? address,  String? website,  List<ProducerProduct> products)?  enrollNoAccountConfirmed,TResult? Function( ProducerAccount producerAccount,  List<OrgProduct> products)?  updateProductsRequested,TResult? Function( ProducerAccount producerAccount,  List<ProducerProduct> products)?  updateNoAccountProductsRequested,}) {final _that = this;
switch (_that) {
case _LoadRequested() when loadRequested != null:
return loadRequested();case _StatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case _DetailRequested() when detailRequested != null:
return detailRequested(_that.producerAccountId);case _BackToListRequested() when backToListRequested != null:
return backToListRequested();case _UpdateStatusRequested() when updateStatusRequested != null:
return updateStatusRequested(_that.producerAccountId,_that.newStatus);case _EnrollSearchChanged() when enrollSearchChanged != null:
return enrollSearchChanged(_that.query);case _EnrollProducerSelected() when enrollProducerSelected != null:
return enrollProducerSelected(_that.producer);case _EnrollNoAccountStarted() when enrollNoAccountStarted != null:
return enrollNoAccountStarted();case _EnrollConfirmed() when enrollConfirmed != null:
return enrollConfirmed(_that.products);case _EnrollNoAccountConfirmed() when enrollNoAccountConfirmed != null:
return enrollNoAccountConfirmed(_that.name,_that.contactEmail,_that.address,_that.website,_that.products);case _UpdateProductsRequested() when updateProductsRequested != null:
return updateProductsRequested(_that.producerAccount,_that.products);case _UpdateNoAccountProductsRequested() when updateNoAccountProductsRequested != null:
return updateNoAccountProductsRequested(_that.producerAccount,_that.products);case _:
  return null;

}
}

}

/// @nodoc


class _LoadRequested implements ProducerManagementEvent {
  const _LoadRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerManagementEvent.loadRequested()';
}


}




/// @nodoc


class _StatusFilterChanged implements ProducerManagementEvent {
  const _StatusFilterChanged(this.status);
  

 final  OrganizationProducerStatus? status;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusFilterChangedCopyWith<_StatusFilterChanged> get copyWith => __$StatusFilterChangedCopyWithImpl<_StatusFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusFilterChanged&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'ProducerManagementEvent.statusFilterChanged(status: $status)';
}


}

/// @nodoc
abstract mixin class _$StatusFilterChangedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$StatusFilterChangedCopyWith(_StatusFilterChanged value, $Res Function(_StatusFilterChanged) _then) = __$StatusFilterChangedCopyWithImpl;
@useResult
$Res call({
 OrganizationProducerStatus? status
});




}
/// @nodoc
class __$StatusFilterChangedCopyWithImpl<$Res>
    implements _$StatusFilterChangedCopyWith<$Res> {
  __$StatusFilterChangedCopyWithImpl(this._self, this._then);

  final _StatusFilterChanged _self;
  final $Res Function(_StatusFilterChanged) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_StatusFilterChanged(
freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrganizationProducerStatus?,
  ));
}


}

/// @nodoc


class _DetailRequested implements ProducerManagementEvent {
  const _DetailRequested(this.producerAccountId);
  

 final  String producerAccountId;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetailRequestedCopyWith<_DetailRequested> get copyWith => __$DetailRequestedCopyWithImpl<_DetailRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetailRequested&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId));
}


@override
int get hashCode => Object.hash(runtimeType,producerAccountId);

@override
String toString() {
  return 'ProducerManagementEvent.detailRequested(producerAccountId: $producerAccountId)';
}


}

/// @nodoc
abstract mixin class _$DetailRequestedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$DetailRequestedCopyWith(_DetailRequested value, $Res Function(_DetailRequested) _then) = __$DetailRequestedCopyWithImpl;
@useResult
$Res call({
 String producerAccountId
});




}
/// @nodoc
class __$DetailRequestedCopyWithImpl<$Res>
    implements _$DetailRequestedCopyWith<$Res> {
  __$DetailRequestedCopyWithImpl(this._self, this._then);

  final _DetailRequested _self;
  final $Res Function(_DetailRequested) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? producerAccountId = null,}) {
  return _then(_DetailRequested(
null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _BackToListRequested implements ProducerManagementEvent {
  const _BackToListRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackToListRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerManagementEvent.backToListRequested()';
}


}




/// @nodoc


class _UpdateStatusRequested implements ProducerManagementEvent {
  const _UpdateStatusRequested({required this.producerAccountId, required this.newStatus});
  

 final  String producerAccountId;
 final  OrganizationProducerStatus newStatus;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateStatusRequestedCopyWith<_UpdateStatusRequested> get copyWith => __$UpdateStatusRequestedCopyWithImpl<_UpdateStatusRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateStatusRequested&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.newStatus, newStatus) || other.newStatus == newStatus));
}


@override
int get hashCode => Object.hash(runtimeType,producerAccountId,newStatus);

@override
String toString() {
  return 'ProducerManagementEvent.updateStatusRequested(producerAccountId: $producerAccountId, newStatus: $newStatus)';
}


}

/// @nodoc
abstract mixin class _$UpdateStatusRequestedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$UpdateStatusRequestedCopyWith(_UpdateStatusRequested value, $Res Function(_UpdateStatusRequested) _then) = __$UpdateStatusRequestedCopyWithImpl;
@useResult
$Res call({
 String producerAccountId, OrganizationProducerStatus newStatus
});




}
/// @nodoc
class __$UpdateStatusRequestedCopyWithImpl<$Res>
    implements _$UpdateStatusRequestedCopyWith<$Res> {
  __$UpdateStatusRequestedCopyWithImpl(this._self, this._then);

  final _UpdateStatusRequested _self;
  final $Res Function(_UpdateStatusRequested) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? producerAccountId = null,Object? newStatus = null,}) {
  return _then(_UpdateStatusRequested(
producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,newStatus: null == newStatus ? _self.newStatus : newStatus // ignore: cast_nullable_to_non_nullable
as OrganizationProducerStatus,
  ));
}


}

/// @nodoc


class _EnrollSearchChanged implements ProducerManagementEvent {
  const _EnrollSearchChanged(this.query);
  

 final  String query;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollSearchChangedCopyWith<_EnrollSearchChanged> get copyWith => __$EnrollSearchChangedCopyWithImpl<_EnrollSearchChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollSearchChanged&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'ProducerManagementEvent.enrollSearchChanged(query: $query)';
}


}

/// @nodoc
abstract mixin class _$EnrollSearchChangedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$EnrollSearchChangedCopyWith(_EnrollSearchChanged value, $Res Function(_EnrollSearchChanged) _then) = __$EnrollSearchChangedCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class __$EnrollSearchChangedCopyWithImpl<$Res>
    implements _$EnrollSearchChangedCopyWith<$Res> {
  __$EnrollSearchChangedCopyWithImpl(this._self, this._then);

  final _EnrollSearchChanged _self;
  final $Res Function(_EnrollSearchChanged) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(_EnrollSearchChanged(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _EnrollProducerSelected implements ProducerManagementEvent {
  const _EnrollProducerSelected(this.producer);
  

 final  ProducerAccount producer;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollProducerSelectedCopyWith<_EnrollProducerSelected> get copyWith => __$EnrollProducerSelectedCopyWithImpl<_EnrollProducerSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollProducerSelected&&(identical(other.producer, producer) || other.producer == producer));
}


@override
int get hashCode => Object.hash(runtimeType,producer);

@override
String toString() {
  return 'ProducerManagementEvent.enrollProducerSelected(producer: $producer)';
}


}

/// @nodoc
abstract mixin class _$EnrollProducerSelectedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$EnrollProducerSelectedCopyWith(_EnrollProducerSelected value, $Res Function(_EnrollProducerSelected) _then) = __$EnrollProducerSelectedCopyWithImpl;
@useResult
$Res call({
 ProducerAccount producer
});


$ProducerAccountCopyWith<$Res> get producer;

}
/// @nodoc
class __$EnrollProducerSelectedCopyWithImpl<$Res>
    implements _$EnrollProducerSelectedCopyWith<$Res> {
  __$EnrollProducerSelectedCopyWithImpl(this._self, this._then);

  final _EnrollProducerSelected _self;
  final $Res Function(_EnrollProducerSelected) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? producer = null,}) {
  return _then(_EnrollProducerSelected(
null == producer ? _self.producer : producer // ignore: cast_nullable_to_non_nullable
as ProducerAccount,
  ));
}

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProducerAccountCopyWith<$Res> get producer {
  
  return $ProducerAccountCopyWith<$Res>(_self.producer, (value) {
    return _then(_self.copyWith(producer: value));
  });
}
}

/// @nodoc


class _EnrollNoAccountStarted implements ProducerManagementEvent {
  const _EnrollNoAccountStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollNoAccountStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerManagementEvent.enrollNoAccountStarted()';
}


}




/// @nodoc


class _EnrollConfirmed implements ProducerManagementEvent {
  const _EnrollConfirmed(final  List<OrgProduct> products): _products = products;
  

 final  List<OrgProduct> _products;
 List<OrgProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollConfirmedCopyWith<_EnrollConfirmed> get copyWith => __$EnrollConfirmedCopyWithImpl<_EnrollConfirmed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollConfirmed&&const DeepCollectionEquality().equals(other._products, _products));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'ProducerManagementEvent.enrollConfirmed(products: $products)';
}


}

/// @nodoc
abstract mixin class _$EnrollConfirmedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$EnrollConfirmedCopyWith(_EnrollConfirmed value, $Res Function(_EnrollConfirmed) _then) = __$EnrollConfirmedCopyWithImpl;
@useResult
$Res call({
 List<OrgProduct> products
});




}
/// @nodoc
class __$EnrollConfirmedCopyWithImpl<$Res>
    implements _$EnrollConfirmedCopyWith<$Res> {
  __$EnrollConfirmedCopyWithImpl(this._self, this._then);

  final _EnrollConfirmed _self;
  final $Res Function(_EnrollConfirmed) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? products = null,}) {
  return _then(_EnrollConfirmed(
null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<OrgProduct>,
  ));
}


}

/// @nodoc


class _EnrollNoAccountConfirmed implements ProducerManagementEvent {
  const _EnrollNoAccountConfirmed({required this.name, this.contactEmail, this.address, this.website, required final  List<ProducerProduct> products}): _products = products;
  

 final  String name;
 final  String? contactEmail;
 final  String? address;
 final  String? website;
 final  List<ProducerProduct> _products;
 List<ProducerProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollNoAccountConfirmedCopyWith<_EnrollNoAccountConfirmed> get copyWith => __$EnrollNoAccountConfirmedCopyWithImpl<_EnrollNoAccountConfirmed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollNoAccountConfirmed&&(identical(other.name, name) || other.name == name)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.address, address) || other.address == address)&&(identical(other.website, website) || other.website == website)&&const DeepCollectionEquality().equals(other._products, _products));
}


@override
int get hashCode => Object.hash(runtimeType,name,contactEmail,address,website,const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'ProducerManagementEvent.enrollNoAccountConfirmed(name: $name, contactEmail: $contactEmail, address: $address, website: $website, products: $products)';
}


}

/// @nodoc
abstract mixin class _$EnrollNoAccountConfirmedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$EnrollNoAccountConfirmedCopyWith(_EnrollNoAccountConfirmed value, $Res Function(_EnrollNoAccountConfirmed) _then) = __$EnrollNoAccountConfirmedCopyWithImpl;
@useResult
$Res call({
 String name, String? contactEmail, String? address, String? website, List<ProducerProduct> products
});




}
/// @nodoc
class __$EnrollNoAccountConfirmedCopyWithImpl<$Res>
    implements _$EnrollNoAccountConfirmedCopyWith<$Res> {
  __$EnrollNoAccountConfirmedCopyWithImpl(this._self, this._then);

  final _EnrollNoAccountConfirmed _self;
  final $Res Function(_EnrollNoAccountConfirmed) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? contactEmail = freezed,Object? address = freezed,Object? website = freezed,Object? products = null,}) {
  return _then(_EnrollNoAccountConfirmed(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<ProducerProduct>,
  ));
}


}

/// @nodoc


class _UpdateProductsRequested implements ProducerManagementEvent {
  const _UpdateProductsRequested({required this.producerAccount, required final  List<OrgProduct> products}): _products = products;
  

 final  ProducerAccount producerAccount;
 final  List<OrgProduct> _products;
 List<OrgProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateProductsRequestedCopyWith<_UpdateProductsRequested> get copyWith => __$UpdateProductsRequestedCopyWithImpl<_UpdateProductsRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateProductsRequested&&(identical(other.producerAccount, producerAccount) || other.producerAccount == producerAccount)&&const DeepCollectionEquality().equals(other._products, _products));
}


@override
int get hashCode => Object.hash(runtimeType,producerAccount,const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'ProducerManagementEvent.updateProductsRequested(producerAccount: $producerAccount, products: $products)';
}


}

/// @nodoc
abstract mixin class _$UpdateProductsRequestedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$UpdateProductsRequestedCopyWith(_UpdateProductsRequested value, $Res Function(_UpdateProductsRequested) _then) = __$UpdateProductsRequestedCopyWithImpl;
@useResult
$Res call({
 ProducerAccount producerAccount, List<OrgProduct> products
});


$ProducerAccountCopyWith<$Res> get producerAccount;

}
/// @nodoc
class __$UpdateProductsRequestedCopyWithImpl<$Res>
    implements _$UpdateProductsRequestedCopyWith<$Res> {
  __$UpdateProductsRequestedCopyWithImpl(this._self, this._then);

  final _UpdateProductsRequested _self;
  final $Res Function(_UpdateProductsRequested) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? producerAccount = null,Object? products = null,}) {
  return _then(_UpdateProductsRequested(
producerAccount: null == producerAccount ? _self.producerAccount : producerAccount // ignore: cast_nullable_to_non_nullable
as ProducerAccount,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<OrgProduct>,
  ));
}

/// Create a copy of ProducerManagementEvent
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


class _UpdateNoAccountProductsRequested implements ProducerManagementEvent {
  const _UpdateNoAccountProductsRequested({required this.producerAccount, required final  List<ProducerProduct> products}): _products = products;
  

 final  ProducerAccount producerAccount;
 final  List<ProducerProduct> _products;
 List<ProducerProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateNoAccountProductsRequestedCopyWith<_UpdateNoAccountProductsRequested> get copyWith => __$UpdateNoAccountProductsRequestedCopyWithImpl<_UpdateNoAccountProductsRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateNoAccountProductsRequested&&(identical(other.producerAccount, producerAccount) || other.producerAccount == producerAccount)&&const DeepCollectionEquality().equals(other._products, _products));
}


@override
int get hashCode => Object.hash(runtimeType,producerAccount,const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'ProducerManagementEvent.updateNoAccountProductsRequested(producerAccount: $producerAccount, products: $products)';
}


}

/// @nodoc
abstract mixin class _$UpdateNoAccountProductsRequestedCopyWith<$Res> implements $ProducerManagementEventCopyWith<$Res> {
  factory _$UpdateNoAccountProductsRequestedCopyWith(_UpdateNoAccountProductsRequested value, $Res Function(_UpdateNoAccountProductsRequested) _then) = __$UpdateNoAccountProductsRequestedCopyWithImpl;
@useResult
$Res call({
 ProducerAccount producerAccount, List<ProducerProduct> products
});


$ProducerAccountCopyWith<$Res> get producerAccount;

}
/// @nodoc
class __$UpdateNoAccountProductsRequestedCopyWithImpl<$Res>
    implements _$UpdateNoAccountProductsRequestedCopyWith<$Res> {
  __$UpdateNoAccountProductsRequestedCopyWithImpl(this._self, this._then);

  final _UpdateNoAccountProductsRequested _self;
  final $Res Function(_UpdateNoAccountProductsRequested) _then;

/// Create a copy of ProducerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? producerAccount = null,Object? products = null,}) {
  return _then(_UpdateNoAccountProductsRequested(
producerAccount: null == producerAccount ? _self.producerAccount : producerAccount // ignore: cast_nullable_to_non_nullable
as ProducerAccount,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<ProducerProduct>,
  ));
}

/// Create a copy of ProducerManagementEvent
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
mixin _$ProducerManagementState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerManagementState()';
}


}

/// @nodoc
class $ProducerManagementStateCopyWith<$Res>  {
$ProducerManagementStateCopyWith(ProducerManagementState _, $Res Function(ProducerManagementState) __);
}


/// Adds pattern-matching-related methods to [ProducerManagementState].
extension ProducerManagementStatePatterns on ProducerManagementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProducerManagementInitial value)?  initial,TResult Function( ProducerManagementLoading value)?  loading,TResult Function( ProducerManagementListLoaded value)?  listLoaded,TResult Function( ProducerManagementDetailLoaded value)?  detailLoaded,TResult Function( ProducerManagementEnrollStep1 value)?  enrollStep1,TResult Function( ProducerManagementEnrollStep2 value)?  enrollStep2,TResult Function( ProducerManagementEnrollNoAccountStep2 value)?  enrollNoAccountStep2,TResult Function( ProducerManagementError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProducerManagementInitial() when initial != null:
return initial(_that);case ProducerManagementLoading() when loading != null:
return loading(_that);case ProducerManagementListLoaded() when listLoaded != null:
return listLoaded(_that);case ProducerManagementDetailLoaded() when detailLoaded != null:
return detailLoaded(_that);case ProducerManagementEnrollStep1() when enrollStep1 != null:
return enrollStep1(_that);case ProducerManagementEnrollStep2() when enrollStep2 != null:
return enrollStep2(_that);case ProducerManagementEnrollNoAccountStep2() when enrollNoAccountStep2 != null:
return enrollNoAccountStep2(_that);case ProducerManagementError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProducerManagementInitial value)  initial,required TResult Function( ProducerManagementLoading value)  loading,required TResult Function( ProducerManagementListLoaded value)  listLoaded,required TResult Function( ProducerManagementDetailLoaded value)  detailLoaded,required TResult Function( ProducerManagementEnrollStep1 value)  enrollStep1,required TResult Function( ProducerManagementEnrollStep2 value)  enrollStep2,required TResult Function( ProducerManagementEnrollNoAccountStep2 value)  enrollNoAccountStep2,required TResult Function( ProducerManagementError value)  error,}){
final _that = this;
switch (_that) {
case ProducerManagementInitial():
return initial(_that);case ProducerManagementLoading():
return loading(_that);case ProducerManagementListLoaded():
return listLoaded(_that);case ProducerManagementDetailLoaded():
return detailLoaded(_that);case ProducerManagementEnrollStep1():
return enrollStep1(_that);case ProducerManagementEnrollStep2():
return enrollStep2(_that);case ProducerManagementEnrollNoAccountStep2():
return enrollNoAccountStep2(_that);case ProducerManagementError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProducerManagementInitial value)?  initial,TResult? Function( ProducerManagementLoading value)?  loading,TResult? Function( ProducerManagementListLoaded value)?  listLoaded,TResult? Function( ProducerManagementDetailLoaded value)?  detailLoaded,TResult? Function( ProducerManagementEnrollStep1 value)?  enrollStep1,TResult? Function( ProducerManagementEnrollStep2 value)?  enrollStep2,TResult? Function( ProducerManagementEnrollNoAccountStep2 value)?  enrollNoAccountStep2,TResult? Function( ProducerManagementError value)?  error,}){
final _that = this;
switch (_that) {
case ProducerManagementInitial() when initial != null:
return initial(_that);case ProducerManagementLoading() when loading != null:
return loading(_that);case ProducerManagementListLoaded() when listLoaded != null:
return listLoaded(_that);case ProducerManagementDetailLoaded() when detailLoaded != null:
return detailLoaded(_that);case ProducerManagementEnrollStep1() when enrollStep1 != null:
return enrollStep1(_that);case ProducerManagementEnrollStep2() when enrollStep2 != null:
return enrollStep2(_that);case ProducerManagementEnrollNoAccountStep2() when enrollNoAccountStep2 != null:
return enrollNoAccountStep2(_that);case ProducerManagementError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Organization organization,  OrganizationProducerStatus? statusFilter,  bool actionInProgress,  String? actionError)?  listLoaded,TResult Function( Organization organization,  String producerAccountId,  bool actionInProgress,  String? actionError)?  detailLoaded,TResult Function( Organization organization,  String searchQuery,  List<ProducerAccount> searchResults,  bool searching)?  enrollStep1,TResult Function( Organization organization,  ProducerAccount selectedProducer,  bool actionInProgress,  String? actionError)?  enrollStep2,TResult Function( Organization organization,  bool actionInProgress,  String? actionError)?  enrollNoAccountStep2,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProducerManagementInitial() when initial != null:
return initial();case ProducerManagementLoading() when loading != null:
return loading();case ProducerManagementListLoaded() when listLoaded != null:
return listLoaded(_that.organization,_that.statusFilter,_that.actionInProgress,_that.actionError);case ProducerManagementDetailLoaded() when detailLoaded != null:
return detailLoaded(_that.organization,_that.producerAccountId,_that.actionInProgress,_that.actionError);case ProducerManagementEnrollStep1() when enrollStep1 != null:
return enrollStep1(_that.organization,_that.searchQuery,_that.searchResults,_that.searching);case ProducerManagementEnrollStep2() when enrollStep2 != null:
return enrollStep2(_that.organization,_that.selectedProducer,_that.actionInProgress,_that.actionError);case ProducerManagementEnrollNoAccountStep2() when enrollNoAccountStep2 != null:
return enrollNoAccountStep2(_that.organization,_that.actionInProgress,_that.actionError);case ProducerManagementError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Organization organization,  OrganizationProducerStatus? statusFilter,  bool actionInProgress,  String? actionError)  listLoaded,required TResult Function( Organization organization,  String producerAccountId,  bool actionInProgress,  String? actionError)  detailLoaded,required TResult Function( Organization organization,  String searchQuery,  List<ProducerAccount> searchResults,  bool searching)  enrollStep1,required TResult Function( Organization organization,  ProducerAccount selectedProducer,  bool actionInProgress,  String? actionError)  enrollStep2,required TResult Function( Organization organization,  bool actionInProgress,  String? actionError)  enrollNoAccountStep2,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ProducerManagementInitial():
return initial();case ProducerManagementLoading():
return loading();case ProducerManagementListLoaded():
return listLoaded(_that.organization,_that.statusFilter,_that.actionInProgress,_that.actionError);case ProducerManagementDetailLoaded():
return detailLoaded(_that.organization,_that.producerAccountId,_that.actionInProgress,_that.actionError);case ProducerManagementEnrollStep1():
return enrollStep1(_that.organization,_that.searchQuery,_that.searchResults,_that.searching);case ProducerManagementEnrollStep2():
return enrollStep2(_that.organization,_that.selectedProducer,_that.actionInProgress,_that.actionError);case ProducerManagementEnrollNoAccountStep2():
return enrollNoAccountStep2(_that.organization,_that.actionInProgress,_that.actionError);case ProducerManagementError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Organization organization,  OrganizationProducerStatus? statusFilter,  bool actionInProgress,  String? actionError)?  listLoaded,TResult? Function( Organization organization,  String producerAccountId,  bool actionInProgress,  String? actionError)?  detailLoaded,TResult? Function( Organization organization,  String searchQuery,  List<ProducerAccount> searchResults,  bool searching)?  enrollStep1,TResult? Function( Organization organization,  ProducerAccount selectedProducer,  bool actionInProgress,  String? actionError)?  enrollStep2,TResult? Function( Organization organization,  bool actionInProgress,  String? actionError)?  enrollNoAccountStep2,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ProducerManagementInitial() when initial != null:
return initial();case ProducerManagementLoading() when loading != null:
return loading();case ProducerManagementListLoaded() when listLoaded != null:
return listLoaded(_that.organization,_that.statusFilter,_that.actionInProgress,_that.actionError);case ProducerManagementDetailLoaded() when detailLoaded != null:
return detailLoaded(_that.organization,_that.producerAccountId,_that.actionInProgress,_that.actionError);case ProducerManagementEnrollStep1() when enrollStep1 != null:
return enrollStep1(_that.organization,_that.searchQuery,_that.searchResults,_that.searching);case ProducerManagementEnrollStep2() when enrollStep2 != null:
return enrollStep2(_that.organization,_that.selectedProducer,_that.actionInProgress,_that.actionError);case ProducerManagementEnrollNoAccountStep2() when enrollNoAccountStep2 != null:
return enrollNoAccountStep2(_that.organization,_that.actionInProgress,_that.actionError);case ProducerManagementError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ProducerManagementInitial implements ProducerManagementState {
  const ProducerManagementInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerManagementState.initial()';
}


}




/// @nodoc


class ProducerManagementLoading implements ProducerManagementState {
  const ProducerManagementLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerManagementState.loading()';
}


}




/// @nodoc


class ProducerManagementListLoaded implements ProducerManagementState {
  const ProducerManagementListLoaded({required this.organization, this.statusFilter, this.actionInProgress = false, this.actionError});
  

 final  Organization organization;
 final  OrganizationProducerStatus? statusFilter;
@JsonKey() final  bool actionInProgress;
 final  String? actionError;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerManagementListLoadedCopyWith<ProducerManagementListLoaded> get copyWith => _$ProducerManagementListLoadedCopyWithImpl<ProducerManagementListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementListLoaded&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.actionError, actionError) || other.actionError == actionError));
}


@override
int get hashCode => Object.hash(runtimeType,organization,statusFilter,actionInProgress,actionError);

@override
String toString() {
  return 'ProducerManagementState.listLoaded(organization: $organization, statusFilter: $statusFilter, actionInProgress: $actionInProgress, actionError: $actionError)';
}


}

/// @nodoc
abstract mixin class $ProducerManagementListLoadedCopyWith<$Res> implements $ProducerManagementStateCopyWith<$Res> {
  factory $ProducerManagementListLoadedCopyWith(ProducerManagementListLoaded value, $Res Function(ProducerManagementListLoaded) _then) = _$ProducerManagementListLoadedCopyWithImpl;
@useResult
$Res call({
 Organization organization, OrganizationProducerStatus? statusFilter, bool actionInProgress, String? actionError
});


$OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class _$ProducerManagementListLoadedCopyWithImpl<$Res>
    implements $ProducerManagementListLoadedCopyWith<$Res> {
  _$ProducerManagementListLoadedCopyWithImpl(this._self, this._then);

  final ProducerManagementListLoaded _self;
  final $Res Function(ProducerManagementListLoaded) _then;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? statusFilter = freezed,Object? actionInProgress = null,Object? actionError = freezed,}) {
  return _then(ProducerManagementListLoaded(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as OrganizationProducerStatus?,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProducerManagementState
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


class ProducerManagementDetailLoaded implements ProducerManagementState {
  const ProducerManagementDetailLoaded({required this.organization, required this.producerAccountId, this.actionInProgress = false, this.actionError});
  

 final  Organization organization;
 final  String producerAccountId;
@JsonKey() final  bool actionInProgress;
 final  String? actionError;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerManagementDetailLoadedCopyWith<ProducerManagementDetailLoaded> get copyWith => _$ProducerManagementDetailLoadedCopyWithImpl<ProducerManagementDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementDetailLoaded&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.producerAccountId, producerAccountId) || other.producerAccountId == producerAccountId)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.actionError, actionError) || other.actionError == actionError));
}


@override
int get hashCode => Object.hash(runtimeType,organization,producerAccountId,actionInProgress,actionError);

@override
String toString() {
  return 'ProducerManagementState.detailLoaded(organization: $organization, producerAccountId: $producerAccountId, actionInProgress: $actionInProgress, actionError: $actionError)';
}


}

/// @nodoc
abstract mixin class $ProducerManagementDetailLoadedCopyWith<$Res> implements $ProducerManagementStateCopyWith<$Res> {
  factory $ProducerManagementDetailLoadedCopyWith(ProducerManagementDetailLoaded value, $Res Function(ProducerManagementDetailLoaded) _then) = _$ProducerManagementDetailLoadedCopyWithImpl;
@useResult
$Res call({
 Organization organization, String producerAccountId, bool actionInProgress, String? actionError
});


$OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class _$ProducerManagementDetailLoadedCopyWithImpl<$Res>
    implements $ProducerManagementDetailLoadedCopyWith<$Res> {
  _$ProducerManagementDetailLoadedCopyWithImpl(this._self, this._then);

  final ProducerManagementDetailLoaded _self;
  final $Res Function(ProducerManagementDetailLoaded) _then;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? producerAccountId = null,Object? actionInProgress = null,Object? actionError = freezed,}) {
  return _then(ProducerManagementDetailLoaded(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,producerAccountId: null == producerAccountId ? _self.producerAccountId : producerAccountId // ignore: cast_nullable_to_non_nullable
as String,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProducerManagementState
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


class ProducerManagementEnrollStep1 implements ProducerManagementState {
  const ProducerManagementEnrollStep1({required this.organization, this.searchQuery = '', final  List<ProducerAccount> searchResults = const [], this.searching = false}): _searchResults = searchResults;
  

 final  Organization organization;
@JsonKey() final  String searchQuery;
 final  List<ProducerAccount> _searchResults;
@JsonKey() List<ProducerAccount> get searchResults {
  if (_searchResults is EqualUnmodifiableListView) return _searchResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchResults);
}

@JsonKey() final  bool searching;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerManagementEnrollStep1CopyWith<ProducerManagementEnrollStep1> get copyWith => _$ProducerManagementEnrollStep1CopyWithImpl<ProducerManagementEnrollStep1>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementEnrollStep1&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&const DeepCollectionEquality().equals(other._searchResults, _searchResults)&&(identical(other.searching, searching) || other.searching == searching));
}


@override
int get hashCode => Object.hash(runtimeType,organization,searchQuery,const DeepCollectionEquality().hash(_searchResults),searching);

@override
String toString() {
  return 'ProducerManagementState.enrollStep1(organization: $organization, searchQuery: $searchQuery, searchResults: $searchResults, searching: $searching)';
}


}

/// @nodoc
abstract mixin class $ProducerManagementEnrollStep1CopyWith<$Res> implements $ProducerManagementStateCopyWith<$Res> {
  factory $ProducerManagementEnrollStep1CopyWith(ProducerManagementEnrollStep1 value, $Res Function(ProducerManagementEnrollStep1) _then) = _$ProducerManagementEnrollStep1CopyWithImpl;
@useResult
$Res call({
 Organization organization, String searchQuery, List<ProducerAccount> searchResults, bool searching
});


$OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class _$ProducerManagementEnrollStep1CopyWithImpl<$Res>
    implements $ProducerManagementEnrollStep1CopyWith<$Res> {
  _$ProducerManagementEnrollStep1CopyWithImpl(this._self, this._then);

  final ProducerManagementEnrollStep1 _self;
  final $Res Function(ProducerManagementEnrollStep1) _then;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? searchQuery = null,Object? searchResults = null,Object? searching = null,}) {
  return _then(ProducerManagementEnrollStep1(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,searchResults: null == searchResults ? _self._searchResults : searchResults // ignore: cast_nullable_to_non_nullable
as List<ProducerAccount>,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ProducerManagementState
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


class ProducerManagementEnrollStep2 implements ProducerManagementState {
  const ProducerManagementEnrollStep2({required this.organization, required this.selectedProducer, this.actionInProgress = false, this.actionError});
  

 final  Organization organization;
 final  ProducerAccount selectedProducer;
@JsonKey() final  bool actionInProgress;
 final  String? actionError;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerManagementEnrollStep2CopyWith<ProducerManagementEnrollStep2> get copyWith => _$ProducerManagementEnrollStep2CopyWithImpl<ProducerManagementEnrollStep2>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementEnrollStep2&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.selectedProducer, selectedProducer) || other.selectedProducer == selectedProducer)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.actionError, actionError) || other.actionError == actionError));
}


@override
int get hashCode => Object.hash(runtimeType,organization,selectedProducer,actionInProgress,actionError);

@override
String toString() {
  return 'ProducerManagementState.enrollStep2(organization: $organization, selectedProducer: $selectedProducer, actionInProgress: $actionInProgress, actionError: $actionError)';
}


}

/// @nodoc
abstract mixin class $ProducerManagementEnrollStep2CopyWith<$Res> implements $ProducerManagementStateCopyWith<$Res> {
  factory $ProducerManagementEnrollStep2CopyWith(ProducerManagementEnrollStep2 value, $Res Function(ProducerManagementEnrollStep2) _then) = _$ProducerManagementEnrollStep2CopyWithImpl;
@useResult
$Res call({
 Organization organization, ProducerAccount selectedProducer, bool actionInProgress, String? actionError
});


$OrganizationCopyWith<$Res> get organization;$ProducerAccountCopyWith<$Res> get selectedProducer;

}
/// @nodoc
class _$ProducerManagementEnrollStep2CopyWithImpl<$Res>
    implements $ProducerManagementEnrollStep2CopyWith<$Res> {
  _$ProducerManagementEnrollStep2CopyWithImpl(this._self, this._then);

  final ProducerManagementEnrollStep2 _self;
  final $Res Function(ProducerManagementEnrollStep2) _then;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? selectedProducer = null,Object? actionInProgress = null,Object? actionError = freezed,}) {
  return _then(ProducerManagementEnrollStep2(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,selectedProducer: null == selectedProducer ? _self.selectedProducer : selectedProducer // ignore: cast_nullable_to_non_nullable
as ProducerAccount,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get organization {
  
  return $OrganizationCopyWith<$Res>(_self.organization, (value) {
    return _then(_self.copyWith(organization: value));
  });
}/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProducerAccountCopyWith<$Res> get selectedProducer {
  
  return $ProducerAccountCopyWith<$Res>(_self.selectedProducer, (value) {
    return _then(_self.copyWith(selectedProducer: value));
  });
}
}

/// @nodoc


class ProducerManagementEnrollNoAccountStep2 implements ProducerManagementState {
  const ProducerManagementEnrollNoAccountStep2({required this.organization, this.actionInProgress = false, this.actionError});
  

 final  Organization organization;
@JsonKey() final  bool actionInProgress;
 final  String? actionError;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerManagementEnrollNoAccountStep2CopyWith<ProducerManagementEnrollNoAccountStep2> get copyWith => _$ProducerManagementEnrollNoAccountStep2CopyWithImpl<ProducerManagementEnrollNoAccountStep2>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementEnrollNoAccountStep2&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.actionInProgress, actionInProgress) || other.actionInProgress == actionInProgress)&&(identical(other.actionError, actionError) || other.actionError == actionError));
}


@override
int get hashCode => Object.hash(runtimeType,organization,actionInProgress,actionError);

@override
String toString() {
  return 'ProducerManagementState.enrollNoAccountStep2(organization: $organization, actionInProgress: $actionInProgress, actionError: $actionError)';
}


}

/// @nodoc
abstract mixin class $ProducerManagementEnrollNoAccountStep2CopyWith<$Res> implements $ProducerManagementStateCopyWith<$Res> {
  factory $ProducerManagementEnrollNoAccountStep2CopyWith(ProducerManagementEnrollNoAccountStep2 value, $Res Function(ProducerManagementEnrollNoAccountStep2) _then) = _$ProducerManagementEnrollNoAccountStep2CopyWithImpl;
@useResult
$Res call({
 Organization organization, bool actionInProgress, String? actionError
});


$OrganizationCopyWith<$Res> get organization;

}
/// @nodoc
class _$ProducerManagementEnrollNoAccountStep2CopyWithImpl<$Res>
    implements $ProducerManagementEnrollNoAccountStep2CopyWith<$Res> {
  _$ProducerManagementEnrollNoAccountStep2CopyWithImpl(this._self, this._then);

  final ProducerManagementEnrollNoAccountStep2 _self;
  final $Res Function(ProducerManagementEnrollNoAccountStep2) _then;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? actionInProgress = null,Object? actionError = freezed,}) {
  return _then(ProducerManagementEnrollNoAccountStep2(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization,actionInProgress: null == actionInProgress ? _self.actionInProgress : actionInProgress // ignore: cast_nullable_to_non_nullable
as bool,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProducerManagementState
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


class ProducerManagementError implements ProducerManagementState {
  const ProducerManagementError(this.message);
  

 final  String message;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerManagementErrorCopyWith<ProducerManagementError> get copyWith => _$ProducerManagementErrorCopyWithImpl<ProducerManagementError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerManagementError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProducerManagementState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProducerManagementErrorCopyWith<$Res> implements $ProducerManagementStateCopyWith<$Res> {
  factory $ProducerManagementErrorCopyWith(ProducerManagementError value, $Res Function(ProducerManagementError) _then) = _$ProducerManagementErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProducerManagementErrorCopyWithImpl<$Res>
    implements $ProducerManagementErrorCopyWith<$Res> {
  _$ProducerManagementErrorCopyWithImpl(this._self, this._then);

  final ProducerManagementError _self;
  final $Res Function(ProducerManagementError) _then;

/// Create a copy of ProducerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProducerManagementError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
