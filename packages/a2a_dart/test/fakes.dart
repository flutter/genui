// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';

import 'package:http/http.dart' as http;

class FakeHttpClient implements http.Client {
  final Map<String, Object?> response;
  final int statusCode;

  FakeHttpClient(this.response, {this.statusCode = 200});

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return http.Response(jsonEncode(response), statusCode);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.Response(jsonEncode(response), statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransport implements Transport {
  @override
  Map<String, String> authHeaders;

  final Map<String, Object?> response;
  final Stream<Map<String, Object?>> stream;

  FakeTransport({
    required this.response,
    Stream<Map<String, Object?>>? stream,
    this.authHeaders = const {},
  }) : stream = stream ?? Stream.value(response);

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    return response;
  }

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '',
  }) async {
    return response;
  }

  @override
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request) {
    return stream;
  }

  @override
  void close() {}
}
