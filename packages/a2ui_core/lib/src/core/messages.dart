// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../primitives/errors.dart';

/// Base class for all A2UI messages.
abstract class A2uiMessage {
  final String version;
  A2uiMessage({this.version = 'v0.9'});

  /// Deserializes a JSON envelope into a typed [A2uiMessage].
  ///
  /// Throws [A2uiValidationError] if the `version` field is missing or is
  /// not exactly `'v0.9'`, or if the envelope does not contain exactly one
  /// of the known action keys (`createSurface`, `updateComponents`,
  /// `updateDataModel`, `deleteSurface`).
  factory A2uiMessage.fromJson(Map<String, dynamic> json) {
    final Object? rawVersion = json['version'];
    if (rawVersion is! String) {
      throw A2uiValidationError(
        "A2UI message must have a string 'version' field.",
        details: json,
      );
    }
    if (rawVersion != 'v0.9') {
      throw A2uiValidationError(
        "A2UI message must have version 'v0.9' (got '$rawVersion').",
        details: json,
      );
    }
    final String version = rawVersion;

    const messageBodyKeys = {
      'createSurface',
      'updateComponents',
      'updateDataModel',
      'deleteSurface',
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
        theme: body['theme'] as Map<String, dynamic>?,
        sendDataModel: body['sendDataModel'] as bool? ?? false,
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
      // Preserve the wire-level distinction between "value omitted" (remove
      // the key) and "value: null" (set to null) — see UpdateDataModelMessage.
      if (body.containsKey('value')) {
        return UpdateDataModelMessage(
          version: version,
          surfaceId: body['surfaceId'] as String,
          path: body['path'] as String?,
          value: body['value'],
        );
      }
      return UpdateDataModelMessage.removeKey(
        version: version,
        surfaceId: body['surfaceId'] as String,
        path: body['path'] as String?,
      );
    }

    if (json.containsKey('deleteSurface')) {
      final body = json['deleteSurface'] as Map<String, dynamic>;
      return DeleteSurfaceMessage(
        version: version,
        surfaceId: body['surfaceId'] as String,
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
  final Map<String, dynamic>? theme;
  final bool sendDataModel;

  CreateSurfaceMessage({
    super.version,
    required this.surfaceId,
    required this.catalogId,
    this.theme,
    this.sendDataModel = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'createSurface': {
      'surfaceId': surfaceId,
      'catalogId': catalogId,
      if (theme != null) 'theme': theme,
      'sendDataModel': sendDataModel,
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
/// The wire protocol distinguishes between two intents the renderer guide
/// treats differently:
///
/// - `"value": <x>` (present, possibly `null`): set the value at [path].
/// - omitted `value` key: remove the key at [path] (sparse-clear for lists).
///
/// To keep that distinction lossless through parse/serialize, the default
/// constructor marks `hasValue = true` (the message carries an explicit
/// value, which may be `null`), and [UpdateDataModelMessage.removeKey]
/// constructs the "value omitted" form.
class UpdateDataModelMessage extends A2uiMessage {
  final String surfaceId;
  final String? path;
  final Object? value;

  /// True iff the message carries an explicit `value` on the wire. When
  /// false, the `value` key is absent from the JSON envelope and the
  /// receiver should treat the message as a "remove key at [path]".
  final bool hasValue;

  /// Constructs a message that sets [path] to [value]. `value` is part of
  /// the envelope even when `null`.
  UpdateDataModelMessage({
    super.version,
    required this.surfaceId,
    this.path,
    this.value,
  }) : hasValue = true;

  /// Constructs a message that removes the key at [path] (no `value` field
  /// on the wire).
  UpdateDataModelMessage.removeKey({
    super.version,
    required this.surfaceId,
    this.path,
  }) : value = null,
       hasValue = false;

  @override
  Map<String, dynamic> toJson() => {
    'version': version,
    'updateDataModel': {
      'surfaceId': surfaceId,
      if (path != null) 'path': path,
      if (hasValue) 'value': value,
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

/// Reports a user-initiated action from a component.
class A2uiClientAction {
  final String name;
  final String surfaceId;
  final String sourceComponentId;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  A2uiClientAction({
    required this.name,
    required this.surfaceId,
    required this.sourceComponentId,
    required this.timestamp,
    required this.context,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'surfaceId': surfaceId,
    'sourceComponentId': sourceComponentId,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
  };
}

/// Reports a client-side error.
class A2uiClientError {
  final String code;
  final String surfaceId;
  final String message;
  final Object? details;

  A2uiClientError({
    required this.code,
    required this.surfaceId,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'surfaceId': surfaceId,
    'message': message,
    if (details != null) 'details': details,
  };
}
