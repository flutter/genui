// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../string_utils.dart';
import 'agent_capabilities.dart';
import 'agent_interface.dart';
import 'agent_provider.dart';
import 'agent_skill.dart';
import 'security_scheme.dart';

part 'agent_card.g.dart';

/// A self-describing manifest for an A2A agent.
///
/// The [AgentCard] provides essential metadata about an agent, including its
/// identity, capabilities, skills, supported communication methods, and
/// security requirements. It serves as a primary discovery mechanism for
/// clients to understand how to interact with the agent, typically served from
/// `/.well-known/agent-card.json`.
@JsonSerializable()
class AgentCard {
  /// The version of the A2A protocol that this agent implements.
  ///
  /// Example: "0.1.0".
  final String protocolVersion;

  /// A human-readable name for the agent.
  ///
  /// Example: "Recipe Assistant".
  final String name;

  /// A concise, human-readable description of the agent's purpose and
  /// functionality.
  final String description;

  /// The primary endpoint URL for interacting with the agent.
  final String url;

  /// The transport protocol used by the primary endpoint specified in [url].
  ///
  /// Defaults to [TransportProtocol.jsonrpc] if not specified.
  final TransportProtocol? preferredTransport;

  /// A list of alternative interfaces the agent supports.
  ///
  /// This allows an agent to expose its API via multiple transport protocols
  /// or at different URLs.
  final List<AgentInterface>? additionalInterfaces;

  /// An optional URL pointing to an icon representing the agent.
  final String? iconUrl;

  /// Information about the entity providing the agent service.
  final AgentProvider? provider;

  /// The version string of the agent implementation itself.
  ///
  /// The format is specific to the agent provider.
  final String version;

  /// An optional URL pointing to human-readable documentation for the agent.
  final String? documentationUrl;

  /// A declaration of optional A2A protocol features and extensions
  /// supported by the agent.
  final AgentCapabilities capabilities;

  /// A map of security schemes supported by the agent for authorization.
  ///
  /// The keys are scheme names (e.g., "apiKey", "bearerAuth") which can be
  /// referenced in security requirements. The values define the scheme
  /// details, following the OpenAPI 3.0 Security Scheme Object structure.
  final Map<String, SecurityScheme>? securitySchemes;

  /// A list of security requirements that apply globally to all interactions
  /// with this agent, unless overridden by a specific skill or method.
  ///
  /// Each item in the list is a map representing a disjunction (OR) of
  /// security schemes. Within each map, the keys are scheme names from
  /// [securitySchemes], and the values are lists of required scopes (AND).
  final List<Map<String, List<String>>>? security;

  /// Default set of supported input MIME types (e.g., "text/plain") for all
  /// skills.
  ///
  /// This can be overridden on a per-skill basis in [AgentSkill].
  final List<String> defaultInputModes;

  /// Default set of supported output MIME types (e.g., "application/json") for
  /// all skills.
  ///
  /// This can be overridden on a per-skill basis in [AgentSkill].
  final List<String> defaultOutputModes;

  /// The set of skills (distinct functionalities) that the agent can perform.
  final List<AgentSkill> skills;

  /// Indicates whether the agent can provide an extended agent card with
  /// potentially more details to authenticated users.
  ///
  /// Defaults to `false` if not specified.
  final bool? supportsAuthenticatedExtendedCard;

  /// Creates an [AgentCard] instance.
  const AgentCard({
    required this.protocolVersion,
    required this.name,
    required this.description,
    required this.url,
    this.preferredTransport,
    this.additionalInterfaces,
    this.iconUrl,
    this.provider,
    required this.version,
    this.documentationUrl,
    required this.capabilities,
    this.securitySchemes,
    this.security,
    required this.defaultInputModes,
    required this.defaultOutputModes,
    required this.skills,
    this.supportsAuthenticatedExtendedCard,
  });

  /// Deserializes an [AgentCard] instance from a JSON object.
  factory AgentCard.fromJson(Map<String, Object?> json) =>
      _$AgentCardFromJson(json);

  /// Creates a JSON object from a [AgentCard].
  Map<String, Object?> toJson() => _$AgentCardToJson(this);

  AgentCard copyWith({
    String? protocolVersion,
    String? name,
    String? description,
    String? url,
    TransportProtocol? preferredTransport,
    List<AgentInterface>? additionalInterfaces,
    String? iconUrl,
    AgentProvider? provider,
    String? version,
    String? documentationUrl,
    AgentCapabilities? capabilities,
    Map<String, SecurityScheme>? securitySchemes,
    List<Map<String, List<String>>>? security,
    List<String>? defaultInputModes,
    List<String>? defaultOutputModes,
    List<AgentSkill>? skills,
    bool? supportsAuthenticatedExtendedCard,
  }) {
    return AgentCard(
      protocolVersion: protocolVersion ?? this.protocolVersion,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      preferredTransport: preferredTransport ?? this.preferredTransport,
      additionalInterfaces: additionalInterfaces ?? this.additionalInterfaces,
      iconUrl: iconUrl ?? this.iconUrl,
      provider: provider ?? this.provider,
      version: version ?? this.version,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      capabilities: capabilities ?? this.capabilities,
      securitySchemes: securitySchemes ?? this.securitySchemes,
      security: security ?? this.security,
      defaultInputModes: defaultInputModes ?? this.defaultInputModes,
      defaultOutputModes: defaultOutputModes ?? this.defaultOutputModes,
      skills: skills ?? this.skills,
      supportsAuthenticatedExtendedCard:
          supportsAuthenticatedExtendedCard ??
          this.supportsAuthenticatedExtendedCard,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCard &&
          runtimeType == other.runtimeType &&
          protocolVersion == other.protocolVersion &&
          name == other.name &&
          description == other.description &&
          url == other.url &&
          preferredTransport == other.preferredTransport &&
          const DeepCollectionEquality().equals(
            additionalInterfaces,
            other.additionalInterfaces,
          ) &&
          iconUrl == other.iconUrl &&
          provider == other.provider &&
          version == other.version &&
          documentationUrl == other.documentationUrl &&
          capabilities == other.capabilities &&
          const DeepCollectionEquality().equals(
            securitySchemes,
            other.securitySchemes,
          ) &&
          const DeepCollectionEquality().equals(security, other.security) &&
          const DeepCollectionEquality().equals(
            defaultInputModes,
            other.defaultInputModes,
          ) &&
          const DeepCollectionEquality().equals(
            defaultOutputModes,
            other.defaultOutputModes,
          ) &&
          const DeepCollectionEquality().equals(skills, other.skills) &&
          supportsAuthenticatedExtendedCard ==
              other.supportsAuthenticatedExtendedCard;

  @override
  int get hashCode =>
      protocolVersion.hashCode ^
      name.hashCode ^
      description.hashCode ^
      url.hashCode ^
      preferredTransport.hashCode ^
      const DeepCollectionEquality().hash(additionalInterfaces) ^
      iconUrl.hashCode ^
      provider.hashCode ^
      version.hashCode ^
      documentationUrl.hashCode ^
      capabilities.hashCode ^
      const DeepCollectionEquality().hash(securitySchemes) ^
      const DeepCollectionEquality().hash(security) ^
      const DeepCollectionEquality().hash(defaultInputModes) ^
      const DeepCollectionEquality().hash(defaultOutputModes) ^
      const DeepCollectionEquality().hash(skills) ^
      supportsAuthenticatedExtendedCard.hashCode;

  @override
  String toString() => buildToString('AgentCard', {
        'protocolVersion': protocolVersion,
        'name': name,
        'description': description,
        'url': url,
        'preferredTransport': preferredTransport,
        'additionalInterfaces': additionalInterfaces,
        'iconUrl': iconUrl,
        'provider': provider,
        'version': version,
        'documentationUrl': documentationUrl,
        'capabilities': capabilities,
        'securitySchemes': securitySchemes,
        'security': security,
        'defaultInputModes': defaultInputModes,
        'defaultOutputModes': defaultOutputModes,
        'skills': skills,
        'supportsAuthenticatedExtendedCard': supportsAuthenticatedExtendedCard,
      });
}
