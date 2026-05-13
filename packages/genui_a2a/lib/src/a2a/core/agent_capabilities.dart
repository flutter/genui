// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_card.dart';
library;

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../string_utils.dart';

import 'agent_extension.dart';

part 'agent_capabilities.g.dart';

/// Describes the optional features and extensions an A2A agent supports.
///
/// This class is part of the [AgentCard] and allows an agent to advertise
/// its capabilities to clients, such as support for streaming, push
/// notifications, and custom protocol extensions.
@JsonSerializable()
class AgentCapabilities {
  /// Indicates if the agent supports streaming responses, typically via
  /// Server-Sent Events (SSE).
  ///
  /// A value of `true` means the client can use methods like `message/stream`.
  final bool? streaming;

  /// Indicates if the agent supports sending push notifications for
  /// asynchronous task updates to a client-specified endpoint.
  final bool? pushNotifications;

  /// Indicates if the agent maintains and can provide a history of state
  /// transitions for tasks.
  final bool? stateTransitionHistory;

  /// A list of non-standard protocol extensions supported by the agent.
  ///
  /// See [AgentExtension] for more details.
  final List<AgentExtension>? extensions;

  /// Creates an instance of [AgentCapabilities].
  ///
  /// All parameters are optional and default to null if not provided,
  /// indicating the capability is not specified.
  const AgentCapabilities({
    this.streaming,
    this.pushNotifications,
    this.stateTransitionHistory,
    this.extensions,
  });

  /// Deserializes an [AgentCapabilities] instance from a JSON object.
  factory AgentCapabilities.fromJson(Map<String, Object?> json) =>
      _$AgentCapabilitiesFromJson(json);

  /// Creates a JSON object from a [AgentCapabilities].
  Map<String, Object?> toJson() => _$AgentCapabilitiesToJson(this);

  AgentCapabilities copyWith({
    bool? streaming,
    bool? pushNotifications,
    bool? stateTransitionHistory,
    List<AgentExtension>? extensions,
  }) {
    return AgentCapabilities(
      streaming: streaming ?? this.streaming,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      stateTransitionHistory:
          stateTransitionHistory ?? this.stateTransitionHistory,
      extensions: extensions ?? this.extensions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCapabilities &&
          runtimeType == other.runtimeType &&
          streaming == other.streaming &&
          pushNotifications == other.pushNotifications &&
          stateTransitionHistory == other.stateTransitionHistory &&
          const DeepCollectionEquality().equals(extensions, other.extensions);

  @override
  int get hashCode => Object.hash(
    streaming,
    pushNotifications,
    stateTransitionHistory,
    const DeepCollectionEquality().hash(extensions),
  );

  @override
  String toString() => buildToString('AgentCapabilities', {
    'streaming': streaming,
    'pushNotifications': pushNotifications,
    'stateTransitionHistory': stateTransitionHistory,
    'extensions': extensions,
  });
}
