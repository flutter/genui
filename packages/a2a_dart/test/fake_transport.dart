// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart';

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
  }) async {
    _requests.add(request);
    return Future.value({
      'result': const Task(
        id: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      ).toJson(),
    });
  }

  @override
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request) {
    _streamRequests.add(request);
    return _streamController.stream;
  }

  void addEvent(Event event) {
    _streamController.add(event.toJson());
  }

  @override
  void close() {
    _streamController.close();
  }

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }
}
