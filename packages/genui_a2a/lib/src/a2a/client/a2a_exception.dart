// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../string_utils.dart';

/// Base class for exceptions thrown by the A2A client.
///
/// This sealed class hierarchy represents different categories of errors
/// that can occur during communication with an A2A server.
sealed class A2AException implements Exception {
  const A2AException();

  /// Deserializes an [A2AException] from a JSON object.
  factory A2AException.fromJson(Map<String, Object?> json) {
    final type = json['runtimeType'] as String?;
    switch (type) {
      case 'jsonRpc':
        return A2AJsonRpcException.fromJson(json);
      case 'taskNotFound':
        return A2ATaskNotFoundException.fromJson(json);
      case 'taskNotCancelable':
        return A2ATaskNotCancelableException.fromJson(json);
      case 'pushNotificationNotSupported':
        return A2APushNotificationNotSupportedException.fromJson(json);
      case 'pushNotificationConfigNotFound':
        return A2APushNotificationConfigNotFoundException.fromJson(json);
      case 'http':
        return A2AHttpException.fromJson(json);
      case 'network':
        return A2ANetworkException.fromJson(json);
      case 'parsing':
        return A2AParsingException.fromJson(json);
      case 'unsupportedOperation':
        return A2AUnsupportedOperationException.fromJson(json);
      default:
        throw ArgumentError('Unknown A2AException type: $type');
    }
  }

  /// Represents a JSON-RPC error returned by the server.
  const factory A2AException.jsonRpc({
    required int code,
    required String message,
    Map<String, Object?>? data,
  }) = A2AJsonRpcException;

  const factory A2AException.taskNotFound({
    required String message,
    Map<String, Object?>? data,
  }) = A2ATaskNotFoundException;

  const factory A2AException.taskNotCancelable({
    required String message,
    Map<String, Object?>? data,
  }) = A2ATaskNotCancelableException;

  const factory A2AException.pushNotificationNotSupported({
    required String message,
    Map<String, Object?>? data,
  }) = A2APushNotificationNotSupportedException;

  const factory A2AException.pushNotificationConfigNotFound({
    required String message,
    Map<String, Object?>? data,
  }) = A2APushNotificationConfigNotFoundException;

  /// Represents an error related to the HTTP transport layer.
  const factory A2AException.http({required int statusCode, String? reason}) =
      A2AHttpException;

  /// Represents a network connectivity issue.
  const factory A2AException.network({required String message}) =
      A2ANetworkException;

  /// Represents an error during the parsing of a server response.
  const factory A2AException.parsing({required String message}) =
      A2AParsingException;

  /// Represents an operation that is not supported by the current
  /// implementation.
  const factory A2AException.unsupportedOperation({required String message}) =
      A2AUnsupportedOperationException;

  Map<String, Object?> toJson();
}

/// Represents a JSON-RPC error returned by the server.
class A2AJsonRpcException extends A2AException {
  final int code;
  final String message;
  final Map<String, Object?>? data;

  const A2AJsonRpcException({
    required this.code,
    required this.message,
    this.data,
  });

  factory A2AJsonRpcException.fromJson(Map<String, dynamic> json) {
    return A2AJsonRpcException(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'jsonRpc',
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };

  A2AJsonRpcException copyWith({
    int? code,
    String? message,
    Map<String, Object?>? data,
  }) {
    return A2AJsonRpcException(
      code: code ?? this.code,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2AJsonRpcException &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          data == other.data;

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ data.hashCode;

  @override
  String toString() => buildToString('A2AJsonRpcException', {
    'code': code,
    'message': message,
    'data': data,
  });
}

class A2ATaskNotFoundException extends A2AException {
  final String message;
  final Map<String, Object?>? data;

  const A2ATaskNotFoundException({required this.message, this.data});

  factory A2ATaskNotFoundException.fromJson(Map<String, dynamic> json) {
    return A2ATaskNotFoundException(
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'taskNotFound',
    'message': message,
    if (data != null) 'data': data,
  };

  A2ATaskNotFoundException copyWith({
    String? message,
    Map<String, Object?>? data,
  }) {
    return A2ATaskNotFoundException(
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2ATaskNotFoundException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          data == other.data;

  @override
  int get hashCode => message.hashCode ^ data.hashCode;

  @override
  String toString() => buildToString('A2ATaskNotFoundException', {
    'message': message,
    'data': data,
  });
}

class A2ATaskNotCancelableException extends A2AException {
  final String message;
  final Map<String, Object?>? data;

  const A2ATaskNotCancelableException({required this.message, this.data});

  factory A2ATaskNotCancelableException.fromJson(Map<String, dynamic> json) {
    return A2ATaskNotCancelableException(
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'taskNotCancelable',
    'message': message,
    if (data != null) 'data': data,
  };

  A2ATaskNotCancelableException copyWith({
    String? message,
    Map<String, Object?>? data,
  }) {
    return A2ATaskNotCancelableException(
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2ATaskNotCancelableException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          data == other.data;

  @override
  int get hashCode => message.hashCode ^ data.hashCode;

  @override
  String toString() => buildToString('A2ATaskNotCancelableException', {
    'message': message,
    'data': data,
  });
}

class A2APushNotificationNotSupportedException extends A2AException {
  final String message;
  final Map<String, Object?>? data;

  const A2APushNotificationNotSupportedException({
    required this.message,
    this.data,
  });

  factory A2APushNotificationNotSupportedException.fromJson(
    Map<String, dynamic> json,
  ) {
    return A2APushNotificationNotSupportedException(
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'pushNotificationNotSupported',
    'message': message,
    if (data != null) 'data': data,
  };

  A2APushNotificationNotSupportedException copyWith({
    String? message,
    Map<String, Object?>? data,
  }) {
    return A2APushNotificationNotSupportedException(
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2APushNotificationNotSupportedException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          data == other.data;

  @override
  int get hashCode => message.hashCode ^ data.hashCode;

  @override
  String toString() => buildToString(
    'A2APushNotificationNotSupportedException',
    {'message': message, 'data': data},
  );
}

class A2APushNotificationConfigNotFoundException extends A2AException {
  final String message;
  final Map<String, Object?>? data;

  const A2APushNotificationConfigNotFoundException({
    required this.message,
    this.data,
  });

  factory A2APushNotificationConfigNotFoundException.fromJson(
    Map<String, dynamic> json,
  ) {
    return A2APushNotificationConfigNotFoundException(
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'pushNotificationConfigNotFound',
    'message': message,
    if (data != null) 'data': data,
  };

  A2APushNotificationConfigNotFoundException copyWith({
    String? message,
    Map<String, Object?>? data,
  }) {
    return A2APushNotificationConfigNotFoundException(
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2APushNotificationConfigNotFoundException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          data == other.data;

  @override
  int get hashCode => message.hashCode ^ data.hashCode;

  @override
  String toString() => buildToString(
    'A2APushNotificationConfigNotFoundException',
    {'message': message, 'data': data},
  );
}

class A2AHttpException extends A2AException {
  final int statusCode;
  final String? reason;

  const A2AHttpException({required this.statusCode, this.reason});

  factory A2AHttpException.fromJson(Map<String, dynamic> json) {
    return A2AHttpException(
      statusCode: json['statusCode'] as int,
      reason: json['reason'] as String?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'http',
    'statusCode': statusCode,
    if (reason != null) 'reason': reason,
  };

  A2AHttpException copyWith({int? statusCode, String? reason}) {
    return A2AHttpException(
      statusCode: statusCode ?? this.statusCode,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2AHttpException &&
          runtimeType == other.runtimeType &&
          statusCode == other.statusCode &&
          reason == other.reason;

  @override
  int get hashCode => statusCode.hashCode ^ reason.hashCode;

  @override
  String toString() => buildToString('A2AHttpException', {
    'statusCode': statusCode,
    'reason': reason,
  });
}

class A2ANetworkException extends A2AException {
  final String message;

  const A2ANetworkException({required this.message});

  factory A2ANetworkException.fromJson(Map<String, dynamic> json) {
    return A2ANetworkException(message: json['message'] as String);
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'network',
    'message': message,
  };

  A2ANetworkException copyWith({String? message}) {
    return A2ANetworkException(message: message ?? this.message);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2ANetworkException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() =>
      buildToString('A2ANetworkException', {'message': message});
}

class A2AParsingException extends A2AException {
  final String message;

  const A2AParsingException({required this.message});

  factory A2AParsingException.fromJson(Map<String, dynamic> json) {
    return A2AParsingException(message: json['message'] as String);
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'parsing',
    'message': message,
  };

  A2AParsingException copyWith({String? message}) {
    return A2AParsingException(message: message ?? this.message);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2AParsingException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() =>
      buildToString('A2AParsingException', {'message': message});
}

class A2AUnsupportedOperationException extends A2AException {
  final String message;

  const A2AUnsupportedOperationException({required this.message});

  factory A2AUnsupportedOperationException.fromJson(Map<String, dynamic> json) {
    return A2AUnsupportedOperationException(message: json['message'] as String);
  }

  @override
  Map<String, Object?> toJson() => {
    'runtimeType': 'unsupportedOperation',
    'message': message,
  };

  A2AUnsupportedOperationException copyWith({String? message}) {
    return A2AUnsupportedOperationException(message: message ?? this.message);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A2AUnsupportedOperationException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() =>
      buildToString('A2AUnsupportedOperationException', {'message': message});
}
