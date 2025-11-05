import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent_extension.dart';

part 'agent_capabilities.freezed.dart';
part 'agent_capabilities.g.dart';

/// Defines optional capabilities supported by an agent.
@freezed
abstract class AgentCapabilities with _$AgentCapabilities {
  const factory AgentCapabilities({
    /// Indicates if the agent supports Server-Sent Events (SSE) for streaming
    /// responses.
    bool? streaming,

    /// Indicates if the agent supports sending push notifications for asynchronous
    /// task updates.
    bool? pushNotifications,

    /// Indicates if the agent provides a history of state transitions for a task.
    bool? stateTransitionHistory,

    /// A list of protocol extensions supported by the agent.
    List<AgentExtension>? extensions,
  }) = _AgentCapabilities;

  factory AgentCapabilities.fromJson(Map<String, dynamic> json) =>
      _$AgentCapabilitiesFromJson(json);
}
