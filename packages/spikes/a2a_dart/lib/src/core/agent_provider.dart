import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_provider.freezed.dart';

part 'agent_provider.g.dart';

/// Represents the service provider of an agent.
@freezed
abstract class AgentProvider with _$AgentProvider {
  const factory AgentProvider({
    /// The name of the agent provider's organization.
    required String organization,

    /// A URL for the agent provider's website or relevant documentation.
    required String url,
  }) = _AgentProvider;

  factory AgentProvider.fromJson(Map<String, dynamic> json) =>
      _$AgentProviderFromJson(json);
}
