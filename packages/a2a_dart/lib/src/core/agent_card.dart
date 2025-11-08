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

/// A self-describing manifest for an A2A agent.
///
/// The [AgentCard] provides essential metadata about an agent, including its
/// identity, capabilities, skills, supported communication methods, and
/// security requirements. It serves as a primary discovery mechanism for
/// clients to understand how to interact with the agent, typically served from
/// `/.well-known/agent-card.json`.
@freezed
abstract class AgentCard with _$AgentCard {
  /// Creates an [AgentCard] instance.
  const factory AgentCard({
    /// The version of the A2A protocol that this agent implements.
    ///
    /// Example: "0.1.0".
    required String protocolVersion,

    /// A human-readable name for the agent.
    ///
    /// Example: "Recipe Assistant".
    required String name,

    /// A concise, human-readable description of the agent's purpose and
    /// functionality.
    required String description,

    /// The primary endpoint URL for interacting with the agent.
    required String url,

    /// The transport protocol used by the primary endpoint specified in [url].
    ///
    /// Defaults to [TransportProtocol.jsonrpc] if not specified.
    TransportProtocol? preferredTransport,

    /// A list of alternative interfaces the agent supports.
    ///
    /// This allows an agent to expose its API via multiple transport protocols
    /// or at different URLs.
    List<AgentInterface>? additionalInterfaces,

    /// An optional URL pointing to an icon representing the agent.
    String? iconUrl,

    /// Information about the entity providing the agent service.
    AgentProvider? provider,

    /// The version string of the agent implementation itself.
    ///
    /// The format is specific to the agent provider.
    required String version,

    /// An optional URL pointing to human-readable documentation for the agent.
    String? documentationUrl,

    /// A declaration of optional A2A protocol features and extensions
    /// supported by the agent.
    required AgentCapabilities capabilities,

    /// A map of security schemes supported by the agent for authorization.
    ///
    /// The keys are scheme names (e.g., "apiKey", "bearerAuth") which can be
    /// referenced in security requirements. The values define the scheme
    /// details, following the OpenAPI 3.0 Security Scheme Object structure.
    Map<String, SecurityScheme>? securitySchemes,

    /// A list of security requirements that apply globally to all interactions
    /// with this agent, unless overridden by a specific skill or method.
    ///
    /// Each item in the list is a map representing a disjunction (OR) of
    /// security schemes. Within each map, the keys are scheme names from
    /// [securitySchemes], and the values are lists of required scopes (AND).
    List<Map<String, List<String>>>? security,

    /// Default set of supported input MIME types (e.g., "text/plain") for all
    /// skills.
    ///
    /// This can be overridden on a per-skill basis in [AgentSkill].
    required List<String> defaultInputModes,

    /// Default set of supported output MIME types (e.g., "application/json") for
    /// all skills.
    ///
    /// This can be overridden on a per-skill basis in [AgentSkill].
    required List<String> defaultOutputModes,

    /// The set of skills (distinct functionalities) that the agent can perform.
    required List<AgentSkill> skills,

    /// Indicates whether the agent can provide an extended agent card with
    /// potentially more details to authenticated users.
    ///
    /// Defaults to `false` if not specified.
    bool? supportsAuthenticatedExtendedCard,
  }) = _AgentCard;

  /// Deserializes an [AgentCard] instance from a JSON object.
  factory AgentCard.fromJson(Map<String, Object?> json) =>
      _$AgentCardFromJson(json);
}
