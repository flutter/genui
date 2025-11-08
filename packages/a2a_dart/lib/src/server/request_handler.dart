// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'a2a_server.dart';
import 'handler_result.dart';

/// An interface for a handler of a specific A2A RPC method.
///
/// Implement this class to create a handler for a specific RPC method. The
/// [A2AServer] will delegate requests to the appropriate handler based on the
/// method name.
abstract class RequestHandler {
  /// The name of the RPC method this handler supports (e.g., 'tasks/get').
  String get method;

  /// The security requirements for this handler. Each map represents a security
  /// scheme, where the key is the scheme name (from AgentCard.securitySchemes)
  /// and the value is a list of scopes required for this method.
  /// An empty list means the handler is public.
  /// Defaults to null, meaning the server's default security applies.
  List<Map<String, List<String>>>? get securityRequirements => null;

  /// Handles an incoming request.
  ///
  /// The [params] are the parameters of the RPC call. This method should return
  /// a [FutureOr] of a [HandlerResult] which will be sent as the `result` of
  /// the JSON-RPC 2.0 response.
  FutureOr<HandlerResult> handle(Map<String, Object?> params);
}
