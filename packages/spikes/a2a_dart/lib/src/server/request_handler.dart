import 'dart:async';

import 'package:shelf/shelf.dart';

/// A handler for a specific A2A RPC method.
abstract class RequestHandler {
  /// The name of the RPC method this handler supports.
  String get method;

  /// Handles an incoming request.
  FutureOr<Response> handle(Request request);
}
