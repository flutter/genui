// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'agent_card.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_interface.freezed.dart';
part 'agent_interface.g.dart';

/// Supported A2A transport protocols.
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

/// Declares a combination of a target URL and a transport protocol for
/// interacting with an agent.
///
/// Part of the [AgentCard], this allows an agent to expose the same
/// functionality over multiple transport mechanisms.
@freezed
abstract class AgentInterface with _$AgentInterface {
  /// Creates an [AgentInterface].
  const factory AgentInterface({
    /// The URL where this interface is available.
    ///
    /// In production, this must be a valid absolute HTTPS URL.
    required String url,

    /// The transport protocol supported at this URL.
    required TransportProtocol transport,
  }) = _AgentInterface;

  /// Creates an [AgentInterface] from a JSON object.
  factory AgentInterface.fromJson(Map<String, Object?> json) =>
      _$AgentInterfaceFromJson(json);
}
