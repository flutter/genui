import 'dart:async';

/// A handler for a specific A2A RPC method.
abstract class RequestHandler {
  /// The name of the RPC method this handler supports.
  String get method;

  /// Handles an incoming request.
  FutureOr<Map<String, dynamic>> handle(Map<String, dynamic> params);
}
