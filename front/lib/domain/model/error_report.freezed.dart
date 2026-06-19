// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ErrorReport {

@JsonKey(name: 'error_report_id') String get errorReportId;@JsonKey(name: 'error_message') String get errorMessage;// ISO-8601 instant string, e.g. "2026-06-09T12:00:00Z".
@JsonKey(name: 'reported_at') String get reportedAt;
/// Create a copy of ErrorReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorReportCopyWith<ErrorReport> get copyWith => _$ErrorReportCopyWithImpl<ErrorReport>(this as ErrorReport, _$identity);

  /// Serializes this ErrorReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorReport&&(identical(other.errorReportId, errorReportId) || other.errorReportId == errorReportId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,errorReportId,errorMessage,reportedAt);

@override
String toString() {
  return 'ErrorReport(errorReportId: $errorReportId, errorMessage: $errorMessage, reportedAt: $reportedAt)';
}


}

/// @nodoc
abstract mixin class $ErrorReportCopyWith<$Res>  {
  factory $ErrorReportCopyWith(ErrorReport value, $Res Function(ErrorReport) _then) = _$ErrorReportCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'error_report_id') String errorReportId,@JsonKey(name: 'error_message') String errorMessage,@JsonKey(name: 'reported_at') String reportedAt
});




}
/// @nodoc
class _$ErrorReportCopyWithImpl<$Res>
    implements $ErrorReportCopyWith<$Res> {
  _$ErrorReportCopyWithImpl(this._self, this._then);

  final ErrorReport _self;
  final $Res Function(ErrorReport) _then;

/// Create a copy of ErrorReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? errorReportId = null,Object? errorMessage = null,Object? reportedAt = null,}) {
  return _then(_self.copyWith(
errorReportId: null == errorReportId ? _self.errorReportId : errorReportId // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,reportedAt: null == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ErrorReport].
extension ErrorReportPatterns on ErrorReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorReport value)  $default,){
final _that = this;
switch (_that) {
case _ErrorReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorReport value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'error_report_id')  String errorReportId, @JsonKey(name: 'error_message')  String errorMessage, @JsonKey(name: 'reported_at')  String reportedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorReport() when $default != null:
return $default(_that.errorReportId,_that.errorMessage,_that.reportedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'error_report_id')  String errorReportId, @JsonKey(name: 'error_message')  String errorMessage, @JsonKey(name: 'reported_at')  String reportedAt)  $default,) {final _that = this;
switch (_that) {
case _ErrorReport():
return $default(_that.errorReportId,_that.errorMessage,_that.reportedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'error_report_id')  String errorReportId, @JsonKey(name: 'error_message')  String errorMessage, @JsonKey(name: 'reported_at')  String reportedAt)?  $default,) {final _that = this;
switch (_that) {
case _ErrorReport() when $default != null:
return $default(_that.errorReportId,_that.errorMessage,_that.reportedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorReport implements ErrorReport {
  const _ErrorReport({@JsonKey(name: 'error_report_id') required this.errorReportId, @JsonKey(name: 'error_message') required this.errorMessage, @JsonKey(name: 'reported_at') required this.reportedAt});
  factory _ErrorReport.fromJson(Map<String, dynamic> json) => _$ErrorReportFromJson(json);

@override@JsonKey(name: 'error_report_id') final  String errorReportId;
@override@JsonKey(name: 'error_message') final  String errorMessage;
// ISO-8601 instant string, e.g. "2026-06-09T12:00:00Z".
@override@JsonKey(name: 'reported_at') final  String reportedAt;

/// Create a copy of ErrorReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorReportCopyWith<_ErrorReport> get copyWith => __$ErrorReportCopyWithImpl<_ErrorReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorReport&&(identical(other.errorReportId, errorReportId) || other.errorReportId == errorReportId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,errorReportId,errorMessage,reportedAt);

@override
String toString() {
  return 'ErrorReport(errorReportId: $errorReportId, errorMessage: $errorMessage, reportedAt: $reportedAt)';
}


}

/// @nodoc
abstract mixin class _$ErrorReportCopyWith<$Res> implements $ErrorReportCopyWith<$Res> {
  factory _$ErrorReportCopyWith(_ErrorReport value, $Res Function(_ErrorReport) _then) = __$ErrorReportCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'error_report_id') String errorReportId,@JsonKey(name: 'error_message') String errorMessage,@JsonKey(name: 'reported_at') String reportedAt
});




}
/// @nodoc
class __$ErrorReportCopyWithImpl<$Res>
    implements _$ErrorReportCopyWith<$Res> {
  __$ErrorReportCopyWithImpl(this._self, this._then);

  final _ErrorReport _self;
  final $Res Function(_ErrorReport) _then;

/// Create a copy of ErrorReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? errorReportId = null,Object? errorMessage = null,Object? reportedAt = null,}) {
  return _then(_ErrorReport(
errorReportId: null == errorReportId ? _self.errorReportId : errorReportId // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,reportedAt: null == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
