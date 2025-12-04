// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_capabilities.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_extension.freezed.dart';
part 'agent_extension.g.dart';

/// Specifies an extension to the A2A protocol supported by an agent.
///
/// Used in [AgentCapabilities] to list supported protocol extensions, allowing
/// agents to advertise custom features beyond the core A2A specification.
@freezed
abstract class AgentExtension with _$AgentExtension {
  /// Creates an [AgentExtension].
  const factory AgentExtension({
    /// The unique URI identifying the extension.
    required String uri,

    /// A human-readable description of the extension.
    String? description,

    /// If true, the client must understand and comply with the extension's
    /// requirements to interact with the agent.
    bool? required,

    /// Optional, extension-specific configuration parameters.
    Map<String, Object?>? params,
  }) = _AgentExtension;

  /// Creates an [AgentExtension] from a JSON object.
  factory AgentExtension.fromJson(Map<String, Object?> json) =>
      _$AgentExtensionFromJson(json);
}
