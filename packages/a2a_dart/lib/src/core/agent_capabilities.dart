// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent_extension.dart';

part 'agent_capabilities.freezed.dart';
part 'agent_capabilities.g.dart';

/// Defines the optional capabilities that an agent supports.
///
/// This class is part of the [AgentCard] and provides a way for an agent to
/// advertise its features, such as support for streaming or push notifications.
@freezed
abstract class AgentCapabilities with _$AgentCapabilities {
  /// Creates an [AgentCapabilities] object.
  const factory AgentCapabilities({
    /// Indicates whether the agent supports Server-Sent Events (SSE) for
    /// streaming responses.
    ///
    /// If `true`, the agent can send multiple responses over a single connection.
    bool? streaming,

    /// Indicates whether the agent supports sending push notifications for
    /// asynchronous task updates.
    bool? pushNotifications,

    /// Indicates whether the agent provides a history of state transitions for a
    /// task.
    bool? stateTransitionHistory,

    /// A list of protocol extensions that the agent supports.
    List<AgentExtension>? extensions,
  }) = _AgentCapabilities;

  /// Creates an [AgentCapabilities] from a JSON object.
  factory AgentCapabilities.fromJson(Map<String, dynamic> json) =>
      _$AgentCapabilitiesFromJson(json);
}
