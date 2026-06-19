// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_template_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveryTemplateEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplateEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryTemplateEvent()';
}


}

/// @nodoc
class $DeliveryTemplateEventCopyWith<$Res>  {
$DeliveryTemplateEventCopyWith(DeliveryTemplateEvent _, $Res Function(DeliveryTemplateEvent) __);
}


/// Adds pattern-matching-related methods to [DeliveryTemplateEvent].
extension DeliveryTemplateEventPatterns on DeliveryTemplateEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadTemplates value)?  loadTemplates,TResult Function( _CreateTemplate value)?  createTemplate,TResult Function( _UpdateTemplate value)?  updateTemplate,TResult Function( _DeleteTemplate value)?  deleteTemplate,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadTemplates() when loadTemplates != null:
return loadTemplates(_that);case _CreateTemplate() when createTemplate != null:
return createTemplate(_that);case _UpdateTemplate() when updateTemplate != null:
return updateTemplate(_that);case _DeleteTemplate() when deleteTemplate != null:
return deleteTemplate(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadTemplates value)  loadTemplates,required TResult Function( _CreateTemplate value)  createTemplate,required TResult Function( _UpdateTemplate value)  updateTemplate,required TResult Function( _DeleteTemplate value)  deleteTemplate,}){
final _that = this;
switch (_that) {
case _LoadTemplates():
return loadTemplates(_that);case _CreateTemplate():
return createTemplate(_that);case _UpdateTemplate():
return updateTemplate(_that);case _DeleteTemplate():
return deleteTemplate(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadTemplates value)?  loadTemplates,TResult? Function( _CreateTemplate value)?  createTemplate,TResult? Function( _UpdateTemplate value)?  updateTemplate,TResult? Function( _DeleteTemplate value)?  deleteTemplate,}){
final _that = this;
switch (_that) {
case _LoadTemplates() when loadTemplates != null:
return loadTemplates(_that);case _CreateTemplate() when createTemplate != null:
return createTemplate(_that);case _UpdateTemplate() when updateTemplate != null:
return updateTemplate(_that);case _DeleteTemplate() when deleteTemplate != null:
return deleteTemplate(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadTemplates,TResult Function( DeliveryTemplate template)?  createTemplate,TResult Function( DeliveryTemplate template)?  updateTemplate,TResult Function( String templateId,  String organizationId)?  deleteTemplate,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadTemplates() when loadTemplates != null:
return loadTemplates();case _CreateTemplate() when createTemplate != null:
return createTemplate(_that.template);case _UpdateTemplate() when updateTemplate != null:
return updateTemplate(_that.template);case _DeleteTemplate() when deleteTemplate != null:
return deleteTemplate(_that.templateId,_that.organizationId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadTemplates,required TResult Function( DeliveryTemplate template)  createTemplate,required TResult Function( DeliveryTemplate template)  updateTemplate,required TResult Function( String templateId,  String organizationId)  deleteTemplate,}) {final _that = this;
switch (_that) {
case _LoadTemplates():
return loadTemplates();case _CreateTemplate():
return createTemplate(_that.template);case _UpdateTemplate():
return updateTemplate(_that.template);case _DeleteTemplate():
return deleteTemplate(_that.templateId,_that.organizationId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadTemplates,TResult? Function( DeliveryTemplate template)?  createTemplate,TResult? Function( DeliveryTemplate template)?  updateTemplate,TResult? Function( String templateId,  String organizationId)?  deleteTemplate,}) {final _that = this;
switch (_that) {
case _LoadTemplates() when loadTemplates != null:
return loadTemplates();case _CreateTemplate() when createTemplate != null:
return createTemplate(_that.template);case _UpdateTemplate() when updateTemplate != null:
return updateTemplate(_that.template);case _DeleteTemplate() when deleteTemplate != null:
return deleteTemplate(_that.templateId,_that.organizationId);case _:
  return null;

}
}

}

/// @nodoc


class _LoadTemplates implements DeliveryTemplateEvent {
  const _LoadTemplates();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadTemplates);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryTemplateEvent.loadTemplates()';
}


}




/// @nodoc


class _CreateTemplate implements DeliveryTemplateEvent {
  const _CreateTemplate(this.template);
  

 final  DeliveryTemplate template;

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTemplateCopyWith<_CreateTemplate> get copyWith => __$CreateTemplateCopyWithImpl<_CreateTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTemplate&&(identical(other.template, template) || other.template == template));
}


@override
int get hashCode => Object.hash(runtimeType,template);

@override
String toString() {
  return 'DeliveryTemplateEvent.createTemplate(template: $template)';
}


}

/// @nodoc
abstract mixin class _$CreateTemplateCopyWith<$Res> implements $DeliveryTemplateEventCopyWith<$Res> {
  factory _$CreateTemplateCopyWith(_CreateTemplate value, $Res Function(_CreateTemplate) _then) = __$CreateTemplateCopyWithImpl;
@useResult
$Res call({
 DeliveryTemplate template
});


$DeliveryTemplateCopyWith<$Res> get template;

}
/// @nodoc
class __$CreateTemplateCopyWithImpl<$Res>
    implements _$CreateTemplateCopyWith<$Res> {
  __$CreateTemplateCopyWithImpl(this._self, this._then);

  final _CreateTemplate _self;
  final $Res Function(_CreateTemplate) _then;

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? template = null,}) {
  return _then(_CreateTemplate(
null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as DeliveryTemplate,
  ));
}

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryTemplateCopyWith<$Res> get template {
  
  return $DeliveryTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}

/// @nodoc


class _UpdateTemplate implements DeliveryTemplateEvent {
  const _UpdateTemplate(this.template);
  

 final  DeliveryTemplate template;

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateTemplateCopyWith<_UpdateTemplate> get copyWith => __$UpdateTemplateCopyWithImpl<_UpdateTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateTemplate&&(identical(other.template, template) || other.template == template));
}


@override
int get hashCode => Object.hash(runtimeType,template);

@override
String toString() {
  return 'DeliveryTemplateEvent.updateTemplate(template: $template)';
}


}

/// @nodoc
abstract mixin class _$UpdateTemplateCopyWith<$Res> implements $DeliveryTemplateEventCopyWith<$Res> {
  factory _$UpdateTemplateCopyWith(_UpdateTemplate value, $Res Function(_UpdateTemplate) _then) = __$UpdateTemplateCopyWithImpl;
@useResult
$Res call({
 DeliveryTemplate template
});


$DeliveryTemplateCopyWith<$Res> get template;

}
/// @nodoc
class __$UpdateTemplateCopyWithImpl<$Res>
    implements _$UpdateTemplateCopyWith<$Res> {
  __$UpdateTemplateCopyWithImpl(this._self, this._then);

  final _UpdateTemplate _self;
  final $Res Function(_UpdateTemplate) _then;

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? template = null,}) {
  return _then(_UpdateTemplate(
null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as DeliveryTemplate,
  ));
}

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryTemplateCopyWith<$Res> get template {
  
  return $DeliveryTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}

/// @nodoc


class _DeleteTemplate implements DeliveryTemplateEvent {
  const _DeleteTemplate({required this.templateId, required this.organizationId});
  

 final  String templateId;
 final  String organizationId;

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteTemplateCopyWith<_DeleteTemplate> get copyWith => __$DeleteTemplateCopyWithImpl<_DeleteTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteTemplate&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode => Object.hash(runtimeType,templateId,organizationId);

@override
String toString() {
  return 'DeliveryTemplateEvent.deleteTemplate(templateId: $templateId, organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class _$DeleteTemplateCopyWith<$Res> implements $DeliveryTemplateEventCopyWith<$Res> {
  factory _$DeleteTemplateCopyWith(_DeleteTemplate value, $Res Function(_DeleteTemplate) _then) = __$DeleteTemplateCopyWithImpl;
@useResult
$Res call({
 String templateId, String organizationId
});




}
/// @nodoc
class __$DeleteTemplateCopyWithImpl<$Res>
    implements _$DeleteTemplateCopyWith<$Res> {
  __$DeleteTemplateCopyWithImpl(this._self, this._then);

  final _DeleteTemplate _self;
  final $Res Function(_DeleteTemplate) _then;

/// Create a copy of DeliveryTemplateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? templateId = null,Object? organizationId = null,}) {
  return _then(_DeleteTemplate(
templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DeliveryTemplateState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplateState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryTemplateState()';
}


}

/// @nodoc
class $DeliveryTemplateStateCopyWith<$Res>  {
$DeliveryTemplateStateCopyWith(DeliveryTemplateState _, $Res Function(DeliveryTemplateState) __);
}


/// Adds pattern-matching-related methods to [DeliveryTemplateState].
extension DeliveryTemplateStatePatterns on DeliveryTemplateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeliveryTemplateInitial value)?  initial,TResult Function( DeliveryTemplateLoading value)?  loading,TResult Function( DeliveryTemplateLoaded value)?  loaded,TResult Function( DeliveryTemplateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeliveryTemplateInitial() when initial != null:
return initial(_that);case DeliveryTemplateLoading() when loading != null:
return loading(_that);case DeliveryTemplateLoaded() when loaded != null:
return loaded(_that);case DeliveryTemplateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeliveryTemplateInitial value)  initial,required TResult Function( DeliveryTemplateLoading value)  loading,required TResult Function( DeliveryTemplateLoaded value)  loaded,required TResult Function( DeliveryTemplateError value)  error,}){
final _that = this;
switch (_that) {
case DeliveryTemplateInitial():
return initial(_that);case DeliveryTemplateLoading():
return loading(_that);case DeliveryTemplateLoaded():
return loaded(_that);case DeliveryTemplateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeliveryTemplateInitial value)?  initial,TResult? Function( DeliveryTemplateLoading value)?  loading,TResult? Function( DeliveryTemplateLoaded value)?  loaded,TResult? Function( DeliveryTemplateError value)?  error,}){
final _that = this;
switch (_that) {
case DeliveryTemplateInitial() when initial != null:
return initial(_that);case DeliveryTemplateLoading() when loading != null:
return loading(_that);case DeliveryTemplateLoaded() when loaded != null:
return loaded(_that);case DeliveryTemplateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<DeliveryTemplate> templates)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeliveryTemplateInitial() when initial != null:
return initial();case DeliveryTemplateLoading() when loading != null:
return loading();case DeliveryTemplateLoaded() when loaded != null:
return loaded(_that.templates);case DeliveryTemplateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<DeliveryTemplate> templates)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case DeliveryTemplateInitial():
return initial();case DeliveryTemplateLoading():
return loading();case DeliveryTemplateLoaded():
return loaded(_that.templates);case DeliveryTemplateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<DeliveryTemplate> templates)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case DeliveryTemplateInitial() when initial != null:
return initial();case DeliveryTemplateLoading() when loading != null:
return loading();case DeliveryTemplateLoaded() when loaded != null:
return loaded(_that.templates);case DeliveryTemplateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class DeliveryTemplateInitial implements DeliveryTemplateState {
  const DeliveryTemplateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryTemplateState.initial()';
}


}




/// @nodoc


class DeliveryTemplateLoading implements DeliveryTemplateState {
  const DeliveryTemplateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryTemplateState.loading()';
}


}




/// @nodoc


class DeliveryTemplateLoaded implements DeliveryTemplateState {
  const DeliveryTemplateLoaded(final  List<DeliveryTemplate> templates): _templates = templates;
  

 final  List<DeliveryTemplate> _templates;
 List<DeliveryTemplate> get templates {
  if (_templates is EqualUnmodifiableListView) return _templates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_templates);
}


/// Create a copy of DeliveryTemplateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryTemplateLoadedCopyWith<DeliveryTemplateLoaded> get copyWith => _$DeliveryTemplateLoadedCopyWithImpl<DeliveryTemplateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplateLoaded&&const DeepCollectionEquality().equals(other._templates, _templates));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_templates));

@override
String toString() {
  return 'DeliveryTemplateState.loaded(templates: $templates)';
}


}

/// @nodoc
abstract mixin class $DeliveryTemplateLoadedCopyWith<$Res> implements $DeliveryTemplateStateCopyWith<$Res> {
  factory $DeliveryTemplateLoadedCopyWith(DeliveryTemplateLoaded value, $Res Function(DeliveryTemplateLoaded) _then) = _$DeliveryTemplateLoadedCopyWithImpl;
@useResult
$Res call({
 List<DeliveryTemplate> templates
});




}
/// @nodoc
class _$DeliveryTemplateLoadedCopyWithImpl<$Res>
    implements $DeliveryTemplateLoadedCopyWith<$Res> {
  _$DeliveryTemplateLoadedCopyWithImpl(this._self, this._then);

  final DeliveryTemplateLoaded _self;
  final $Res Function(DeliveryTemplateLoaded) _then;

/// Create a copy of DeliveryTemplateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? templates = null,}) {
  return _then(DeliveryTemplateLoaded(
null == templates ? _self._templates : templates // ignore: cast_nullable_to_non_nullable
as List<DeliveryTemplate>,
  ));
}


}

/// @nodoc


class DeliveryTemplateError implements DeliveryTemplateState {
  const DeliveryTemplateError(this.message);
  

 final  String message;

/// Create a copy of DeliveryTemplateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryTemplateErrorCopyWith<DeliveryTemplateError> get copyWith => _$DeliveryTemplateErrorCopyWithImpl<DeliveryTemplateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryTemplateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DeliveryTemplateState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $DeliveryTemplateErrorCopyWith<$Res> implements $DeliveryTemplateStateCopyWith<$Res> {
  factory $DeliveryTemplateErrorCopyWith(DeliveryTemplateError value, $Res Function(DeliveryTemplateError) _then) = _$DeliveryTemplateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$DeliveryTemplateErrorCopyWithImpl<$Res>
    implements $DeliveryTemplateErrorCopyWith<$Res> {
  _$DeliveryTemplateErrorCopyWithImpl(this._self, this._then);

  final DeliveryTemplateError _self;
  final $Res Function(DeliveryTemplateError) _then;

/// Create a copy of DeliveryTemplateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(DeliveryTemplateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
