// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_types_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemTypesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ItemTypesState()';
}


}

/// @nodoc
class $ItemTypesStateCopyWith<$Res>  {
$ItemTypesStateCopyWith(ItemTypesState _, $Res Function(ItemTypesState) __);
}


/// Adds pattern-matching-related methods to [ItemTypesState].
extension ItemTypesStatePatterns on ItemTypesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ItemTypesInitial value)?  initial,TResult Function( ItemTypesLoaded value)?  loaded,TResult Function( ItemTypesSaving value)?  saving,TResult Function( ItemTypesSaved value)?  saved,TResult Function( ItemTypesError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ItemTypesInitial() when initial != null:
return initial(_that);case ItemTypesLoaded() when loaded != null:
return loaded(_that);case ItemTypesSaving() when saving != null:
return saving(_that);case ItemTypesSaved() when saved != null:
return saved(_that);case ItemTypesError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ItemTypesInitial value)  initial,required TResult Function( ItemTypesLoaded value)  loaded,required TResult Function( ItemTypesSaving value)  saving,required TResult Function( ItemTypesSaved value)  saved,required TResult Function( ItemTypesError value)  error,}){
final _that = this;
switch (_that) {
case ItemTypesInitial():
return initial(_that);case ItemTypesLoaded():
return loaded(_that);case ItemTypesSaving():
return saving(_that);case ItemTypesSaved():
return saved(_that);case ItemTypesError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ItemTypesInitial value)?  initial,TResult? Function( ItemTypesLoaded value)?  loaded,TResult? Function( ItemTypesSaving value)?  saving,TResult? Function( ItemTypesSaved value)?  saved,TResult? Function( ItemTypesError value)?  error,}){
final _that = this;
switch (_that) {
case ItemTypesInitial() when initial != null:
return initial(_that);case ItemTypesLoaded() when loaded != null:
return loaded(_that);case ItemTypesSaving() when saving != null:
return saving(_that);case ItemTypesSaved() when saved != null:
return saved(_that);case ItemTypesError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( ProductType productType)?  loaded,TResult Function( ProductType productType)?  saving,TResult Function( ProductType productType)?  saved,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ItemTypesInitial() when initial != null:
return initial();case ItemTypesLoaded() when loaded != null:
return loaded(_that.productType);case ItemTypesSaving() when saving != null:
return saving(_that.productType);case ItemTypesSaved() when saved != null:
return saved(_that.productType);case ItemTypesError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( ProductType productType)  loaded,required TResult Function( ProductType productType)  saving,required TResult Function( ProductType productType)  saved,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ItemTypesInitial():
return initial();case ItemTypesLoaded():
return loaded(_that.productType);case ItemTypesSaving():
return saving(_that.productType);case ItemTypesSaved():
return saved(_that.productType);case ItemTypesError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( ProductType productType)?  loaded,TResult? Function( ProductType productType)?  saving,TResult? Function( ProductType productType)?  saved,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ItemTypesInitial() when initial != null:
return initial();case ItemTypesLoaded() when loaded != null:
return loaded(_that.productType);case ItemTypesSaving() when saving != null:
return saving(_that.productType);case ItemTypesSaved() when saved != null:
return saved(_that.productType);case ItemTypesError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ItemTypesInitial implements ItemTypesState {
  const ItemTypesInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ItemTypesState.initial()';
}


}




/// @nodoc


class ItemTypesLoaded implements ItemTypesState {
  const ItemTypesLoaded({required this.productType});
  

 final  ProductType productType;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypesLoadedCopyWith<ItemTypesLoaded> get copyWith => _$ItemTypesLoadedCopyWithImpl<ItemTypesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesLoaded&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hash(runtimeType,productType);

@override
String toString() {
  return 'ItemTypesState.loaded(productType: $productType)';
}


}

/// @nodoc
abstract mixin class $ItemTypesLoadedCopyWith<$Res> implements $ItemTypesStateCopyWith<$Res> {
  factory $ItemTypesLoadedCopyWith(ItemTypesLoaded value, $Res Function(ItemTypesLoaded) _then) = _$ItemTypesLoadedCopyWithImpl;
@useResult
$Res call({
 ProductType productType
});


$ProductTypeCopyWith<$Res> get productType;

}
/// @nodoc
class _$ItemTypesLoadedCopyWithImpl<$Res>
    implements $ItemTypesLoadedCopyWith<$Res> {
  _$ItemTypesLoadedCopyWithImpl(this._self, this._then);

  final ItemTypesLoaded _self;
  final $Res Function(ItemTypesLoaded) _then;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productType = null,}) {
  return _then(ItemTypesLoaded(
productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductTypeCopyWith<$Res> get productType {
  
  return $ProductTypeCopyWith<$Res>(_self.productType, (value) {
    return _then(_self.copyWith(productType: value));
  });
}
}

/// @nodoc


class ItemTypesSaving implements ItemTypesState {
  const ItemTypesSaving({required this.productType});
  

 final  ProductType productType;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypesSavingCopyWith<ItemTypesSaving> get copyWith => _$ItemTypesSavingCopyWithImpl<ItemTypesSaving>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesSaving&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hash(runtimeType,productType);

@override
String toString() {
  return 'ItemTypesState.saving(productType: $productType)';
}


}

/// @nodoc
abstract mixin class $ItemTypesSavingCopyWith<$Res> implements $ItemTypesStateCopyWith<$Res> {
  factory $ItemTypesSavingCopyWith(ItemTypesSaving value, $Res Function(ItemTypesSaving) _then) = _$ItemTypesSavingCopyWithImpl;
@useResult
$Res call({
 ProductType productType
});


$ProductTypeCopyWith<$Res> get productType;

}
/// @nodoc
class _$ItemTypesSavingCopyWithImpl<$Res>
    implements $ItemTypesSavingCopyWith<$Res> {
  _$ItemTypesSavingCopyWithImpl(this._self, this._then);

  final ItemTypesSaving _self;
  final $Res Function(ItemTypesSaving) _then;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productType = null,}) {
  return _then(ItemTypesSaving(
productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductTypeCopyWith<$Res> get productType {
  
  return $ProductTypeCopyWith<$Res>(_self.productType, (value) {
    return _then(_self.copyWith(productType: value));
  });
}
}

/// @nodoc


class ItemTypesSaved implements ItemTypesState {
  const ItemTypesSaved({required this.productType});
  

 final  ProductType productType;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypesSavedCopyWith<ItemTypesSaved> get copyWith => _$ItemTypesSavedCopyWithImpl<ItemTypesSaved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesSaved&&(identical(other.productType, productType) || other.productType == productType));
}


@override
int get hashCode => Object.hash(runtimeType,productType);

@override
String toString() {
  return 'ItemTypesState.saved(productType: $productType)';
}


}

/// @nodoc
abstract mixin class $ItemTypesSavedCopyWith<$Res> implements $ItemTypesStateCopyWith<$Res> {
  factory $ItemTypesSavedCopyWith(ItemTypesSaved value, $Res Function(ItemTypesSaved) _then) = _$ItemTypesSavedCopyWithImpl;
@useResult
$Res call({
 ProductType productType
});


$ProductTypeCopyWith<$Res> get productType;

}
/// @nodoc
class _$ItemTypesSavedCopyWithImpl<$Res>
    implements $ItemTypesSavedCopyWith<$Res> {
  _$ItemTypesSavedCopyWithImpl(this._self, this._then);

  final ItemTypesSaved _self;
  final $Res Function(ItemTypesSaved) _then;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productType = null,}) {
  return _then(ItemTypesSaved(
productType: null == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductTypeCopyWith<$Res> get productType {
  
  return $ProductTypeCopyWith<$Res>(_self.productType, (value) {
    return _then(_self.copyWith(productType: value));
  });
}
}

/// @nodoc


class ItemTypesError implements ItemTypesState {
  const ItemTypesError({required this.message});
  

 final  String message;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTypesErrorCopyWith<ItemTypesError> get copyWith => _$ItemTypesErrorCopyWithImpl<ItemTypesError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTypesError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ItemTypesState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ItemTypesErrorCopyWith<$Res> implements $ItemTypesStateCopyWith<$Res> {
  factory $ItemTypesErrorCopyWith(ItemTypesError value, $Res Function(ItemTypesError) _then) = _$ItemTypesErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ItemTypesErrorCopyWithImpl<$Res>
    implements $ItemTypesErrorCopyWith<$Res> {
  _$ItemTypesErrorCopyWithImpl(this._self, this._then);

  final ItemTypesError _self;
  final $Res Function(ItemTypesError) _then;

/// Create a copy of ItemTypesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ItemTypesError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
