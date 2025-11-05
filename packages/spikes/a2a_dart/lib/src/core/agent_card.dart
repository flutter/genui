import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent_capabilities.dart';
import 'agent_interface.dart';
import 'agent_provider.dart';
import 'agent_skill.dart';
import 'security_scheme.dart';

part 'agent_card.freezed.dart';
part 'agent_card.g.dart';

/// A self-describing manifest for an agent, providing essential metadata.
///
/// The AgentCard includes the agent's identity, capabilities, skills, supported
/// communication methods, and security requirements. It serves as a discovery
/// mechanism for clients to understand how to interact with the agent.
@freezed
abstract class AgentCard with _$AgentCard {
  /// Creates an [AgentCard].
  const factory AgentCard({
    /// The version of the A2A protocol that this agent supports.
    required String protocolVersion,

    /// A human-readable name for the agent (e.g., "Weather Bot").
    required String name,

    /// A brief summary of the agent's purpose and capabilities.
    required String description,

    /// A URL for the agent's website or relevant documentation.
    required String url,

    /// The preferred transport protocol for this agent (e.g., "sse").
    TransportProtocol? preferredTransport,

    /// A list of additional communication interfaces the agent supports.
    List<AgentInterface>? additionalInterfaces,

    /// A URL for an icon representing the agent.
    String? iconUrl,

    /// Information about the entity that provides the agent.
    AgentProvider? provider,

    /// The version of the agent's software (e.g., "1.2.3").
    required String version,

    /// A URL for the agent's detailed documentation.
    String? documentationUrl,

    /// The capabilities of the agent, such as supported extensions.
    required AgentCapabilities capabilities,

    /// The security schemes supported by the agent (e.g., OAuth 2.0).
    Map<String, SecurityScheme>? securitySchemes,

    /// The security requirements for accessing the agent's services.
    List<Map<String, List<String>>>? security,

    /// The default input modes for the agent (e.g., "text/plain").
    required List<String> defaultInputModes,

    /// The default output modes for the agent (e.g., "application/json").
    required List<String> defaultOutputModes,

    /// The skills or functionalities that the agent can perform.
    required List<AgentSkill> skills,

    /// Indicates whether the agent supports authenticated extended card requests.
    bool? supportsAuthenticatedExtendedCard,
  }) = _AgentCard;

  /// Creates an [AgentCard] from a JSON object.
  factory AgentCard.fromJson(Map<String, dynamic> json) =>
      _$AgentCardFromJson(json);
}
