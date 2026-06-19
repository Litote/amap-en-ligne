// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_requests_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdminRequestsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AdminRequestsEvent()';
}


}

/// @nodoc
class $AdminRequestsEventCopyWith<$Res>  {
$AdminRequestsEventCopyWith(AdminRequestsEvent _, $Res Function(AdminRequestsEvent) __);
}


/// Adds pattern-matching-related methods to [AdminRequestsEvent].
extension AdminRequestsEventPatterns on AdminRequestsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AdminRequestsLoadRequested value)?  loadRequested,TResult Function( AdminRequestsOrganizationTypeFilterChanged value)?  organizationTypeFilterChanged,TResult Function( AdminRequestsApproveRequested value)?  approveRequested,TResult Function( AdminRequestsRejectRequested value)?  rejectRequested,TResult Function( AdminRequestsResendRequested value)?  resendRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AdminRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that);case AdminRequestsOrganizationTypeFilterChanged() when organizationTypeFilterChanged != null:
return organizationTypeFilterChanged(_that);case AdminRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that);case AdminRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case AdminRequestsResendRequested() when resendRequested != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AdminRequestsLoadRequested value)  loadRequested,required TResult Function( AdminRequestsOrganizationTypeFilterChanged value)  organizationTypeFilterChanged,required TResult Function( AdminRequestsApproveRequested value)  approveRequested,required TResult Function( AdminRequestsRejectRequested value)  rejectRequested,required TResult Function( AdminRequestsResendRequested value)  resendRequested,}){
final _that = this;
switch (_that) {
case AdminRequestsLoadRequested():
return loadRequested(_that);case AdminRequestsOrganizationTypeFilterChanged():
return organizationTypeFilterChanged(_that);case AdminRequestsApproveRequested():
return approveRequested(_that);case AdminRequestsRejectRequested():
return rejectRequested(_that);case AdminRequestsResendRequested():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AdminRequestsLoadRequested value)?  loadRequested,TResult? Function( AdminRequestsOrganizationTypeFilterChanged value)?  organizationTypeFilterChanged,TResult? Function( AdminRequestsApproveRequested value)?  approveRequested,TResult? Function( AdminRequestsRejectRequested value)?  rejectRequested,TResult? Function( AdminRequestsResendRequested value)?  resendRequested,}){
final _that = this;
switch (_that) {
case AdminRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that);case AdminRequestsOrganizationTypeFilterChanged() when organizationTypeFilterChanged != null:
return organizationTypeFilterChanged(_that);case AdminRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that);case AdminRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case AdminRequestsResendRequested() when resendRequested != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( OrganizationRequestStatus? statusFilter)?  loadRequested,TResult Function( OrganizationType organizationType)?  organizationTypeFilterChanged,TResult Function( AdminOrganizationRequest request)?  approveRequested,TResult Function( AdminOrganizationRequest request,  String? reviewComment)?  rejectRequested,TResult Function( AdminOrganizationRequest request)?  resendRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AdminRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that.statusFilter);case AdminRequestsOrganizationTypeFilterChanged() when organizationTypeFilterChanged != null:
return organizationTypeFilterChanged(_that.organizationType);case AdminRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that.request);case AdminRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that.request,_that.reviewComment);case AdminRequestsResendRequested() when resendRequested != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( OrganizationRequestStatus? statusFilter)  loadRequested,required TResult Function( OrganizationType organizationType)  organizationTypeFilterChanged,required TResult Function( AdminOrganizationRequest request)  approveRequested,required TResult Function( AdminOrganizationRequest request,  String? reviewComment)  rejectRequested,required TResult Function( AdminOrganizationRequest request)  resendRequested,}) {final _that = this;
switch (_that) {
case AdminRequestsLoadRequested():
return loadRequested(_that.statusFilter);case AdminRequestsOrganizationTypeFilterChanged():
return organizationTypeFilterChanged(_that.organizationType);case AdminRequestsApproveRequested():
return approveRequested(_that.request);case AdminRequestsRejectRequested():
return rejectRequested(_that.request,_that.reviewComment);case AdminRequestsResendRequested():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( OrganizationRequestStatus? statusFilter)?  loadRequested,TResult? Function( OrganizationType organizationType)?  organizationTypeFilterChanged,TResult? Function( AdminOrganizationRequest request)?  approveRequested,TResult? Function( AdminOrganizationRequest request,  String? reviewComment)?  rejectRequested,TResult? Function( AdminOrganizationRequest request)?  resendRequested,}) {final _that = this;
switch (_that) {
case AdminRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that.statusFilter);case AdminRequestsOrganizationTypeFilterChanged() when organizationTypeFilterChanged != null:
return organizationTypeFilterChanged(_that.organizationType);case AdminRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that.request);case AdminRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that.request,_that.reviewComment);case AdminRequestsResendRequested() when resendRequested != null:
return resendRequested(_that.request);case _:
  return null;

}
}

}

/// @nodoc


class AdminRequestsLoadRequested implements AdminRequestsEvent {
  const AdminRequestsLoadRequested({this.statusFilter});
  

 final  OrganizationRequestStatus? statusFilter;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminRequestsLoadRequestedCopyWith<AdminRequestsLoadRequested> get copyWith => _$AdminRequestsLoadRequestedCopyWithImpl<AdminRequestsLoadRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsLoadRequested&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter));
}


@override
int get hashCode => Object.hash(runtimeType,statusFilter);

@override
String toString() {
  return 'AdminRequestsEvent.loadRequested(statusFilter: $statusFilter)';
}


}

/// @nodoc
abstract mixin class $AdminRequestsLoadRequestedCopyWith<$Res> implements $AdminRequestsEventCopyWith<$Res> {
  factory $AdminRequestsLoadRequestedCopyWith(AdminRequestsLoadRequested value, $Res Function(AdminRequestsLoadRequested) _then) = _$AdminRequestsLoadRequestedCopyWithImpl;
@useResult
$Res call({
 OrganizationRequestStatus? statusFilter
});




}
/// @nodoc
class _$AdminRequestsLoadRequestedCopyWithImpl<$Res>
    implements $AdminRequestsLoadRequestedCopyWith<$Res> {
  _$AdminRequestsLoadRequestedCopyWithImpl(this._self, this._then);

  final AdminRequestsLoadRequested _self;
  final $Res Function(AdminRequestsLoadRequested) _then;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusFilter = freezed,}) {
  return _then(AdminRequestsLoadRequested(
statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as OrganizationRequestStatus?,
  ));
}


}

/// @nodoc


class AdminRequestsOrganizationTypeFilterChanged implements AdminRequestsEvent {
  const AdminRequestsOrganizationTypeFilterChanged(this.organizationType);
  

 final  OrganizationType organizationType;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminRequestsOrganizationTypeFilterChangedCopyWith<AdminRequestsOrganizationTypeFilterChanged> get copyWith => _$AdminRequestsOrganizationTypeFilterChangedCopyWithImpl<AdminRequestsOrganizationTypeFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsOrganizationTypeFilterChanged&&(identical(other.organizationType, organizationType) || other.organizationType == organizationType));
}


@override
int get hashCode => Object.hash(runtimeType,organizationType);

@override
String toString() {
  return 'AdminRequestsEvent.organizationTypeFilterChanged(organizationType: $organizationType)';
}


}

/// @nodoc
abstract mixin class $AdminRequestsOrganizationTypeFilterChangedCopyWith<$Res> implements $AdminRequestsEventCopyWith<$Res> {
  factory $AdminRequestsOrganizationTypeFilterChangedCopyWith(AdminRequestsOrganizationTypeFilterChanged value, $Res Function(AdminRequestsOrganizationTypeFilterChanged) _then) = _$AdminRequestsOrganizationTypeFilterChangedCopyWithImpl;
@useResult
$Res call({
 OrganizationType organizationType
});




}
/// @nodoc
class _$AdminRequestsOrganizationTypeFilterChangedCopyWithImpl<$Res>
    implements $AdminRequestsOrganizationTypeFilterChangedCopyWith<$Res> {
  _$AdminRequestsOrganizationTypeFilterChangedCopyWithImpl(this._self, this._then);

  final AdminRequestsOrganizationTypeFilterChanged _self;
  final $Res Function(AdminRequestsOrganizationTypeFilterChanged) _then;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationType = null,}) {
  return _then(AdminRequestsOrganizationTypeFilterChanged(
null == organizationType ? _self.organizationType : organizationType // ignore: cast_nullable_to_non_nullable
as OrganizationType,
  ));
}


}

/// @nodoc


class AdminRequestsApproveRequested implements AdminRequestsEvent {
  const AdminRequestsApproveRequested(this.request);
  

 final  AdminOrganizationRequest request;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminRequestsApproveRequestedCopyWith<AdminRequestsApproveRequested> get copyWith => _$AdminRequestsApproveRequestedCopyWithImpl<AdminRequestsApproveRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsApproveRequested&&(identical(other.request, request) || other.request == request));
}


@override
int get hashCode => Object.hash(runtimeType,request);

@override
String toString() {
  return 'AdminRequestsEvent.approveRequested(request: $request)';
}


}

/// @nodoc
abstract mixin class $AdminRequestsApproveRequestedCopyWith<$Res> implements $AdminRequestsEventCopyWith<$Res> {
  factory $AdminRequestsApproveRequestedCopyWith(AdminRequestsApproveRequested value, $Res Function(AdminRequestsApproveRequested) _then) = _$AdminRequestsApproveRequestedCopyWithImpl;
@useResult
$Res call({
 AdminOrganizationRequest request
});


$AdminOrganizationRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$AdminRequestsApproveRequestedCopyWithImpl<$Res>
    implements $AdminRequestsApproveRequestedCopyWith<$Res> {
  _$AdminRequestsApproveRequestedCopyWithImpl(this._self, this._then);

  final AdminRequestsApproveRequested _self;
  final $Res Function(AdminRequestsApproveRequested) _then;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(AdminRequestsApproveRequested(
null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminOrganizationRequest,
  ));
}

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminOrganizationRequestCopyWith<$Res> get request {
  
  return $AdminOrganizationRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

/// @nodoc


class AdminRequestsRejectRequested implements AdminRequestsEvent {
  const AdminRequestsRejectRequested({required this.request, this.reviewComment});
  

 final  AdminOrganizationRequest request;
 final  String? reviewComment;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminRequestsRejectRequestedCopyWith<AdminRequestsRejectRequested> get copyWith => _$AdminRequestsRejectRequestedCopyWithImpl<AdminRequestsRejectRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsRejectRequested&&(identical(other.request, request) || other.request == request)&&(identical(other.reviewComment, reviewComment) || other.reviewComment == reviewComment));
}


@override
int get hashCode => Object.hash(runtimeType,request,reviewComment);

@override
String toString() {
  return 'AdminRequestsEvent.rejectRequested(request: $request, reviewComment: $reviewComment)';
}


}

/// @nodoc
abstract mixin class $AdminRequestsRejectRequestedCopyWith<$Res> implements $AdminRequestsEventCopyWith<$Res> {
  factory $AdminRequestsRejectRequestedCopyWith(AdminRequestsRejectRequested value, $Res Function(AdminRequestsRejectRequested) _then) = _$AdminRequestsRejectRequestedCopyWithImpl;
@useResult
$Res call({
 AdminOrganizationRequest request, String? reviewComment
});


$AdminOrganizationRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$AdminRequestsRejectRequestedCopyWithImpl<$Res>
    implements $AdminRequestsRejectRequestedCopyWith<$Res> {
  _$AdminRequestsRejectRequestedCopyWithImpl(this._self, this._then);

  final AdminRequestsRejectRequested _self;
  final $Res Function(AdminRequestsRejectRequested) _then;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,Object? reviewComment = freezed,}) {
  return _then(AdminRequestsRejectRequested(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminOrganizationRequest,reviewComment: freezed == reviewComment ? _self.reviewComment : reviewComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminOrganizationRequestCopyWith<$Res> get request {
  
  return $AdminOrganizationRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

/// @nodoc


class AdminRequestsResendRequested implements AdminRequestsEvent {
  const AdminRequestsResendRequested(this.request);
  

 final  AdminOrganizationRequest request;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminRequestsResendRequestedCopyWith<AdminRequestsResendRequested> get copyWith => _$AdminRequestsResendRequestedCopyWithImpl<AdminRequestsResendRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminRequestsResendRequested&&(identical(other.request, request) || other.request == request));
}


@override
int get hashCode => Object.hash(runtimeType,request);

@override
String toString() {
  return 'AdminRequestsEvent.resendRequested(request: $request)';
}


}

/// @nodoc
abstract mixin class $AdminRequestsResendRequestedCopyWith<$Res> implements $AdminRequestsEventCopyWith<$Res> {
  factory $AdminRequestsResendRequestedCopyWith(AdminRequestsResendRequested value, $Res Function(AdminRequestsResendRequested) _then) = _$AdminRequestsResendRequestedCopyWithImpl;
@useResult
$Res call({
 AdminOrganizationRequest request
});


$AdminOrganizationRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$AdminRequestsResendRequestedCopyWithImpl<$Res>
    implements $AdminRequestsResendRequestedCopyWith<$Res> {
  _$AdminRequestsResendRequestedCopyWithImpl(this._self, this._then);

  final AdminRequestsResendRequested _self;
  final $Res Function(AdminRequestsResendRequested) _then;

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(AdminRequestsResendRequested(
null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminOrganizationRequest,
  ));
}

/// Create a copy of AdminRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminOrganizationRequestCopyWith<$Res> get request {
  
  return $AdminOrganizationRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

// dart format on
