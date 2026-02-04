// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../interfaces/a2ui_message_sink.dart';
import '../interfaces/gen_ui_context.dart';
import '../interfaces/gen_ui_host.dart';
import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import 'cleanup_strategy.dart';
import 'data_model_store.dart';
import 'surface_registry.dart' as surface_reg;

/// The runtime engine for the GenUI system.
class GenUiEngine implements GenUiHost, A2uiMessageSink {
  /// Creates a [GenUiEngine].
  ///
  /// The [catalogs] parameter defines the set of component catalogs available
  /// for use by surfaces managed by this engine.
  ///
  /// The [cleanupStrategy] determines when and how surfaces are removed from
  /// the registry to free up resources.
  ///
  /// The [pendingUpdateTimeout] specifies how long to wait for a surface
  /// creation message before discarding buffered updates for that surface.
  GenUiEngine({
    required this.catalogs,
    this.cleanupStrategy = const ManualCleanupStrategy(),
    this.pendingUpdateTimeout = const Duration(minutes: 1),
  });

  /// The catalogs available to surfaces in this engine.
  final Iterable<Catalog> catalogs;

  /// The strategy used to clean up unused surfaces.
  final SurfaceCleanupStrategy cleanupStrategy;

  /// The timeout for pending updates waiting for a surface creation.
  final Duration pendingUpdateTimeout;

  late final surface_reg.SurfaceRegistry _registry =
      surface_reg.SurfaceRegistry();
  late final DataModelStore _store = DataModelStore();

  final _onSubmit = StreamController<ChatMessage>.broadcast();
  final _pendingUpdates = <String, List<A2uiMessage>>{};
  final _pendingUpdateTimers = <String, Timer>{};

  // Expose registry events as surface updates
  @override
  Stream<GenUiUpdate> get surfaceUpdates => _registry.events.map((e) {
    switch (e) {
      case surface_reg.SurfaceAdded():
        return SurfaceAdded(e.surfaceId, e.definition);
      case surface_reg.SurfaceUpdated():
        return ComponentsUpdated(e.surfaceId, e.definition);
      case surface_reg.SurfaceRemoved():
        return SurfaceRemoved(e.surfaceId);
    }
  });

  Stream<ChatMessage> get onSubmit => _onSubmit.stream;

  @override
  GenUiContext contextFor(String surfaceId) {
    return _EngineContext(this, surfaceId);
  }

  surface_reg.SurfaceRegistry get registry => _registry;
  DataModelStore get store => _store;

  /// Process an [message] from the AI service.
  ///
  /// This method decodes the message and updates the state of the relevant
  /// surface, provided the message passes validation.
  ///
  /// If validation fails, a [GenUiValidationException] is caught and logged,
  /// and an error message is sent back via [onSubmit].
  @override
  void handleMessage(A2uiMessage message) {
    try {
      _handleMessageInternal(message);
    } on GenUiValidationException catch (e) {
      genUiLogger.warning('Validation failed for surface ${e.surfaceId}: $e');
      final Map<String, Map<String, Object>> errorMsg = {
        'error': {
          'version': 'v0.9',
          'code': 'VALIDATION_FAILED',
          'surfaceId': e.surfaceId,
          'path': e.path,
          'message': e.message,
        },
      };
      _onSubmit.add(
        ChatMessage.user(
          '',
          parts: [UiInteractionPart.create(jsonEncode(errorMsg))],
        ),
      );
    } catch (e, stack) {
      genUiLogger.severe('Error handling message: $message', e, stack);
    }
  }

  void _handleMessageInternal(A2uiMessage message) {
    switch (message) {
      case CreateSurface():
        final String surfaceId = message.surfaceId;
        if (surfaceId.isEmpty) {
          throw GenUiValidationException(
            surfaceId: surfaceId,
            message: 'Surface ID cannot be empty',
            path: 'surfaceId',
          );
        }

        final List<A2uiMessage>? pending = _pendingUpdates.remove(surfaceId);
        _pendingUpdateTimers.remove(surfaceId)?.cancel();

        _store.getDataModel(surfaceId); // Ensure model exists

        final UiDefinition? existing = _registry.getSurface(surfaceId);
        final UiDefinition newDefinition =
            (existing ?? UiDefinition(surfaceId: surfaceId)).copyWith(
              catalogId: message.catalogId,
              theme: message.theme,
            );

        if (message.attachDataModel) {
          _store.attachSurface(surfaceId);
        } else {
          _store.detachSurface(surfaceId);
        }

        _registry.updateSurface(
          surfaceId,
          newDefinition,
          isNew: existing == null,
        );
        _enforceCleanupPolicy();

        if (pending != null) {
          for (final A2uiMessage msg in pending) {
            _handleMessageInternal(msg);
          }
        }

      case UpdateComponents():
        final String surfaceId = message.surfaceId;
        if (!_registry.hasSurface(surfaceId)) {
          _bufferMessage(surfaceId, message);
          return;
        }

        final UiDefinition current = _registry.getSurface(surfaceId)!;
        final Map<String, Component> newComponents = Map.of(current.components);
        for (final Component component in message.components) {
          newComponents[component.id] = component;
        }

        _registry.updateSurface(
          surfaceId,
          current.copyWith(components: newComponents),
        );

      case UpdateDataModel():
        final String surfaceId = message.surfaceId;
        if (!_registry.hasSurface(surfaceId)) {
          _bufferMessage(surfaceId, message);
          return;
        }

        final DataModel model = _store.getDataModel(surfaceId);
        model.update(DataPath(message.path), message.value);

        // Trigger generic update on surface to refresh UI
        final UiDefinition current = _registry.getSurface(surfaceId)!;
        _registry.updateSurface(surfaceId, current);

      case DeleteSurface():
        final String surfaceId = message.surfaceId;
        _pendingUpdates.remove(surfaceId);
        _pendingUpdateTimers.remove(surfaceId)?.cancel();
        _registry.removeSurface(surfaceId);
        _store.removeDataModel(surfaceId);
    }
  }

  void _bufferMessage(String surfaceId, A2uiMessage message) {
    _pendingUpdates.putIfAbsent(surfaceId, () => []).add(message);
    if (!_pendingUpdateTimers.containsKey(surfaceId)) {
      _pendingUpdateTimers[surfaceId] = Timer(pendingUpdateTimeout, () {
        _pendingUpdates.remove(surfaceId);
        _pendingUpdateTimers.remove(surfaceId);
      });
    }
  }

  void _enforceCleanupPolicy() {
    final List<String> toRemove = cleanupStrategy.cleanup(
      _registry.surfaceOrder,
    );
    for (final id in toRemove) {
      _registry.removeSurface(id);
      _store.removeDataModel(id);
    }
  }

  void handleUiEvent(UiEvent event) {
    if (event is! UserActionEvent) return;
    _onSubmit.add(
      ChatMessage.user(
        '',
        parts: [
          UiInteractionPart.create(jsonEncode({'action': event.toMap()})),
        ],
      ),
    );
  }

  /// Disposes of the engine and releases all resources.
  ///
  /// This closes the [onSubmit] stream and cancels any pending timers.
  void dispose() {
    _registry.dispose();
    _store.dispose();
    _onSubmit.close();
    for (final Timer timer in _pendingUpdateTimers.values) {
      timer.cancel();
    }
  }
}

class _EngineContext implements GenUiContext {
  _EngineContext(this._engine, this.surfaceId);
  final GenUiEngine _engine;

  @override
  final String surfaceId;

  @override
  ValueListenable<UiDefinition?> get definition =>
      _engine.registry.watchSurface(surfaceId);

  @override
  DataModel get dataModel => _engine.store.getDataModel(surfaceId);

  @override
  Iterable<Catalog> get catalogs => _engine.catalogs;

  @override
  void handleUiEvent(UiEvent event) {
    _engine.handleUiEvent(event);
  }
}
