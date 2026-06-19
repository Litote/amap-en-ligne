// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_slots_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimeSlotsEvent {

 Organization get currentOrg; String get deliveryId;
/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeSlotsEventCopyWith<TimeSlotsEvent> get copyWith => _$TimeSlotsEventCopyWithImpl<TimeSlotsEvent>(this as TimeSlotsEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsEvent&&(identical(other.currentOrg, currentOrg) || other.currentOrg == currentOrg)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId));
}


@override
int get hashCode => Object.hash(runtimeType,currentOrg,deliveryId);

@override
String toString() {
  return 'TimeSlotsEvent(currentOrg: $currentOrg, deliveryId: $deliveryId)';
}


}

/// @nodoc
abstract mixin class $TimeSlotsEventCopyWith<$Res>  {
  factory $TimeSlotsEventCopyWith(TimeSlotsEvent value, $Res Function(TimeSlotsEvent) _then) = _$TimeSlotsEventCopyWithImpl;
@useResult
$Res call({
 Organization currentOrg, String deliveryId
});


$OrganizationCopyWith<$Res> get currentOrg;

}
/// @nodoc
class _$TimeSlotsEventCopyWithImpl<$Res>
    implements $TimeSlotsEventCopyWith<$Res> {
  _$TimeSlotsEventCopyWithImpl(this._self, this._then);

  final TimeSlotsEvent _self;
  final $Res Function(TimeSlotsEvent) _then;

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentOrg = null,Object? deliveryId = null,}) {
  return _then(_self.copyWith(
currentOrg: null == currentOrg ? _self.currentOrg : currentOrg // ignore: cast_nullable_to_non_nullable
as Organization,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get currentOrg {
  
  return $OrganizationCopyWith<$Res>(_self.currentOrg, (value) {
    return _then(_self.copyWith(currentOrg: value));
  });
}
}


/// Adds pattern-matching-related methods to [TimeSlotsEvent].
extension TimeSlotsEventPatterns on TimeSlotsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TimeSlotsDeleteRequested value)?  deleteRequested,TResult Function( SlotCancelRequested value)?  slotCancelRequested,TResult Function( SlotDeleteRequested value)?  slotDeleteRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TimeSlotsDeleteRequested() when deleteRequested != null:
return deleteRequested(_that);case SlotCancelRequested() when slotCancelRequested != null:
return slotCancelRequested(_that);case SlotDeleteRequested() when slotDeleteRequested != null:
return slotDeleteRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TimeSlotsDeleteRequested value)  deleteRequested,required TResult Function( SlotCancelRequested value)  slotCancelRequested,required TResult Function( SlotDeleteRequested value)  slotDeleteRequested,}){
final _that = this;
switch (_that) {
case TimeSlotsDeleteRequested():
return deleteRequested(_that);case SlotCancelRequested():
return slotCancelRequested(_that);case SlotDeleteRequested():
return slotDeleteRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TimeSlotsDeleteRequested value)?  deleteRequested,TResult? Function( SlotCancelRequested value)?  slotCancelRequested,TResult? Function( SlotDeleteRequested value)?  slotDeleteRequested,}){
final _that = this;
switch (_that) {
case TimeSlotsDeleteRequested() when deleteRequested != null:
return deleteRequested(_that);case SlotCancelRequested() when slotCancelRequested != null:
return slotCancelRequested(_that);case SlotDeleteRequested() when slotDeleteRequested != null:
return slotDeleteRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Organization currentOrg,  String deliveryId)?  deleteRequested,TResult Function( Organization currentOrg,  String deliveryId,  String contractId,  MemberSlot slot)?  slotCancelRequested,TResult Function( Organization currentOrg,  String deliveryId,  String contractId,  MemberSlot slot)?  slotDeleteRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TimeSlotsDeleteRequested() when deleteRequested != null:
return deleteRequested(_that.currentOrg,_that.deliveryId);case SlotCancelRequested() when slotCancelRequested != null:
return slotCancelRequested(_that.currentOrg,_that.deliveryId,_that.contractId,_that.slot);case SlotDeleteRequested() when slotDeleteRequested != null:
return slotDeleteRequested(_that.currentOrg,_that.deliveryId,_that.contractId,_that.slot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Organization currentOrg,  String deliveryId)  deleteRequested,required TResult Function( Organization currentOrg,  String deliveryId,  String contractId,  MemberSlot slot)  slotCancelRequested,required TResult Function( Organization currentOrg,  String deliveryId,  String contractId,  MemberSlot slot)  slotDeleteRequested,}) {final _that = this;
switch (_that) {
case TimeSlotsDeleteRequested():
return deleteRequested(_that.currentOrg,_that.deliveryId);case SlotCancelRequested():
return slotCancelRequested(_that.currentOrg,_that.deliveryId,_that.contractId,_that.slot);case SlotDeleteRequested():
return slotDeleteRequested(_that.currentOrg,_that.deliveryId,_that.contractId,_that.slot);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Organization currentOrg,  String deliveryId)?  deleteRequested,TResult? Function( Organization currentOrg,  String deliveryId,  String contractId,  MemberSlot slot)?  slotCancelRequested,TResult? Function( Organization currentOrg,  String deliveryId,  String contractId,  MemberSlot slot)?  slotDeleteRequested,}) {final _that = this;
switch (_that) {
case TimeSlotsDeleteRequested() when deleteRequested != null:
return deleteRequested(_that.currentOrg,_that.deliveryId);case SlotCancelRequested() when slotCancelRequested != null:
return slotCancelRequested(_that.currentOrg,_that.deliveryId,_that.contractId,_that.slot);case SlotDeleteRequested() when slotDeleteRequested != null:
return slotDeleteRequested(_that.currentOrg,_that.deliveryId,_that.contractId,_that.slot);case _:
  return null;

}
}

}

/// @nodoc


class TimeSlotsDeleteRequested implements TimeSlotsEvent {
  const TimeSlotsDeleteRequested({required this.currentOrg, required this.deliveryId});
  

@override final  Organization currentOrg;
@override final  String deliveryId;

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeSlotsDeleteRequestedCopyWith<TimeSlotsDeleteRequested> get copyWith => _$TimeSlotsDeleteRequestedCopyWithImpl<TimeSlotsDeleteRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsDeleteRequested&&(identical(other.currentOrg, currentOrg) || other.currentOrg == currentOrg)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId));
}


@override
int get hashCode => Object.hash(runtimeType,currentOrg,deliveryId);

@override
String toString() {
  return 'TimeSlotsEvent.deleteRequested(currentOrg: $currentOrg, deliveryId: $deliveryId)';
}


}

/// @nodoc
abstract mixin class $TimeSlotsDeleteRequestedCopyWith<$Res> implements $TimeSlotsEventCopyWith<$Res> {
  factory $TimeSlotsDeleteRequestedCopyWith(TimeSlotsDeleteRequested value, $Res Function(TimeSlotsDeleteRequested) _then) = _$TimeSlotsDeleteRequestedCopyWithImpl;
@override @useResult
$Res call({
 Organization currentOrg, String deliveryId
});


@override $OrganizationCopyWith<$Res> get currentOrg;

}
/// @nodoc
class _$TimeSlotsDeleteRequestedCopyWithImpl<$Res>
    implements $TimeSlotsDeleteRequestedCopyWith<$Res> {
  _$TimeSlotsDeleteRequestedCopyWithImpl(this._self, this._then);

  final TimeSlotsDeleteRequested _self;
  final $Res Function(TimeSlotsDeleteRequested) _then;

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentOrg = null,Object? deliveryId = null,}) {
  return _then(TimeSlotsDeleteRequested(
currentOrg: null == currentOrg ? _self.currentOrg : currentOrg // ignore: cast_nullable_to_non_nullable
as Organization,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get currentOrg {
  
  return $OrganizationCopyWith<$Res>(_self.currentOrg, (value) {
    return _then(_self.copyWith(currentOrg: value));
  });
}
}

/// @nodoc


class SlotCancelRequested implements TimeSlotsEvent {
  const SlotCancelRequested({required this.currentOrg, required this.deliveryId, required this.contractId, required this.slot});
  

@override final  Organization currentOrg;
@override final  String deliveryId;
 final  String contractId;
 final  MemberSlot slot;

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotCancelRequestedCopyWith<SlotCancelRequested> get copyWith => _$SlotCancelRequestedCopyWithImpl<SlotCancelRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotCancelRequested&&(identical(other.currentOrg, currentOrg) || other.currentOrg == currentOrg)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.slot, slot) || other.slot == slot));
}


@override
int get hashCode => Object.hash(runtimeType,currentOrg,deliveryId,contractId,slot);

@override
String toString() {
  return 'TimeSlotsEvent.slotCancelRequested(currentOrg: $currentOrg, deliveryId: $deliveryId, contractId: $contractId, slot: $slot)';
}


}

/// @nodoc
abstract mixin class $SlotCancelRequestedCopyWith<$Res> implements $TimeSlotsEventCopyWith<$Res> {
  factory $SlotCancelRequestedCopyWith(SlotCancelRequested value, $Res Function(SlotCancelRequested) _then) = _$SlotCancelRequestedCopyWithImpl;
@override @useResult
$Res call({
 Organization currentOrg, String deliveryId, String contractId, MemberSlot slot
});


@override $OrganizationCopyWith<$Res> get currentOrg;$MemberSlotCopyWith<$Res> get slot;

}
/// @nodoc
class _$SlotCancelRequestedCopyWithImpl<$Res>
    implements $SlotCancelRequestedCopyWith<$Res> {
  _$SlotCancelRequestedCopyWithImpl(this._self, this._then);

  final SlotCancelRequested _self;
  final $Res Function(SlotCancelRequested) _then;

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentOrg = null,Object? deliveryId = null,Object? contractId = null,Object? slot = null,}) {
  return _then(SlotCancelRequested(
currentOrg: null == currentOrg ? _self.currentOrg : currentOrg // ignore: cast_nullable_to_non_nullable
as Organization,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as MemberSlot,
  ));
}

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get currentOrg {
  
  return $OrganizationCopyWith<$Res>(_self.currentOrg, (value) {
    return _then(_self.copyWith(currentOrg: value));
  });
}/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberSlotCopyWith<$Res> get slot {
  
  return $MemberSlotCopyWith<$Res>(_self.slot, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}

/// @nodoc


class SlotDeleteRequested implements TimeSlotsEvent {
  const SlotDeleteRequested({required this.currentOrg, required this.deliveryId, required this.contractId, required this.slot});
  

@override final  Organization currentOrg;
@override final  String deliveryId;
 final  String contractId;
 final  MemberSlot slot;

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotDeleteRequestedCopyWith<SlotDeleteRequested> get copyWith => _$SlotDeleteRequestedCopyWithImpl<SlotDeleteRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotDeleteRequested&&(identical(other.currentOrg, currentOrg) || other.currentOrg == currentOrg)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.slot, slot) || other.slot == slot));
}


@override
int get hashCode => Object.hash(runtimeType,currentOrg,deliveryId,contractId,slot);

@override
String toString() {
  return 'TimeSlotsEvent.slotDeleteRequested(currentOrg: $currentOrg, deliveryId: $deliveryId, contractId: $contractId, slot: $slot)';
}


}

/// @nodoc
abstract mixin class $SlotDeleteRequestedCopyWith<$Res> implements $TimeSlotsEventCopyWith<$Res> {
  factory $SlotDeleteRequestedCopyWith(SlotDeleteRequested value, $Res Function(SlotDeleteRequested) _then) = _$SlotDeleteRequestedCopyWithImpl;
@override @useResult
$Res call({
 Organization currentOrg, String deliveryId, String contractId, MemberSlot slot
});


@override $OrganizationCopyWith<$Res> get currentOrg;$MemberSlotCopyWith<$Res> get slot;

}
/// @nodoc
class _$SlotDeleteRequestedCopyWithImpl<$Res>
    implements $SlotDeleteRequestedCopyWith<$Res> {
  _$SlotDeleteRequestedCopyWithImpl(this._self, this._then);

  final SlotDeleteRequested _self;
  final $Res Function(SlotDeleteRequested) _then;

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentOrg = null,Object? deliveryId = null,Object? contractId = null,Object? slot = null,}) {
  return _then(SlotDeleteRequested(
currentOrg: null == currentOrg ? _self.currentOrg : currentOrg // ignore: cast_nullable_to_non_nullable
as Organization,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as MemberSlot,
  ));
}

/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res> get currentOrg {
  
  return $OrganizationCopyWith<$Res>(_self.currentOrg, (value) {
    return _then(_self.copyWith(currentOrg: value));
  });
}/// Create a copy of TimeSlotsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberSlotCopyWith<$Res> get slot {
  
  return $MemberSlotCopyWith<$Res>(_self.slot, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}

/// @nodoc
mixin _$TimeSlotsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimeSlotsState()';
}


}

/// @nodoc
class $TimeSlotsStateCopyWith<$Res>  {
$TimeSlotsStateCopyWith(TimeSlotsState _, $Res Function(TimeSlotsState) __);
}


/// Adds pattern-matching-related methods to [TimeSlotsState].
extension TimeSlotsStatePatterns on TimeSlotsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TimeSlotsIdle value)?  idle,TResult Function( TimeSlotsDeleting value)?  deleting,TResult Function( TimeSlotsDeleted value)?  deleted,TResult Function( TimeSlotsSlotMutating value)?  slotMutating,TResult Function( TimeSlotsSlotMutated value)?  slotMutated,TResult Function( TimeSlotsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TimeSlotsIdle() when idle != null:
return idle(_that);case TimeSlotsDeleting() when deleting != null:
return deleting(_that);case TimeSlotsDeleted() when deleted != null:
return deleted(_that);case TimeSlotsSlotMutating() when slotMutating != null:
return slotMutating(_that);case TimeSlotsSlotMutated() when slotMutated != null:
return slotMutated(_that);case TimeSlotsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TimeSlotsIdle value)  idle,required TResult Function( TimeSlotsDeleting value)  deleting,required TResult Function( TimeSlotsDeleted value)  deleted,required TResult Function( TimeSlotsSlotMutating value)  slotMutating,required TResult Function( TimeSlotsSlotMutated value)  slotMutated,required TResult Function( TimeSlotsError value)  error,}){
final _that = this;
switch (_that) {
case TimeSlotsIdle():
return idle(_that);case TimeSlotsDeleting():
return deleting(_that);case TimeSlotsDeleted():
return deleted(_that);case TimeSlotsSlotMutating():
return slotMutating(_that);case TimeSlotsSlotMutated():
return slotMutated(_that);case TimeSlotsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TimeSlotsIdle value)?  idle,TResult? Function( TimeSlotsDeleting value)?  deleting,TResult? Function( TimeSlotsDeleted value)?  deleted,TResult? Function( TimeSlotsSlotMutating value)?  slotMutating,TResult? Function( TimeSlotsSlotMutated value)?  slotMutated,TResult? Function( TimeSlotsError value)?  error,}){
final _that = this;
switch (_that) {
case TimeSlotsIdle() when idle != null:
return idle(_that);case TimeSlotsDeleting() when deleting != null:
return deleting(_that);case TimeSlotsDeleted() when deleted != null:
return deleted(_that);case TimeSlotsSlotMutating() when slotMutating != null:
return slotMutating(_that);case TimeSlotsSlotMutated() when slotMutated != null:
return slotMutated(_that);case TimeSlotsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  deleting,TResult Function()?  deleted,TResult Function()?  slotMutating,TResult Function()?  slotMutated,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TimeSlotsIdle() when idle != null:
return idle();case TimeSlotsDeleting() when deleting != null:
return deleting();case TimeSlotsDeleted() when deleted != null:
return deleted();case TimeSlotsSlotMutating() when slotMutating != null:
return slotMutating();case TimeSlotsSlotMutated() when slotMutated != null:
return slotMutated();case TimeSlotsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  deleting,required TResult Function()  deleted,required TResult Function()  slotMutating,required TResult Function()  slotMutated,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case TimeSlotsIdle():
return idle();case TimeSlotsDeleting():
return deleting();case TimeSlotsDeleted():
return deleted();case TimeSlotsSlotMutating():
return slotMutating();case TimeSlotsSlotMutated():
return slotMutated();case TimeSlotsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  deleting,TResult? Function()?  deleted,TResult? Function()?  slotMutating,TResult? Function()?  slotMutated,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case TimeSlotsIdle() when idle != null:
return idle();case TimeSlotsDeleting() when deleting != null:
return deleting();case TimeSlotsDeleted() when deleted != null:
return deleted();case TimeSlotsSlotMutating() when slotMutating != null:
return slotMutating();case TimeSlotsSlotMutated() when slotMutated != null:
return slotMutated();case TimeSlotsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class TimeSlotsIdle implements TimeSlotsState {
  const TimeSlotsIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimeSlotsState.idle()';
}


}




/// @nodoc


class TimeSlotsDeleting implements TimeSlotsState {
  const TimeSlotsDeleting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsDeleting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimeSlotsState.deleting()';
}


}




/// @nodoc


class TimeSlotsDeleted implements TimeSlotsState {
  const TimeSlotsDeleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsDeleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimeSlotsState.deleted()';
}


}




/// @nodoc


class TimeSlotsSlotMutating implements TimeSlotsState {
  const TimeSlotsSlotMutating();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsSlotMutating);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimeSlotsState.slotMutating()';
}


}




/// @nodoc


class TimeSlotsSlotMutated implements TimeSlotsState {
  const TimeSlotsSlotMutated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsSlotMutated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TimeSlotsState.slotMutated()';
}


}




/// @nodoc


class TimeSlotsError implements TimeSlotsState {
  const TimeSlotsError({required this.message});
  

 final  String message;

/// Create a copy of TimeSlotsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeSlotsErrorCopyWith<TimeSlotsError> get copyWith => _$TimeSlotsErrorCopyWithImpl<TimeSlotsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeSlotsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TimeSlotsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $TimeSlotsErrorCopyWith<$Res> implements $TimeSlotsStateCopyWith<$Res> {
  factory $TimeSlotsErrorCopyWith(TimeSlotsError value, $Res Function(TimeSlotsError) _then) = _$TimeSlotsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$TimeSlotsErrorCopyWithImpl<$Res>
    implements $TimeSlotsErrorCopyWith<$Res> {
  _$TimeSlotsErrorCopyWithImpl(this._self, this._then);

  final TimeSlotsError _self;
  final $Res Function(TimeSlotsError) _then;

/// Create a copy of TimeSlotsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(TimeSlotsError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
