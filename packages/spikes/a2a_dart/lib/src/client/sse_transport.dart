import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_transport.dart';

/// An implementation of [Transport] that uses Server-Sent Events (SSE) for
/// streaming communication.
///
/// This class extends [HttpTransport] and adds support for streaming responses
/// from the server. It should be used when real-time, bidirectional
/// communication is required. For simple request-response interactions,
/// [HttpTransport] is sufficient.
class SseTransport extends HttpTransport {
  /// Creates an [SseTransport].
  ///
  /// The [url] is the base URL of the A2A server. An optional [client] can be
  /// provided for testing or to customize the HTTP client.
  SseTransport({required super.url, super.client});

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) {
    final httpRequest = http.Request('POST', Uri.parse('$url/rpc'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode(request);

    final controller = StreamController<Map<String, dynamic>>();

    client.send(httpRequest).then((response) {
      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            final dataString = line.substring('data: '.length);
            if (dataString.isNotEmpty) {
              try {
                final data = jsonDecode(dataString) as Map<String, dynamic>;
                if (data.containsKey('result')) {
                  controller.add(data['result'] as Map<String, dynamic>);
                } else if (data.containsKey('error')) {
                  controller.addError(data['error']);
                }
              } catch (e) {
                controller.addError(e);
              }
            }
          }
        },
        onError: controller.addError,
        onDone: controller.close,
        cancelOnError: true,
      );
    }).catchError((dynamic error) {
      controller.addError(error);
      controller.close();
    });

    return controller.stream;
  }
}
