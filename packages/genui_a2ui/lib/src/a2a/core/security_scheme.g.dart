// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore

part of 'security_scheme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIKeySecurityScheme _$APIKeySecuritySchemeFromJson(
  Map<String, dynamic> json,
) => APIKeySecurityScheme(
  type: json['type'] as String? ?? 'apiKey',
  description: json['description'] as String?,
  name: json['name'] as String,
  in_: json['in'] as String,
);

Map<String, dynamic> _$APIKeySecuritySchemeToJson(
  APIKeySecurityScheme instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
  'name': instance.name,
  'in': instance.in_,
};

HttpAuthSecurityScheme _$HttpAuthSecuritySchemeFromJson(
  Map<String, dynamic> json,
) => HttpAuthSecurityScheme(
  type: json['type'] as String? ?? 'http',
  description: json['description'] as String?,
  scheme: json['scheme'] as String,
  bearerFormat: json['bearerFormat'] as String?,
);

Map<String, dynamic> _$HttpAuthSecuritySchemeToJson(
  HttpAuthSecurityScheme instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
  'scheme': instance.scheme,
  'bearerFormat': instance.bearerFormat,
};

OAuth2SecurityScheme _$OAuth2SecuritySchemeFromJson(
  Map<String, dynamic> json,
) => OAuth2SecurityScheme(
  type: json['type'] as String? ?? 'oauth2',
  description: json['description'] as String?,
  flows: OAuthFlows.fromJson(json['flows'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OAuth2SecuritySchemeToJson(
  OAuth2SecurityScheme instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
  'flows': instance.flows.toJson(),
};

OpenIdConnectSecurityScheme _$OpenIdConnectSecuritySchemeFromJson(
  Map<String, dynamic> json,
) => OpenIdConnectSecurityScheme(
  type: json['type'] as String? ?? 'openIdConnect',
  description: json['description'] as String?,
  openIdConnectUrl: json['openIdConnectUrl'] as String,
);

Map<String, dynamic> _$OpenIdConnectSecuritySchemeToJson(
  OpenIdConnectSecurityScheme instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
  'openIdConnectUrl': instance.openIdConnectUrl,
};

MutualTlsSecurityScheme _$MutualTlsSecuritySchemeFromJson(
  Map<String, dynamic> json,
) => MutualTlsSecurityScheme(
  type: json['type'] as String? ?? 'mutualTls',
  description: json['description'] as String?,
);

Map<String, dynamic> _$MutualTlsSecuritySchemeToJson(
  MutualTlsSecurityScheme instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
};

_OAuthFlows _$OAuthFlowsFromJson(Map<String, dynamic> json) => _OAuthFlows(
  implicit: json['implicit'] == null
      ? null
      : OAuthFlow.fromJson(json['implicit'] as Map<String, dynamic>),
  password: json['password'] == null
      ? null
      : OAuthFlow.fromJson(json['password'] as Map<String, dynamic>),
  clientCredentials: json['clientCredentials'] == null
      ? null
      : OAuthFlow.fromJson(json['clientCredentials'] as Map<String, dynamic>),
  authorizationCode: json['authorizationCode'] == null
      ? null
      : OAuthFlow.fromJson(json['authorizationCode'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OAuthFlowsToJson(_OAuthFlows instance) =>
    <String, dynamic>{
      'implicit': instance.implicit?.toJson(),
      'password': instance.password?.toJson(),
      'clientCredentials': instance.clientCredentials?.toJson(),
      'authorizationCode': instance.authorizationCode?.toJson(),
    };

_OAuthFlow _$OAuthFlowFromJson(Map<String, dynamic> json) => _OAuthFlow(
  authorizationUrl: json['authorizationUrl'] as String?,
  tokenUrl: json['tokenUrl'] as String?,
  refreshUrl: json['refreshUrl'] as String?,
  scopes: Map<String, String>.from(json['scopes'] as Map),
);

Map<String, dynamic> _$OAuthFlowToJson(_OAuthFlow instance) =>
    <String, dynamic>{
      'authorizationUrl': instance.authorizationUrl,
      'tokenUrl': instance.tokenUrl,
      'refreshUrl': instance.refreshUrl,
      'scopes': instance.scopes,
    };
