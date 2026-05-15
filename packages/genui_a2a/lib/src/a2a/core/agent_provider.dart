// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport "agent_card.dart";
library;

import 'package:json_annotation/json_annotation.dart';

part 'agent_provider.g.dart';

/// Information about the agent's service provider.
///
/// Part of the [AgentCard], this provides information about the entity that
/// created and maintains the agent.
@JsonSerializable()
class AgentProvider {
  /// The name of the agent provider's organization.
  final String organization;

  /// A URL for the agent provider's website or relevant documentation.
  final String url;

  /// Creates an [AgentProvider].
  const AgentProvider({required this.organization, required this.url});

  /// Creates an [AgentProvider] from a JSON object.
  factory AgentProvider.fromJson(Map<String, Object?> json) =>
      _$AgentProviderFromJson(json);

  /// Creates a JSON object from a [AgentProvider].
  Map<String, Object?> toJson() => _$AgentProviderToJson(this);

  AgentProvider copyWith({String? organization, String? url}) {
    return AgentProvider(
      organization: organization ?? this.organization,
      url: url ?? this.url,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentProvider &&
          runtimeType == other.runtimeType &&
          organization == other.organization &&
          url == other.url;

  @override
  int get hashCode => Object.hash(organization, url);

  @override
  String toString() => 'AgentProvider(organization: $organization, url: $url)';
}
