// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart';

import '../core/agent_card.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Stub implementation of A2AServer for web platforms.
///
/// The A2A server functionality is not supported in browser environments.
/// All methods in this class throw [UnsupportedError].
class A2AServer {
  /// Attempts to create an instance of [A2AServer].
  ///
  /// Throws an [UnsupportedError] because server functionality is not available
  /// on the web.
  A2AServer(
    List<RequestHandler> handlers,
    TaskManager taskManager, {
    String host = 'localhost',
    int port = 0,
    Logger? logger,
    AgentCard? agentCard,
    AgentCard? extendedAgentCard,
    Object? initialMiddleware,
  }) {
    throw UnsupportedError('Cannot create an A2AServer on the web.');
  }

  /// The hostname the server would listen on.
  ///
  /// Throws an [UnsupportedError].
  String get host => throw UnsupportedError('Cannot get the host on the web.');

  /// The port number the server would listen on.
  ///
  /// Throws an [UnsupportedError].
  int get port => throw UnsupportedError('Cannot get the port on the web.');

  /// Registers a request handler.
  ///
  /// Throws an [UnsupportedError].
  void registerHandler(RequestHandler handler) {
    throw UnsupportedError('Cannot register a handler on the web.');
  }

  /// The logger instance.
  ///
  /// Throws an [UnsupportedError].
  Logger? get logger =>
      throw UnsupportedError('Cannot get the logger on the web.');

  /// Starts the server.
  ///
  /// Throws an [UnsupportedError].
  Future<void> start() async {
    throw UnsupportedError('Cannot start the server on the web.');
  }

  /// Stops the server.
  ///
  /// Throws an [UnsupportedError].
  Future<void> stop() async {
    throw UnsupportedError('Cannot stop the server on the web.');
  }
}
