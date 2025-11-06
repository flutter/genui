// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../a2a_dart.dart' show AgentCapabilities;

import 'agent_capabilities.dart' show AgentCapabilities;

part 'agent_extension.freezed.dart';

part 'agent_extension.g.dart';

/// A declaration of a protocol extension supported by an agent.
///
/// This class is used in the [AgentCapabilities] to list the protocol
/// extensions that an agent supports. It provides a way for agents to advertise
/// custom features that are not part of the core A2A specification.
@freezed
abstract class AgentExtension with _$AgentExtension {
  /// Creates an [AgentExtension].
  const factory AgentExtension({
    /// A unique URI that identifies the extension.
    required String uri,

    /// A human-readable description of how this agent uses the extension.
    String? description,

    /// If `true`, the client must understand and comply with the extension's
    /// requirements to interact with the agent.
    bool? required,

    /// Optional, extension-specific configuration parameters.
    Map<String, dynamic>? params,
  }) = _AgentExtension;

  /// Creates an [AgentExtension] from a JSON object.
  factory AgentExtension.fromJson(Map<String, dynamic> json) =>
      _$AgentExtensionFromJson(json);
}
