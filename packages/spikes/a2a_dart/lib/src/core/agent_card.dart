import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent_capabilities.dart';
import 'agent_interface.dart';
import 'agent_provider.dart';
import 'agent_skill.dart';
import 'security_scheme.dart';

part 'agent_card.freezed.dart';
part 'agent_card.g.dart';

/// The AgentCard is a self-describing manifest for an agent. It provides
/// essential metadata including the agent's identity, capabilities, skills,
/// supported communication methods, and security requirements.
@freezed
abstract class AgentCard with _$AgentCard {
  const factory AgentCard({
    /// The version of the A2A protocol this agent supports.
    required String protocolVersion,

    /// A human-readable name for the agent.
    required String name,

    /// A short description of the agent's purpose and capabilities.
    required String description,

    /// A URL for the agent's website or relevant documentation.
    required String url,

    /// The preferred transport protocol for this agent.
    TransportProtocol? preferredTransport,

    /// A list of additional interfaces the agent supports.
    List<AgentInterface>? additionalInterfaces,

    /// A URL for an icon representing the agent.
    String? iconUrl,

    /// Information about the agent's provider.
    AgentProvider? provider,

    /// The version of the agent's software.
    required String version,

    /// A URL for the agent's detailed documentation.
    String? documentationUrl,

    /// The capabilities of the agent.
    required AgentCapabilities capabilities,

    /// The security schemes supported by the agent.
    Map<String, SecurityScheme>? securitySchemes,

    /// The security requirements for the agent.
    List<Map<String, List<String>>>? security,

    /// The default input modes for the agent.
    required List<String> defaultInputModes,

    /// The default output modes for the agent.
    required List<String> defaultOutputModes,

    /// The skills supported by the agent.
    required List<AgentSkill> skills,

    /// Whether the agent supports authenticated extended card requests.
    bool? supportsAuthenticatedExtendedCard,
  }) = _AgentCard;

  factory AgentCard.fromJson(Map<String, dynamic> json) =>
      _$AgentCardFromJson(json);
}
