// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../primitives/errors.dart';

/// The A2UI protocol version implemented by this package.
const String a2uiProtocolVersion = 'v1.0';

/// Base class for all A2UI messages.
abstract class A2uiMessage {
  final String version;
  A2uiMessage({this.version = a2uiProtocolVersion});

  /// Deserializes a JSON envelope into a typed [A2uiMessage].
  factory A2uiMessage.fromJson(Map<String, dynamic> json) {
    final Object? rawVersion = json['version'];
    if (rawVersion is! String) {
      throw A2uiValidationError(
        "A2UI message must have a string 'version' field.",
        details: json,
      );
    }
    if (rawVersion != a2uiProtocolVersion) {
      throw A2uiValidationError(
        "A2UI message must have version '$a2uiProtocolVersion' "
        "(got '$rawVersion').",
        details: json,
      );
    }
    final String version = rawVersion;

    const messageBodyKeys = {
      'createSurface',
      'updateComponents',
      'updateDataModel',
      'deleteSurface',
      'callFunction',
      'actionResponse',
    };
    final List<String> presentKeys = messageBodyKeys
        .where(json.containsKey)
        .toList();
    if (presentKeys.length > 1) {
      throw A2uiValidationError(
        'A2UI message must contain exactly one of '
        '${messageBodyKeys.join(', ')}; got ${presentKeys.join(', ')}.',
        details: json,
      );
    }

    if (json.containsKey('createSurface')) {
      final body = json['createSurface'] as Map<String, dynamic>;
      return CreateSurfaceMessage(
        version: version,
        surfaceId: body['surfaceId'] as String,
        catalogId: body['catalogId'] as String,
        surfaceProperties: body['surfaceProperties'] as Map<String, dynamic>?,
        sendDataModel: body['sendDataModel'] as bool? ?? false,
        components: (body['components'] as List?)?.cast<Map<String, dynamic>>(),
        dataModel: body['dataModel'] as Map<String, dynamic>?,
      );
    }

    if (json.containsKey('updateComponents')) {
      final body = json['updateComponents'] as Map<String, dynamic>;
      return UpdateComponentsMessage(
        version: version,
        surfaceId: body['surfaceId'] as String,
        components: (body['components'] as List).cast<Map<String, dynamic>>(),
      );
    }

    if (json.containsKey('updateDataModel')) {
      final body = json['updateDataModel'] as Map<String, dynamic>;
      return UpdateDataModelMessage(
        version: version,
        surfaceId: body['surfaceId'] as String,
        path: body['path'] as String?,
        value: body['value'],
      );
    }

    if (json.containsKey('deleteSurface')) {
      final body = json['deleteSurface'] as Map<String, dynamic>;
      return DeleteSurfaceMessage(
        version: version,
        surfaceId: body['surfaceId'] as String,
      );
    }

    if (json.containsKey('callFunction')) {
      final body = json['callFunction'] as Map<String, dynamic>;
      final Object? functionCallId = json['functionCallId'];
      if (functionCallId is! String) {
        throw A2uiValidationError(
          "A2UI callFunction message must have a string 'functionCallId' "
          'field.',
          details: json,
        );
      }
      return CallFunctionMessage(
        version: version,
        functionCallId: functionCallId,
        wantResponse: json['wantResponse'] as bool? ?? false,
        call: body['call'] as String,
        args: body['args'] as Map<String, dynamic>?,
      );
    }

    if (json.containsKey('actionResponse')) {
      final body = json['actionResponse'] as Map<String, dynamic>;
      final Object? actionId = json['actionId'];
      if (actionId is! String) {
        throw A2uiValidationError(
          "A2UI actionResponse message must have a string 'actionId' field.",
          details: json,
        );
      }
      final bool hasValue = body.containsKey('value');
      final Object? rawError = body['error'];
      if (hasValue == (rawError != null)) {
        throw A2uiValidationError(
          "A2UI actionResponse must contain exactly one of 'value' or "
          "'error'.",
          details: json,
        );
      }
      return ActionResponseMessage(
        version: version,
        actionId: actionId,
        value: body['value'],
        hasValue: hasValue,
        error: rawError == null
            ? null
            : A2uiActionError.fromJson(rawError as Map<String, dynamic>),
      );
    }

    throw A2uiValidationError(
      'Unknown A2UI message type. Expected one of: '
      '${messageBodyKeys.join(', ')}.',
      details: json,
    );
  }

  Map<String, dynamic> toJson();
}

/// Signals the client to create a new surface.
class CreateSurfaceMessage extends A2uiMessage {
  final String surfaceId;
  final String catalogId;
  final Map<String, dynamic>? surfaceProperties;
  final bool sendDataModel;

  /// Optional initial components, allowing an entire UI to be defined in a
  /// single `createSurface` message.
  final List<Map<String, dynamic>>? components;

  /// Optional initial root data model object for the surface.
  final Map<String, dynamic>? dataModel;

  CreateSurfaceMessage({
    super.version,
    required this.surfaceId,
    required this.catalogId,
    this.surfaceProperties,
    this.sendDataModel = false,
    this.components,
    this.dataModel,
  });

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'createSurface': {
      'surfaceId': surfaceId,
      'catalogId': catalogId,
      if (surfaceProperties != null) 'surfaceProperties': surfaceProperties,
      'sendDataModel': sendDataModel,
      if (components != null) 'components': components,
      if (dataModel != null) 'dataModel': dataModel,
    },
  };
}

/// Updates a surface with a new set of components.
class UpdateComponentsMessage extends A2uiMessage {
  final String surfaceId;
  final List<Map<String, dynamic>> components;

  UpdateComponentsMessage({
    super.version,
    required this.surfaceId,
    required this.components,
  });

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'updateComponents': {'surfaceId': surfaceId, 'components': components},
  };
}

/// Updates the data model for an existing surface.
///
/// Setting a path's [value] to `null` deletes the key at that path.
class UpdateDataModelMessage extends A2uiMessage {
  final String surfaceId;
  final String? path;
  final Object? value;

  UpdateDataModelMessage({
    super.version,
    required this.surfaceId,
    this.path,
    this.value,
  });

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'updateDataModel': {
      'surfaceId': surfaceId,
      if (path != null) 'path': path,
      // An explicit null value deletes the key at 'path' in v1.0, so null is
      // serialized rather than omitted.
      'value': value,
    },
  };
}

/// Signals the client to delete a surface.
class DeleteSurfaceMessage extends A2uiMessage {
  final String surfaceId;

  DeleteSurfaceMessage({super.version, required this.surfaceId});

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'deleteSurface': {'surfaceId': surfaceId},
  };
}

/// A server-initiated function call to be executed on the client.
class CallFunctionMessage extends A2uiMessage {
  /// Unique ID for this function call instance. Must be copied verbatim into
  /// the resulting `functionResponse` or `error` message.
  final String functionCallId;

  /// Whether the server expects a `functionResponse` for this call.
  final bool wantResponse;

  /// The name of the function to call.
  final String call;

  /// Arguments passed to the function.
  final Map<String, dynamic>? args;

  CallFunctionMessage({
    super.version,
    required this.functionCallId,
    this.wantResponse = false,
    required this.call,
    this.args,
  });

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'functionCallId': functionCallId,
    if (wantResponse) 'wantResponse': wantResponse,
    'callFunction': {'call': call, if (args != null) 'args': args},
  };
}

/// An error returned by the server in an [ActionResponseMessage].
class A2uiActionError {
  final String code;
  final String message;

  A2uiActionError({required this.code, required this.message});

  factory A2uiActionError.fromJson(Map<String, dynamic> json) =>
      A2uiActionError(
        code: json['code'] as String,
        message: json['message'] as String,
      );

  Map<String, dynamic> toJson() => {'code': code, 'message': message};
}

/// A server response to a client-initiated action that requested a response
/// (`wantResponse: true`).
class ActionResponseMessage extends A2uiMessage {
  /// The ID of the action call this response belongs to.
  final String actionId;

  /// The return value of the action. May be `null` even when present on the
  /// wire; check [hasValue] to distinguish a null value from an error
  /// response.
  final Object? value;

  /// Whether the response carried a `value` (as opposed to an [error]).
  final bool hasValue;

  /// The error returned by the action, if it failed.
  final A2uiActionError? error;

  ActionResponseMessage({
    super.version,
    required this.actionId,
    this.value,
    bool? hasValue,
    this.error,
  }) : hasValue = hasValue ?? error == null;

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'actionId': actionId,
    'actionResponse': {
      if (hasValue) 'value': value,
      if (error != null) 'error': error!.toJson(),
    },
  };
}

/// Reports a user-initiated action from a component.
class A2uiClientAction {
  final String name;
  final String surfaceId;
  final String sourceComponentId;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  /// Whether the client expects an `actionResponse` from the server.
  final bool wantResponse;

  /// Unique ID for this action call. Required when [wantResponse] is true.
  final String? actionId;

  A2uiClientAction({
    required this.name,
    required this.surfaceId,
    required this.sourceComponentId,
    required this.timestamp,
    required this.context,
    this.wantResponse = false,
    this.actionId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'surfaceId': surfaceId,
    'sourceComponentId': sourceComponentId,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    if (wantResponse) 'wantResponse': wantResponse,
    if (actionId != null) 'actionId': actionId,
  };
}

/// Returns the result of a server-initiated function call to the server.
class A2uiFunctionResponse {
  /// Unique ID of the function call instance, copied verbatim from the
  /// [CallFunctionMessage] that initiated the call.
  final String functionCallId;

  /// The name of the function which was called, copied verbatim from the
  /// invocation.
  final String call;

  /// The return value of the function invocation.
  final Object? value;

  A2uiFunctionResponse({
    required this.functionCallId,
    required this.call,
    this.value,
  });

  Map<String, dynamic> toJson() => {
    'functionCallId': functionCallId,
    'call': call,
    'value': value,
  };
}

/// Reports a client-side error.
///
/// Exactly one of [surfaceId] (for surface-scoped errors) or [functionCallId]
/// (for function execution failures) should be set.
class A2uiClientError {
  final String code;
  final String? surfaceId;
  final String? functionCallId;
  final String message;
  final Object? details;

  A2uiClientError({
    required this.code,
    this.surfaceId,
    this.functionCallId,
    required this.message,
    this.details,
  }) : assert(
         (surfaceId == null) != (functionCallId == null),
         "Exactly one of 'surfaceId' or 'functionCallId' must be set.",
       );

  Map<String, dynamic> toJson() => {
    'code': code,
    if (surfaceId != null) 'surfaceId': surfaceId,
    if (functionCallId != null) 'functionCallId': functionCallId,
    'message': message,
    if (details != null) 'details': details,
  };
}
