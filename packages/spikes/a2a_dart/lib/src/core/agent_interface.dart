import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_interface.freezed.dart';

part 'agent_interface.g.dart';

/// Supported A2A transport protocols.
enum TransportProtocol {
  /// JSON-RPC 2.0 over HTTP (optional)
  @JsonValue('JSONRPC')
  jsonrpc,

  /// gRPC over HTTP/2 (optional)
  @JsonValue('GRPC')
  grpc,

  /// REST-style HTTP with JSON (optional)
  @JsonValue('HTTP+JSON')
  httpJson,
}

/// Declares a combination of a target URL and a transport protocol for
/// interacting with the agent.
@freezed
abstract class AgentInterface with _$AgentInterface {
  const factory AgentInterface({
    /// The URL where this interface is available. Must be a valid absolute HTTPS
    /// URL in production.
    required String url,

    /// The transport protocol supported at this URL.
    required TransportProtocol transport,
  }) = _AgentInterface;

  factory AgentInterface.fromJson(Map<String, dynamic> json) =>
      _$AgentInterfaceFromJson(json);
}
