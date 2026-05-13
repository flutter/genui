// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'security_scheme.g.dart';

// ignore_for_file: invalid_annotation_target

/// Defines a security scheme used to protect an agent's API endpoints.
///
/// This class is a Dart representation of the OpenAPI 3.0 Security Scheme
/// Object. It's a discriminated union based on the `type` field, allowing for
/// various authentication and authorization mechanisms.
sealed class SecurityScheme {
  /// The type discriminator.
  final String type;

  /// An optional description of the security scheme.
  final String? description;

  const SecurityScheme({required this.type, this.description});

  /// Deserializes a [SecurityScheme] instance from a JSON object.
  factory SecurityScheme.fromJson(Map<String, Object?> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'apiKey':
        return APIKeySecurityScheme.fromJson(json);
      case 'http':
        return HttpAuthSecurityScheme.fromJson(json);
      case 'oauth2':
        return OAuth2SecurityScheme.fromJson(json);
      case 'openIdConnect':
        return OpenIdConnectSecurityScheme.fromJson(json);
      case 'mutualTls':
        return MutualTlsSecurityScheme.fromJson(json);
      default:
        throw ArgumentError('Unknown SecurityScheme type: $type');
    }
  }

  /// Represents an API key-based security scheme.
  const factory SecurityScheme.apiKey({
    String? type,
    String? description,
    required String name,
    required String in_,
  }) = APIKeySecurityScheme;

  /// Represents an HTTP authentication scheme (e.g., Basic, Bearer).
  const factory SecurityScheme.http({
    String? type,
    String? description,
    required String scheme,
    String? bearerFormat,
  }) = HttpAuthSecurityScheme;

  /// Represents an OAuth 2.0 security scheme.
  const factory SecurityScheme.oauth2({
    String? type,
    String? description,
    required OAuthFlows flows,
  }) = OAuth2SecurityScheme;

  /// Represents an OpenID Connect security scheme.
  const factory SecurityScheme.openIdConnect({
    String? type,
    String? description,
    required String openIdConnectUrl,
  }) = OpenIdConnectSecurityScheme;

  /// Represents a mutual TLS authentication scheme.
  const factory SecurityScheme.mutualTls({String? type, String? description}) =
      MutualTlsSecurityScheme;

  /// Creates a JSON object from a [SecurityScheme].
  Map<String, Object?> toJson();
}

/// Represents an API key-based security scheme.
@JsonSerializable()
class APIKeySecurityScheme extends SecurityScheme {
  /// The name of the header, query, or cookie parameter used to transmit
  /// the API key.
  final String name;

  /// Specifies the location of the API key.
  ///
  /// Valid values are "query", "header", or "cookie".
  @JsonKey(name: 'in')
  final String in_;

  const APIKeySecurityScheme({
    String? type,
    super.description,
    required this.name,
    required this.in_,
  }) : super(type: type ?? 'apiKey');

  factory APIKeySecurityScheme.fromJson(Map<String, Object?> json) =>
      _$APIKeySecuritySchemeFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$APIKeySecuritySchemeToJson(this)..['type'] = 'apiKey';

  APIKeySecurityScheme copyWith({
    String? description,
    String? name,
    String? in_,
  }) {
    return APIKeySecurityScheme(
      description: description ?? this.description,
      name: name ?? this.name,
      in_: in_ ?? this.in_,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is APIKeySecurityScheme &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          name == other.name &&
          in_ == other.in_;

  @override
  int get hashCode => description.hashCode ^ name.hashCode ^ in_.hashCode;

  @override
  String toString() =>
      'APIKeySecurityScheme(description: $description, name: $name, in: $in_)';
}

/// Represents an HTTP authentication scheme (e.g., Basic, Bearer).
@JsonSerializable()
class HttpAuthSecurityScheme extends SecurityScheme {
  /// The name of the HTTP Authorization scheme, e.g., "Bearer", "Basic".
  final String scheme;

  /// An optional hint about the format of the bearer token (e.g., "JWT").
  final String? bearerFormat;

  const HttpAuthSecurityScheme({
    String? type,
    super.description,
    required this.scheme,
    this.bearerFormat,
  }) : super(type: type ?? 'http');

  factory HttpAuthSecurityScheme.fromJson(Map<String, Object?> json) =>
      _$HttpAuthSecuritySchemeFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$HttpAuthSecuritySchemeToJson(this)..['type'] = 'http';

  HttpAuthSecurityScheme copyWith({
    String? description,
    String? scheme,
    String? bearerFormat,
  }) {
    return HttpAuthSecurityScheme(
      description: description ?? this.description,
      scheme: scheme ?? this.scheme,
      bearerFormat: bearerFormat ?? this.bearerFormat,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HttpAuthSecurityScheme &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          scheme == other.scheme &&
          bearerFormat == other.bearerFormat;

  @override
  int get hashCode =>
      description.hashCode ^ scheme.hashCode ^ bearerFormat.hashCode;

  @override
  String toString() =>
      'HttpAuthSecurityScheme(description: $description, '
      'scheme: $scheme, bearerFormat: $bearerFormat)';
}

/// Represents an OAuth 2.0 security scheme.
@JsonSerializable()
class OAuth2SecurityScheme extends SecurityScheme {
  /// Configuration details for the supported OAuth 2.0 flows.
  final OAuthFlows flows;

  const OAuth2SecurityScheme({
    String? type,
    super.description,
    required this.flows,
  }) : super(type: type ?? 'oauth2');

  factory OAuth2SecurityScheme.fromJson(Map<String, Object?> json) =>
      _$OAuth2SecuritySchemeFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$OAuth2SecuritySchemeToJson(this)..['type'] = 'oauth2';

  OAuth2SecurityScheme copyWith({String? description, OAuthFlows? flows}) {
    return OAuth2SecurityScheme(
      description: description ?? this.description,
      flows: flows ?? this.flows,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OAuth2SecurityScheme &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          flows == other.flows;

  @override
  int get hashCode => description.hashCode ^ flows.hashCode;

  @override
  String toString() =>
      'OAuth2SecurityScheme(description: $description, flows: $flows)';
}

/// Represents an OpenID Connect security scheme.
@JsonSerializable()
class OpenIdConnectSecurityScheme extends SecurityScheme {
  /// The OpenID Connect Discovery URL (e.g., ending in `.well-known/openid-configuration`).
  final String openIdConnectUrl;

  const OpenIdConnectSecurityScheme({
    String? type,
    super.description,
    required this.openIdConnectUrl,
  }) : super(type: type ?? 'openIdConnect');

  factory OpenIdConnectSecurityScheme.fromJson(Map<String, Object?> json) =>
      _$OpenIdConnectSecuritySchemeFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$OpenIdConnectSecuritySchemeToJson(this)..['type'] = 'openIdConnect';

  OpenIdConnectSecurityScheme copyWith({
    String? description,
    String? openIdConnectUrl,
  }) {
    return OpenIdConnectSecurityScheme(
      description: description ?? this.description,
      openIdConnectUrl: openIdConnectUrl ?? this.openIdConnectUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenIdConnectSecurityScheme &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          openIdConnectUrl == other.openIdConnectUrl;

  @override
  int get hashCode => description.hashCode ^ openIdConnectUrl.hashCode;

  @override
  String toString() =>
      'OpenIdConnectSecurityScheme(description: $description, '
      'openIdConnectUrl: $openIdConnectUrl)';
}

/// Represents a mutual TLS authentication scheme.
@JsonSerializable()
class MutualTlsSecurityScheme extends SecurityScheme {
  const MutualTlsSecurityScheme({String? type, super.description})
    : super(type: type ?? 'mutualTls');

  factory MutualTlsSecurityScheme.fromJson(Map<String, Object?> json) =>
      _$MutualTlsSecuritySchemeFromJson(json);

  @override
  Map<String, Object?> toJson() =>
      _$MutualTlsSecuritySchemeToJson(this)..['type'] = 'mutualTls';

  MutualTlsSecurityScheme copyWith({String? description}) {
    return MutualTlsSecurityScheme(
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutualTlsSecurityScheme &&
          runtimeType == other.runtimeType &&
          description == other.description;

  @override
  int get hashCode => description.hashCode;

  @override
  String toString() => 'MutualTlsSecurityScheme(description: $description)';
}

/// Container for the OAuth 2.0 flows supported by a [SecurityScheme.oauth2].
@JsonSerializable()
class OAuthFlows {
  /// Configuration for the Implicit Grant flow.
  final OAuthFlow? implicit;

  /// Configuration for the Resource Owner Password Credentials Grant flow.
  final OAuthFlow? password;

  /// Configuration for the Client Credentials Grant flow.
  final OAuthFlow? clientCredentials;

  /// Configuration for the Authorization Code Grant flow.
  final OAuthFlow? authorizationCode;

  const OAuthFlows({
    this.implicit,
    this.password,
    this.clientCredentials,
    this.authorizationCode,
  });

  factory OAuthFlows.fromJson(Map<String, Object?> json) =>
      _$OAuthFlowsFromJson(json);

  Map<String, Object?> toJson() => _$OAuthFlowsToJson(this);

  OAuthFlows copyWith({
    OAuthFlow? implicit,
    OAuthFlow? password,
    OAuthFlow? clientCredentials,
    OAuthFlow? authorizationCode,
  }) {
    return OAuthFlows(
      implicit: implicit ?? this.implicit,
      password: password ?? this.password,
      clientCredentials: clientCredentials ?? this.clientCredentials,
      authorizationCode: authorizationCode ?? this.authorizationCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OAuthFlows &&
          runtimeType == other.runtimeType &&
          implicit == other.implicit &&
          password == other.password &&
          clientCredentials == other.clientCredentials &&
          authorizationCode == other.authorizationCode;

  @override
  int get hashCode =>
      implicit.hashCode ^
      password.hashCode ^
      clientCredentials.hashCode ^
      authorizationCode.hashCode;

  @override
  String toString() =>
      'OAuthFlows(implicit: $implicit, password: $password, '
      'clientCredentials: $clientCredentials, '
      'authorizationCode: $authorizationCode)';
}

/// Configuration details for a single OAuth 2.0 flow.
@JsonSerializable()
class OAuthFlow {
  /// The Authorization URL for this flow.
  final String? authorizationUrl;

  /// The Token URL for this flow.
  final String? tokenUrl;

  /// The Refresh URL to obtain a new access token.
  final String? refreshUrl;

  /// A map of available scopes for this flow.
  final Map<String, String> scopes;

  const OAuthFlow({
    this.authorizationUrl,
    this.tokenUrl,
    this.refreshUrl,
    required this.scopes,
  });

  factory OAuthFlow.fromJson(Map<String, Object?> json) =>
      _$OAuthFlowFromJson(json);

  Map<String, Object?> toJson() => _$OAuthFlowToJson(this);

  OAuthFlow copyWith({
    String? authorizationUrl,
    String? tokenUrl,
    String? refreshUrl,
    Map<String, String>? scopes,
  }) {
    return OAuthFlow(
      authorizationUrl: authorizationUrl ?? this.authorizationUrl,
      tokenUrl: tokenUrl ?? this.tokenUrl,
      refreshUrl: refreshUrl ?? this.refreshUrl,
      scopes: scopes ?? this.scopes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OAuthFlow &&
          runtimeType == other.runtimeType &&
          authorizationUrl == other.authorizationUrl &&
          tokenUrl == other.tokenUrl &&
          refreshUrl == other.refreshUrl &&
          const MapEquality<String, String>().equals(scopes, other.scopes);

  @override
  int get hashCode =>
      authorizationUrl.hashCode ^
      tokenUrl.hashCode ^
      refreshUrl.hashCode ^
      const MapEquality<String, String>().hash(scopes);

  @override
  String toString() =>
      'OAuthFlow(authorizationUrl: $authorizationUrl, tokenUrl: $tokenUrl, '
      'refreshUrl: $refreshUrl, scopes: $scopes)';
}
