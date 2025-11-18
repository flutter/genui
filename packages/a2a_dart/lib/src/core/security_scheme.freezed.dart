// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security_scheme.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
SecurityScheme _$SecuritySchemeFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'apiKey':
          return APIKeySecurityScheme.fromJson(
            json
          );
                case 'http':
          return HttpAuthSecurityScheme.fromJson(
            json
          );
                case 'oauth2':
          return OAuth2SecurityScheme.fromJson(
            json
          );
                case 'openIdConnect':
          return OpenIdConnectSecurityScheme.fromJson(
            json
          );
                case 'mutualTls':
          return MutualTlsSecurityScheme.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'SecurityScheme',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$SecurityScheme {

/// The type discriminator, always 'apiKey'.
 String get type;/// An optional description of the API key security scheme.
 String? get description;
/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecuritySchemeCopyWith<SecurityScheme> get copyWith => _$SecuritySchemeCopyWithImpl<SecurityScheme>(this as SecurityScheme, _$identity);

  /// Serializes this SecurityScheme to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecurityScheme&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description);

@override
String toString() {
  return 'SecurityScheme(type: $type, description: $description)';
}


}

/// @nodoc
abstract mixin class $SecuritySchemeCopyWith<$Res>  {
  factory $SecuritySchemeCopyWith(SecurityScheme value, $Res Function(SecurityScheme) _then) = _$SecuritySchemeCopyWithImpl;
@useResult
$Res call({
 String type, String? description
});




}
/// @nodoc
class _$SecuritySchemeCopyWithImpl<$Res>
    implements $SecuritySchemeCopyWith<$Res> {
  _$SecuritySchemeCopyWithImpl(this._self, this._then);

  final SecurityScheme _self;
  final $Res Function(SecurityScheme) _then;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecurityScheme].
extension SecuritySchemePatterns on SecurityScheme {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( APIKeySecurityScheme value)?  apiKey,TResult Function( HttpAuthSecurityScheme value)?  http,TResult Function( OAuth2SecurityScheme value)?  oauth2,TResult Function( OpenIdConnectSecurityScheme value)?  openIdConnect,TResult Function( MutualTlsSecurityScheme value)?  mutualTls,required TResult orElse(),}){
final _that = this;
switch (_that) {
case APIKeySecurityScheme() when apiKey != null:
return apiKey(_that);case HttpAuthSecurityScheme() when http != null:
return http(_that);case OAuth2SecurityScheme() when oauth2 != null:
return oauth2(_that);case OpenIdConnectSecurityScheme() when openIdConnect != null:
return openIdConnect(_that);case MutualTlsSecurityScheme() when mutualTls != null:
return mutualTls(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( APIKeySecurityScheme value)  apiKey,required TResult Function( HttpAuthSecurityScheme value)  http,required TResult Function( OAuth2SecurityScheme value)  oauth2,required TResult Function( OpenIdConnectSecurityScheme value)  openIdConnect,required TResult Function( MutualTlsSecurityScheme value)  mutualTls,}){
final _that = this;
switch (_that) {
case APIKeySecurityScheme():
return apiKey(_that);case HttpAuthSecurityScheme():
return http(_that);case OAuth2SecurityScheme():
return oauth2(_that);case OpenIdConnectSecurityScheme():
return openIdConnect(_that);case MutualTlsSecurityScheme():
return mutualTls(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( APIKeySecurityScheme value)?  apiKey,TResult? Function( HttpAuthSecurityScheme value)?  http,TResult? Function( OAuth2SecurityScheme value)?  oauth2,TResult? Function( OpenIdConnectSecurityScheme value)?  openIdConnect,TResult? Function( MutualTlsSecurityScheme value)?  mutualTls,}){
final _that = this;
switch (_that) {
case APIKeySecurityScheme() when apiKey != null:
return apiKey(_that);case HttpAuthSecurityScheme() when http != null:
return http(_that);case OAuth2SecurityScheme() when oauth2 != null:
return oauth2(_that);case OpenIdConnectSecurityScheme() when openIdConnect != null:
return openIdConnect(_that);case MutualTlsSecurityScheme() when mutualTls != null:
return mutualTls(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String type,  String? description,  String name, @JsonKey(name: 'in')  String in_)?  apiKey,TResult Function( String type,  String? description,  String scheme,  String? bearerFormat)?  http,TResult Function( String type,  String? description,  OAuthFlows flows)?  oauth2,TResult Function( String type,  String? description,  String openIdConnectUrl)?  openIdConnect,TResult Function( String type,  String? description)?  mutualTls,required TResult orElse(),}) {final _that = this;
switch (_that) {
case APIKeySecurityScheme() when apiKey != null:
return apiKey(_that.type,_that.description,_that.name,_that.in_);case HttpAuthSecurityScheme() when http != null:
return http(_that.type,_that.description,_that.scheme,_that.bearerFormat);case OAuth2SecurityScheme() when oauth2 != null:
return oauth2(_that.type,_that.description,_that.flows);case OpenIdConnectSecurityScheme() when openIdConnect != null:
return openIdConnect(_that.type,_that.description,_that.openIdConnectUrl);case MutualTlsSecurityScheme() when mutualTls != null:
return mutualTls(_that.type,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String type,  String? description,  String name, @JsonKey(name: 'in')  String in_)  apiKey,required TResult Function( String type,  String? description,  String scheme,  String? bearerFormat)  http,required TResult Function( String type,  String? description,  OAuthFlows flows)  oauth2,required TResult Function( String type,  String? description,  String openIdConnectUrl)  openIdConnect,required TResult Function( String type,  String? description)  mutualTls,}) {final _that = this;
switch (_that) {
case APIKeySecurityScheme():
return apiKey(_that.type,_that.description,_that.name,_that.in_);case HttpAuthSecurityScheme():
return http(_that.type,_that.description,_that.scheme,_that.bearerFormat);case OAuth2SecurityScheme():
return oauth2(_that.type,_that.description,_that.flows);case OpenIdConnectSecurityScheme():
return openIdConnect(_that.type,_that.description,_that.openIdConnectUrl);case MutualTlsSecurityScheme():
return mutualTls(_that.type,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String type,  String? description,  String name, @JsonKey(name: 'in')  String in_)?  apiKey,TResult? Function( String type,  String? description,  String scheme,  String? bearerFormat)?  http,TResult? Function( String type,  String? description,  OAuthFlows flows)?  oauth2,TResult? Function( String type,  String? description,  String openIdConnectUrl)?  openIdConnect,TResult? Function( String type,  String? description)?  mutualTls,}) {final _that = this;
switch (_that) {
case APIKeySecurityScheme() when apiKey != null:
return apiKey(_that.type,_that.description,_that.name,_that.in_);case HttpAuthSecurityScheme() when http != null:
return http(_that.type,_that.description,_that.scheme,_that.bearerFormat);case OAuth2SecurityScheme() when oauth2 != null:
return oauth2(_that.type,_that.description,_that.flows);case OpenIdConnectSecurityScheme() when openIdConnect != null:
return openIdConnect(_that.type,_that.description,_that.openIdConnectUrl);case MutualTlsSecurityScheme() when mutualTls != null:
return mutualTls(_that.type,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class APIKeySecurityScheme implements SecurityScheme {
  const APIKeySecurityScheme({this.type = 'apiKey', this.description, required this.name, @JsonKey(name: 'in') required this.in_});
  factory APIKeySecurityScheme.fromJson(Map<String, dynamic> json) => _$APIKeySecuritySchemeFromJson(json);

/// The type discriminator, always 'apiKey'.
@override@JsonKey() final  String type;
/// An optional description of the API key security scheme.
@override final  String? description;
/// The name of the header, query, or cookie parameter used to transmit
/// the API key.
 final  String name;
/// Specifies the location of the API key.
///
/// Valid values are "query", "header", or "cookie".
@JsonKey(name: 'in') final  String in_;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$APIKeySecuritySchemeCopyWith<APIKeySecurityScheme> get copyWith => _$APIKeySecuritySchemeCopyWithImpl<APIKeySecurityScheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$APIKeySecuritySchemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is APIKeySecurityScheme&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.name, name) || other.name == name)&&(identical(other.in_, in_) || other.in_ == in_));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,name,in_);

@override
String toString() {
  return 'SecurityScheme.apiKey(type: $type, description: $description, name: $name, in_: $in_)';
}


}

/// @nodoc
abstract mixin class $APIKeySecuritySchemeCopyWith<$Res> implements $SecuritySchemeCopyWith<$Res> {
  factory $APIKeySecuritySchemeCopyWith(APIKeySecurityScheme value, $Res Function(APIKeySecurityScheme) _then) = _$APIKeySecuritySchemeCopyWithImpl;
@override @useResult
$Res call({
 String type, String? description, String name,@JsonKey(name: 'in') String in_
});




}
/// @nodoc
class _$APIKeySecuritySchemeCopyWithImpl<$Res>
    implements $APIKeySecuritySchemeCopyWith<$Res> {
  _$APIKeySecuritySchemeCopyWithImpl(this._self, this._then);

  final APIKeySecurityScheme _self;
  final $Res Function(APIKeySecurityScheme) _then;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = freezed,Object? name = null,Object? in_ = null,}) {
  return _then(APIKeySecurityScheme(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,in_: null == in_ ? _self.in_ : in_ // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class HttpAuthSecurityScheme implements SecurityScheme {
  const HttpAuthSecurityScheme({this.type = 'http', this.description, required this.scheme, this.bearerFormat});
  factory HttpAuthSecurityScheme.fromJson(Map<String, dynamic> json) => _$HttpAuthSecuritySchemeFromJson(json);

/// The type discriminator, always 'http'.
@override@JsonKey() final  String type;
/// An optional description of the HTTP security scheme.
@override final  String? description;
/// The name of the HTTP Authorization scheme, e.g., "Bearer", "Basic".
///
/// Values should be registered in the IANA "Hypertext Transfer Protocol
/// (HTTP) Authentication Scheme Registry".
 final  String scheme;
/// An optional hint about the format of the bearer token (e.g., "JWT").
///
/// Only relevant when `scheme` is "Bearer".
 final  String? bearerFormat;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpAuthSecuritySchemeCopyWith<HttpAuthSecurityScheme> get copyWith => _$HttpAuthSecuritySchemeCopyWithImpl<HttpAuthSecurityScheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HttpAuthSecuritySchemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpAuthSecurityScheme&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.scheme, scheme) || other.scheme == scheme)&&(identical(other.bearerFormat, bearerFormat) || other.bearerFormat == bearerFormat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,scheme,bearerFormat);

@override
String toString() {
  return 'SecurityScheme.http(type: $type, description: $description, scheme: $scheme, bearerFormat: $bearerFormat)';
}


}

/// @nodoc
abstract mixin class $HttpAuthSecuritySchemeCopyWith<$Res> implements $SecuritySchemeCopyWith<$Res> {
  factory $HttpAuthSecuritySchemeCopyWith(HttpAuthSecurityScheme value, $Res Function(HttpAuthSecurityScheme) _then) = _$HttpAuthSecuritySchemeCopyWithImpl;
@override @useResult
$Res call({
 String type, String? description, String scheme, String? bearerFormat
});




}
/// @nodoc
class _$HttpAuthSecuritySchemeCopyWithImpl<$Res>
    implements $HttpAuthSecuritySchemeCopyWith<$Res> {
  _$HttpAuthSecuritySchemeCopyWithImpl(this._self, this._then);

  final HttpAuthSecurityScheme _self;
  final $Res Function(HttpAuthSecurityScheme) _then;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = freezed,Object? scheme = null,Object? bearerFormat = freezed,}) {
  return _then(HttpAuthSecurityScheme(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,scheme: null == scheme ? _self.scheme : scheme // ignore: cast_nullable_to_non_nullable
as String,bearerFormat: freezed == bearerFormat ? _self.bearerFormat : bearerFormat // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class OAuth2SecurityScheme implements SecurityScheme {
  const OAuth2SecurityScheme({this.type = 'oauth2', this.description, required this.flows});
  factory OAuth2SecurityScheme.fromJson(Map<String, dynamic> json) => _$OAuth2SecuritySchemeFromJson(json);

/// The type discriminator, always 'oauth2'.
@override@JsonKey() final  String type;
/// An optional description of the OAuth 2.0 security scheme.
@override final  String? description;
/// Configuration details for the supported OAuth 2.0 flows.
 final  OAuthFlows flows;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OAuth2SecuritySchemeCopyWith<OAuth2SecurityScheme> get copyWith => _$OAuth2SecuritySchemeCopyWithImpl<OAuth2SecurityScheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OAuth2SecuritySchemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OAuth2SecurityScheme&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.flows, flows) || other.flows == flows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,flows);

@override
String toString() {
  return 'SecurityScheme.oauth2(type: $type, description: $description, flows: $flows)';
}


}

/// @nodoc
abstract mixin class $OAuth2SecuritySchemeCopyWith<$Res> implements $SecuritySchemeCopyWith<$Res> {
  factory $OAuth2SecuritySchemeCopyWith(OAuth2SecurityScheme value, $Res Function(OAuth2SecurityScheme) _then) = _$OAuth2SecuritySchemeCopyWithImpl;
@override @useResult
$Res call({
 String type, String? description, OAuthFlows flows
});


$OAuthFlowsCopyWith<$Res> get flows;

}
/// @nodoc
class _$OAuth2SecuritySchemeCopyWithImpl<$Res>
    implements $OAuth2SecuritySchemeCopyWith<$Res> {
  _$OAuth2SecuritySchemeCopyWithImpl(this._self, this._then);

  final OAuth2SecurityScheme _self;
  final $Res Function(OAuth2SecurityScheme) _then;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = freezed,Object? flows = null,}) {
  return _then(OAuth2SecurityScheme(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,flows: null == flows ? _self.flows : flows // ignore: cast_nullable_to_non_nullable
as OAuthFlows,
  ));
}

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowsCopyWith<$Res> get flows {
  
  return $OAuthFlowsCopyWith<$Res>(_self.flows, (value) {
    return _then(_self.copyWith(flows: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class OpenIdConnectSecurityScheme implements SecurityScheme {
  const OpenIdConnectSecurityScheme({this.type = 'openIdConnect', this.description, required this.openIdConnectUrl});
  factory OpenIdConnectSecurityScheme.fromJson(Map<String, dynamic> json) => _$OpenIdConnectSecuritySchemeFromJson(json);

/// The type discriminator, always 'openIdConnect'.
@override@JsonKey() final  String type;
/// An optional description of the OpenID Connect security scheme.
@override final  String? description;
/// The OpenID Connect Discovery URL (e.g., ending in `.well-known/openid-configuration`).
 final  String openIdConnectUrl;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenIdConnectSecuritySchemeCopyWith<OpenIdConnectSecurityScheme> get copyWith => _$OpenIdConnectSecuritySchemeCopyWithImpl<OpenIdConnectSecurityScheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenIdConnectSecuritySchemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenIdConnectSecurityScheme&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.openIdConnectUrl, openIdConnectUrl) || other.openIdConnectUrl == openIdConnectUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,openIdConnectUrl);

@override
String toString() {
  return 'SecurityScheme.openIdConnect(type: $type, description: $description, openIdConnectUrl: $openIdConnectUrl)';
}


}

/// @nodoc
abstract mixin class $OpenIdConnectSecuritySchemeCopyWith<$Res> implements $SecuritySchemeCopyWith<$Res> {
  factory $OpenIdConnectSecuritySchemeCopyWith(OpenIdConnectSecurityScheme value, $Res Function(OpenIdConnectSecurityScheme) _then) = _$OpenIdConnectSecuritySchemeCopyWithImpl;
@override @useResult
$Res call({
 String type, String? description, String openIdConnectUrl
});




}
/// @nodoc
class _$OpenIdConnectSecuritySchemeCopyWithImpl<$Res>
    implements $OpenIdConnectSecuritySchemeCopyWith<$Res> {
  _$OpenIdConnectSecuritySchemeCopyWithImpl(this._self, this._then);

  final OpenIdConnectSecurityScheme _self;
  final $Res Function(OpenIdConnectSecurityScheme) _then;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = freezed,Object? openIdConnectUrl = null,}) {
  return _then(OpenIdConnectSecurityScheme(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,openIdConnectUrl: null == openIdConnectUrl ? _self.openIdConnectUrl : openIdConnectUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MutualTlsSecurityScheme implements SecurityScheme {
  const MutualTlsSecurityScheme({this.type = 'mutualTls', this.description});
  factory MutualTlsSecurityScheme.fromJson(Map<String, dynamic> json) => _$MutualTlsSecuritySchemeFromJson(json);

/// The type discriminator, always 'mutualTls'.
@override@JsonKey() final  String type;
/// An optional description of the mutual TLS security scheme.
@override final  String? description;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutualTlsSecuritySchemeCopyWith<MutualTlsSecurityScheme> get copyWith => _$MutualTlsSecuritySchemeCopyWithImpl<MutualTlsSecurityScheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MutualTlsSecuritySchemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MutualTlsSecurityScheme&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description);

@override
String toString() {
  return 'SecurityScheme.mutualTls(type: $type, description: $description)';
}


}

/// @nodoc
abstract mixin class $MutualTlsSecuritySchemeCopyWith<$Res> implements $SecuritySchemeCopyWith<$Res> {
  factory $MutualTlsSecuritySchemeCopyWith(MutualTlsSecurityScheme value, $Res Function(MutualTlsSecurityScheme) _then) = _$MutualTlsSecuritySchemeCopyWithImpl;
@override @useResult
$Res call({
 String type, String? description
});




}
/// @nodoc
class _$MutualTlsSecuritySchemeCopyWithImpl<$Res>
    implements $MutualTlsSecuritySchemeCopyWith<$Res> {
  _$MutualTlsSecuritySchemeCopyWithImpl(this._self, this._then);

  final MutualTlsSecurityScheme _self;
  final $Res Function(MutualTlsSecurityScheme) _then;

/// Create a copy of SecurityScheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = freezed,}) {
  return _then(MutualTlsSecurityScheme(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OAuthFlows {

/// Configuration for the Implicit Grant flow.
 OAuthFlow? get implicit;/// Configuration for the Resource Owner Password Credentials Grant flow.
 OAuthFlow? get password;/// Configuration for the Client Credentials Grant flow.
 OAuthFlow? get clientCredentials;/// Configuration for the Authorization Code Grant flow.
 OAuthFlow? get authorizationCode;
/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OAuthFlowsCopyWith<OAuthFlows> get copyWith => _$OAuthFlowsCopyWithImpl<OAuthFlows>(this as OAuthFlows, _$identity);

  /// Serializes this OAuthFlows to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OAuthFlows&&(identical(other.implicit, implicit) || other.implicit == implicit)&&(identical(other.password, password) || other.password == password)&&(identical(other.clientCredentials, clientCredentials) || other.clientCredentials == clientCredentials)&&(identical(other.authorizationCode, authorizationCode) || other.authorizationCode == authorizationCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,implicit,password,clientCredentials,authorizationCode);

@override
String toString() {
  return 'OAuthFlows(implicit: $implicit, password: $password, clientCredentials: $clientCredentials, authorizationCode: $authorizationCode)';
}


}

/// @nodoc
abstract mixin class $OAuthFlowsCopyWith<$Res>  {
  factory $OAuthFlowsCopyWith(OAuthFlows value, $Res Function(OAuthFlows) _then) = _$OAuthFlowsCopyWithImpl;
@useResult
$Res call({
 OAuthFlow? implicit, OAuthFlow? password, OAuthFlow? clientCredentials, OAuthFlow? authorizationCode
});


$OAuthFlowCopyWith<$Res>? get implicit;$OAuthFlowCopyWith<$Res>? get password;$OAuthFlowCopyWith<$Res>? get clientCredentials;$OAuthFlowCopyWith<$Res>? get authorizationCode;

}
/// @nodoc
class _$OAuthFlowsCopyWithImpl<$Res>
    implements $OAuthFlowsCopyWith<$Res> {
  _$OAuthFlowsCopyWithImpl(this._self, this._then);

  final OAuthFlows _self;
  final $Res Function(OAuthFlows) _then;

/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? implicit = freezed,Object? password = freezed,Object? clientCredentials = freezed,Object? authorizationCode = freezed,}) {
  return _then(_self.copyWith(
implicit: freezed == implicit ? _self.implicit : implicit // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,clientCredentials: freezed == clientCredentials ? _self.clientCredentials : clientCredentials // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,authorizationCode: freezed == authorizationCode ? _self.authorizationCode : authorizationCode // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,
  ));
}
/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get implicit {
    if (_self.implicit == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.implicit!, (value) {
    return _then(_self.copyWith(implicit: value));
  });
}/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get password {
    if (_self.password == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.password!, (value) {
    return _then(_self.copyWith(password: value));
  });
}/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get clientCredentials {
    if (_self.clientCredentials == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.clientCredentials!, (value) {
    return _then(_self.copyWith(clientCredentials: value));
  });
}/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get authorizationCode {
    if (_self.authorizationCode == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.authorizationCode!, (value) {
    return _then(_self.copyWith(authorizationCode: value));
  });
}
}


/// Adds pattern-matching-related methods to [OAuthFlows].
extension OAuthFlowsPatterns on OAuthFlows {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OAuthFlows value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OAuthFlows() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OAuthFlows value)  $default,){
final _that = this;
switch (_that) {
case _OAuthFlows():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OAuthFlows value)?  $default,){
final _that = this;
switch (_that) {
case _OAuthFlows() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OAuthFlow? implicit,  OAuthFlow? password,  OAuthFlow? clientCredentials,  OAuthFlow? authorizationCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OAuthFlows() when $default != null:
return $default(_that.implicit,_that.password,_that.clientCredentials,_that.authorizationCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OAuthFlow? implicit,  OAuthFlow? password,  OAuthFlow? clientCredentials,  OAuthFlow? authorizationCode)  $default,) {final _that = this;
switch (_that) {
case _OAuthFlows():
return $default(_that.implicit,_that.password,_that.clientCredentials,_that.authorizationCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OAuthFlow? implicit,  OAuthFlow? password,  OAuthFlow? clientCredentials,  OAuthFlow? authorizationCode)?  $default,) {final _that = this;
switch (_that) {
case _OAuthFlows() when $default != null:
return $default(_that.implicit,_that.password,_that.clientCredentials,_that.authorizationCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OAuthFlows implements OAuthFlows {
  const _OAuthFlows({this.implicit, this.password, this.clientCredentials, this.authorizationCode});
  factory _OAuthFlows.fromJson(Map<String, dynamic> json) => _$OAuthFlowsFromJson(json);

/// Configuration for the Implicit Grant flow.
@override final  OAuthFlow? implicit;
/// Configuration for the Resource Owner Password Credentials Grant flow.
@override final  OAuthFlow? password;
/// Configuration for the Client Credentials Grant flow.
@override final  OAuthFlow? clientCredentials;
/// Configuration for the Authorization Code Grant flow.
@override final  OAuthFlow? authorizationCode;

/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OAuthFlowsCopyWith<_OAuthFlows> get copyWith => __$OAuthFlowsCopyWithImpl<_OAuthFlows>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OAuthFlowsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OAuthFlows&&(identical(other.implicit, implicit) || other.implicit == implicit)&&(identical(other.password, password) || other.password == password)&&(identical(other.clientCredentials, clientCredentials) || other.clientCredentials == clientCredentials)&&(identical(other.authorizationCode, authorizationCode) || other.authorizationCode == authorizationCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,implicit,password,clientCredentials,authorizationCode);

@override
String toString() {
  return 'OAuthFlows(implicit: $implicit, password: $password, clientCredentials: $clientCredentials, authorizationCode: $authorizationCode)';
}


}

/// @nodoc
abstract mixin class _$OAuthFlowsCopyWith<$Res> implements $OAuthFlowsCopyWith<$Res> {
  factory _$OAuthFlowsCopyWith(_OAuthFlows value, $Res Function(_OAuthFlows) _then) = __$OAuthFlowsCopyWithImpl;
@override @useResult
$Res call({
 OAuthFlow? implicit, OAuthFlow? password, OAuthFlow? clientCredentials, OAuthFlow? authorizationCode
});


@override $OAuthFlowCopyWith<$Res>? get implicit;@override $OAuthFlowCopyWith<$Res>? get password;@override $OAuthFlowCopyWith<$Res>? get clientCredentials;@override $OAuthFlowCopyWith<$Res>? get authorizationCode;

}
/// @nodoc
class __$OAuthFlowsCopyWithImpl<$Res>
    implements _$OAuthFlowsCopyWith<$Res> {
  __$OAuthFlowsCopyWithImpl(this._self, this._then);

  final _OAuthFlows _self;
  final $Res Function(_OAuthFlows) _then;

/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? implicit = freezed,Object? password = freezed,Object? clientCredentials = freezed,Object? authorizationCode = freezed,}) {
  return _then(_OAuthFlows(
implicit: freezed == implicit ? _self.implicit : implicit // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,clientCredentials: freezed == clientCredentials ? _self.clientCredentials : clientCredentials // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,authorizationCode: freezed == authorizationCode ? _self.authorizationCode : authorizationCode // ignore: cast_nullable_to_non_nullable
as OAuthFlow?,
  ));
}

/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get implicit {
    if (_self.implicit == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.implicit!, (value) {
    return _then(_self.copyWith(implicit: value));
  });
}/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get password {
    if (_self.password == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.password!, (value) {
    return _then(_self.copyWith(password: value));
  });
}/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get clientCredentials {
    if (_self.clientCredentials == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.clientCredentials!, (value) {
    return _then(_self.copyWith(clientCredentials: value));
  });
}/// Create a copy of OAuthFlows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<$Res>? get authorizationCode {
    if (_self.authorizationCode == null) {
    return null;
  }

  return $OAuthFlowCopyWith<$Res>(_self.authorizationCode!, (value) {
    return _then(_self.copyWith(authorizationCode: value));
  });
}
}


/// @nodoc
mixin _$OAuthFlow {

/// The Authorization URL for this flow.
///
/// Required for `implicit` and `authorizationCode` flows.
 String? get authorizationUrl;/// The Token URL for this flow.
///
/// Required for `password`, `clientCredentials`, and `authorizationCode`
/// flows.
 String? get tokenUrl;/// The Refresh URL to obtain a new access token.
 String? get refreshUrl;/// A map of available scopes for this flow.
///
/// The keys are scope names, and the values are human-readable
/// descriptions.
 Map<String, String> get scopes;
/// Create a copy of OAuthFlow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OAuthFlowCopyWith<OAuthFlow> get copyWith => _$OAuthFlowCopyWithImpl<OAuthFlow>(this as OAuthFlow, _$identity);

  /// Serializes this OAuthFlow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OAuthFlow&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.tokenUrl, tokenUrl) || other.tokenUrl == tokenUrl)&&(identical(other.refreshUrl, refreshUrl) || other.refreshUrl == refreshUrl)&&const DeepCollectionEquality().equals(other.scopes, scopes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authorizationUrl,tokenUrl,refreshUrl,const DeepCollectionEquality().hash(scopes));

@override
String toString() {
  return 'OAuthFlow(authorizationUrl: $authorizationUrl, tokenUrl: $tokenUrl, refreshUrl: $refreshUrl, scopes: $scopes)';
}


}

/// @nodoc
abstract mixin class $OAuthFlowCopyWith<$Res>  {
  factory $OAuthFlowCopyWith(OAuthFlow value, $Res Function(OAuthFlow) _then) = _$OAuthFlowCopyWithImpl;
@useResult
$Res call({
 String? authorizationUrl, String? tokenUrl, String? refreshUrl, Map<String, String> scopes
});




}
/// @nodoc
class _$OAuthFlowCopyWithImpl<$Res>
    implements $OAuthFlowCopyWith<$Res> {
  _$OAuthFlowCopyWithImpl(this._self, this._then);

  final OAuthFlow _self;
  final $Res Function(OAuthFlow) _then;

/// Create a copy of OAuthFlow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authorizationUrl = freezed,Object? tokenUrl = freezed,Object? refreshUrl = freezed,Object? scopes = null,}) {
  return _then(_self.copyWith(
authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,tokenUrl: freezed == tokenUrl ? _self.tokenUrl : tokenUrl // ignore: cast_nullable_to_non_nullable
as String?,refreshUrl: freezed == refreshUrl ? _self.refreshUrl : refreshUrl // ignore: cast_nullable_to_non_nullable
as String?,scopes: null == scopes ? _self.scopes : scopes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OAuthFlow].
extension OAuthFlowPatterns on OAuthFlow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OAuthFlow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OAuthFlow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OAuthFlow value)  $default,){
final _that = this;
switch (_that) {
case _OAuthFlow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OAuthFlow value)?  $default,){
final _that = this;
switch (_that) {
case _OAuthFlow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? authorizationUrl,  String? tokenUrl,  String? refreshUrl,  Map<String, String> scopes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OAuthFlow() when $default != null:
return $default(_that.authorizationUrl,_that.tokenUrl,_that.refreshUrl,_that.scopes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? authorizationUrl,  String? tokenUrl,  String? refreshUrl,  Map<String, String> scopes)  $default,) {final _that = this;
switch (_that) {
case _OAuthFlow():
return $default(_that.authorizationUrl,_that.tokenUrl,_that.refreshUrl,_that.scopes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? authorizationUrl,  String? tokenUrl,  String? refreshUrl,  Map<String, String> scopes)?  $default,) {final _that = this;
switch (_that) {
case _OAuthFlow() when $default != null:
return $default(_that.authorizationUrl,_that.tokenUrl,_that.refreshUrl,_that.scopes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OAuthFlow implements OAuthFlow {
  const _OAuthFlow({this.authorizationUrl, this.tokenUrl, this.refreshUrl, required final  Map<String, String> scopes}): _scopes = scopes;
  factory _OAuthFlow.fromJson(Map<String, dynamic> json) => _$OAuthFlowFromJson(json);

/// The Authorization URL for this flow.
///
/// Required for `implicit` and `authorizationCode` flows.
@override final  String? authorizationUrl;
/// The Token URL for this flow.
///
/// Required for `password`, `clientCredentials`, and `authorizationCode`
/// flows.
@override final  String? tokenUrl;
/// The Refresh URL to obtain a new access token.
@override final  String? refreshUrl;
/// A map of available scopes for this flow.
///
/// The keys are scope names, and the values are human-readable
/// descriptions.
 final  Map<String, String> _scopes;
/// A map of available scopes for this flow.
///
/// The keys are scope names, and the values are human-readable
/// descriptions.
@override Map<String, String> get scopes {
  if (_scopes is EqualUnmodifiableMapView) return _scopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_scopes);
}


/// Create a copy of OAuthFlow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OAuthFlowCopyWith<_OAuthFlow> get copyWith => __$OAuthFlowCopyWithImpl<_OAuthFlow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OAuthFlowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OAuthFlow&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.tokenUrl, tokenUrl) || other.tokenUrl == tokenUrl)&&(identical(other.refreshUrl, refreshUrl) || other.refreshUrl == refreshUrl)&&const DeepCollectionEquality().equals(other._scopes, _scopes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authorizationUrl,tokenUrl,refreshUrl,const DeepCollectionEquality().hash(_scopes));

@override
String toString() {
  return 'OAuthFlow(authorizationUrl: $authorizationUrl, tokenUrl: $tokenUrl, refreshUrl: $refreshUrl, scopes: $scopes)';
}


}

/// @nodoc
abstract mixin class _$OAuthFlowCopyWith<$Res> implements $OAuthFlowCopyWith<$Res> {
  factory _$OAuthFlowCopyWith(_OAuthFlow value, $Res Function(_OAuthFlow) _then) = __$OAuthFlowCopyWithImpl;
@override @useResult
$Res call({
 String? authorizationUrl, String? tokenUrl, String? refreshUrl, Map<String, String> scopes
});




}
/// @nodoc
class __$OAuthFlowCopyWithImpl<$Res>
    implements _$OAuthFlowCopyWith<$Res> {
  __$OAuthFlowCopyWithImpl(this._self, this._then);

  final _OAuthFlow _self;
  final $Res Function(_OAuthFlow) _then;

/// Create a copy of OAuthFlow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authorizationUrl = freezed,Object? tokenUrl = freezed,Object? refreshUrl = freezed,Object? scopes = null,}) {
  return _then(_OAuthFlow(
authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,tokenUrl: freezed == tokenUrl ? _self.tokenUrl : tokenUrl // ignore: cast_nullable_to_non_nullable
as String?,refreshUrl: freezed == refreshUrl ? _self.refreshUrl : refreshUrl // ignore: cast_nullable_to_non_nullable
as String?,scopes: null == scopes ? _self._scopes : scopes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
