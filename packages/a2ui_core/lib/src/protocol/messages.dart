/// Base class for all A2UI messages.
abstract class A2uiMessage {
  final String version;
  A2uiMessage({this.version = 'v0.9'});

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
class UpdateDataModelMessage extends A2uiMessage {
  final String surfaceId;
  final String? path;
  final dynamic value;

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
      if (value != null) 'value': value,
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
  final dynamic details;

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
