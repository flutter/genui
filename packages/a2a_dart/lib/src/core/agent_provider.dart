// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_card.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_provider.freezed.dart';
part 'agent_provider.g.dart';

/// Information about the agent's service provider.
///
/// Part of the [AgentCard], this provides information about the entity that
/// created and maintains the agent.
@freezed
abstract class AgentProvider with _$AgentProvider {
  /// Creates an [AgentProvider].
  const factory AgentProvider({
    /// The name of the agent provider's organization.
    required String organization,

    /// A URL for the agent provider's website or relevant documentation.
    required String url,
  }) = _AgentProvider;

  /// Creates an [AgentProvider] from a JSON object.
  factory AgentProvider.fromJson(Map<String, Object?> json) =>
      _$AgentProviderFromJson(json);
}
