// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport "agent_card.dart";
library;

import 'package:json_annotation/json_annotation.dart';

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
@JsonSerializable()
class AgentInterface {
  /// The URL where this interface is available.
  ///
  /// In production, this must be a valid absolute HTTPS URL.
  final String url;

  /// The transport protocol supported at this URL.
  final TransportProtocol transport;

  /// Creates an [AgentInterface].
  const AgentInterface({required this.url, required this.transport});

  /// Creates an [AgentInterface] from a JSON object.
  factory AgentInterface.fromJson(Map<String, Object?> json) =>
      _$AgentInterfaceFromJson(json);

  /// Creates a JSON object from a [AgentInterface].
  Map<String, Object?> toJson() => _$AgentInterfaceToJson(this);

  AgentInterface copyWith({String? url, TransportProtocol? transport}) {
    return AgentInterface(
      url: url ?? this.url,
      transport: transport ?? this.transport,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentInterface &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          transport == other.transport;

  @override
  int get hashCode => Object.hash(url, transport);

  @override
  String toString() => 'AgentInterface(url: $url, transport: $transport)';
}
