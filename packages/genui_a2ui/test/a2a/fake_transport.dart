// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:genui_a2ui/src/a2a/a2a.dart';

class FakeTransport implements Transport {
  @override
  Map<String, String> authHeaders;

  final _requests = <Map<String, Object?>>[];
  final _streamRequests = <Map<String, Object?>>[];
  final _streamController = StreamController<Map<String, Object?>>();

  List<Map<String, Object?>> get requests => _requests;
  List<Map<String, Object?>> get streamRequests => _streamRequests;

  FakeTransport({this.authHeaders = const {}});

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = 'rpc',
    Map<String, String> headers = const {},
  }) async {
    _requests.add(request);
    return Future.value(
      jsonDecode(
            jsonEncode({
              'result': const Task(
                id: 'task-123',
                contextId: 'context-123',
                status: TaskStatus(state: TaskState.working),
              ).toJson(),
            }),
          )
          as Map<String, Object?>,
    );
  }

  @override
  Stream<Map<String, Object?>> sendStream(
    Map<String, Object?> request, {
    Map<String, String> headers = const {},
  }) {
    _streamRequests.add(request);
    return _streamController.stream;
  }

  void addEvent(Event event) {
    _streamController.add(
      jsonDecode(jsonEncode(event.toJson())) as Map<String, Object?>,
    );
  }

  @override
  void close() {
    _streamController.close();
  }

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  }) {
    throw UnimplementedError();
  }
}
