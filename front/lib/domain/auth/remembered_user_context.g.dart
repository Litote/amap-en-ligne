// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remembered_user_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RememberedUserContext _$RememberedUserContextFromJson(
  Map<String, dynamic> json,
) => _RememberedUserContext(
  email: json['email'] as String,
  serverId: json['serverId'] as String,
  rememberMe: json['rememberMe'] as bool,
);

Map<String, dynamic> _$RememberedUserContextToJson(
  _RememberedUserContext instance,
) => <String, dynamic>{
  'email': instance.email,
  'serverId': instance.serverId,
  'rememberMe': instance.rememberMe,
};
