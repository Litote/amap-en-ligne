// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'basket_exchange.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BasketExchangeRequest {

@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'requester_member_id') String get requesterMemberId;// ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
@JsonKey(name: 'created_at') String get createdAt; BasketExchangeRequestStatus get status;// ISO-8601 instant string; null/absent when not yet decided.
@JsonKey(name: 'decided_at') String? get decidedAt;// Reciprocal swap: the delivery (and optional contract) the requester offers
// in return. The offerer receives this basket when validating the request.
// Required at submission time (enforced by the back); nullable on the wire for
// robustness / legacy rows.
@JsonKey(name: 'proposed_delivery_id') String? get proposedDeliveryId;@JsonKey(name: 'proposed_contract_id') String? get proposedContractId;
/// Create a copy of BasketExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketExchangeRequestCopyWith<BasketExchangeRequest> get copyWith => _$BasketExchangeRequestCopyWithImpl<BasketExchangeRequest>(this as BasketExchangeRequest, _$identity);

  /// Serializes this BasketExchangeRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchangeRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.requesterMemberId, requesterMemberId) || other.requesterMemberId == requesterMemberId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.proposedDeliveryId, proposedDeliveryId) || other.proposedDeliveryId == proposedDeliveryId)&&(identical(other.proposedContractId, proposedContractId) || other.proposedContractId == proposedContractId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,requesterMemberId,createdAt,status,decidedAt,proposedDeliveryId,proposedContractId);

@override
String toString() {
  return 'BasketExchangeRequest(requestId: $requestId, requesterMemberId: $requesterMemberId, createdAt: $createdAt, status: $status, decidedAt: $decidedAt, proposedDeliveryId: $proposedDeliveryId, proposedContractId: $proposedContractId)';
}


}

/// @nodoc
abstract mixin class $BasketExchangeRequestCopyWith<$Res>  {
  factory $BasketExchangeRequestCopyWith(BasketExchangeRequest value, $Res Function(BasketExchangeRequest) _then) = _$BasketExchangeRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'requester_member_id') String requesterMemberId,@JsonKey(name: 'created_at') String createdAt, BasketExchangeRequestStatus status,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'proposed_delivery_id') String? proposedDeliveryId,@JsonKey(name: 'proposed_contract_id') String? proposedContractId
});




}
/// @nodoc
class _$BasketExchangeRequestCopyWithImpl<$Res>
    implements $BasketExchangeRequestCopyWith<$Res> {
  _$BasketExchangeRequestCopyWithImpl(this._self, this._then);

  final BasketExchangeRequest _self;
  final $Res Function(BasketExchangeRequest) _then;

/// Create a copy of BasketExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? requesterMemberId = null,Object? createdAt = null,Object? status = null,Object? decidedAt = freezed,Object? proposedDeliveryId = freezed,Object? proposedContractId = freezed,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,requesterMemberId: null == requesterMemberId ? _self.requesterMemberId : requesterMemberId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BasketExchangeRequestStatus,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,proposedDeliveryId: freezed == proposedDeliveryId ? _self.proposedDeliveryId : proposedDeliveryId // ignore: cast_nullable_to_non_nullable
as String?,proposedContractId: freezed == proposedContractId ? _self.proposedContractId : proposedContractId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketExchangeRequest].
extension BasketExchangeRequestPatterns on BasketExchangeRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketExchangeRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketExchangeRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketExchangeRequest value)  $default,){
final _that = this;
switch (_that) {
case _BasketExchangeRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketExchangeRequest value)?  $default,){
final _that = this;
switch (_that) {
case _BasketExchangeRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'requester_member_id')  String requesterMemberId, @JsonKey(name: 'created_at')  String createdAt,  BasketExchangeRequestStatus status, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'proposed_delivery_id')  String? proposedDeliveryId, @JsonKey(name: 'proposed_contract_id')  String? proposedContractId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketExchangeRequest() when $default != null:
return $default(_that.requestId,_that.requesterMemberId,_that.createdAt,_that.status,_that.decidedAt,_that.proposedDeliveryId,_that.proposedContractId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'requester_member_id')  String requesterMemberId, @JsonKey(name: 'created_at')  String createdAt,  BasketExchangeRequestStatus status, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'proposed_delivery_id')  String? proposedDeliveryId, @JsonKey(name: 'proposed_contract_id')  String? proposedContractId)  $default,) {final _that = this;
switch (_that) {
case _BasketExchangeRequest():
return $default(_that.requestId,_that.requesterMemberId,_that.createdAt,_that.status,_that.decidedAt,_that.proposedDeliveryId,_that.proposedContractId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'requester_member_id')  String requesterMemberId, @JsonKey(name: 'created_at')  String createdAt,  BasketExchangeRequestStatus status, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'proposed_delivery_id')  String? proposedDeliveryId, @JsonKey(name: 'proposed_contract_id')  String? proposedContractId)?  $default,) {final _that = this;
switch (_that) {
case _BasketExchangeRequest() when $default != null:
return $default(_that.requestId,_that.requesterMemberId,_that.createdAt,_that.status,_that.decidedAt,_that.proposedDeliveryId,_that.proposedContractId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketExchangeRequest implements BasketExchangeRequest {
  const _BasketExchangeRequest({@JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'requester_member_id') required this.requesterMemberId, @JsonKey(name: 'created_at') required this.createdAt, required this.status, @JsonKey(name: 'decided_at') this.decidedAt, @JsonKey(name: 'proposed_delivery_id') this.proposedDeliveryId, @JsonKey(name: 'proposed_contract_id') this.proposedContractId});
  factory _BasketExchangeRequest.fromJson(Map<String, dynamic> json) => _$BasketExchangeRequestFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'requester_member_id') final  String requesterMemberId;
// ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
@override@JsonKey(name: 'created_at') final  String createdAt;
@override final  BasketExchangeRequestStatus status;
// ISO-8601 instant string; null/absent when not yet decided.
@override@JsonKey(name: 'decided_at') final  String? decidedAt;
// Reciprocal swap: the delivery (and optional contract) the requester offers
// in return. The offerer receives this basket when validating the request.
// Required at submission time (enforced by the back); nullable on the wire for
// robustness / legacy rows.
@override@JsonKey(name: 'proposed_delivery_id') final  String? proposedDeliveryId;
@override@JsonKey(name: 'proposed_contract_id') final  String? proposedContractId;

/// Create a copy of BasketExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketExchangeRequestCopyWith<_BasketExchangeRequest> get copyWith => __$BasketExchangeRequestCopyWithImpl<_BasketExchangeRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketExchangeRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketExchangeRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.requesterMemberId, requesterMemberId) || other.requesterMemberId == requesterMemberId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.proposedDeliveryId, proposedDeliveryId) || other.proposedDeliveryId == proposedDeliveryId)&&(identical(other.proposedContractId, proposedContractId) || other.proposedContractId == proposedContractId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,requesterMemberId,createdAt,status,decidedAt,proposedDeliveryId,proposedContractId);

@override
String toString() {
  return 'BasketExchangeRequest(requestId: $requestId, requesterMemberId: $requesterMemberId, createdAt: $createdAt, status: $status, decidedAt: $decidedAt, proposedDeliveryId: $proposedDeliveryId, proposedContractId: $proposedContractId)';
}


}

/// @nodoc
abstract mixin class _$BasketExchangeRequestCopyWith<$Res> implements $BasketExchangeRequestCopyWith<$Res> {
  factory _$BasketExchangeRequestCopyWith(_BasketExchangeRequest value, $Res Function(_BasketExchangeRequest) _then) = __$BasketExchangeRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'requester_member_id') String requesterMemberId,@JsonKey(name: 'created_at') String createdAt, BasketExchangeRequestStatus status,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'proposed_delivery_id') String? proposedDeliveryId,@JsonKey(name: 'proposed_contract_id') String? proposedContractId
});




}
/// @nodoc
class __$BasketExchangeRequestCopyWithImpl<$Res>
    implements _$BasketExchangeRequestCopyWith<$Res> {
  __$BasketExchangeRequestCopyWithImpl(this._self, this._then);

  final _BasketExchangeRequest _self;
  final $Res Function(_BasketExchangeRequest) _then;

/// Create a copy of BasketExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? requesterMemberId = null,Object? createdAt = null,Object? status = null,Object? decidedAt = freezed,Object? proposedDeliveryId = freezed,Object? proposedContractId = freezed,}) {
  return _then(_BasketExchangeRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,requesterMemberId: null == requesterMemberId ? _self.requesterMemberId : requesterMemberId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BasketExchangeRequestStatus,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,proposedDeliveryId: freezed == proposedDeliveryId ? _self.proposedDeliveryId : proposedDeliveryId // ignore: cast_nullable_to_non_nullable
as String?,proposedContractId: freezed == proposedContractId ? _self.proposedContractId : proposedContractId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BasketExchange {

@JsonKey(name: 'basket_exchange_id') String get basketExchangeId;@JsonKey(name: 'organization_id') String get organizationId;@JsonKey(name: 'delivery_id') String get deliveryId;@JsonKey(name: 'contract_id') String get contractId;@JsonKey(name: 'offering_member_id') String get offeringMemberId; String? get motive; BasketExchangeStatus get status;// ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
@JsonKey(name: 'created_at') String get createdAt;// ISO-8601 instant string; null/absent until the exchange is decided.
@JsonKey(name: 'decided_at') String? get decidedAt;// Null/absent while no request has been accepted yet.
@JsonKey(name: 'accepted_request_id') String? get acceptedRequestId; List<BasketExchangeRequest> get requests;
/// Create a copy of BasketExchange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketExchangeCopyWith<BasketExchange> get copyWith => _$BasketExchangeCopyWithImpl<BasketExchange>(this as BasketExchange, _$identity);

  /// Serializes this BasketExchange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketExchange&&(identical(other.basketExchangeId, basketExchangeId) || other.basketExchangeId == basketExchangeId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.offeringMemberId, offeringMemberId) || other.offeringMemberId == offeringMemberId)&&(identical(other.motive, motive) || other.motive == motive)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.acceptedRequestId, acceptedRequestId) || other.acceptedRequestId == acceptedRequestId)&&const DeepCollectionEquality().equals(other.requests, requests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,basketExchangeId,organizationId,deliveryId,contractId,offeringMemberId,motive,status,createdAt,decidedAt,acceptedRequestId,const DeepCollectionEquality().hash(requests));

@override
String toString() {
  return 'BasketExchange(basketExchangeId: $basketExchangeId, organizationId: $organizationId, deliveryId: $deliveryId, contractId: $contractId, offeringMemberId: $offeringMemberId, motive: $motive, status: $status, createdAt: $createdAt, decidedAt: $decidedAt, acceptedRequestId: $acceptedRequestId, requests: $requests)';
}


}

/// @nodoc
abstract mixin class $BasketExchangeCopyWith<$Res>  {
  factory $BasketExchangeCopyWith(BasketExchange value, $Res Function(BasketExchange) _then) = _$BasketExchangeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'basket_exchange_id') String basketExchangeId,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'offering_member_id') String offeringMemberId, String? motive, BasketExchangeStatus status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'accepted_request_id') String? acceptedRequestId, List<BasketExchangeRequest> requests
});




}
/// @nodoc
class _$BasketExchangeCopyWithImpl<$Res>
    implements $BasketExchangeCopyWith<$Res> {
  _$BasketExchangeCopyWithImpl(this._self, this._then);

  final BasketExchange _self;
  final $Res Function(BasketExchange) _then;

/// Create a copy of BasketExchange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? basketExchangeId = null,Object? organizationId = null,Object? deliveryId = null,Object? contractId = null,Object? offeringMemberId = null,Object? motive = freezed,Object? status = null,Object? createdAt = null,Object? decidedAt = freezed,Object? acceptedRequestId = freezed,Object? requests = null,}) {
  return _then(_self.copyWith(
basketExchangeId: null == basketExchangeId ? _self.basketExchangeId : basketExchangeId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,offeringMemberId: null == offeringMemberId ? _self.offeringMemberId : offeringMemberId // ignore: cast_nullable_to_non_nullable
as String,motive: freezed == motive ? _self.motive : motive // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BasketExchangeStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,acceptedRequestId: freezed == acceptedRequestId ? _self.acceptedRequestId : acceptedRequestId // ignore: cast_nullable_to_non_nullable
as String?,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as List<BasketExchangeRequest>,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketExchange].
extension BasketExchangePatterns on BasketExchange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketExchange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketExchange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketExchange value)  $default,){
final _that = this;
switch (_that) {
case _BasketExchange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketExchange value)?  $default,){
final _that = this;
switch (_that) {
case _BasketExchange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'basket_exchange_id')  String basketExchangeId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'offering_member_id')  String offeringMemberId,  String? motive,  BasketExchangeStatus status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'accepted_request_id')  String? acceptedRequestId,  List<BasketExchangeRequest> requests)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketExchange() when $default != null:
return $default(_that.basketExchangeId,_that.organizationId,_that.deliveryId,_that.contractId,_that.offeringMemberId,_that.motive,_that.status,_that.createdAt,_that.decidedAt,_that.acceptedRequestId,_that.requests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'basket_exchange_id')  String basketExchangeId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'offering_member_id')  String offeringMemberId,  String? motive,  BasketExchangeStatus status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'accepted_request_id')  String? acceptedRequestId,  List<BasketExchangeRequest> requests)  $default,) {final _that = this;
switch (_that) {
case _BasketExchange():
return $default(_that.basketExchangeId,_that.organizationId,_that.deliveryId,_that.contractId,_that.offeringMemberId,_that.motive,_that.status,_that.createdAt,_that.decidedAt,_that.acceptedRequestId,_that.requests);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'basket_exchange_id')  String basketExchangeId, @JsonKey(name: 'organization_id')  String organizationId, @JsonKey(name: 'delivery_id')  String deliveryId, @JsonKey(name: 'contract_id')  String contractId, @JsonKey(name: 'offering_member_id')  String offeringMemberId,  String? motive,  BasketExchangeStatus status, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'accepted_request_id')  String? acceptedRequestId,  List<BasketExchangeRequest> requests)?  $default,) {final _that = this;
switch (_that) {
case _BasketExchange() when $default != null:
return $default(_that.basketExchangeId,_that.organizationId,_that.deliveryId,_that.contractId,_that.offeringMemberId,_that.motive,_that.status,_that.createdAt,_that.decidedAt,_that.acceptedRequestId,_that.requests);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketExchange implements BasketExchange {
  const _BasketExchange({@JsonKey(name: 'basket_exchange_id') required this.basketExchangeId, @JsonKey(name: 'organization_id') required this.organizationId, @JsonKey(name: 'delivery_id') required this.deliveryId, @JsonKey(name: 'contract_id') required this.contractId, @JsonKey(name: 'offering_member_id') required this.offeringMemberId, this.motive, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'decided_at') this.decidedAt, @JsonKey(name: 'accepted_request_id') this.acceptedRequestId, final  List<BasketExchangeRequest> requests = const []}): _requests = requests;
  factory _BasketExchange.fromJson(Map<String, dynamic> json) => _$BasketExchangeFromJson(json);

@override@JsonKey(name: 'basket_exchange_id') final  String basketExchangeId;
@override@JsonKey(name: 'organization_id') final  String organizationId;
@override@JsonKey(name: 'delivery_id') final  String deliveryId;
@override@JsonKey(name: 'contract_id') final  String contractId;
@override@JsonKey(name: 'offering_member_id') final  String offeringMemberId;
@override final  String? motive;
@override final  BasketExchangeStatus status;
// ISO-8601 instant string, e.g. "2026-05-26T12:00:00Z".
@override@JsonKey(name: 'created_at') final  String createdAt;
// ISO-8601 instant string; null/absent until the exchange is decided.
@override@JsonKey(name: 'decided_at') final  String? decidedAt;
// Null/absent while no request has been accepted yet.
@override@JsonKey(name: 'accepted_request_id') final  String? acceptedRequestId;
 final  List<BasketExchangeRequest> _requests;
@override@JsonKey() List<BasketExchangeRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}


/// Create a copy of BasketExchange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketExchangeCopyWith<_BasketExchange> get copyWith => __$BasketExchangeCopyWithImpl<_BasketExchange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketExchangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketExchange&&(identical(other.basketExchangeId, basketExchangeId) || other.basketExchangeId == basketExchangeId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.offeringMemberId, offeringMemberId) || other.offeringMemberId == offeringMemberId)&&(identical(other.motive, motive) || other.motive == motive)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.acceptedRequestId, acceptedRequestId) || other.acceptedRequestId == acceptedRequestId)&&const DeepCollectionEquality().equals(other._requests, _requests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,basketExchangeId,organizationId,deliveryId,contractId,offeringMemberId,motive,status,createdAt,decidedAt,acceptedRequestId,const DeepCollectionEquality().hash(_requests));

@override
String toString() {
  return 'BasketExchange(basketExchangeId: $basketExchangeId, organizationId: $organizationId, deliveryId: $deliveryId, contractId: $contractId, offeringMemberId: $offeringMemberId, motive: $motive, status: $status, createdAt: $createdAt, decidedAt: $decidedAt, acceptedRequestId: $acceptedRequestId, requests: $requests)';
}


}

/// @nodoc
abstract mixin class _$BasketExchangeCopyWith<$Res> implements $BasketExchangeCopyWith<$Res> {
  factory _$BasketExchangeCopyWith(_BasketExchange value, $Res Function(_BasketExchange) _then) = __$BasketExchangeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'basket_exchange_id') String basketExchangeId,@JsonKey(name: 'organization_id') String organizationId,@JsonKey(name: 'delivery_id') String deliveryId,@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'offering_member_id') String offeringMemberId, String? motive, BasketExchangeStatus status,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'accepted_request_id') String? acceptedRequestId, List<BasketExchangeRequest> requests
});




}
/// @nodoc
class __$BasketExchangeCopyWithImpl<$Res>
    implements _$BasketExchangeCopyWith<$Res> {
  __$BasketExchangeCopyWithImpl(this._self, this._then);

  final _BasketExchange _self;
  final $Res Function(_BasketExchange) _then;

/// Create a copy of BasketExchange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? basketExchangeId = null,Object? organizationId = null,Object? deliveryId = null,Object? contractId = null,Object? offeringMemberId = null,Object? motive = freezed,Object? status = null,Object? createdAt = null,Object? decidedAt = freezed,Object? acceptedRequestId = freezed,Object? requests = null,}) {
  return _then(_BasketExchange(
basketExchangeId: null == basketExchangeId ? _self.basketExchangeId : basketExchangeId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,offeringMemberId: null == offeringMemberId ? _self.offeringMemberId : offeringMemberId // ignore: cast_nullable_to_non_nullable
as String,motive: freezed == motive ? _self.motive : motive // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BasketExchangeStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,acceptedRequestId: freezed == acceptedRequestId ? _self.acceptedRequestId : acceptedRequestId // ignore: cast_nullable_to_non_nullable
as String?,requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<BasketExchangeRequest>,
  ));
}


}

// dart format on
