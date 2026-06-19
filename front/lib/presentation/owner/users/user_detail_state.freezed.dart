// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailState()';
}


}

/// @nodoc
class $UserDetailStateCopyWith<$Res>  {
$UserDetailStateCopyWith(UserDetailState _, $Res Function(UserDetailState) __);
}


/// Adds pattern-matching-related methods to [UserDetailState].
extension UserDetailStatePatterns on UserDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserDetailInitial value)?  initial,TResult Function( UserDetailLoading value)?  loading,TResult Function( UserDetailLoaded value)?  loaded,TResult Function( UserDetailNotFound value)?  notFound,TResult Function( UserDetailError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserDetailInitial() when initial != null:
return initial(_that);case UserDetailLoading() when loading != null:
return loading(_that);case UserDetailLoaded() when loaded != null:
return loaded(_that);case UserDetailNotFound() when notFound != null:
return notFound(_that);case UserDetailError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserDetailInitial value)  initial,required TResult Function( UserDetailLoading value)  loading,required TResult Function( UserDetailLoaded value)  loaded,required TResult Function( UserDetailNotFound value)  notFound,required TResult Function( UserDetailError value)  error,}){
final _that = this;
switch (_that) {
case UserDetailInitial():
return initial(_that);case UserDetailLoading():
return loading(_that);case UserDetailLoaded():
return loaded(_that);case UserDetailNotFound():
return notFound(_that);case UserDetailError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserDetailInitial value)?  initial,TResult? Function( UserDetailLoading value)?  loading,TResult? Function( UserDetailLoaded value)?  loaded,TResult? Function( UserDetailNotFound value)?  notFound,TResult? Function( UserDetailError value)?  error,}){
final _that = this;
switch (_that) {
case UserDetailInitial() when initial != null:
return initial(_that);case UserDetailLoading() when loading != null:
return loading(_that);case UserDetailLoaded() when loaded != null:
return loaded(_that);case UserDetailNotFound() when notFound != null:
return notFound(_that);case UserDetailError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( UserRow userRow)?  loaded,TResult Function()?  notFound,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserDetailInitial() when initial != null:
return initial();case UserDetailLoading() when loading != null:
return loading();case UserDetailLoaded() when loaded != null:
return loaded(_that.userRow);case UserDetailNotFound() when notFound != null:
return notFound();case UserDetailError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( UserRow userRow)  loaded,required TResult Function()  notFound,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case UserDetailInitial():
return initial();case UserDetailLoading():
return loading();case UserDetailLoaded():
return loaded(_that.userRow);case UserDetailNotFound():
return notFound();case UserDetailError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( UserRow userRow)?  loaded,TResult? Function()?  notFound,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case UserDetailInitial() when initial != null:
return initial();case UserDetailLoading() when loading != null:
return loading();case UserDetailLoaded() when loaded != null:
return loaded(_that.userRow);case UserDetailNotFound() when notFound != null:
return notFound();case UserDetailError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class UserDetailInitial implements UserDetailState {
  const UserDetailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailState.initial()';
}


}




/// @nodoc


class UserDetailLoading implements UserDetailState {
  const UserDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailState.loading()';
}


}




/// @nodoc


class UserDetailLoaded implements UserDetailState {
  const UserDetailLoaded({required this.userRow});
  

 final  UserRow userRow;

/// Create a copy of UserDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailLoadedCopyWith<UserDetailLoaded> get copyWith => _$UserDetailLoadedCopyWithImpl<UserDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailLoaded&&(identical(other.userRow, userRow) || other.userRow == userRow));
}


@override
int get hashCode => Object.hash(runtimeType,userRow);

@override
String toString() {
  return 'UserDetailState.loaded(userRow: $userRow)';
}


}

/// @nodoc
abstract mixin class $UserDetailLoadedCopyWith<$Res> implements $UserDetailStateCopyWith<$Res> {
  factory $UserDetailLoadedCopyWith(UserDetailLoaded value, $Res Function(UserDetailLoaded) _then) = _$UserDetailLoadedCopyWithImpl;
@useResult
$Res call({
 UserRow userRow
});




}
/// @nodoc
class _$UserDetailLoadedCopyWithImpl<$Res>
    implements $UserDetailLoadedCopyWith<$Res> {
  _$UserDetailLoadedCopyWithImpl(this._self, this._then);

  final UserDetailLoaded _self;
  final $Res Function(UserDetailLoaded) _then;

/// Create a copy of UserDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userRow = null,}) {
  return _then(UserDetailLoaded(
userRow: null == userRow ? _self.userRow : userRow // ignore: cast_nullable_to_non_nullable
as UserRow,
  ));
}


}

/// @nodoc


class UserDetailNotFound implements UserDetailState {
  const UserDetailNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailState.notFound()';
}


}




/// @nodoc


class UserDetailError implements UserDetailState {
  const UserDetailError(this.message);
  

 final  String message;

/// Create a copy of UserDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailErrorCopyWith<UserDetailError> get copyWith => _$UserDetailErrorCopyWithImpl<UserDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'UserDetailState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $UserDetailErrorCopyWith<$Res> implements $UserDetailStateCopyWith<$Res> {
  factory $UserDetailErrorCopyWith(UserDetailError value, $Res Function(UserDetailError) _then) = _$UserDetailErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UserDetailErrorCopyWithImpl<$Res>
    implements $UserDetailErrorCopyWith<$Res> {
  _$UserDetailErrorCopyWithImpl(this._self, this._then);

  final UserDetailError _self;
  final $Res Function(UserDetailError) _then;

/// Create a copy of UserDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UserDetailError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
