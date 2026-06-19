// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_requests_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProducerRequestsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProducerRequestsEvent()';
}


}

/// @nodoc
class $ProducerRequestsEventCopyWith<$Res>  {
$ProducerRequestsEventCopyWith(ProducerRequestsEvent _, $Res Function(ProducerRequestsEvent) __);
}


/// Adds pattern-matching-related methods to [ProducerRequestsEvent].
extension ProducerRequestsEventPatterns on ProducerRequestsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProducerRequestsLoadRequested value)?  loadRequested,TResult Function( ProducerRequestsApproveRequested value)?  approveRequested,TResult Function( ProducerRequestsRejectRequested value)?  rejectRequested,TResult Function( ProducerRequestsResendRequested value)?  resendRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProducerRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that);case ProducerRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that);case ProducerRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case ProducerRequestsResendRequested() when resendRequested != null:
return resendRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProducerRequestsLoadRequested value)  loadRequested,required TResult Function( ProducerRequestsApproveRequested value)  approveRequested,required TResult Function( ProducerRequestsRejectRequested value)  rejectRequested,required TResult Function( ProducerRequestsResendRequested value)  resendRequested,}){
final _that = this;
switch (_that) {
case ProducerRequestsLoadRequested():
return loadRequested(_that);case ProducerRequestsApproveRequested():
return approveRequested(_that);case ProducerRequestsRejectRequested():
return rejectRequested(_that);case ProducerRequestsResendRequested():
return resendRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProducerRequestsLoadRequested value)?  loadRequested,TResult? Function( ProducerRequestsApproveRequested value)?  approveRequested,TResult? Function( ProducerRequestsRejectRequested value)?  rejectRequested,TResult? Function( ProducerRequestsResendRequested value)?  resendRequested,}){
final _that = this;
switch (_that) {
case ProducerRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that);case ProducerRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that);case ProducerRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case ProducerRequestsResendRequested() when resendRequested != null:
return resendRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ProducerRequestStatus? statusFilter)?  loadRequested,TResult Function( AdminProducerRequest request)?  approveRequested,TResult Function( AdminProducerRequest request,  String? reviewComment)?  rejectRequested,TResult Function( AdminProducerRequest request)?  resendRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProducerRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that.statusFilter);case ProducerRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that.request);case ProducerRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that.request,_that.reviewComment);case ProducerRequestsResendRequested() when resendRequested != null:
return resendRequested(_that.request);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ProducerRequestStatus? statusFilter)  loadRequested,required TResult Function( AdminProducerRequest request)  approveRequested,required TResult Function( AdminProducerRequest request,  String? reviewComment)  rejectRequested,required TResult Function( AdminProducerRequest request)  resendRequested,}) {final _that = this;
switch (_that) {
case ProducerRequestsLoadRequested():
return loadRequested(_that.statusFilter);case ProducerRequestsApproveRequested():
return approveRequested(_that.request);case ProducerRequestsRejectRequested():
return rejectRequested(_that.request,_that.reviewComment);case ProducerRequestsResendRequested():
return resendRequested(_that.request);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ProducerRequestStatus? statusFilter)?  loadRequested,TResult? Function( AdminProducerRequest request)?  approveRequested,TResult? Function( AdminProducerRequest request,  String? reviewComment)?  rejectRequested,TResult? Function( AdminProducerRequest request)?  resendRequested,}) {final _that = this;
switch (_that) {
case ProducerRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that.statusFilter);case ProducerRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that.request);case ProducerRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that.request,_that.reviewComment);case ProducerRequestsResendRequested() when resendRequested != null:
return resendRequested(_that.request);case _:
  return null;

}
}

}

/// @nodoc


class ProducerRequestsLoadRequested implements ProducerRequestsEvent {
  const ProducerRequestsLoadRequested({this.statusFilter});
  

 final  ProducerRequestStatus? statusFilter;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestsLoadRequestedCopyWith<ProducerRequestsLoadRequested> get copyWith => _$ProducerRequestsLoadRequestedCopyWithImpl<ProducerRequestsLoadRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsLoadRequested&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter));
}


@override
int get hashCode => Object.hash(runtimeType,statusFilter);

@override
String toString() {
  return 'ProducerRequestsEvent.loadRequested(statusFilter: $statusFilter)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestsLoadRequestedCopyWith<$Res> implements $ProducerRequestsEventCopyWith<$Res> {
  factory $ProducerRequestsLoadRequestedCopyWith(ProducerRequestsLoadRequested value, $Res Function(ProducerRequestsLoadRequested) _then) = _$ProducerRequestsLoadRequestedCopyWithImpl;
@useResult
$Res call({
 ProducerRequestStatus? statusFilter
});




}
/// @nodoc
class _$ProducerRequestsLoadRequestedCopyWithImpl<$Res>
    implements $ProducerRequestsLoadRequestedCopyWith<$Res> {
  _$ProducerRequestsLoadRequestedCopyWithImpl(this._self, this._then);

  final ProducerRequestsLoadRequested _self;
  final $Res Function(ProducerRequestsLoadRequested) _then;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusFilter = freezed,}) {
  return _then(ProducerRequestsLoadRequested(
statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as ProducerRequestStatus?,
  ));
}


}

/// @nodoc


class ProducerRequestsApproveRequested implements ProducerRequestsEvent {
  const ProducerRequestsApproveRequested({required this.request});
  

 final  AdminProducerRequest request;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestsApproveRequestedCopyWith<ProducerRequestsApproveRequested> get copyWith => _$ProducerRequestsApproveRequestedCopyWithImpl<ProducerRequestsApproveRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsApproveRequested&&(identical(other.request, request) || other.request == request));
}


@override
int get hashCode => Object.hash(runtimeType,request);

@override
String toString() {
  return 'ProducerRequestsEvent.approveRequested(request: $request)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestsApproveRequestedCopyWith<$Res> implements $ProducerRequestsEventCopyWith<$Res> {
  factory $ProducerRequestsApproveRequestedCopyWith(ProducerRequestsApproveRequested value, $Res Function(ProducerRequestsApproveRequested) _then) = _$ProducerRequestsApproveRequestedCopyWithImpl;
@useResult
$Res call({
 AdminProducerRequest request
});


$AdminProducerRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$ProducerRequestsApproveRequestedCopyWithImpl<$Res>
    implements $ProducerRequestsApproveRequestedCopyWith<$Res> {
  _$ProducerRequestsApproveRequestedCopyWithImpl(this._self, this._then);

  final ProducerRequestsApproveRequested _self;
  final $Res Function(ProducerRequestsApproveRequested) _then;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(ProducerRequestsApproveRequested(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminProducerRequest,
  ));
}

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminProducerRequestCopyWith<$Res> get request {
  
  return $AdminProducerRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

/// @nodoc


class ProducerRequestsRejectRequested implements ProducerRequestsEvent {
  const ProducerRequestsRejectRequested({required this.request, this.reviewComment});
  

 final  AdminProducerRequest request;
 final  String? reviewComment;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestsRejectRequestedCopyWith<ProducerRequestsRejectRequested> get copyWith => _$ProducerRequestsRejectRequestedCopyWithImpl<ProducerRequestsRejectRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsRejectRequested&&(identical(other.request, request) || other.request == request)&&(identical(other.reviewComment, reviewComment) || other.reviewComment == reviewComment));
}


@override
int get hashCode => Object.hash(runtimeType,request,reviewComment);

@override
String toString() {
  return 'ProducerRequestsEvent.rejectRequested(request: $request, reviewComment: $reviewComment)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestsRejectRequestedCopyWith<$Res> implements $ProducerRequestsEventCopyWith<$Res> {
  factory $ProducerRequestsRejectRequestedCopyWith(ProducerRequestsRejectRequested value, $Res Function(ProducerRequestsRejectRequested) _then) = _$ProducerRequestsRejectRequestedCopyWithImpl;
@useResult
$Res call({
 AdminProducerRequest request, String? reviewComment
});


$AdminProducerRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$ProducerRequestsRejectRequestedCopyWithImpl<$Res>
    implements $ProducerRequestsRejectRequestedCopyWith<$Res> {
  _$ProducerRequestsRejectRequestedCopyWithImpl(this._self, this._then);

  final ProducerRequestsRejectRequested _self;
  final $Res Function(ProducerRequestsRejectRequested) _then;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,Object? reviewComment = freezed,}) {
  return _then(ProducerRequestsRejectRequested(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminProducerRequest,reviewComment: freezed == reviewComment ? _self.reviewComment : reviewComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminProducerRequestCopyWith<$Res> get request {
  
  return $AdminProducerRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

/// @nodoc


class ProducerRequestsResendRequested implements ProducerRequestsEvent {
  const ProducerRequestsResendRequested({required this.request});
  

 final  AdminProducerRequest request;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestsResendRequestedCopyWith<ProducerRequestsResendRequested> get copyWith => _$ProducerRequestsResendRequestedCopyWithImpl<ProducerRequestsResendRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestsResendRequested&&(identical(other.request, request) || other.request == request));
}


@override
int get hashCode => Object.hash(runtimeType,request);

@override
String toString() {
  return 'ProducerRequestsEvent.resendRequested(request: $request)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestsResendRequestedCopyWith<$Res> implements $ProducerRequestsEventCopyWith<$Res> {
  factory $ProducerRequestsResendRequestedCopyWith(ProducerRequestsResendRequested value, $Res Function(ProducerRequestsResendRequested) _then) = _$ProducerRequestsResendRequestedCopyWithImpl;
@useResult
$Res call({
 AdminProducerRequest request
});


$AdminProducerRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$ProducerRequestsResendRequestedCopyWithImpl<$Res>
    implements $ProducerRequestsResendRequestedCopyWith<$Res> {
  _$ProducerRequestsResendRequestedCopyWithImpl(this._self, this._then);

  final ProducerRequestsResendRequested _self;
  final $Res Function(ProducerRequestsResendRequested) _then;

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(ProducerRequestsResendRequested(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminProducerRequest,
  ));
}

/// Create a copy of ProducerRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminProducerRequestCopyWith<$Res> get request {
  
  return $AdminProducerRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

// dart format on
