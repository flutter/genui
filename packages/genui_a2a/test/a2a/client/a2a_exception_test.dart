// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2a/src/a2a/a2a.dart';

void main() {
  group('A2AException', () {
    test('A2AJsonRpcException fromJson and toJson', () {
      final json = {
        'runtimeType': 'jsonRpc',
        'code': -32000,
        'message': 'Test error',
        'data': {'key': 'value'},
      };
      final exception = A2AException.fromJson(json) as A2AJsonRpcException;
      expect(exception.code, -32000);
      expect(exception.message, 'Test error');
      expect(exception.data, {'key': 'value'});
      expect(exception.toJson(), json);
    });

    test('A2AJsonRpcException copyWith', () {
      const exception = A2AJsonRpcException(code: -32000, message: 'Test error');
      final copy = exception.copyWith(message: 'New message');
      expect(copy.message, 'New message');
      expect(copy.code, -32000);
    });

    test('A2AJsonRpcException toString', () {
      const exception = A2AJsonRpcException(code: -32000, message: 'Test error');
      expect(exception.toString(), contains('A2AJsonRpcException'));
      expect(exception.toString(), contains('code: -32000'));
    });

    test('A2ATaskNotFoundException fromJson and toJson', () {
      final json = {
        'runtimeType': 'taskNotFound',
        'message': 'Task not found',
        'data': {'taskId': '123'},
      };
      final exception = A2AException.fromJson(json) as A2ATaskNotFoundException;
      expect(exception.message, 'Task not found');
      expect(exception.toJson(), json);
    });

    test('A2ATaskNotCancelableException fromJson and toJson', () {
      final json = {
        'runtimeType': 'taskNotCancelable',
        'message': 'Task not cancelable',
        'data': {'taskId': '123'},
      };
      final exception = A2AException.fromJson(json) as A2ATaskNotCancelableException;
      expect(exception.message, 'Task not cancelable');
      expect(exception.toJson(), json);
    });

    test('A2APushNotificationNotSupportedException fromJson and toJson', () {
      final json = {
        'runtimeType': 'pushNotificationNotSupported',
        'message': 'Not supported',
        'data': {'feature': 'push'},
      };
      final exception = A2AException.fromJson(json) as A2APushNotificationNotSupportedException;
      expect(exception.message, 'Not supported');
      expect(exception.toJson(), json);
    });

    test('A2APushNotificationConfigNotFoundException fromJson and toJson', () {
      final json = {
        'runtimeType': 'pushNotificationConfigNotFound',
        'message': 'Config not found',
        'data': {'configId': '456'},
      };
      final exception = A2AException.fromJson(json) as A2APushNotificationConfigNotFoundException;
      expect(exception.message, 'Config not found');
      expect(exception.toJson(), json);
    });

    test('A2AHttpException fromJson and toJson', () {
      final json = {
        'runtimeType': 'http',
        'statusCode': 404,
        'reason': 'Not Found',
      };
      final exception = A2AException.fromJson(json) as A2AHttpException;
      expect(exception.statusCode, 404);
      expect(exception.reason, 'Not Found');
      expect(exception.toJson(), json);
    });

    test('A2AHttpException copyWith', () {
      const exception = A2AHttpException(statusCode: 404, reason: 'Not Found');
      final copy = exception.copyWith(statusCode: 500);
      expect(copy.statusCode, 500);
      expect(copy.reason, 'Not Found');
    });

    test('A2ANetworkException fromJson and toJson', () {
      final json = {
        'runtimeType': 'network',
        'message': 'Network error',
      };
      final exception = A2AException.fromJson(json) as A2ANetworkException;
      expect(exception.message, 'Network error');
      expect(exception.toJson(), json);
    });

    test('A2ANetworkException copyWith', () {
      const exception = A2ANetworkException(message: 'Network error');
      final copy = exception.copyWith(message: 'New error');
      expect(copy.message, 'New error');
    });

    test('A2AParsingException fromJson and toJson', () {
      final json = {
        'runtimeType': 'parsing',
        'message': 'Parsing error',
      };
      final exception = A2AException.fromJson(json) as A2AParsingException;
      expect(exception.message, 'Parsing error');
      expect(exception.toJson(), json);
    });

    test('A2AParsingException copyWith', () {
      const exception = A2AParsingException(message: 'Parsing error');
      final copy = exception.copyWith(message: 'New error');
      expect(copy.message, 'New error');
    });

    test('A2AUnsupportedOperationException fromJson and toJson', () {
      final json = {
        'runtimeType': 'unsupportedOperation',
        'message': 'Unsupported',
      };
      final exception = A2AException.fromJson(json) as A2AUnsupportedOperationException;
      expect(exception.message, 'Unsupported');
      expect(exception.toJson(), json);
    });

    test('A2AUnsupportedOperationException copyWith', () {
      const exception = A2AUnsupportedOperationException(message: 'Unsupported');
      final copy = exception.copyWith(message: 'New error');
      expect(copy.message, 'New error');
    });

    test('A2AException.fromJson throws on unknown type', () {
      final json = {
        'runtimeType': 'unknown',
      };
      expect(() => A2AException.fromJson(json), throwsArgumentError);
    });
  });
}
