import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_extension.freezed.dart';

part 'agent_extension.g.dart';

/// A declaration of a protocol extension supported by an Agent.
@freezed
abstract class AgentExtension with _$AgentExtension {
  const factory AgentExtension({
    /// The unique URI identifying the extension.
    required String uri,

    /// A human-readable description of how this agent uses the extension.
    String? description,

    /// If true, the client must understand and comply with the extension's
    /// requirements to interact with the agent.
    bool? required,

    /// Optional, extension-specific configuration parameters.
    Map<String, dynamic>? params,
  }) = _AgentExtension;

  factory AgentExtension.fromJson(Map<String, dynamic> json) =>
      _$AgentExtensionFromJson(json);
}
