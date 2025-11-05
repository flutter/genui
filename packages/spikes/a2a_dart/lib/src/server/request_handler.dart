import 'dart:async';

/// A handler for a specific A2A RPC method.
///
/// Implement this class to create a handler for a specific RPC method. The
/// [A2AServer] will delegate requests to the appropriate handler based on the
/// method name.
abstract class RequestHandler {
  /// The name of the RPC method this handler supports.
  String get method;

  /// Handles an incoming request.
  ///
  /// The [params] are the parameters of the RPC call. This method should return
  /// a [FutureOr] of a [Map] that will be sent as the `result` of the JSON-RPC
  /// 2.0 response.
  FutureOr<Map<String, dynamic>> handle(Map<String, dynamic> params);
}
