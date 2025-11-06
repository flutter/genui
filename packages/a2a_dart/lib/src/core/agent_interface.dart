// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_interface.freezed.dart';

part 'agent_interface.g.dart';

/// Defines the transport protocols that can be used for A2A communication.
enum TransportProtocol {
  /// JSON-RPC 2.0 over HTTP.
  @JsonValue('JSONRPC')
  jsonrpc,

  /// gRPC over HTTP/2.
  @JsonValue('GRPC')
  grpc,

  /// REST-style HTTP with JSON.
  @JsonValue('HTTP+JSON')
  httpJson,
}

/// Declares a communication interface for an agent, combining a URL with a
/// specific transport protocol.
///
/// Part of the [AgentCard], this allows an agent to advertise multiple endpoints
/// or protocols for interaction.
@freezed
abstract class AgentInterface with _$AgentInterface {
  /// Creates an [AgentInterface].
  const factory AgentInterface({
    /// The URL where this interface is available.
    ///
    /// In a production environment, this must be a valid absolute HTTPS URL.
    required String url,

    /// The transport protocol supported at this URL.
    required TransportProtocol transport,
  }) = _AgentInterface;

  /// Creates an [AgentInterface] from a JSON object.
  factory AgentInterface.fromJson(Map<String, dynamic> json) =>
      _$AgentInterfaceFromJson(json);
}
