// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_sheets_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AttendanceSheetsEvent {

 String get deliveryId;
/// Create a copy of AttendanceSheetsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceSheetsEventCopyWith<AttendanceSheetsEvent> get copyWith => _$AttendanceSheetsEventCopyWithImpl<AttendanceSheetsEvent>(this as AttendanceSheetsEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceSheetsEvent&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId));
}


@override
int get hashCode => Object.hash(runtimeType,deliveryId);

@override
String toString() {
  return 'AttendanceSheetsEvent(deliveryId: $deliveryId)';
}


}

/// @nodoc
abstract mixin class $AttendanceSheetsEventCopyWith<$Res>  {
  factory $AttendanceSheetsEventCopyWith(AttendanceSheetsEvent value, $Res Function(AttendanceSheetsEvent) _then) = _$AttendanceSheetsEventCopyWithImpl;
@useResult
$Res call({
 String deliveryId
});




}
/// @nodoc
class _$AttendanceSheetsEventCopyWithImpl<$Res>
    implements $AttendanceSheetsEventCopyWith<$Res> {
  _$AttendanceSheetsEventCopyWithImpl(this._self, this._then);

  final AttendanceSheetsEvent _self;
  final $Res Function(AttendanceSheetsEvent) _then;

/// Create a copy of AttendanceSheetsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deliveryId = null,}) {
  return _then(_self.copyWith(
deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceSheetsEvent].
extension AttendanceSheetsEventPatterns on AttendanceSheetsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AttendanceSheetsDeliverySelected value)?  deliverySelected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AttendanceSheetsDeliverySelected() when deliverySelected != null:
return deliverySelected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AttendanceSheetsDeliverySelected value)  deliverySelected,}){
final _that = this;
switch (_that) {
case AttendanceSheetsDeliverySelected():
return deliverySelected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AttendanceSheetsDeliverySelected value)?  deliverySelected,}){
final _that = this;
switch (_that) {
case AttendanceSheetsDeliverySelected() when deliverySelected != null:
return deliverySelected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String deliveryId)?  deliverySelected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AttendanceSheetsDeliverySelected() when deliverySelected != null:
return deliverySelected(_that.deliveryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String deliveryId)  deliverySelected,}) {final _that = this;
switch (_that) {
case AttendanceSheetsDeliverySelected():
return deliverySelected(_that.deliveryId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String deliveryId)?  deliverySelected,}) {final _that = this;
switch (_that) {
case AttendanceSheetsDeliverySelected() when deliverySelected != null:
return deliverySelected(_that.deliveryId);case _:
  return null;

}
}

}

/// @nodoc


class AttendanceSheetsDeliverySelected implements AttendanceSheetsEvent {
  const AttendanceSheetsDeliverySelected({required this.deliveryId});
  

@override final  String deliveryId;

/// Create a copy of AttendanceSheetsEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceSheetsDeliverySelectedCopyWith<AttendanceSheetsDeliverySelected> get copyWith => _$AttendanceSheetsDeliverySelectedCopyWithImpl<AttendanceSheetsDeliverySelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceSheetsDeliverySelected&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId));
}


@override
int get hashCode => Object.hash(runtimeType,deliveryId);

@override
String toString() {
  return 'AttendanceSheetsEvent.deliverySelected(deliveryId: $deliveryId)';
}


}

/// @nodoc
abstract mixin class $AttendanceSheetsDeliverySelectedCopyWith<$Res> implements $AttendanceSheetsEventCopyWith<$Res> {
  factory $AttendanceSheetsDeliverySelectedCopyWith(AttendanceSheetsDeliverySelected value, $Res Function(AttendanceSheetsDeliverySelected) _then) = _$AttendanceSheetsDeliverySelectedCopyWithImpl;
@override @useResult
$Res call({
 String deliveryId
});




}
/// @nodoc
class _$AttendanceSheetsDeliverySelectedCopyWithImpl<$Res>
    implements $AttendanceSheetsDeliverySelectedCopyWith<$Res> {
  _$AttendanceSheetsDeliverySelectedCopyWithImpl(this._self, this._then);

  final AttendanceSheetsDeliverySelected _self;
  final $Res Function(AttendanceSheetsDeliverySelected) _then;

/// Create a copy of AttendanceSheetsEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deliveryId = null,}) {
  return _then(AttendanceSheetsDeliverySelected(
deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AttendanceSheetsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceSheetsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AttendanceSheetsState()';
}


}

/// @nodoc
class $AttendanceSheetsStateCopyWith<$Res>  {
$AttendanceSheetsStateCopyWith(AttendanceSheetsState _, $Res Function(AttendanceSheetsState) __);
}


/// Adds pattern-matching-related methods to [AttendanceSheetsState].
extension AttendanceSheetsStatePatterns on AttendanceSheetsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AttendanceSheetsIdle value)?  idle,TResult Function( AttendanceSheetsDeliveryShown value)?  deliverySelected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AttendanceSheetsIdle() when idle != null:
return idle(_that);case AttendanceSheetsDeliveryShown() when deliverySelected != null:
return deliverySelected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AttendanceSheetsIdle value)  idle,required TResult Function( AttendanceSheetsDeliveryShown value)  deliverySelected,}){
final _that = this;
switch (_that) {
case AttendanceSheetsIdle():
return idle(_that);case AttendanceSheetsDeliveryShown():
return deliverySelected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AttendanceSheetsIdle value)?  idle,TResult? Function( AttendanceSheetsDeliveryShown value)?  deliverySelected,}){
final _that = this;
switch (_that) {
case AttendanceSheetsIdle() when idle != null:
return idle(_that);case AttendanceSheetsDeliveryShown() when deliverySelected != null:
return deliverySelected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( String deliveryId,  Delivery delivery)?  deliverySelected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AttendanceSheetsIdle() when idle != null:
return idle();case AttendanceSheetsDeliveryShown() when deliverySelected != null:
return deliverySelected(_that.deliveryId,_that.delivery);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( String deliveryId,  Delivery delivery)  deliverySelected,}) {final _that = this;
switch (_that) {
case AttendanceSheetsIdle():
return idle();case AttendanceSheetsDeliveryShown():
return deliverySelected(_that.deliveryId,_that.delivery);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( String deliveryId,  Delivery delivery)?  deliverySelected,}) {final _that = this;
switch (_that) {
case AttendanceSheetsIdle() when idle != null:
return idle();case AttendanceSheetsDeliveryShown() when deliverySelected != null:
return deliverySelected(_that.deliveryId,_that.delivery);case _:
  return null;

}
}

}

/// @nodoc


class AttendanceSheetsIdle implements AttendanceSheetsState {
  const AttendanceSheetsIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceSheetsIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AttendanceSheetsState.idle()';
}


}




/// @nodoc


class AttendanceSheetsDeliveryShown implements AttendanceSheetsState {
  const AttendanceSheetsDeliveryShown({required this.deliveryId, required this.delivery});
  

 final  String deliveryId;
 final  Delivery delivery;

/// Create a copy of AttendanceSheetsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceSheetsDeliveryShownCopyWith<AttendanceSheetsDeliveryShown> get copyWith => _$AttendanceSheetsDeliveryShownCopyWithImpl<AttendanceSheetsDeliveryShown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceSheetsDeliveryShown&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.delivery, delivery) || other.delivery == delivery));
}


@override
int get hashCode => Object.hash(runtimeType,deliveryId,delivery);

@override
String toString() {
  return 'AttendanceSheetsState.deliverySelected(deliveryId: $deliveryId, delivery: $delivery)';
}


}

/// @nodoc
abstract mixin class $AttendanceSheetsDeliveryShownCopyWith<$Res> implements $AttendanceSheetsStateCopyWith<$Res> {
  factory $AttendanceSheetsDeliveryShownCopyWith(AttendanceSheetsDeliveryShown value, $Res Function(AttendanceSheetsDeliveryShown) _then) = _$AttendanceSheetsDeliveryShownCopyWithImpl;
@useResult
$Res call({
 String deliveryId, Delivery delivery
});


$DeliveryCopyWith<$Res> get delivery;

}
/// @nodoc
class _$AttendanceSheetsDeliveryShownCopyWithImpl<$Res>
    implements $AttendanceSheetsDeliveryShownCopyWith<$Res> {
  _$AttendanceSheetsDeliveryShownCopyWithImpl(this._self, this._then);

  final AttendanceSheetsDeliveryShown _self;
  final $Res Function(AttendanceSheetsDeliveryShown) _then;

/// Create a copy of AttendanceSheetsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deliveryId = null,Object? delivery = null,}) {
  return _then(AttendanceSheetsDeliveryShown(
deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,delivery: null == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as Delivery,
  ));
}

/// Create a copy of AttendanceSheetsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryCopyWith<$Res> get delivery {
  
  return $DeliveryCopyWith<$Res>(_self.delivery, (value) {
    return _then(_self.copyWith(delivery: value));
  });
}
}

// dart format on
