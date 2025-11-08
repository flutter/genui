// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../a2a_dart.dart' show A2AServerException;
import 'a2a_server.dart';
import 'a2a_server_exception.dart' show A2AServerException;
import 'handler_result.dart';

/// Defines the interface for handling a specific A2A JSON-RPC method.
///
/// Implementations of this class are responsible for processing requests for
/// a single RPC method. The [A2AServer] uses these handlers to delegate
/// incoming requests based on the method name.
abstract class RequestHandler {
  /// The name of the JSON-RPC method this handler is responsible for.
  ///
  /// Example: 'tasks/get', 'message/send'.
  String get method;

  /// Specifies the security requirements for invoking this method.
  ///
  /// This is a list of security requirement objects, where each object maps
  /// security scheme names (defined in the agent's `AgentCard.securitySchemes`)
  /// to a list of required scopes.
  ///
  /// An empty list (`[]`) means the handler is public and requires no
  /// authentication. A `null` value means the server's default security
  /// policies apply.
  ///
  /// Example: `[{ "bearerAuth": ["read:tasks"] }]` - Requires Bearer
  /// authentication with the `read:tasks` scope.
  List<Map<String, List<String>>>? get securityRequirements => null;

  /// Processes an incoming JSON-RPC request for this handler's [method].
  ///
  /// The [params] map contains the parameters provided in the JSON-RPC request.
  /// This method should return a [FutureOr] of a [HandlerResult], which can be
  /// either a [SingleResult] for a standard response or a [StreamResult] for
  /// a streaming response.
  ///
  /// Implementations should throw [A2AServerException] for expected error
  /// conditions that need to be communicated back to the client as JSON-RPC
  /// errors.
  FutureOr<HandlerResult> handle(Map<String, Object?> params);
}
