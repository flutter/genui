// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2a/src/a2a/a2a.dart';

void main() {
  group('A2AException', () {
    test('A2AJsonRpcException fromJson and toJson', () {
      final Map<String, Object> json = {
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
      const exception = A2AJsonRpcException(
        code: -32000,
        message: 'Test error',
      );
      final A2AJsonRpcException copy = exception.copyWith(
        message: 'New message',
      );
      expect(copy.message, 'New message');
      expect(copy.code, -32000);
    });

    test('A2AJsonRpcException toString', () {
      const exception = A2AJsonRpcException(
        code: -32000,
        message: 'Test error',
      );
      expect(exception.toString(), contains('A2AJsonRpcException'));
      expect(exception.toString(), contains('code: -32000'));
    });

    test('A2ATaskNotFoundException fromJson and toJson', () {
      final Map<String, Object> json = {
        'runtimeType': 'taskNotFound',
        'message': 'Task not found',
        'data': {'taskId': '123'},
      };
      final exception = A2AException.fromJson(json) as A2ATaskNotFoundException;
      expect(exception.message, 'Task not found');
      expect(exception.toJson(), json);
    });

    test('A2ATaskNotCancelableException fromJson and toJson', () {
      final Map<String, Object> json = {
        'runtimeType': 'taskNotCancelable',
        'message': 'Task not cancelable',
        'data': {'taskId': '123'},
      };
      final exception =
          A2AException.fromJson(json) as A2ATaskNotCancelableException;
      expect(exception.message, 'Task not cancelable');
      expect(exception.toJson(), json);
    });

    test('A2APushNotificationNotSupportedException fromJson and toJson', () {
      final Map<String, Object> json = {
        'runtimeType': 'pushNotificationNotSupported',
        'message': 'Not supported',
        'data': {'feature': 'push'},
      };
      final exception =
          A2AException.fromJson(json)
              as A2APushNotificationNotSupportedException;
      expect(exception.message, 'Not supported');
      expect(exception.toJson(), json);
    });

    test('A2APushNotificationConfigNotFoundException fromJson and toJson', () {
      final Map<String, Object> json = {
        'runtimeType': 'pushNotificationConfigNotFound',
        'message': 'Config not found',
        'data': {'configId': '456'},
      };
      final exception =
          A2AException.fromJson(json)
              as A2APushNotificationConfigNotFoundException;
      expect(exception.message, 'Config not found');
      expect(exception.toJson(), json);
    });

    test('A2AHttpException fromJson and toJson', () {
      final Map<String, Object> json = {
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
      final A2AHttpException copy = exception.copyWith(statusCode: 500);
      expect(copy.statusCode, 500);
      expect(copy.reason, 'Not Found');
    });

    test('A2ANetworkException fromJson and toJson', () {
      final json = {'runtimeType': 'network', 'message': 'Network error'};
      final exception = A2AException.fromJson(json) as A2ANetworkException;
      expect(exception.message, 'Network error');
      expect(exception.toJson(), json);
    });

    test('A2ANetworkException copyWith', () {
      const exception = A2ANetworkException(message: 'Network error');
      final A2ANetworkException copy = exception.copyWith(message: 'New error');
      expect(copy.message, 'New error');
    });

    test('A2AParsingException fromJson and toJson', () {
      final json = {'runtimeType': 'parsing', 'message': 'Parsing error'};
      final exception = A2AException.fromJson(json) as A2AParsingException;
      expect(exception.message, 'Parsing error');
      expect(exception.toJson(), json);
    });

    test('A2AParsingException copyWith', () {
      const exception = A2AParsingException(message: 'Parsing error');
      final A2AParsingException copy = exception.copyWith(message: 'New error');
      expect(copy.message, 'New error');
    });

    test('A2AUnsupportedOperationException fromJson and toJson', () {
      final json = {
        'runtimeType': 'unsupportedOperation',
        'message': 'Unsupported',
      };
      final exception =
          A2AException.fromJson(json) as A2AUnsupportedOperationException;
      expect(exception.message, 'Unsupported');
      expect(exception.toJson(), json);
    });

    test('A2AUnsupportedOperationException copyWith', () {
      const exception = A2AUnsupportedOperationException(
        message: 'Unsupported',
      );
      final A2AUnsupportedOperationException copy = exception.copyWith(
        message: 'New error',
      );
      expect(copy.message, 'New error');
    });

    test('A2AException.fromJson throws on unknown type', () {
      final json = {'runtimeType': 'unknown'};
      expect(() => A2AException.fromJson(json), throwsArgumentError);
    });
    test('A2AJsonRpcException operator == and hashCode', () {
      const exception1 = A2AJsonRpcException(code: 1, message: 'm');
      const exception2 = A2AJsonRpcException(code: 1, message: 'm');
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('A2ATaskNotFoundException operator == and hashCode', () {
      const exception1 = A2ATaskNotFoundException(message: 'm');
      const exception2 = A2ATaskNotFoundException(message: 'm');
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('A2ATaskNotCancelableException operator == and hashCode', () {
      const exception1 = A2ATaskNotCancelableException(message: 'm');
      const exception2 = A2ATaskNotCancelableException(message: 'm');
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test(
      'A2APushNotificationNotSupportedException operator == and hashCode',
      () {
        const exception1 = A2APushNotificationNotSupportedException(
          message: 'm',
        );
        const exception2 = A2APushNotificationNotSupportedException(
          message: 'm',
        );
        expect(exception1, equals(exception2));
        expect(exception1.hashCode, equals(exception2.hashCode));
      },
    );

    test(
      'A2APushNotificationConfigNotFoundException operator == and hashCode',
      () {
        const exception1 = A2APushNotificationConfigNotFoundException(
          message: 'm',
        );
        const exception2 = A2APushNotificationConfigNotFoundException(
          message: 'm',
        );
        expect(exception1, equals(exception2));
        expect(exception1.hashCode, equals(exception2.hashCode));
      },
    );

    test('A2AHttpException operator == and hashCode', () {
      const exception1 = A2AHttpException(statusCode: 404, reason: 'Not Found');
      const exception2 = A2AHttpException(statusCode: 404, reason: 'Not Found');
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('A2ANetworkException operator == and hashCode', () {
      const exception1 = A2ANetworkException(message: 'm');
      const exception2 = A2ANetworkException(message: 'm');
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('A2AParsingException operator == and hashCode', () {
      const exception1 = A2AParsingException(message: 'm');
      const exception2 = A2AParsingException(message: 'm');
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('A2AUnsupportedOperationException operator == and hashCode', () {
      const exception1 = A2AUnsupportedOperationException(message: 'm');
      const exception2 = A2AUnsupportedOperationException(message: 'm');
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('A2AHttpException toString', () {
      const exception = A2AHttpException(statusCode: 404, reason: 'Not Found');
      expect(exception.toString(), contains('A2AHttpException'));
    });

    test('A2ANetworkException toString', () {
      const exception = A2ANetworkException(message: 'm');
      expect(exception.toString(), contains('A2ANetworkException'));
    });

    test('A2AParsingException toString', () {
      const exception = A2AParsingException(message: 'm');
      expect(exception.toString(), contains('A2AParsingException'));
    });

    test('A2AUnsupportedOperationException toString', () {
      const exception = A2AUnsupportedOperationException(message: 'm');
      expect(
        exception.toString(),
        contains('A2AUnsupportedOperationException'),
      );
    });
    test('A2AJsonRpcException copyWith without arguments', () {
      const exception = A2AJsonRpcException(code: 1, message: 'm');
      final A2AJsonRpcException copy = exception.copyWith();
      expect(copy.code, 1);
      expect(copy.message, 'm');
    });

    test('A2ATaskNotFoundException copyWith without arguments', () {
      const exception = A2ATaskNotFoundException(message: 'm');
      final A2ATaskNotFoundException copy = exception.copyWith();
      expect(copy.message, 'm');
    });

    test('A2ATaskNotCancelableException copyWith without arguments', () {
      const exception = A2ATaskNotCancelableException(message: 'm');
      final A2ATaskNotCancelableException copy = exception.copyWith();
      expect(copy.message, 'm');
    });

    test(
      'A2APushNotificationNotSupportedException copyWith without arguments',
      () {
        const exception = A2APushNotificationNotSupportedException(
          message: 'm',
        );
        final A2APushNotificationNotSupportedException copy = exception
            .copyWith();
        expect(copy.message, 'm');
      },
    );

    test(
      'A2APushNotificationConfigNotFoundException copyWith without arguments',
      () {
        const exception = A2APushNotificationConfigNotFoundException(
          message: 'm',
        );
        final A2APushNotificationConfigNotFoundException copy = exception
            .copyWith();
        expect(copy.message, 'm');
      },
    );

    test('A2AHttpException copyWith without arguments', () {
      const exception = A2AHttpException(statusCode: 404, reason: 'Not Found');
      final A2AHttpException copy = exception.copyWith();
      expect(copy.statusCode, 404);
      expect(copy.reason, 'Not Found');
    });

    test('A2ANetworkException copyWith without arguments', () {
      const exception = A2ANetworkException(message: 'm');
      final A2ANetworkException copy = exception.copyWith();
      expect(copy.message, 'm');
    });

    test('A2AParsingException copyWith without arguments', () {
      const exception = A2AParsingException(message: 'm');
      final A2AParsingException copy = exception.copyWith();
      expect(copy.message, 'm');
    });

    test('A2AUnsupportedOperationException copyWith without arguments', () {
      const exception = A2AUnsupportedOperationException(message: 'm');
      final A2AUnsupportedOperationException copy = exception.copyWith();
      expect(copy.message, 'm');
    });
    test(
      'A2AJsonRpcException operator == returns false for different code',
      () {
        const exception1 = A2AJsonRpcException(code: 1, message: 'm');
        const exception2 = A2AJsonRpcException(code: 2, message: 'm');
        expect(exception1 == exception2, isFalse);
      },
    );

    test(
      'A2AJsonRpcException operator == returns false for different message',
      () {
        const exception1 = A2AJsonRpcException(code: 1, message: 'm');
        const exception2 = A2AJsonRpcException(code: 1, message: 'n');
        expect(exception1 == exception2, isFalse);
      },
    );

    test(
      'A2AJsonRpcException operator == returns false for different data',
      () {
        const exception1 = A2AJsonRpcException(
          code: 1,
          message: 'm',
          data: {'k': 'v'},
        );
        const exception2 = A2AJsonRpcException(
          code: 1,
          message: 'm',
          data: {'k': 'w'},
        );
        expect(exception1 == exception2, isFalse);
      },
    );
    test('A2ATaskNotFoundException operator == returns false for different '
        'message', () {
      const exception1 = A2ATaskNotFoundException(message: 'm');
      const exception2 = A2ATaskNotFoundException(message: 'n');
      expect(exception1 == exception2, isFalse);
    });

    test(
      'A2ATaskNotCancelableException operator == returns false for different '
      'message',
      () {
        const exception1 = A2ATaskNotCancelableException(message: 'm');
        const exception2 = A2ATaskNotCancelableException(message: 'n');
        expect(exception1 == exception2, isFalse);
      },
    );

    test('A2ATaskNotCancelableException hashCode works', () {
      const exception1 = A2ATaskNotCancelableException(message: 'm');
      const exception2 = A2ATaskNotCancelableException(message: 'm');
      expect(exception1.hashCode, equals(exception2.hashCode));
    });
    test(
      'A2APushNotificationNotSupportedException operator == returns false for '
      'different message',
      () {
        const exception1 = A2APushNotificationNotSupportedException(
          message: 'm',
        );
        const exception2 = A2APushNotificationNotSupportedException(
          message: 'n',
        );
        expect(exception1 == exception2, isFalse);
      },
    );

    test('A2APushNotificationConfigNotFoundException operator == returns false '
        'for different message', () {
      const exception1 = A2APushNotificationConfigNotFoundException(
        message: 'm',
      );
      const exception2 = A2APushNotificationConfigNotFoundException(
        message: 'n',
      );
      expect(exception1 == exception2, isFalse);
    });

    test(
      'A2AHttpException operator == returns false for different statusCode',
      () {
        const exception1 = A2AHttpException(
          statusCode: 404,
          reason: 'Not Found',
        );
        const exception2 = A2AHttpException(
          statusCode: 500,
          reason: 'Not Found',
        );
        expect(exception1 == exception2, isFalse);
      },
    );

    test('A2APushNotificationNotSupportedException hashCode works', () {
      const exception1 = A2APushNotificationNotSupportedException(message: 'm');
      const exception2 = A2APushNotificationNotSupportedException(message: 'm');
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('A2APushNotificationConfigNotFoundException hashCode works', () {
      const exception1 = A2APushNotificationConfigNotFoundException(
        message: 'm',
      );
      const exception2 = A2APushNotificationConfigNotFoundException(
        message: 'm',
      );
      expect(exception1.hashCode, equals(exception2.hashCode));
    });
    test('A2APushNotificationNotSupportedException toString', () {
      const exception = A2APushNotificationNotSupportedException(message: 'm');
      expect(
        exception.toString(),
        contains('A2APushNotificationNotSupportedException'),
      );
    });

    test('A2APushNotificationConfigNotFoundException toString', () {
      const exception = A2APushNotificationConfigNotFoundException(
        message: 'm',
      );
      expect(
        exception.toString(),
        contains('A2APushNotificationConfigNotFoundException'),
      );
    });
  });
}
