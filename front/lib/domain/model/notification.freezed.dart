// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppNotification {

@JsonKey(name: 'notification_id') String get notificationId;@JsonKey(name: 'recipient_scope') String get recipientScope; NotificationType get type; NotificationCategory get category; String get title; String get body;@JsonKey(name: 'deep_link') String? get deepLink;@JsonKey(name: 'related_entity_id') String? get relatedEntityId;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'read_at') String? get readAt;
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<AppNotification> get copyWith => _$AppNotificationCopyWithImpl<AppNotification>(this as AppNotification, _$identity);

  /// Serializes this AppNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotification&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.recipientScope, recipientScope) || other.recipientScope == recipientScope)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&(identical(other.relatedEntityId, relatedEntityId) || other.relatedEntityId == relatedEntityId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationId,recipientScope,type,category,title,body,deepLink,relatedEntityId,createdAt,readAt);

@override
String toString() {
  return 'AppNotification(notificationId: $notificationId, recipientScope: $recipientScope, type: $type, category: $category, title: $title, body: $body, deepLink: $deepLink, relatedEntityId: $relatedEntityId, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class $AppNotificationCopyWith<$Res>  {
  factory $AppNotificationCopyWith(AppNotification value, $Res Function(AppNotification) _then) = _$AppNotificationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'notification_id') String notificationId,@JsonKey(name: 'recipient_scope') String recipientScope, NotificationType type, NotificationCategory category, String title, String body,@JsonKey(name: 'deep_link') String? deepLink,@JsonKey(name: 'related_entity_id') String? relatedEntityId,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'read_at') String? readAt
});




}
/// @nodoc
class _$AppNotificationCopyWithImpl<$Res>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._self, this._then);

  final AppNotification _self;
  final $Res Function(AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notificationId = null,Object? recipientScope = null,Object? type = null,Object? category = null,Object? title = null,Object? body = null,Object? deepLink = freezed,Object? relatedEntityId = freezed,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_self.copyWith(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,recipientScope: null == recipientScope ? _self.recipientScope : recipientScope // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NotificationCategory,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,relatedEntityId: freezed == relatedEntityId ? _self.relatedEntityId : relatedEntityId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppNotification].
extension AppNotificationPatterns on AppNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotification value)  $default,){
final _that = this;
switch (_that) {
case _AppNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotification value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'recipient_scope')  String recipientScope,  NotificationType type,  NotificationCategory category,  String title,  String body, @JsonKey(name: 'deep_link')  String? deepLink, @JsonKey(name: 'related_entity_id')  String? relatedEntityId, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'read_at')  String? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.notificationId,_that.recipientScope,_that.type,_that.category,_that.title,_that.body,_that.deepLink,_that.relatedEntityId,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'recipient_scope')  String recipientScope,  NotificationType type,  NotificationCategory category,  String title,  String body, @JsonKey(name: 'deep_link')  String? deepLink, @JsonKey(name: 'related_entity_id')  String? relatedEntityId, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'read_at')  String? readAt)  $default,) {final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that.notificationId,_that.recipientScope,_that.type,_that.category,_that.title,_that.body,_that.deepLink,_that.relatedEntityId,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'notification_id')  String notificationId, @JsonKey(name: 'recipient_scope')  String recipientScope,  NotificationType type,  NotificationCategory category,  String title,  String body, @JsonKey(name: 'deep_link')  String? deepLink, @JsonKey(name: 'related_entity_id')  String? relatedEntityId, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'read_at')  String? readAt)?  $default,) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.notificationId,_that.recipientScope,_that.type,_that.category,_that.title,_that.body,_that.deepLink,_that.relatedEntityId,_that.createdAt,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppNotification implements AppNotification {
  const _AppNotification({@JsonKey(name: 'notification_id') required this.notificationId, @JsonKey(name: 'recipient_scope') required this.recipientScope, required this.type, required this.category, required this.title, required this.body, @JsonKey(name: 'deep_link') this.deepLink, @JsonKey(name: 'related_entity_id') this.relatedEntityId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'read_at') this.readAt});
  factory _AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

@override@JsonKey(name: 'notification_id') final  String notificationId;
@override@JsonKey(name: 'recipient_scope') final  String recipientScope;
@override final  NotificationType type;
@override final  NotificationCategory category;
@override final  String title;
@override final  String body;
@override@JsonKey(name: 'deep_link') final  String? deepLink;
@override@JsonKey(name: 'related_entity_id') final  String? relatedEntityId;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'read_at') final  String? readAt;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationCopyWith<_AppNotification> get copyWith => __$AppNotificationCopyWithImpl<_AppNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotification&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.recipientScope, recipientScope) || other.recipientScope == recipientScope)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&(identical(other.relatedEntityId, relatedEntityId) || other.relatedEntityId == relatedEntityId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationId,recipientScope,type,category,title,body,deepLink,relatedEntityId,createdAt,readAt);

@override
String toString() {
  return 'AppNotification(notificationId: $notificationId, recipientScope: $recipientScope, type: $type, category: $category, title: $title, body: $body, deepLink: $deepLink, relatedEntityId: $relatedEntityId, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationCopyWith<$Res> implements $AppNotificationCopyWith<$Res> {
  factory _$AppNotificationCopyWith(_AppNotification value, $Res Function(_AppNotification) _then) = __$AppNotificationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'notification_id') String notificationId,@JsonKey(name: 'recipient_scope') String recipientScope, NotificationType type, NotificationCategory category, String title, String body,@JsonKey(name: 'deep_link') String? deepLink,@JsonKey(name: 'related_entity_id') String? relatedEntityId,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'read_at') String? readAt
});




}
/// @nodoc
class __$AppNotificationCopyWithImpl<$Res>
    implements _$AppNotificationCopyWith<$Res> {
  __$AppNotificationCopyWithImpl(this._self, this._then);

  final _AppNotification _self;
  final $Res Function(_AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notificationId = null,Object? recipientScope = null,Object? type = null,Object? category = null,Object? title = null,Object? body = null,Object? deepLink = freezed,Object? relatedEntityId = freezed,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_AppNotification(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,recipientScope: null == recipientScope ? _self.recipientScope : recipientScope // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NotificationCategory,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,relatedEntityId: freezed == relatedEntityId ? _self.relatedEntityId : relatedEntityId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
