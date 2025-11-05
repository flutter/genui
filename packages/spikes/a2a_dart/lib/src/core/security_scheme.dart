import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_scheme.freezed.dart';
part 'security_scheme.g.dart';

/// Defines a security scheme that can be used to secure an agent's endpoints.
/// This is a discriminated union type based on the OpenAPI 3.0 Security Scheme
/// Object.
@Freezed(unionKey: 'type')
abstract class SecurityScheme with _$SecurityScheme {
  const factory SecurityScheme.apiKey({
    @Default('apiKey') String type,
    String? description,
    required String name,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'in') required String in_,
  }) = APIKeySecurityScheme;

  const factory SecurityScheme.http({
    @Default('http') String type,
    String? description,
    required String scheme,
    String? bearerFormat,
  }) = HttpAuthSecurityScheme;

  const factory SecurityScheme.oauth2({
    @Default('oauth2') String type,
    String? description,
    required OAuthFlows flows,
  }) = OAuth2SecurityScheme;

  const factory SecurityScheme.openIdConnect({
    @Default('openIdConnect') String type,
    String? description,
    required String openIdConnectUrl,
  }) = OpenIdConnectSecurityScheme;

  const factory SecurityScheme.mutualTls({
    @Default('mutualTls') String type,
    String? description,
  }) = MutualTlsSecurityScheme;

  factory SecurityScheme.fromJson(Map<String, dynamic> json) =>
      _$SecuritySchemeFromJson(json);
}

@freezed
abstract class OAuthFlows with _$OAuthFlows {
  const factory OAuthFlows({
    OAuthFlow? implicit,
    OAuthFlow? password,
    OAuthFlow? clientCredentials,
    OAuthFlow? authorizationCode,
  }) = _OAuthFlows;

  factory OAuthFlows.fromJson(Map<String, dynamic> json) =>
      _$OAuthFlowsFromJson(json);
}

@freezed
abstract class OAuthFlow with _$OAuthFlow {
  const factory OAuthFlow({
    String? authorizationUrl,
    String? tokenUrl,
    String? refreshUrl,
    required Map<String, String> scopes,
  }) = _OAuthFlow;

  factory OAuthFlow.fromJson(Map<String, dynamic> json) =>
      _$OAuthFlowFromJson(json);
}
