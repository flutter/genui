// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent_capabilities.dart';
import 'agent_interface.dart';
import 'agent_provider.dart';
import 'agent_skill.dart';
import 'security_scheme.dart';

part 'agent_card.freezed.dart';
part 'agent_card.g.dart';

/// A self-describing manifest for an agent.
///
/// The AgentCard provides essential metadata about an agent, including its
/// identity, capabilities, skills, supported communication methods, and
/// security requirements. It serves as a discovery mechanism for clients to
/// understand how to interact with the agent.
@freezed
abstract class AgentCard with _$AgentCard {
  /// Creates an [AgentCard].
  const factory AgentCard({
    /// The version of the A2A protocol that this agent supports (e.g., "0.3.0").
    required String protocolVersion,

    /// A human-readable name for the agent (e.g., "Recipe Agent").
    required String name,

    /// A human-readable description of the agent, assisting users and other
    /// agents in understanding its purpose.
    required String description,

    /// The preferred endpoint URL for interacting with the agent.
    required String url,

    /// The transport protocol for the preferred endpoint.
    ///
    /// If not specified, defaults to [TransportProtocol.jsonrpc].
    TransportProtocol? preferredTransport,

    /// A list of additional supported interfaces (transport and URL combinations).
    ///
    /// This allows agents to expose multiple transports, potentially at different
    /// URLs.
    List<AgentInterface>? additionalInterfaces,

    /// An optional URL to an icon for the agent.
    String? iconUrl,

    /// Information about the agent's service provider.
    AgentProvider? provider,

    /// The agent's own version number. The format is defined by the provider.
    required String version,

    /// An optional URL to the agent's documentation.
    String? documentationUrl,

    /// A declaration of optional capabilities supported by the agent.
    required AgentCapabilities capabilities,

    /// A declaration of the security schemes available to authorize requests.
    ///
    /// The key is the scheme name. Follows the OpenAPI 3.0 Security Scheme
    /// Object.
    Map<String, SecurityScheme>? securitySchemes,

    /// A list of security requirement objects that apply to all agent
    /// interactions.
    ///
    /// Each object lists security schemes that can be used. Follows the OpenAPI
    /// 3.0 Security Requirement Object.
    List<Map<String, List<String>>>? security,

    /// Default set of supported input MIME types for all skills, which can be
    /// overridden on a per-skill basis.
    required List<String> defaultInputModes,

    /// Default set of supported output MIME types for all skills, which can be
    /// overridden on a per-skill basis.
    required List<String> defaultOutputModes,

    /// The set of skills, or distinct capabilities, that the agent can perform.
    required List<AgentSkill> skills,

    /// If true, the agent can provide an extended agent card with additional
    /// details to authenticated users. Defaults to false.
    bool? supportsAuthenticatedExtendedCard,
  }) = _AgentCard;

  /// Creates an [AgentCard] from a JSON object.
  factory AgentCard.fromJson(Map<String, Object?> json) =>
      _$AgentCardFromJson(json);
}
