// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_card.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent_extension.dart';

part 'agent_capabilities.freezed.dart';
part 'agent_capabilities.g.dart';

/// Defines optional capabilities supported by an agent.
///
/// Part of the [AgentCard], this class allows an agent to advertise its
/// features, such as support for streaming or push notifications.
@freezed
abstract class AgentCapabilities with _$AgentCapabilities {
  /// Creates an [AgentCapabilities] object.
  const factory AgentCapabilities({
    /// Indicates if the agent supports Server-Sent Events (SSE) for streaming
    /// responses.
    bool? streaming,

    /// Indicates whether the agent supports sending push notifications for
    /// asynchronous task updates.
    bool? pushNotifications,

    /// Indicates whether the agent provides a history of state transitions for
    /// a task.
    bool? stateTransitionHistory,

    /// A list of protocol extensions supported by the agent.
    List<AgentExtension>? extensions,
  }) = _AgentCapabilities;

  /// Creates an [AgentCapabilities] from a JSON object.
  factory AgentCapabilities.fromJson(Map<String, Object?> json) =>
      _$AgentCapabilitiesFromJson(json);
}
