// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:http/http.dart' as http;

class FakeHttpClient extends http.BaseClient {
  final Map<String, dynamic> response;
  final int statusCode;

  FakeHttpClient({required this.response, this.statusCode = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final responseBody = jsonEncode(response);
    final stream = Stream.value(utf8.encode(responseBody));
    return http.StreamedResponse(
      stream,
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

class FakeTransport implements Transport {
  final Map<String, dynamic> response;
  final Stream<Map<String, dynamic>> streamResponse;

  FakeTransport(
      {required this.response, Stream<Map<String, dynamic>>? streamResponse})
      : streamResponse = streamResponse ?? Stream.value(response);

  @override
  Future<Map<String, dynamic>> get(String method) async {
    return response;
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    return response;
  }

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) {
    return streamResponse;
  }
}

class FakeTaskManager implements TaskManager {
  final Task taskToReturn;

  FakeTaskManager({required this.taskToReturn});

  @override
  Task createTask([Message? message]) {
    return taskToReturn;
  }

  @override
  Task? getTask(String taskId) {
    return null;
  }

  @override
  void updateTask(Task task) {}
}
