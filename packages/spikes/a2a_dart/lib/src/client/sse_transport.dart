import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'transport.dart';

/// An implementation of [Transport] that uses Server-Sent Events (SSE) for
/// communication.
class SseTransport implements Transport {
  /// The URL of the A2A server.
  final String url;

  /// Creates an [SseTransport].
  SseTransport({required this.url});

  @override
  Future<Map<String, dynamic>> get(String path) {
    // SSE transport does not support request-response.
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) {
    // SSE transport does not support request-response.
    throw UnimplementedError();
  }

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) {
    final client = http.Client();
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
            onDone: () {
              controller.close();
              client.close();
            },
            cancelOnError: true,
          );
    }).catchError((dynamic error) {
      controller.addError(error);
      controller.close();
      client.close();
    });

    return controller.stream;
  }
}
