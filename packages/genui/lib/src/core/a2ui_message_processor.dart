// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/a2ui_message.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/data_model.dart';
import '../model/ui_models.dart';
import '../primitives/logging.dart';
import 'interfaces.dart';

/// Policies for cleaning up old surfaces when new ones are created.
enum SurfaceCleanupPolicy {
  /// Surfaces are only removed when explicitly deleted by the AI.
  manual,

  /// Only the most recently updated/created surface is kept.
  keepLatest,

  /// The last N surfaces are kept.
  keepLastN,
}

/// Manages the state of all dynamic UI surfaces.
///
/// This class is the core state manager for the dynamic UI. It maintains a map
/// of all active UI "surfaces", where each surface is represented by a
/// `UiDefinition`. It provides the tools (`createSurface`, `updateComponents`,
/// `updateDataModel`, `deleteSurface`) that the AI uses to manipulate the UI.
/// It exposes a stream of `GenUiUpdate` events so that the application can
/// react to changes.
class A2uiMessageProcessor implements GenUiHost, A2uiMessageSink {
  /// Creates a new [A2uiMessageProcessor] with a list of supported widget
  /// catalogs.
  A2uiMessageProcessor({
    required this.catalogs,
    this.cleanupPolicy = SurfaceCleanupPolicy.manual,
    this.maxSurfaces = 1,
    this.pendingUpdateTimeout = const Duration(minutes: 1),
  });

  final Iterable<Catalog> catalogs;

  /// The policy to use for cleaning up old surfaces.
  final SurfaceCleanupPolicy cleanupPolicy;

  /// The maximum number of surfaces to keep when using
  /// [SurfaceCleanupPolicy.keepLastN].
  final int maxSurfaces;

  /// The duration to wait for a [CreateSurface] message before discarding
  /// pending updates.
  final Duration pendingUpdateTimeout;

  final _surfaces = <String, ValueNotifier<UiDefinition?>>{};
  // Track creation/update order for cleanup policies
  final _surfaceOrder = <String>[];
  final _surfaceUpdates = StreamController<GenUiUpdate>.broadcast();
  final _onSubmit = StreamController<ChatMessage>.broadcast();

  final _dataModels = <String, DataModel>{};
  final _pendingUpdates = <String, List<A2uiMessage>>{};
  final _pendingUpdateTimers = <String, Timer>{};
  final _attachedSurfaces = <String>{};

  Map<String, DataModel> get dataModels => Map.unmodifiable(_dataModels);

  DataModel dataModelForSurface(String surfaceId) {
    return _dataModels.putIfAbsent(surfaceId, DataModel.new);
  }

  /// A map of all the surfaces managed by this manager, keyed by surface ID.
  Map<String, ValueNotifier<UiDefinition?>> get surfaces => _surfaces;

  @override
  Stream<GenUiUpdate> get surfaceUpdates => _surfaceUpdates.stream;

  /// A stream of user input messages generated from UI interactions.
  Stream<ChatMessage> get onSubmit => _onSubmit.stream;

  void handleUiEvent(UiEvent event) {
    if (event is! UserActionEvent) {
      // Or handle other event types if necessary
      return;
    }

    // v0.9 uses 'action' instead of 'userAction'
    // TODO: Include attached data models if requested
    _onSubmit.add(
      ChatMessage.user(
        '',
        parts: [
          UiInteractionPart.create(jsonEncode({'action': event.toMap()})),
        ],
      ),
    );
  }

  @override
  GenUiContext contextFor(String surfaceId) {
    return _SurfaceContext(this, surfaceId);
  }

  ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId) {
    if (!_surfaces.containsKey(surfaceId)) {
      genUiLogger.fine('Adding new surface $surfaceId');
    } else {
      genUiLogger.fine('Fetching surface notifier for $surfaceId');
    }
    return _surfaces.putIfAbsent(
      surfaceId,
      () => ValueNotifier<UiDefinition?>(null),
    );
  }

  /// Disposes of the resources used by this manager.
  void dispose() {
    _surfaceUpdates.close();
    _onSubmit.close();
    for (final ValueNotifier<UiDefinition?> notifier in _surfaces.values) {
      notifier.dispose();
    }
    for (final DataModel model in _dataModels.values) {
      model.dispose();
    }
    for (final Timer timer in _pendingUpdateTimers.values) {
      timer.cancel();
    }
    _pendingUpdateTimers.clear();
  }

  /// Handles an [A2uiMessage] and updates the UI accordingly.
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

        // Check buffer first
        final List<A2uiMessage>? pending = _pendingUpdates.remove(surfaceId);
        _pendingUpdateTimers.remove(surfaceId)?.cancel();

        dataModelForSurface(surfaceId);
        final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(
          surfaceId,
        );

        // Create or update definition with theme/catalog
        final UiDefinition uiDefinition =
            notifier.value ?? UiDefinition(surfaceId: surfaceId);

        // v0.9: attachDataModel support
        if (message.attachDataModel) {
          _attachedSurfaces.add(surfaceId);
        } else {
          _attachedSurfaces.remove(surfaceId);
        }

        final UiDefinition newUiDefinition = uiDefinition.copyWith(
          catalogId: message.catalogId,
          theme: message.theme,
        );
        notifier.value = newUiDefinition;

        _updateSurfaceOrder(surfaceId);
        _enforceCleanupPolicy();

        genUiLogger.info('Created new surface $surfaceId');
        _surfaceUpdates.add(SurfaceAdded(surfaceId, newUiDefinition));

        // Process pending updates
        if (pending != null) {
          genUiLogger.info(
            'Processing ${pending.length} pending updates for $surfaceId',
          );
          for (final A2uiMessage msg in pending) {
            _handleMessageInternal(msg);
          }
        }

      case UpdateComponents():
        final String surfaceId = message.surfaceId;
        if (!_surfaces.containsKey(surfaceId)) {
          _bufferMessage(surfaceId, message);
          return;
        }

        final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(
          surfaceId,
        );

        UiDefinition uiDefinition =
            notifier.value ?? UiDefinition(surfaceId: surfaceId);

        final Map<String, Component> newComponents = Map.of(
          uiDefinition.components,
        );
        for (final Component component in message.components) {
          newComponents[component.id] = component;
        }
        uiDefinition = uiDefinition.copyWith(components: newComponents);

        notifier.value = uiDefinition;

        _updateSurfaceOrder(surfaceId);

        genUiLogger.info(
          '''Updating surface $surfaceId with ${message.components.length} components: ${message.components.map((c) => c.id).join(', ')}''',
        );
        _surfaceUpdates.add(ComponentsUpdated(surfaceId, uiDefinition));

      case UpdateDataModel():
        final String surfaceId = message.surfaceId;
        if (!_surfaces.containsKey(surfaceId)) {
          _bufferMessage(surfaceId, message);
          return;
        }

        final String path = message.path;
        genUiLogger.info(
          'Updating data model for surface $surfaceId at path '
          '$path with contents:\n'
          '${const JsonEncoder.withIndent('  ').convert(message.value)}',
        );
        final DataModel dataModel = dataModelForSurface(surfaceId);
        dataModel.update(DataPath(path), message.value);
        final ValueNotifier<UiDefinition?> notifier = getSurfaceNotifier(
          surfaceId,
        );
        final UiDefinition? uiDefinition = notifier.value;
        if (uiDefinition != null) {
          _surfaceUpdates.add(ComponentsUpdated(surfaceId, uiDefinition));
        }

      case DeleteSurface():
        final String surfaceId = message.surfaceId;
        _pendingUpdates.remove(surfaceId);
        _pendingUpdateTimers.remove(surfaceId)?.cancel();
        _deleteSurface(surfaceId);
    }
  }

  void _bufferMessage(String surfaceId, A2uiMessage message) {
    genUiLogger.info(
      'Buffering message for unknown surface $surfaceId: $message',
    );
    _pendingUpdates.putIfAbsent(surfaceId, () => []).add(message);

    if (!_pendingUpdateTimers.containsKey(surfaceId)) {
      _pendingUpdateTimers[surfaceId] = Timer(pendingUpdateTimeout, () {
        genUiLogger.warning(
          'Timeout waiting for CreateSurface for $surfaceId. '
          'Discarding pending updates.',
        );
        _pendingUpdates.remove(surfaceId);
        _pendingUpdateTimers.remove(surfaceId);
      });
    }
  }

  void _updateSurfaceOrder(String surfaceId) {
    _surfaceOrder.remove(surfaceId);
    _surfaceOrder.add(surfaceId);
  }

  void _enforceCleanupPolicy() {
    if (cleanupPolicy == SurfaceCleanupPolicy.manual) return;

    int keepCount;
    if (cleanupPolicy == SurfaceCleanupPolicy.keepLatest) {
      keepCount = 1;
    } else {
      keepCount = maxSurfaces;
    }

    if (_surfaceOrder.length > keepCount) {
      final int removeCount = _surfaceOrder.length - keepCount;
      final List<String> toRemove = _surfaceOrder.sublist(0, removeCount);
      for (final id in toRemove) {
        _deleteSurface(id);
      }
    }
  }

  void _deleteSurface(String surfaceId) {
    if (_surfaces.containsKey(surfaceId)) {
      genUiLogger.info('Deleting surface $surfaceId');
      final ValueNotifier<UiDefinition?>? notifier = _surfaces.remove(
        surfaceId,
      );
      notifier?.dispose();
      final DataModel? dataModel = _dataModels.remove(surfaceId);
      dataModel?.dispose();
      _surfaceOrder.remove(surfaceId);
      _attachedSurfaces.remove(surfaceId);
      _surfaceUpdates.add(SurfaceRemoved(surfaceId));
    }
  }

  /// Returns the current client data model for all attached surfaces.
  Map<String, Object?> getClientDataModel() {
    final result = <String, Object?>{};
    for (final String surfaceId in _attachedSurfaces) {
      if (_dataModels.containsKey(surfaceId)) {
        result[surfaceId] = _dataModels[surfaceId]!.data;
      }
    }
    return {'version': 'v0.9', 'surfaces': result};
  }
}

class _SurfaceContext implements GenUiContext {
  _SurfaceContext(this._host, this.surfaceId);

  final A2uiMessageProcessor _host;

  @override
  final String surfaceId;

  @override
  ValueListenable<UiDefinition?> get definition =>
      _host.getSurfaceNotifier(surfaceId);

  @override
  DataModel get dataModel => _host.dataModelForSurface(surfaceId);

  @override
  Iterable<Catalog> get catalogs => _host.catalogs;

  @override
  void handleUiEvent(UiEvent event) {
    // Ensure the event has the correct surfaceId.
    // The event from the surface widget *might* already have it if the widget
    // put it there, but we enforce it here or allow the host to handle it.
    // However, A2uiMessageProcessor.handleUiEvent historically took an event
    // and just emitted it. It didn't validate surfaceId inside the event map
    // strictly against "this" surfaceId, but typically listeners need to know
    // where it came from.
    //
    // GenUiSurface._dispatchEvent attaches the surfaceId.
    // We pass it through to the host.
    _host.handleUiEvent(event);
  }
}
