// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'producer_request_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProducerRequestEvent {

 String get producerName; String get adminFirstName; String get adminLastName; String get adminEmail; String? get submitterComment;
/// Create a copy of ProducerRequestEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestEventCopyWith<ProducerRequestEvent> get copyWith => _$ProducerRequestEventCopyWithImpl<ProducerRequestEvent>(this as ProducerRequestEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestEvent&&(identical(other.producerName, producerName) || other.producerName == producerName)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}


@override
int get hashCode => Object.hash(runtimeType,producerName,adminFirstName,adminLastName,adminEmail,submitterComment);

@override
String toString() {
  return 'ProducerRequestEvent(producerName: $producerName, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestEventCopyWith<$Res>  {
  factory $ProducerRequestEventCopyWith(ProducerRequestEvent value, $Res Function(ProducerRequestEvent) _then) = _$ProducerRequestEventCopyWithImpl;
@useResult
$Res call({
 String producerName, String adminFirstName, String adminLastName, String adminEmail, String? submitterComment
});




}
/// @nodoc
class _$ProducerRequestEventCopyWithImpl<$Res>
    implements $ProducerRequestEventCopyWith<$Res> {
  _$ProducerRequestEventCopyWithImpl(this._self, this._then);

  final ProducerRequestEvent _self;
  final $Res Function(ProducerRequestEvent) _then;

/// Create a copy of ProducerRequestEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? producerName = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? submitterComment = freezed,}) {
  return _then(_self.copyWith(
producerName: null == producerName ? _self.producerName : producerName // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProducerRequestEvent].
extension ProducerRequestEventPatterns on ProducerRequestEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProducerRequestSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProducerRequestSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProducerRequestSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case ProducerRequestSubmitted():
return submitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProducerRequestSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case ProducerRequestSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String producerName,  String adminFirstName,  String adminLastName,  String adminEmail,  String? submitterComment)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProducerRequestSubmitted() when submitted != null:
return submitted(_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.submitterComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String producerName,  String adminFirstName,  String adminLastName,  String adminEmail,  String? submitterComment)  submitted,}) {final _that = this;
switch (_that) {
case ProducerRequestSubmitted():
return submitted(_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.submitterComment);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String producerName,  String adminFirstName,  String adminLastName,  String adminEmail,  String? submitterComment)?  submitted,}) {final _that = this;
switch (_that) {
case ProducerRequestSubmitted() when submitted != null:
return submitted(_that.producerName,_that.adminFirstName,_that.adminLastName,_that.adminEmail,_that.submitterComment);case _:
  return null;

}
}

}

/// @nodoc


class ProducerRequestSubmitted implements ProducerRequestEvent {
  const ProducerRequestSubmitted({required this.producerName, required this.adminFirstName, required this.adminLastName, required this.adminEmail, this.submitterComment});
  

@override final  String producerName;
@override final  String adminFirstName;
@override final  String adminLastName;
@override final  String adminEmail;
@override final  String? submitterComment;

/// Create a copy of ProducerRequestEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProducerRequestSubmittedCopyWith<ProducerRequestSubmitted> get copyWith => _$ProducerRequestSubmittedCopyWithImpl<ProducerRequestSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProducerRequestSubmitted&&(identical(other.producerName, producerName) || other.producerName == producerName)&&(identical(other.adminFirstName, adminFirstName) || other.adminFirstName == adminFirstName)&&(identical(other.adminLastName, adminLastName) || other.adminLastName == adminLastName)&&(identical(other.adminEmail, adminEmail) || other.adminEmail == adminEmail)&&(identical(other.submitterComment, submitterComment) || other.submitterComment == submitterComment));
}


@override
int get hashCode => Object.hash(runtimeType,producerName,adminFirstName,adminLastName,adminEmail,submitterComment);

@override
String toString() {
  return 'ProducerRequestEvent.submitted(producerName: $producerName, adminFirstName: $adminFirstName, adminLastName: $adminLastName, adminEmail: $adminEmail, submitterComment: $submitterComment)';
}


}

/// @nodoc
abstract mixin class $ProducerRequestSubmittedCopyWith<$Res> implements $ProducerRequestEventCopyWith<$Res> {
  factory $ProducerRequestSubmittedCopyWith(ProducerRequestSubmitted value, $Res Function(ProducerRequestSubmitted) _then) = _$ProducerRequestSubmittedCopyWithImpl;
@override @useResult
$Res call({
 String producerName, String adminFirstName, String adminLastName, String adminEmail, String? submitterComment
});




}
/// @nodoc
class _$ProducerRequestSubmittedCopyWithImpl<$Res>
    implements $ProducerRequestSubmittedCopyWith<$Res> {
  _$ProducerRequestSubmittedCopyWithImpl(this._self, this._then);

  final ProducerRequestSubmitted _self;
  final $Res Function(ProducerRequestSubmitted) _then;

/// Create a copy of ProducerRequestEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? producerName = null,Object? adminFirstName = null,Object? adminLastName = null,Object? adminEmail = null,Object? submitterComment = freezed,}) {
  return _then(ProducerRequestSubmitted(
producerName: null == producerName ? _self.producerName : producerName // ignore: cast_nullable_to_non_nullable
as String,adminFirstName: null == adminFirstName ? _self.adminFirstName : adminFirstName // ignore: cast_nullable_to_non_nullable
as String,adminLastName: null == adminLastName ? _self.adminLastName : adminLastName // ignore: cast_nullable_to_non_nullable
as String,adminEmail: null == adminEmail ? _self.adminEmail : adminEmail // ignore: cast_nullable_to_non_nullable
as String,submitterComment: freezed == submitterComment ? _self.submitterComment : submitterComment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
