// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentCard {

/// The version of the A2A protocol that this agent implements.
///
/// Example: "0.1.0".
 String get protocolVersion;/// A human-readable name for the agent.
///
/// Example: "Recipe Assistant".
 String get name;/// A concise, human-readable description of the agent's purpose and
/// functionality.
 String get description;/// The primary endpoint URL for interacting with the agent.
 String get url;/// The transport protocol used by the primary endpoint specified in [url].
///
/// Defaults to [TransportProtocol.jsonrpc] if not specified.
 TransportProtocol? get preferredTransport;/// A list of alternative interfaces the agent supports.
///
/// This allows an agent to expose its API via multiple transport protocols
/// or at different URLs.
 List<AgentInterface>? get additionalInterfaces;/// An optional URL pointing to an icon representing the agent.
 String? get iconUrl;/// Information about the entity providing the agent service.
 AgentProvider? get provider;/// The version string of the agent implementation itself.
///
/// The format is specific to the agent provider.
 String get version;/// An optional URL pointing to human-readable documentation for the agent.
 String? get documentationUrl;/// A declaration of optional A2A protocol features and extensions
/// supported by the agent.
 AgentCapabilities get capabilities;/// A map of security schemes supported by the agent for authorization.
///
/// The keys are scheme names (e.g., "apiKey", "bearerAuth") which can be
/// referenced in security requirements. The values define the scheme
/// details, following the OpenAPI 3.0 Security Scheme Object structure.
 Map<String, SecurityScheme>? get securitySchemes;/// A list of security requirements that apply globally to all interactions
/// with this agent, unless overridden by a specific skill or method.
///
/// Each item in the list is a map representing a disjunction (OR) of
/// security schemes. Within each map, the keys are scheme names from
/// [securitySchemes], and the values are lists of required scopes (AND).
 List<Map<String, List<String>>>? get security;/// Default set of supported input MIME types (e.g., "text/plain") for all
/// skills.
///
/// This can be overridden on a per-skill basis in [AgentSkill].
 List<String> get defaultInputModes;/// Default set of supported output MIME types (e.g., "application/json") for
/// all skills.
///
/// This can be overridden on a per-skill basis in [AgentSkill].
 List<String> get defaultOutputModes;/// The set of skills (distinct functionalities) that the agent can perform.
 List<AgentSkill> get skills;/// Indicates whether the agent can provide an extended agent card with
/// potentially more details to authenticated users.
///
/// Defaults to `false` if not specified.
 bool? get supportsAuthenticatedExtendedCard;
/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentCardCopyWith<AgentCard> get copyWith => _$AgentCardCopyWithImpl<AgentCard>(this as AgentCard, _$identity);

  /// Serializes this AgentCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentCard&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&(identical(other.preferredTransport, preferredTransport) || other.preferredTransport == preferredTransport)&&const DeepCollectionEquality().equals(other.additionalInterfaces, additionalInterfaces)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.version, version) || other.version == version)&&(identical(other.documentationUrl, documentationUrl) || other.documentationUrl == documentationUrl)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&const DeepCollectionEquality().equals(other.securitySchemes, securitySchemes)&&const DeepCollectionEquality().equals(other.security, security)&&const DeepCollectionEquality().equals(other.defaultInputModes, defaultInputModes)&&const DeepCollectionEquality().equals(other.defaultOutputModes, defaultOutputModes)&&const DeepCollectionEquality().equals(other.skills, skills)&&(identical(other.supportsAuthenticatedExtendedCard, supportsAuthenticatedExtendedCard) || other.supportsAuthenticatedExtendedCard == supportsAuthenticatedExtendedCard));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,protocolVersion,name,description,url,preferredTransport,const DeepCollectionEquality().hash(additionalInterfaces),iconUrl,provider,version,documentationUrl,capabilities,const DeepCollectionEquality().hash(securitySchemes),const DeepCollectionEquality().hash(security),const DeepCollectionEquality().hash(defaultInputModes),const DeepCollectionEquality().hash(defaultOutputModes),const DeepCollectionEquality().hash(skills),supportsAuthenticatedExtendedCard);

@override
String toString() {
  return 'AgentCard(protocolVersion: $protocolVersion, name: $name, description: $description, url: $url, preferredTransport: $preferredTransport, additionalInterfaces: $additionalInterfaces, iconUrl: $iconUrl, provider: $provider, version: $version, documentationUrl: $documentationUrl, capabilities: $capabilities, securitySchemes: $securitySchemes, security: $security, defaultInputModes: $defaultInputModes, defaultOutputModes: $defaultOutputModes, skills: $skills, supportsAuthenticatedExtendedCard: $supportsAuthenticatedExtendedCard)';
}


}

/// @nodoc
abstract mixin class $AgentCardCopyWith<$Res>  {
  factory $AgentCardCopyWith(AgentCard value, $Res Function(AgentCard) _then) = _$AgentCardCopyWithImpl;
@useResult
$Res call({
 String protocolVersion, String name, String description, String url, TransportProtocol? preferredTransport, List<AgentInterface>? additionalInterfaces, String? iconUrl, AgentProvider? provider, String version, String? documentationUrl, AgentCapabilities capabilities, Map<String, SecurityScheme>? securitySchemes, List<Map<String, List<String>>>? security, List<String> defaultInputModes, List<String> defaultOutputModes, List<AgentSkill> skills, bool? supportsAuthenticatedExtendedCard
});


$AgentProviderCopyWith<$Res>? get provider;$AgentCapabilitiesCopyWith<$Res> get capabilities;

}
/// @nodoc
class _$AgentCardCopyWithImpl<$Res>
    implements $AgentCardCopyWith<$Res> {
  _$AgentCardCopyWithImpl(this._self, this._then);

  final AgentCard _self;
  final $Res Function(AgentCard) _then;

/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocolVersion = null,Object? name = null,Object? description = null,Object? url = null,Object? preferredTransport = freezed,Object? additionalInterfaces = freezed,Object? iconUrl = freezed,Object? provider = freezed,Object? version = null,Object? documentationUrl = freezed,Object? capabilities = null,Object? securitySchemes = freezed,Object? security = freezed,Object? defaultInputModes = null,Object? defaultOutputModes = null,Object? skills = null,Object? supportsAuthenticatedExtendedCard = freezed,}) {
  return _then(_self.copyWith(
protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,preferredTransport: freezed == preferredTransport ? _self.preferredTransport : preferredTransport // ignore: cast_nullable_to_non_nullable
as TransportProtocol?,additionalInterfaces: freezed == additionalInterfaces ? _self.additionalInterfaces : additionalInterfaces // ignore: cast_nullable_to_non_nullable
as List<AgentInterface>?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AgentProvider?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,documentationUrl: freezed == documentationUrl ? _self.documentationUrl : documentationUrl // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as AgentCapabilities,securitySchemes: freezed == securitySchemes ? _self.securitySchemes : securitySchemes // ignore: cast_nullable_to_non_nullable
as Map<String, SecurityScheme>?,security: freezed == security ? _self.security : security // ignore: cast_nullable_to_non_nullable
as List<Map<String, List<String>>>?,defaultInputModes: null == defaultInputModes ? _self.defaultInputModes : defaultInputModes // ignore: cast_nullable_to_non_nullable
as List<String>,defaultOutputModes: null == defaultOutputModes ? _self.defaultOutputModes : defaultOutputModes // ignore: cast_nullable_to_non_nullable
as List<String>,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkill>,supportsAuthenticatedExtendedCard: freezed == supportsAuthenticatedExtendedCard ? _self.supportsAuthenticatedExtendedCard : supportsAuthenticatedExtendedCard // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentProviderCopyWith<$Res>? get provider {
    if (_self.provider == null) {
    return null;
  }

  return $AgentProviderCopyWith<$Res>(_self.provider!, (value) {
    return _then(_self.copyWith(provider: value));
  });
}/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentCapabilitiesCopyWith<$Res> get capabilities {
  
  return $AgentCapabilitiesCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}
}


/// Adds pattern-matching-related methods to [AgentCard].
extension AgentCardPatterns on AgentCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentCard value)  $default,){
final _that = this;
switch (_that) {
case _AgentCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentCard value)?  $default,){
final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String protocolVersion,  String name,  String description,  String url,  TransportProtocol? preferredTransport,  List<AgentInterface>? additionalInterfaces,  String? iconUrl,  AgentProvider? provider,  String version,  String? documentationUrl,  AgentCapabilities capabilities,  Map<String, SecurityScheme>? securitySchemes,  List<Map<String, List<String>>>? security,  List<String> defaultInputModes,  List<String> defaultOutputModes,  List<AgentSkill> skills,  bool? supportsAuthenticatedExtendedCard)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
return $default(_that.protocolVersion,_that.name,_that.description,_that.url,_that.preferredTransport,_that.additionalInterfaces,_that.iconUrl,_that.provider,_that.version,_that.documentationUrl,_that.capabilities,_that.securitySchemes,_that.security,_that.defaultInputModes,_that.defaultOutputModes,_that.skills,_that.supportsAuthenticatedExtendedCard);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String protocolVersion,  String name,  String description,  String url,  TransportProtocol? preferredTransport,  List<AgentInterface>? additionalInterfaces,  String? iconUrl,  AgentProvider? provider,  String version,  String? documentationUrl,  AgentCapabilities capabilities,  Map<String, SecurityScheme>? securitySchemes,  List<Map<String, List<String>>>? security,  List<String> defaultInputModes,  List<String> defaultOutputModes,  List<AgentSkill> skills,  bool? supportsAuthenticatedExtendedCard)  $default,) {final _that = this;
switch (_that) {
case _AgentCard():
return $default(_that.protocolVersion,_that.name,_that.description,_that.url,_that.preferredTransport,_that.additionalInterfaces,_that.iconUrl,_that.provider,_that.version,_that.documentationUrl,_that.capabilities,_that.securitySchemes,_that.security,_that.defaultInputModes,_that.defaultOutputModes,_that.skills,_that.supportsAuthenticatedExtendedCard);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String protocolVersion,  String name,  String description,  String url,  TransportProtocol? preferredTransport,  List<AgentInterface>? additionalInterfaces,  String? iconUrl,  AgentProvider? provider,  String version,  String? documentationUrl,  AgentCapabilities capabilities,  Map<String, SecurityScheme>? securitySchemes,  List<Map<String, List<String>>>? security,  List<String> defaultInputModes,  List<String> defaultOutputModes,  List<AgentSkill> skills,  bool? supportsAuthenticatedExtendedCard)?  $default,) {final _that = this;
switch (_that) {
case _AgentCard() when $default != null:
return $default(_that.protocolVersion,_that.name,_that.description,_that.url,_that.preferredTransport,_that.additionalInterfaces,_that.iconUrl,_that.provider,_that.version,_that.documentationUrl,_that.capabilities,_that.securitySchemes,_that.security,_that.defaultInputModes,_that.defaultOutputModes,_that.skills,_that.supportsAuthenticatedExtendedCard);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentCard implements AgentCard {
  const _AgentCard({required this.protocolVersion, required this.name, required this.description, required this.url, this.preferredTransport, final  List<AgentInterface>? additionalInterfaces, this.iconUrl, this.provider, required this.version, this.documentationUrl, required this.capabilities, final  Map<String, SecurityScheme>? securitySchemes, final  List<Map<String, List<String>>>? security, required final  List<String> defaultInputModes, required final  List<String> defaultOutputModes, required final  List<AgentSkill> skills, this.supportsAuthenticatedExtendedCard}): _additionalInterfaces = additionalInterfaces,_securitySchemes = securitySchemes,_security = security,_defaultInputModes = defaultInputModes,_defaultOutputModes = defaultOutputModes,_skills = skills;
  factory _AgentCard.fromJson(Map<String, dynamic> json) => _$AgentCardFromJson(json);

/// The version of the A2A protocol that this agent implements.
///
/// Example: "0.1.0".
@override final  String protocolVersion;
/// A human-readable name for the agent.
///
/// Example: "Recipe Assistant".
@override final  String name;
/// A concise, human-readable description of the agent's purpose and
/// functionality.
@override final  String description;
/// The primary endpoint URL for interacting with the agent.
@override final  String url;
/// The transport protocol used by the primary endpoint specified in [url].
///
/// Defaults to [TransportProtocol.jsonrpc] if not specified.
@override final  TransportProtocol? preferredTransport;
/// A list of alternative interfaces the agent supports.
///
/// This allows an agent to expose its API via multiple transport protocols
/// or at different URLs.
 final  List<AgentInterface>? _additionalInterfaces;
/// A list of alternative interfaces the agent supports.
///
/// This allows an agent to expose its API via multiple transport protocols
/// or at different URLs.
@override List<AgentInterface>? get additionalInterfaces {
  final value = _additionalInterfaces;
  if (value == null) return null;
  if (_additionalInterfaces is EqualUnmodifiableListView) return _additionalInterfaces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// An optional URL pointing to an icon representing the agent.
@override final  String? iconUrl;
/// Information about the entity providing the agent service.
@override final  AgentProvider? provider;
/// The version string of the agent implementation itself.
///
/// The format is specific to the agent provider.
@override final  String version;
/// An optional URL pointing to human-readable documentation for the agent.
@override final  String? documentationUrl;
/// A declaration of optional A2A protocol features and extensions
/// supported by the agent.
@override final  AgentCapabilities capabilities;
/// A map of security schemes supported by the agent for authorization.
///
/// The keys are scheme names (e.g., "apiKey", "bearerAuth") which can be
/// referenced in security requirements. The values define the scheme
/// details, following the OpenAPI 3.0 Security Scheme Object structure.
 final  Map<String, SecurityScheme>? _securitySchemes;
/// A map of security schemes supported by the agent for authorization.
///
/// The keys are scheme names (e.g., "apiKey", "bearerAuth") which can be
/// referenced in security requirements. The values define the scheme
/// details, following the OpenAPI 3.0 Security Scheme Object structure.
@override Map<String, SecurityScheme>? get securitySchemes {
  final value = _securitySchemes;
  if (value == null) return null;
  if (_securitySchemes is EqualUnmodifiableMapView) return _securitySchemes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// A list of security requirements that apply globally to all interactions
/// with this agent, unless overridden by a specific skill or method.
///
/// Each item in the list is a map representing a disjunction (OR) of
/// security schemes. Within each map, the keys are scheme names from
/// [securitySchemes], and the values are lists of required scopes (AND).
 final  List<Map<String, List<String>>>? _security;
/// A list of security requirements that apply globally to all interactions
/// with this agent, unless overridden by a specific skill or method.
///
/// Each item in the list is a map representing a disjunction (OR) of
/// security schemes. Within each map, the keys are scheme names from
/// [securitySchemes], and the values are lists of required scopes (AND).
@override List<Map<String, List<String>>>? get security {
  final value = _security;
  if (value == null) return null;
  if (_security is EqualUnmodifiableListView) return _security;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Default set of supported input MIME types (e.g., "text/plain") for all
/// skills.
///
/// This can be overridden on a per-skill basis in [AgentSkill].
 final  List<String> _defaultInputModes;
/// Default set of supported input MIME types (e.g., "text/plain") for all
/// skills.
///
/// This can be overridden on a per-skill basis in [AgentSkill].
@override List<String> get defaultInputModes {
  if (_defaultInputModes is EqualUnmodifiableListView) return _defaultInputModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_defaultInputModes);
}

/// Default set of supported output MIME types (e.g., "application/json") for
/// all skills.
///
/// This can be overridden on a per-skill basis in [AgentSkill].
 final  List<String> _defaultOutputModes;
/// Default set of supported output MIME types (e.g., "application/json") for
/// all skills.
///
/// This can be overridden on a per-skill basis in [AgentSkill].
@override List<String> get defaultOutputModes {
  if (_defaultOutputModes is EqualUnmodifiableListView) return _defaultOutputModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_defaultOutputModes);
}

/// The set of skills (distinct functionalities) that the agent can perform.
 final  List<AgentSkill> _skills;
/// The set of skills (distinct functionalities) that the agent can perform.
@override List<AgentSkill> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

/// Indicates whether the agent can provide an extended agent card with
/// potentially more details to authenticated users.
///
/// Defaults to `false` if not specified.
@override final  bool? supportsAuthenticatedExtendedCard;

/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentCardCopyWith<_AgentCard> get copyWith => __$AgentCardCopyWithImpl<_AgentCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentCard&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&(identical(other.preferredTransport, preferredTransport) || other.preferredTransport == preferredTransport)&&const DeepCollectionEquality().equals(other._additionalInterfaces, _additionalInterfaces)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.version, version) || other.version == version)&&(identical(other.documentationUrl, documentationUrl) || other.documentationUrl == documentationUrl)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&const DeepCollectionEquality().equals(other._securitySchemes, _securitySchemes)&&const DeepCollectionEquality().equals(other._security, _security)&&const DeepCollectionEquality().equals(other._defaultInputModes, _defaultInputModes)&&const DeepCollectionEquality().equals(other._defaultOutputModes, _defaultOutputModes)&&const DeepCollectionEquality().equals(other._skills, _skills)&&(identical(other.supportsAuthenticatedExtendedCard, supportsAuthenticatedExtendedCard) || other.supportsAuthenticatedExtendedCard == supportsAuthenticatedExtendedCard));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,protocolVersion,name,description,url,preferredTransport,const DeepCollectionEquality().hash(_additionalInterfaces),iconUrl,provider,version,documentationUrl,capabilities,const DeepCollectionEquality().hash(_securitySchemes),const DeepCollectionEquality().hash(_security),const DeepCollectionEquality().hash(_defaultInputModes),const DeepCollectionEquality().hash(_defaultOutputModes),const DeepCollectionEquality().hash(_skills),supportsAuthenticatedExtendedCard);

@override
String toString() {
  return 'AgentCard(protocolVersion: $protocolVersion, name: $name, description: $description, url: $url, preferredTransport: $preferredTransport, additionalInterfaces: $additionalInterfaces, iconUrl: $iconUrl, provider: $provider, version: $version, documentationUrl: $documentationUrl, capabilities: $capabilities, securitySchemes: $securitySchemes, security: $security, defaultInputModes: $defaultInputModes, defaultOutputModes: $defaultOutputModes, skills: $skills, supportsAuthenticatedExtendedCard: $supportsAuthenticatedExtendedCard)';
}


}

/// @nodoc
abstract mixin class _$AgentCardCopyWith<$Res> implements $AgentCardCopyWith<$Res> {
  factory _$AgentCardCopyWith(_AgentCard value, $Res Function(_AgentCard) _then) = __$AgentCardCopyWithImpl;
@override @useResult
$Res call({
 String protocolVersion, String name, String description, String url, TransportProtocol? preferredTransport, List<AgentInterface>? additionalInterfaces, String? iconUrl, AgentProvider? provider, String version, String? documentationUrl, AgentCapabilities capabilities, Map<String, SecurityScheme>? securitySchemes, List<Map<String, List<String>>>? security, List<String> defaultInputModes, List<String> defaultOutputModes, List<AgentSkill> skills, bool? supportsAuthenticatedExtendedCard
});


@override $AgentProviderCopyWith<$Res>? get provider;@override $AgentCapabilitiesCopyWith<$Res> get capabilities;

}
/// @nodoc
class __$AgentCardCopyWithImpl<$Res>
    implements _$AgentCardCopyWith<$Res> {
  __$AgentCardCopyWithImpl(this._self, this._then);

  final _AgentCard _self;
  final $Res Function(_AgentCard) _then;

/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocolVersion = null,Object? name = null,Object? description = null,Object? url = null,Object? preferredTransport = freezed,Object? additionalInterfaces = freezed,Object? iconUrl = freezed,Object? provider = freezed,Object? version = null,Object? documentationUrl = freezed,Object? capabilities = null,Object? securitySchemes = freezed,Object? security = freezed,Object? defaultInputModes = null,Object? defaultOutputModes = null,Object? skills = null,Object? supportsAuthenticatedExtendedCard = freezed,}) {
  return _then(_AgentCard(
protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,preferredTransport: freezed == preferredTransport ? _self.preferredTransport : preferredTransport // ignore: cast_nullable_to_non_nullable
as TransportProtocol?,additionalInterfaces: freezed == additionalInterfaces ? _self._additionalInterfaces : additionalInterfaces // ignore: cast_nullable_to_non_nullable
as List<AgentInterface>?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AgentProvider?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,documentationUrl: freezed == documentationUrl ? _self.documentationUrl : documentationUrl // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as AgentCapabilities,securitySchemes: freezed == securitySchemes ? _self._securitySchemes : securitySchemes // ignore: cast_nullable_to_non_nullable
as Map<String, SecurityScheme>?,security: freezed == security ? _self._security : security // ignore: cast_nullable_to_non_nullable
as List<Map<String, List<String>>>?,defaultInputModes: null == defaultInputModes ? _self._defaultInputModes : defaultInputModes // ignore: cast_nullable_to_non_nullable
as List<String>,defaultOutputModes: null == defaultOutputModes ? _self._defaultOutputModes : defaultOutputModes // ignore: cast_nullable_to_non_nullable
as List<String>,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<AgentSkill>,supportsAuthenticatedExtendedCard: freezed == supportsAuthenticatedExtendedCard ? _self.supportsAuthenticatedExtendedCard : supportsAuthenticatedExtendedCard // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentProviderCopyWith<$Res>? get provider {
    if (_self.provider == null) {
    return null;
  }

  return $AgentProviderCopyWith<$Res>(_self.provider!, (value) {
    return _then(_self.copyWith(provider: value));
  });
}/// Create a copy of AgentCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgentCapabilitiesCopyWith<$Res> get capabilities {
  
  return $AgentCapabilitiesCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}
}

// dart format on
