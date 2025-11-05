import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_scheme.freezed.dart';
part 'security_scheme.g.dart';

// ignore_for_file: invalid_annotation_target

/// Defines a security scheme that can be used to secure an agent's endpoints.
///
/// This is a discriminated union type based on the OpenAPI 3.0 Security Scheme
/// Object. The `type` field is used as a discriminator.
@Freezed(unionKey: 'type')
abstract class SecurityScheme with _$SecurityScheme {
  /// An API key security scheme.
  const factory SecurityScheme.apiKey({
    /// The type of the security scheme, always 'apiKey'.
    @Default('apiKey') String type,
    /// A short description for the API key.
    String? description,
    /// The name of the header, query or cookie parameter to be used.
    required String name,
    /// The location of the API key. Valid values are "query", "header" or "cookie".
    @JsonKey(name: 'in') required String in_,
  }) = APIKeySecurityScheme;

  /// An HTTP authentication security scheme.
  const factory SecurityScheme.http({
    /// The type of the security scheme, always 'http'.
    @Default('http') String type,
    /// A short description for the HTTP security scheme.
    String? description,
    /// The name of the HTTP Authorization scheme to be used in the Authorization
    /// header defined in RFC7235. The values used should be registered in the
    /// IANA "Hypertext Transfer Protocol (HTTP) Authentication Scheme Registry".
    required String scheme,
    /// A hint to the client to identify how the bearer token is formatted.
    String? bearerFormat,
  }) = HttpAuthSecurityScheme;

  /// An OAuth 2.0 security scheme.
  const factory SecurityScheme.oauth2({
    /// The type of the security scheme, always 'oauth2'.
    @Default('oauth2') String type,
    /// A short description for the OAuth 2.0 security scheme.
    String? description,
    /// An object containing configuration information for the supported OAuth Flows.
    required OAuthFlows flows,
  }) = OAuth2SecurityScheme;

  /// An OpenID Connect security scheme.
  const factory SecurityScheme.openIdConnect({
    /// The type of the security scheme, always 'openIdConnect'.
    @Default('openIdConnect') String type,
    /// A short description for the OpenID Connect security scheme.
    String? description,
    /// OpenID Connect Discovery URL.
    required String openIdConnectUrl,
  }) = OpenIdConnectSecurityScheme;

  /// A mutual TLS security scheme.
  const factory SecurityScheme.mutualTls({
    /// The type of the security scheme, always 'mutualTls'.
    @Default('mutualTls') String type,
    /// A short description for the mutual TLS security scheme.
    String? description,
  }) = MutualTlsSecurityScheme;

  /// Creates a [SecurityScheme] from a JSON object.
  factory SecurityScheme.fromJson(Map<String, dynamic> json) =>
      _$SecuritySchemeFromJson(json);
}

/// Defines the OAuth 2.0 flows.
@freezed
abstract class OAuthFlows with _$OAuthFlows {
  /// Creates an [OAuthFlows] object.
  const factory OAuthFlows({
    /// The implicit flow.
    OAuthFlow? implicit,
    /// The password flow.
    OAuthFlow? password,
    /// The client credentials flow.
    OAuthFlow? clientCredentials,
    /// The authorization code flow.
    OAuthFlow? authorizationCode,
  }) = _OAuthFlows;

  /// Creates an [OAuthFlows] from a JSON object.
  factory OAuthFlows.fromJson(Map<String, dynamic> json) =>
      _$OAuthFlowsFromJson(json);
}

/// Defines a single OAuth 2.0 flow.
@freezed
abstract class OAuthFlow with _$OAuthFlow {
  /// Creates an [OAuthFlow] object.
  const factory OAuthFlow({
    /// The authorization URL for the flow.
    String? authorizationUrl,
    /// The token URL for the flow.
    String? tokenUrl,
    /// The refresh URL for the flow.
    String? refreshUrl,
    /// The available scopes for the flow.
    required Map<String, String> scopes,
  }) = _OAuthFlow;

  /// Creates an [OAuthFlow] from a JSON object.
  factory OAuthFlow.fromJson(Map<String, dynamic> json) =>
      _$OAuthFlowFromJson(json);
}
