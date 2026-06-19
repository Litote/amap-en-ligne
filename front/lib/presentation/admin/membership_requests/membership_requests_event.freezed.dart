// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership_requests_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MembershipRequestsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MembershipRequestsEvent()';
}


}

/// @nodoc
class $MembershipRequestsEventCopyWith<$Res>  {
$MembershipRequestsEventCopyWith(MembershipRequestsEvent _, $Res Function(MembershipRequestsEvent) __);
}


/// Adds pattern-matching-related methods to [MembershipRequestsEvent].
extension MembershipRequestsEventPatterns on MembershipRequestsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MembershipRequestsLoadRequested value)?  loadRequested,TResult Function( MembershipRequestsApproveRequested value)?  approveRequested,TResult Function( MembershipRequestsRejectRequested value)?  rejectRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MembershipRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that);case MembershipRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that);case MembershipRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MembershipRequestsLoadRequested value)  loadRequested,required TResult Function( MembershipRequestsApproveRequested value)  approveRequested,required TResult Function( MembershipRequestsRejectRequested value)  rejectRequested,}){
final _that = this;
switch (_that) {
case MembershipRequestsLoadRequested():
return loadRequested(_that);case MembershipRequestsApproveRequested():
return approveRequested(_that);case MembershipRequestsRejectRequested():
return rejectRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MembershipRequestsLoadRequested value)?  loadRequested,TResult? Function( MembershipRequestsApproveRequested value)?  approveRequested,TResult? Function( MembershipRequestsRejectRequested value)?  rejectRequested,}){
final _that = this;
switch (_that) {
case MembershipRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that);case MembershipRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that);case MembershipRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( MemberJoinRequestStatus? statusFilter)?  loadRequested,TResult Function( AdminMemberJoinRequest request)?  approveRequested,TResult Function( AdminMemberJoinRequest request,  String? reviewComment)?  rejectRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MembershipRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that.statusFilter);case MembershipRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that.request);case MembershipRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that.request,_that.reviewComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( MemberJoinRequestStatus? statusFilter)  loadRequested,required TResult Function( AdminMemberJoinRequest request)  approveRequested,required TResult Function( AdminMemberJoinRequest request,  String? reviewComment)  rejectRequested,}) {final _that = this;
switch (_that) {
case MembershipRequestsLoadRequested():
return loadRequested(_that.statusFilter);case MembershipRequestsApproveRequested():
return approveRequested(_that.request);case MembershipRequestsRejectRequested():
return rejectRequested(_that.request,_that.reviewComment);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( MemberJoinRequestStatus? statusFilter)?  loadRequested,TResult? Function( AdminMemberJoinRequest request)?  approveRequested,TResult? Function( AdminMemberJoinRequest request,  String? reviewComment)?  rejectRequested,}) {final _that = this;
switch (_that) {
case MembershipRequestsLoadRequested() when loadRequested != null:
return loadRequested(_that.statusFilter);case MembershipRequestsApproveRequested() when approveRequested != null:
return approveRequested(_that.request);case MembershipRequestsRejectRequested() when rejectRequested != null:
return rejectRequested(_that.request,_that.reviewComment);case _:
  return null;

}
}

}

/// @nodoc


class MembershipRequestsLoadRequested implements MembershipRequestsEvent {
  const MembershipRequestsLoadRequested({this.statusFilter});
  

 final  MemberJoinRequestStatus? statusFilter;

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRequestsLoadRequestedCopyWith<MembershipRequestsLoadRequested> get copyWith => _$MembershipRequestsLoadRequestedCopyWithImpl<MembershipRequestsLoadRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsLoadRequested&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter));
}


@override
int get hashCode => Object.hash(runtimeType,statusFilter);

@override
String toString() {
  return 'MembershipRequestsEvent.loadRequested(statusFilter: $statusFilter)';
}


}

/// @nodoc
abstract mixin class $MembershipRequestsLoadRequestedCopyWith<$Res> implements $MembershipRequestsEventCopyWith<$Res> {
  factory $MembershipRequestsLoadRequestedCopyWith(MembershipRequestsLoadRequested value, $Res Function(MembershipRequestsLoadRequested) _then) = _$MembershipRequestsLoadRequestedCopyWithImpl;
@useResult
$Res call({
 MemberJoinRequestStatus? statusFilter
});




}
/// @nodoc
class _$MembershipRequestsLoadRequestedCopyWithImpl<$Res>
    implements $MembershipRequestsLoadRequestedCopyWith<$Res> {
  _$MembershipRequestsLoadRequestedCopyWithImpl(this._self, this._then);

  final MembershipRequestsLoadRequested _self;
  final $Res Function(MembershipRequestsLoadRequested) _then;

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusFilter = freezed,}) {
  return _then(MembershipRequestsLoadRequested(
statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as MemberJoinRequestStatus?,
  ));
}


}

/// @nodoc


class MembershipRequestsApproveRequested implements MembershipRequestsEvent {
  const MembershipRequestsApproveRequested({required this.request});
  

 final  AdminMemberJoinRequest request;

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRequestsApproveRequestedCopyWith<MembershipRequestsApproveRequested> get copyWith => _$MembershipRequestsApproveRequestedCopyWithImpl<MembershipRequestsApproveRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsApproveRequested&&(identical(other.request, request) || other.request == request));
}


@override
int get hashCode => Object.hash(runtimeType,request);

@override
String toString() {
  return 'MembershipRequestsEvent.approveRequested(request: $request)';
}


}

/// @nodoc
abstract mixin class $MembershipRequestsApproveRequestedCopyWith<$Res> implements $MembershipRequestsEventCopyWith<$Res> {
  factory $MembershipRequestsApproveRequestedCopyWith(MembershipRequestsApproveRequested value, $Res Function(MembershipRequestsApproveRequested) _then) = _$MembershipRequestsApproveRequestedCopyWithImpl;
@useResult
$Res call({
 AdminMemberJoinRequest request
});


$AdminMemberJoinRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$MembershipRequestsApproveRequestedCopyWithImpl<$Res>
    implements $MembershipRequestsApproveRequestedCopyWith<$Res> {
  _$MembershipRequestsApproveRequestedCopyWithImpl(this._self, this._then);

  final MembershipRequestsApproveRequested _self;
  final $Res Function(MembershipRequestsApproveRequested) _then;

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(MembershipRequestsApproveRequested(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminMemberJoinRequest,
  ));
}

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminMemberJoinRequestCopyWith<$Res> get request {
  
  return $AdminMemberJoinRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

/// @nodoc


class MembershipRequestsRejectRequested implements MembershipRequestsEvent {
  const MembershipRequestsRejectRequested({required this.request, this.reviewComment});
  

 final  AdminMemberJoinRequest request;
 final  String? reviewComment;

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRequestsRejectRequestedCopyWith<MembershipRequestsRejectRequested> get copyWith => _$MembershipRequestsRejectRequestedCopyWithImpl<MembershipRequestsRejectRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequestsRejectRequested&&(identical(other.request, request) || other.request == request)&&(identical(other.reviewComment, reviewComment) || other.reviewComment == reviewComment));
}


@override
int get hashCode => Object.hash(runtimeType,request,reviewComment);

@override
String toString() {
  return 'MembershipRequestsEvent.rejectRequested(request: $request, reviewComment: $reviewComment)';
}


}

/// @nodoc
abstract mixin class $MembershipRequestsRejectRequestedCopyWith<$Res> implements $MembershipRequestsEventCopyWith<$Res> {
  factory $MembershipRequestsRejectRequestedCopyWith(MembershipRequestsRejectRequested value, $Res Function(MembershipRequestsRejectRequested) _then) = _$MembershipRequestsRejectRequestedCopyWithImpl;
@useResult
$Res call({
 AdminMemberJoinRequest request, String? reviewComment
});


$AdminMemberJoinRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$MembershipRequestsRejectRequestedCopyWithImpl<$Res>
    implements $MembershipRequestsRejectRequestedCopyWith<$Res> {
  _$MembershipRequestsRejectRequestedCopyWithImpl(this._self, this._then);

  final MembershipRequestsRejectRequested _self;
  final $Res Function(MembershipRequestsRejectRequested) _then;

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,Object? reviewComment = freezed,}) {
  return _then(MembershipRequestsRejectRequested(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as AdminMemberJoinRequest,reviewComment: freezed == reviewComment ? _self.reviewComment : reviewComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of MembershipRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminMemberJoinRequestCopyWith<$Res> get request {
  
  return $AdminMemberJoinRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

// dart format on
