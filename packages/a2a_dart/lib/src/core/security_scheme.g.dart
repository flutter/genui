// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_scheme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIKeySecurityScheme _$APIKeySecuritySchemeFromJson(
  Map<String, Object?> json,
) => APIKeySecurityScheme(
  type: json['type'] as String? ?? 'apiKey',
  description: json['description'] as String?,
  name: json['name'] as String,
  in_: json['in'] as String,
);

Map<String, Object?> _$APIKeySecuritySchemeToJson(
  APIKeySecurityScheme instance,
) => <String, Object?>{
  'type': instance.type,
  'description': instance.description,
  'name': instance.name,
  'in': instance.in_,
};

HttpAuthSecurityScheme _$HttpAuthSecuritySchemeFromJson(
  Map<String, Object?> json,
) => HttpAuthSecurityScheme(
  type: json['type'] as String? ?? 'http',
  description: json['description'] as String?,
  scheme: json['scheme'] as String,
  bearerFormat: json['bearerFormat'] as String?,
);

Map<String, Object?> _$HttpAuthSecuritySchemeToJson(
  HttpAuthSecurityScheme instance,
) => <String, Object?>{
  'type': instance.type,
  'description': instance.description,
  'scheme': instance.scheme,
  'bearerFormat': instance.bearerFormat,
};

OAuth2SecurityScheme _$OAuth2SecuritySchemeFromJson(
  Map<String, Object?> json,
) => OAuth2SecurityScheme(
  type: json['type'] as String? ?? 'oauth2',
  description: json['description'] as String?,
  flows: OAuthFlows.fromJson(json['flows'] as Map<String, Object?>),
);

Map<String, Object?> _$OAuth2SecuritySchemeToJson(
  OAuth2SecurityScheme instance,
) => <String, Object?>{
  'type': instance.type,
  'description': instance.description,
  'flows': instance.flows.toJson(),
};

OpenIdConnectSecurityScheme _$OpenIdConnectSecuritySchemeFromJson(
  Map<String, Object?> json,
) => OpenIdConnectSecurityScheme(
  type: json['type'] as String? ?? 'openIdConnect',
  description: json['description'] as String?,
  openIdConnectUrl: json['openIdConnectUrl'] as String,
);

Map<String, Object?> _$OpenIdConnectSecuritySchemeToJson(
  OpenIdConnectSecurityScheme instance,
) => <String, Object?>{
  'type': instance.type,
  'description': instance.description,
  'openIdConnectUrl': instance.openIdConnectUrl,
};

MutualTlsSecurityScheme _$MutualTlsSecuritySchemeFromJson(
  Map<String, Object?> json,
) => MutualTlsSecurityScheme(
  type: json['type'] as String? ?? 'mutualTls',
  description: json['description'] as String?,
);

Map<String, Object?> _$MutualTlsSecuritySchemeToJson(
  MutualTlsSecurityScheme instance,
) => <String, Object?>{
  'type': instance.type,
  'description': instance.description,
};

_OAuthFlows _$OAuthFlowsFromJson(Map<String, Object?> json) => _OAuthFlows(
  implicit: json['implicit'] == null
      ? null
      : OAuthFlow.fromJson(json['implicit'] as Map<String, Object?>),
  password: json['password'] == null
      ? null
      : OAuthFlow.fromJson(json['password'] as Map<String, Object?>),
  clientCredentials: json['clientCredentials'] == null
      ? null
      : OAuthFlow.fromJson(json['clientCredentials'] as Map<String, Object?>),
  authorizationCode: json['authorizationCode'] == null
      ? null
      : OAuthFlow.fromJson(json['authorizationCode'] as Map<String, Object?>),
);

Map<String, Object?> _$OAuthFlowsToJson(_OAuthFlows instance) =>
    <String, Object?>{
      'implicit': instance.implicit?.toJson(),
      'password': instance.password?.toJson(),
      'clientCredentials': instance.clientCredentials?.toJson(),
      'authorizationCode': instance.authorizationCode?.toJson(),
    };

_OAuthFlow _$OAuthFlowFromJson(Map<String, Object?> json) => _OAuthFlow(
  authorizationUrl: json['authorizationUrl'] as String?,
  tokenUrl: json['tokenUrl'] as String?,
  refreshUrl: json['refreshUrl'] as String?,
  scopes: Map<String, String>.from(json['scopes'] as Map),
);

Map<String, Object?> _$OAuthFlowToJson(_OAuthFlow instance) =>
    <String, Object?>{
      'authorizationUrl': instance.authorizationUrl,
      'tokenUrl': instance.tokenUrl,
      'refreshUrl': instance.refreshUrl,
      'scopes': instance.scopes,
    };
