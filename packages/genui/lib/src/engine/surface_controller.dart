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
import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
import '../model/schema_validation.dart' as schema_validation;
import '../model/ui_models.dart';
import '../primitives/logging.dart';

import 'data_model_store.dart';
import 'surface_registry.dart' as surface_reg;

/// The runtime controller for the GenUI system.
///
/// Thin Flutter-side wrapper around [core.MessageProcessor]: the substrate
/// owns the canonical A2UI state-mutation rules (create/update/delete
/// surfaces and their components/data models) and this class adds the
/// Flutter-specific concerns on top: pre-create message buffering, schema
/// validation against the genui catalog, and a [SurfaceUpdate] stream the
/// Flutter facade subscribes to.
interface class SurfaceController implements SurfaceHost, A2uiMessageSink {
  SurfaceController({
    required this.catalogs,
    this.pendingUpdateTimeout = const Duration(minutes: 1),
  }) {
    _processor = core.MessageProcessor<core.ComponentApi>(
      // Growable: handleMessage may inject stub catalogs for unknown
      // catalogIds (see comment near _processor.catalogs.add below).
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
  late final DataModelStore _store = DataModelStore(
    lookup: (String surfaceId) {
      final core.SurfaceModel? surface = _registry.getSurface(surfaceId);
      if (surface == null) return null;
      return InMemoryDataModel.wrap(surface.dataModel);
    },
  );

  final _onSubmit = StreamController<ChatMessage>.broadcast();
  final _pendingUpdates = <String, List<core.A2uiMessage>>{};
  final _pendingUpdateTimers = <String, Timer>{};

  @override
  Stream<SurfaceUpdate> get surfaceUpdates => _registry.events.map(
    (e) => switch (e) {
      surface_reg.SurfaceAdded(:final surfaceId, :final surface) =>
        SurfaceAdded(surfaceId, surface),
      surface_reg.SurfaceUpdated(:final surfaceId, :final surface) =>
        ComponentsUpdated(surfaceId, surface),
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

  /// The source-compatible store of data models managed by this controller.
  DataModelStore get store => _store;

  /// Processes a message from the AI service.
  ///
  /// Delegates the canonical state mutation to [core.MessageProcessor] and
  /// adds Flutter-specific concerns around it (pre-create buffering of
  /// updates, schema validation of the resulting component set, and
  /// surface-level `ComponentsUpdated` emission for the [surfaceUpdates]
  /// stream).
  @override
  void handleMessage(A2uiMessage message) {
    genUiLogger.info(
      'SurfaceController.handleMessage received: ${message.runtimeType}',
    );
    _handleCoreMessage(message.toCoreMessage());
  }

  /// Internal entry point used by buffered/flushed messages where we already
  /// hold the substrate representation. Public callers go through
  /// [handleMessage] with the GenUI facade type.
  void _handleCoreMessage(core.A2uiMessage coreMessage) {
    // Empty surfaceId — reject before delegating so the substrate doesn't
    // create a surface with id "".
    if (coreMessage is core.CreateSurfaceMessage &&
        coreMessage.surfaceId.isEmpty) {
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

    // Buffer updates that arrive before their surface is created.
    final String? bufferSurfaceId = _bufferSurfaceIdIfNoSurface(coreMessage);
    if (bufferSurfaceId != null) {
      _bufferMessage(bufferSurfaceId, coreMessage);
      return;
    }

    // If a createSurface refers to a catalogId we do not have, register an
    // empty stub so the substrate's "catalog not found" check passes. This
    // mirrors the previous lenient behavior where unknown catalogIds were
    // accepted with an empty component set — useful for tests/demos that
    // do not pre-register every catalog the server may send.
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

    // Genui-side post-mutation handling. The substrate has already applied
    // the mutation by this point — these are additive Flutter/genui
    // concerns the substrate does not own.
    if (coreMessage is core.UpdateComponentsMessage) {
      final core.SurfaceModel<core.ComponentApi>? surface = _processor
          .groupModel
          .getSurface(coreMessage.surfaceId);
      if (surface != null) {
        // Emit a surface-level "components updated" so subscribers to
        // `surfaceUpdates` can react without listening to every
        // ComponentModel individually.
        _registry.notifyUpdated(surface);
        // Validate the resulting component set against the genui catalog
        // schema. Mutation is not rolled back on validation failure — we
        // surface the error and let the caller decide.
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

  /// Returns the surfaceId of [message] if it is an update for a surface
  /// that does not yet exist (and therefore needs to be buffered), or null
  /// if no buffering is needed.
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
    _registry.addSurface(surface);
    // Flush any updates that arrived for this surfaceId before createSurface.
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
    _store.removeDataModel(surfaceId);
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

  /// Handles a UI event from a surface — converts a [UserActionEvent] into
  /// a [ChatMessage] sent on [onSubmit].
  void handleUiEvent(UiEvent event) {
    if (event is! UserActionEvent) return;
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
    final core.SurfaceModel<core.ComponentApi>? surface = _registry.getSurface(
      surfaceId,
    );
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
    _store.dispose();
    _registry.dispose();
    _onSubmit.close();
    for (final Timer timer in _pendingUpdateTimers.values) {
      timer.cancel();
    }
  }
}

class _ControllerContext implements LiveSurfaceContext {
  _ControllerContext(this._controller, this.surfaceId);
  final SurfaceController _controller;

  @override
  final String surfaceId;

  @override
  ValueListenable<core.SurfaceModel?> get surface =>
      _controller.registry.watchSurface(surfaceId);

  @override
  ValueListenable<SurfaceDefinition?> get definition =>
      _controller.registry.watchDefinition(surfaceId);

  @override
  DataModel get dataModel {
    final core.SurfaceModel? s = _controller.registry.getSurface(surfaceId);
    if (s == null) {
      throw StateError(
        'SurfaceContext.dataModel accessed for surface "$surfaceId" '
        'before the surface was created. Guard on `definition.value != null` '
        'or wait for a SurfaceAdded event before reading the data model.',
      );
    }
    return InMemoryDataModel.wrap(s.dataModel);
  }

  @override
  Catalog? get catalog => _controller._findCatalogForSurface(surfaceId);

  @override
  void handleUiEvent(UiEvent event) => _controller.handleUiEvent(event);

  @override
  void reportError(Object error, StackTrace? stack) =>
      _controller.reportError(error, stack);
}
