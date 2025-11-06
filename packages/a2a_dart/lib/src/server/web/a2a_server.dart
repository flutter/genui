// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart';

import '../request_handler.dart';

/// A class that represents an A2A server.
///
/// This is a stub implementation for the web, since the server is not
/// supported in a browser environment.
class A2AServer {
  /// Creates an instance of [A2AServer].
  ///
  /// Throws an [UnsupportedError] because the server is not supported on the
  /// web.
  A2AServer(
    List<RequestHandler> handlers, {
    String host = 'localhost',
    int port = 0,
    Logger? logger,
  }) {
    throw UnsupportedError('Cannot create an A2AServer on the web.');
  }

  /// The host that the server is listening on.
  ///
  /// Throws an [UnsupportedError] because the server is not supported on the
  /// web.
  String get host => throw UnsupportedError('Cannot get the host on the web.');

  /// The port that the server is listening on.
  ///
  /// Throws an [UnsupportedError] because the server is not supported on the
  /// web.
  int get port => throw UnsupportedError('Cannot get the port on the web.');

  /// Starts the server.
  ///
  /// Throws an [UnsupportedError] because the server is not supported on the
  /// web.
  Future<void> start() async {
    throw UnsupportedError('Cannot start the server on the web.');
  }

  /// Stops the server.
  ///
  /// Throws an [UnsupportedError] because the server is not supported on the
  /// web.
  Future<void> stop() async {
    throw UnsupportedError('Cannot stop the server on the web.');
  }
}
