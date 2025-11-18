// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_scheme.freezed.dart';
part 'security_scheme.g.dart';

// ignore_for_file: invalid_annotation_target

/// Defines a security scheme used to protect an agent's API endpoints.
///
/// This class is a Dart representation of the OpenAPI 3.0 Security Scheme
/// Object. It's a discriminated union based on the `type` field, allowing for
/// various authentication and authorization mechanisms.
@Freezed(unionKey: 'type')
abstract class SecurityScheme with _$SecurityScheme {
  /// Represents an API key-based security scheme.
  const factory SecurityScheme.apiKey({
    /// The type discriminator, always 'apiKey'.
    @Default('apiKey') String type,

    /// An optional description of the API key security scheme.
    String? description,

    /// The name of the header, query, or cookie parameter used to transmit
    /// the API key.
    required String name,

    /// Specifies the location of the API key.
    ///
    /// Valid values are "query", "header", or "cookie".
    @JsonKey(name: 'in') required String in_,
  }) = APIKeySecurityScheme;

  /// Represents an HTTP authentication scheme (e.g., Basic, Bearer).
  const factory SecurityScheme.http({
    /// The type discriminator, always 'http'.
    @Default('http') String type,

    /// An optional description of the HTTP security scheme.
    String? description,

    /// The name of the HTTP Authorization scheme, e.g., "Bearer", "Basic".
    ///
    /// Values should be registered in the IANA "Hypertext Transfer Protocol
    /// (HTTP) Authentication Scheme Registry".
    required String scheme,

    /// An optional hint about the format of the bearer token (e.g., "JWT").
    ///
    /// Only relevant when `scheme` is "Bearer".
    String? bearerFormat,
  }) = HttpAuthSecurityScheme;

  /// Represents an OAuth 2.0 security scheme.
  const factory SecurityScheme.oauth2({
    /// The type discriminator, always 'oauth2'.
    @Default('oauth2') String type,

    /// An optional description of the OAuth 2.0 security scheme.
    String? description,

    /// Configuration details for the supported OAuth 2.0 flows.
    required OAuthFlows flows,
  }) = OAuth2SecurityScheme;

  /// Represents an OpenID Connect security scheme.
  const factory SecurityScheme.openIdConnect({
    /// The type discriminator, always 'openIdConnect'.
    @Default('openIdConnect') String type,

    /// An optional description of the OpenID Connect security scheme.
    String? description,

    /// The OpenID Connect Discovery URL (e.g., ending in `.well-known/openid-configuration`).
    required String openIdConnectUrl,
  }) = OpenIdConnectSecurityScheme;

  /// Represents a mutual TLS authentication scheme.
  const factory SecurityScheme.mutualTls({
    /// The type discriminator, always 'mutualTls'.
    @Default('mutualTls') String type,

    /// An optional description of the mutual TLS security scheme.
    String? description,
  }) = MutualTlsSecurityScheme;

  /// Deserializes a [SecurityScheme] instance from a JSON object.
  factory SecurityScheme.fromJson(Map<String, Object?> json) =>
      _$SecuritySchemeFromJson(json);
}

/// Container for the OAuth 2.0 flows supported by a [SecurityScheme.oauth2].
///
/// Each property represents a different OAuth 2.0 grant type.
@freezed
abstract class OAuthFlows with _$OAuthFlows {
  /// Creates an [OAuthFlows] instance.
  const factory OAuthFlows({
    /// Configuration for the Implicit Grant flow.
    OAuthFlow? implicit,

    /// Configuration for the Resource Owner Password Credentials Grant flow.
    OAuthFlow? password,

    /// Configuration for the Client Credentials Grant flow.
    OAuthFlow? clientCredentials,

    /// Configuration for the Authorization Code Grant flow.
    OAuthFlow? authorizationCode,
  }) = _OAuthFlows;

  /// Deserializes an [OAuthFlows] instance from a JSON object.
  factory OAuthFlows.fromJson(Map<String, Object?> json) =>
      _$OAuthFlowsFromJson(json);
}

/// Configuration details for a single OAuth 2.0 flow.
@freezed
abstract class OAuthFlow with _$OAuthFlow {
  /// Creates an [OAuthFlow] instance.
  const factory OAuthFlow({
    /// The Authorization URL for this flow.
    ///
    /// Required for `implicit` and `authorizationCode` flows.
    String? authorizationUrl,

    /// The Token URL for this flow.
    ///
    /// Required for `password`, `clientCredentials`, and `authorizationCode`
    /// flows.
    String? tokenUrl,

    /// The Refresh URL to obtain a new access token.
    String? refreshUrl,

    /// A map of available scopes for this flow.
    ///
    /// The keys are scope names, and the values are human-readable
    /// descriptions.
    required Map<String, String> scopes,
  }) = _OAuthFlow;

  /// Deserializes an [OAuthFlow] instance from a JSON object.
  factory OAuthFlow.fromJson(Map<String, Object?> json) =>
      _$OAuthFlowFromJson(json);
}
