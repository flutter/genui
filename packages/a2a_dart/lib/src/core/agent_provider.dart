// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../a2a_dart.dart' show AgentCard;

import 'agent_card.dart' show AgentCard;

part 'agent_provider.freezed.dart';

part 'agent_provider.g.dart';

/// Represents the service provider of an agent.
///
/// This class is part of the [AgentCard] and provides information about the
/// entity that created and maintains the agent.
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
  factory AgentProvider.fromJson(Map<String, dynamic> json) =>
      _$AgentProviderFromJson(json);
}
