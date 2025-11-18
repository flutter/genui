// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_card.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'agent_extension.dart';

part 'agent_capabilities.freezed.dart';
part 'agent_capabilities.g.dart';

/// Describes the optional features and extensions an A2A agent supports.
///
/// This class is part of the [AgentCard] and allows an agent to advertise
/// its capabilities to clients, such as support for streaming, push
/// notifications, and custom protocol extensions.
@freezed
abstract class AgentCapabilities with _$AgentCapabilities {
  /// Creates an instance of [AgentCapabilities].
  ///
  /// All parameters are optional and default to null if not provided,
  /// indicating the capability is not specified.
  const factory AgentCapabilities({
    /// Indicates if the agent supports streaming responses, typically via
    /// Server-Sent Events (SSE).
    ///
    /// A value of `true` means the client can use methods like `message/stream`.
    bool? streaming,

    /// Indicates if the agent supports sending push notifications for
    /// asynchronous task updates to a client-specified endpoint.
    bool? pushNotifications,

    /// Indicates if the agent maintains and can provide a history of state
    /// transitions for tasks.
    bool? stateTransitionHistory,

    /// A list of non-standard protocol extensions supported by the agent.
    ///
    /// See [AgentExtension] for more details.
    List<AgentExtension>? extensions,
  }) = _AgentCapabilities;

  /// Deserializes an [AgentCapabilities] instance from a JSON object.
  factory AgentCapabilities.fromJson(Map<String, Object?> json) =>
      _$AgentCapabilitiesFromJson(json);
}
