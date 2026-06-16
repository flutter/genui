// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../interfaces/a2ui_message_sink.dart';
import '../interfaces/surface_context.dart';
import '../interfaces/surface_host.dart';
import '../model/a2ui_client_capabilities.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
import '../model/schema_validation.dart' as schema_validation;
import '../model/ui_models.dart';
import '../primitives/a2ui_validation_exception.dart';
import '../primitives/logging.dart';

import 'surface_registry.dart' as surface_reg;

/// The runtime controller for the GenUI system.
///
/// Wraps [core.MessageProcessor] and adds Flutter-side concerns: pre-create
/// message buffering, catalog-schema validation, and a [SurfaceUpdate]
/// stream the Flutter facade subscribes to.
interface class SurfaceController implements SurfaceHost, A2uiMessageSink {
  SurfaceController({
    required this.catalogs,
    this.pendingUpdateTimeout = const Duration(minutes: 1),
  }) {
    _processor = core.MessageProcessor<core.ComponentApi>(
      // Growable: handleMessage injects stub catalogs for unknown catalogIds.
      catalogs: catalogs.map((c) => c.coreCatalog).toList(),
    );
    _processor.groupModel.onSurfaceCreated.addListener(_onCoreSurfaceCreated);
    _processor.groupModel.onSurfaceDeleted.addListener(_onCoreSurfaceDeleted);
  }

  /// The catalogs available to surfaces in this engine.
  final Iterable<Catalog> catalogs;

  /// The timeout for buffered updates waiting for a surface creation.
  final Duration pendingUpdateTimeout;

  late final core.MessageProcessor<core.ComponentApi> _processor;
  late final surface_reg.SurfaceRegistry _registry =
      surface_reg.SurfaceRegistry();
  // Writable data models handed out by `contextFor(id).dataModel` before the
  // surface exists; migrated into the live core model on surface creation.
  final Map<String, DataModel> _preCreateDataModels = {};
  final Map<String, DataModel> _liveDataModels = {};

  final _onSubmit = StreamController<ChatMessage>.broadcast();
  final _pendingUpdates = <String, List<core.A2uiMessage>>{};
  final _pendingUpdateTimers = <String, Timer>{};

  @override
  Stream<SurfaceUpdate> get surfaceUpdates => _registry.events.map(
    (e) => switch (e) {
      surface_reg.SurfaceAdded(:final surfaceId, :final surface) =>
        SurfaceAdded.fromCore(surfaceId, surface),
      surface_reg.SurfaceUpdated(:final surfaceId, :final surface) =>
        ComponentsUpdated.fromCore(surfaceId, surface),
      surface_reg.SurfaceRemoved(:final surfaceId) => SurfaceRemoved(surfaceId),
    },
  );

  /// A stream of messages to be submitted to the AI service.
  Stream<ChatMessage> get onSubmit => _onSubmit.stream;

  /// The IDs of the currently active surfaces.
  Iterable<String> get activeSurfaceIds => _registry.surfaceOrder;

  /// Evaluates and returns the client capabilities for the catalogs managed
  /// by this controller.
  A2UiClientCapabilities get clientCapabilities =>
      A2UiClientCapabilities.fromCatalogs(catalogs);

  @override
  SurfaceContext contextFor(String surfaceId) {
    return _ControllerContext(this, surfaceId);
  }

  /// The registry of surfaces managed by this controller.
  surface_reg.SurfaceRegistry get registry => _registry;

  DataModel _dataModelFor(String surfaceId) {
    final DataModel? live = _liveDataModels[surfaceId];
    if (live != null) return live;
    final core.SurfaceModel? surface = _registry.getLiveSurface(surfaceId);
    if (surface != null) {
      final DataModel wrapped = InMemoryDataModel.wrap(surface.dataModel);
      _liveDataModels[surfaceId] = wrapped;
      return wrapped;
    }
    return _preCreateDataModels.putIfAbsent(surfaceId, InMemoryDataModel.new);
  }

  /// Processes a message from the AI service.
  @override
  void handleMessage(core.A2uiMessage message) {
    genUiLogger.info(
      'SurfaceController.handleMessage received: ${message.runtimeType}',
    );
    _handleCoreMessage(message);
  }

  void _handleCoreMessage(core.A2uiMessage coreMessage) {
    // Reject an empty surfaceId on any message that carries one. CreateSurface
    // would otherwise create a surface with id ""; updates and deletes would
    // buffer under "" until they time out, since a surface "" can never exist.
    final String? surfaceId = _surfaceIdOf(coreMessage);
    if (surfaceId != null && surfaceId.isEmpty) {
      reportError(
        A2uiValidationException(
          'Surface ID cannot be empty',
          surfaceId: '',
          path: 'surfaceId',
        ),
        StackTrace.current,
      );
      return;
    }

    final String? bufferSurfaceId = _bufferSurfaceIdIfNoSurface(coreMessage);
    if (bufferSurfaceId != null) {
      _bufferMessage(bufferSurfaceId, coreMessage);
      return;
    }

    // Register an empty stub for unknown catalogIds. Mirrors the lenient
    // pre-migration behavior tests and demos relied on.
    if (coreMessage is core.CreateSurfaceMessage) {
      final core.CreateSurfaceMessage createMessage = coreMessage;
      if (!_processor.catalogs.any((c) => c.id == createMessage.catalogId)) {
        _processor.catalogs.add(
          core.Catalog<core.ComponentApi>(
            id: createMessage.catalogId,
            components: const [],
          ),
        );
      }
    }

    try {
      _processor.processMessages([coreMessage]);
    } on core.A2uiStateError catch (e) {
      genUiLogger.warning('State error from MessageProcessor: ${e.message}');
      reportError(
        A2uiValidationException(
          e.message,
          surfaceId: _surfaceIdOf(coreMessage),
        ),
        StackTrace.current,
      );
      return;
    } on core.A2uiValidationError catch (e) {
      genUiLogger.warning(
        'Validation error from MessageProcessor: ${e.message}',
      );
      reportError(
        A2uiValidationException(
          e.message,
          surfaceId: _surfaceIdOf(coreMessage),
        ),
        StackTrace.current,
      );
      return;
    } on A2uiValidationException catch (e) {
      genUiLogger.warning('Validation failed for surface ${e.surfaceId}: $e');
      reportError(e, StackTrace.current);
      return;
    } catch (exception, stackTrace) {
      genUiLogger.severe(
        'Error handling message: $coreMessage',
        exception,
        stackTrace,
      );
      reportError(exception, stackTrace);
      return;
    }

    if (coreMessage is core.UpdateComponentsMessage) {
      final core.SurfaceModel<core.ComponentApi>? surface = _processor
          .groupModel
          .getSurface(coreMessage.surfaceId);
      if (surface != null) {
        _registry.notifyUpdated(surface);
        // Validation does not roll back the mutation; we surface the error
        // and let the caller decide.
        try {
          final Catalog? genuiCatalog = catalogs.firstWhereOrNull(
            (c) => c.catalogId == surface.catalog.id,
          );
          if (genuiCatalog != null) {
            _validateComponents(coreMessage.surfaceId, surface, genuiCatalog);
          }
        } on A2uiValidationException catch (e) {
          genUiLogger.warning(
            'Schema validation failed for surface ${e.surfaceId}: $e',
          );
          reportError(e, StackTrace.current);
        }
      }
    }
  }

  /// If [message] targets a surface that does not yet exist, returns that
  /// surfaceId so the caller can buffer the message. Otherwise returns null.
  String? _bufferSurfaceIdIfNoSurface(core.A2uiMessage message) {
    final String? targetId = switch (message) {
      core.UpdateComponentsMessage(:final surfaceId) => surfaceId,
      core.UpdateDataModelMessage(:final surfaceId) => surfaceId,
      _ => null,
    };
    if (targetId == null) return null;
    if (_processor.groupModel.getSurface(targetId) != null) return null;
    return targetId;
  }

  String? _surfaceIdOf(core.A2uiMessage message) => switch (message) {
    core.CreateSurfaceMessage(:final surfaceId) => surfaceId,
    core.UpdateComponentsMessage(:final surfaceId) => surfaceId,
    core.UpdateDataModelMessage(:final surfaceId) => surfaceId,
    core.DeleteSurfaceMessage(:final surfaceId) => surfaceId,
    _ => null,
  };

  void _onCoreSurfaceCreated(core.SurfaceModel<core.ComponentApi> surface) {
    // Migrate pre-create fallback data into the live model BEFORE notifying
    // registry listeners; otherwise a synchronous listener could call
    // contextFor(...).dataModel and cache an empty live wrapper before the
    // fallback's data is copied in.
    final DataModel live = InMemoryDataModel.wrap(surface.dataModel);
    final DataModel? fallback = _preCreateDataModels.remove(surface.id);
    if (fallback != null) {
      live.update(DataPath.root, fallback.getValue<Object?>(DataPath.root));
      fallback.dispose();
    }
    _liveDataModels[surface.id] = live;
    _registry.addSurface(surface);
    final List<core.A2uiMessage>? pending = _pendingUpdates.remove(surface.id);
    _pendingUpdateTimers.remove(surface.id)?.cancel();
    if (pending != null) {
      for (final core.A2uiMessage msg in pending) {
        _handleCoreMessage(msg);
      }
    }
  }

  void _onCoreSurfaceDeleted(String surfaceId) {
    _pendingUpdates.remove(surfaceId);
    _pendingUpdateTimers.remove(surfaceId)?.cancel();
    _preCreateDataModels.remove(surfaceId)?.dispose();
    _liveDataModels.remove(surfaceId)?.dispose();
    _registry.removeSurface(surfaceId);
  }

  /// Reports an error to the AI service.
  void reportError(Object error, StackTrace? stack) {
    var errorCode = 'RUNTIME_ERROR';
    var message = error.toString();
    String? surfaceId;
    String? path;

    if (error is A2uiValidationException) {
      errorCode = 'VALIDATION_FAILED';
      message = error.message;
      surfaceId = error.surfaceId;
      path = error.path;
    }

    final Map<String, Object> errorMsg = {
      'version': 'v0.9',
      'error': {
        'code': errorCode,
        'surfaceId': ?surfaceId,
        'path': ?path,
        'message': message,
      },
    };
    _onSubmit.add(
      ChatMessage.user(
        '',
        parts: [UiInteractionPart.create(jsonEncode(errorMsg))],
      ),
    );
  }

  void _bufferMessage(String surfaceId, core.A2uiMessage message) {
    _pendingUpdates.putIfAbsent(surfaceId, () => []).add(message);
    if (!_pendingUpdateTimers.containsKey(surfaceId)) {
      _pendingUpdateTimers[surfaceId] = Timer(pendingUpdateTimeout, () {
        _pendingUpdates.remove(surfaceId);
        _pendingUpdateTimers.remove(surfaceId);
      });
    }
  }

  /// Sends a [UserActionEvent] to [onSubmit] as a [ChatMessage]. No-op for
  /// non-action [UiEvent]s.
  void handleUiEvent(UiEvent event) {
    if (!event.isUserAction) return;
    _onSubmit.add(
      ChatMessage.user(
        '',
        parts: [
          UiInteractionPart.create(
            jsonEncode({'version': 'v0.9', 'action': event.toMap()}),
          ),
        ],
      ),
    );
  }

  Catalog? _findCatalogForSurface(String surfaceId) {
    final core.SurfaceModel<core.ComponentApi>? surface = _registry
        .getLiveSurface(surfaceId);
    if (surface == null) return null;
    return catalogs.firstWhereOrNull((c) => c.catalogId == surface.catalog.id);
  }

  /// Validates the components currently in [surface] against [catalog]'s
  /// schema. Throws [A2uiValidationException] on the first failing component.
  void _validateComponents(
    String surfaceId,
    core.SurfaceModel<core.ComponentApi> surface,
    Catalog catalog,
  ) {
    schema_validation.validateComponents(
      surfaceId: surfaceId,
      components: surface.componentsModel.all.map(
        (c) => (id: c.id, type: c.type, json: c.toJson()),
      ),
      schema: catalog.definition,
    );
  }

  /// Disposes of the controller and releases all resources.
  void dispose() {
    _processor.groupModel.onSurfaceCreated.removeListener(
      _onCoreSurfaceCreated,
    );
    _processor.groupModel.onSurfaceDeleted.removeListener(
      _onCoreSurfaceDeleted,
    );
    _processor.groupModel.dispose();
    for (final DataModel model in _preCreateDataModels.values) {
      model.dispose();
    }
    for (final DataModel model in _liveDataModels.values) {
      model.dispose();
    }
    _registry.dispose();
    _onSubmit.close();
    for (final Timer timer in _pendingUpdateTimers.values) {
      timer.cancel();
    }
  }
}

class _ControllerContext implements SurfaceContext {
  _ControllerContext(this._controller, this.surfaceId);
  final SurfaceController _controller;

  @override
  final String surfaceId;

  @override
  ValueListenable<SurfaceDefinition?> get definition =>
      _controller.registry.watchDefinition(surfaceId);

  @override
  DataModel get dataModel => _controller._dataModelFor(surfaceId);

  @override
  Catalog? get catalog => _controller._findCatalogForSurface(surfaceId);

  @override
  void handleUiEvent(UiEvent event) => _controller.handleUiEvent(event);

  @override
  void reportError(Object error, StackTrace? stack) =>
      _controller.reportError(error, stack);
}
