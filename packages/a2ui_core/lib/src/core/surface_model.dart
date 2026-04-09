// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../common/event_notifier.dart';
import 'catalog.dart';
import 'common.dart';
import 'component_model.dart';
import 'contexts.dart';
import 'data_model.dart';
import 'messages.dart';

/// The state model for a single UI surface.
class SurfaceModel<T extends ComponentApi> {
  final String id;
  final Catalog<T> catalog;
  final Map<String, dynamic> theme;
  final bool sendDataModel;

  final DataModel dataModel;
  final SurfaceComponentsModel componentsModel;

  final _onAction = EventNotifier<A2uiClientAction>();
  final _onError = EventNotifier<A2uiClientError>();

  /// Fires whenever an action is dispatched from this surface.
  EventListenable<A2uiClientAction> get onAction => _onAction;

  /// Fires whenever an error occurs on this surface.
  EventListenable<A2uiClientError> get onError => _onError;

  SurfaceModel(
    this.id, {
    required this.catalog,
    this.theme = const {},
    this.sendDataModel = false,
  }) : dataModel = DataModel(),
       componentsModel = SurfaceComponentsModel();

  /// Dispatches an action from this surface.
  Future<void> dispatchAction(
    Map<String, dynamic> payload,
    String sourceComponentId,
  ) async {
    if (payload.containsKey('event')) {
      final event = payload['event'] as Map<String, dynamic>;
      final action = A2uiClientAction(
        name: (event['name'] as String?) ?? 'unknown',
        surfaceId: id,
        sourceComponentId: sourceComponentId,
        timestamp: DateTime.now(),
        context: Map<String, dynamic>.from(
          (event['context'] ?? <String, dynamic>{}) as Map,
        ),
      );
      _onAction.emit(action);
    } else if (payload.containsKey('functionCall')) {
      final callJson = payload['functionCall'] as Map<String, dynamic>;
      final call = FunctionCall.fromJson(callJson);
      catalog.invoker(
        call.call,
        Map<String, dynamic>.from(call.args),
        DataContext(dataModel, catalog.invoker, '/'),
      );
    }
  }

  /// Dispatches an error from this surface.
  Future<void> dispatchError(A2uiClientError error) async {
    _onError.emit(error);
  }

  /// Disposes of the surface and its resources.
  void dispose() {
    dataModel.dispose();
    componentsModel.dispose();
    _onAction.dispose();
    _onError.dispose();
  }
}

/// The root state model for the A2UI system.
class SurfaceGroupModel<T extends ComponentApi> {
  final Map<String, SurfaceModel<T>> _surfaces = {};
  final Map<String, void Function(A2uiClientAction)> _actionForwarders = {};

  final _onSurfaceCreated = EventNotifier<SurfaceModel<T>>();
  final _onSurfaceDeleted = EventNotifier<String>();
  final _onAction = EventNotifier<A2uiClientAction>();

  /// Fires when a new surface is added.
  EventListenable<SurfaceModel<T>> get onSurfaceCreated => _onSurfaceCreated;

  /// Fires when a surface is removed.
  EventListenable<String> get onSurfaceDeleted => _onSurfaceDeleted;

  /// Fires when an action is dispatched from ANY surface in the group.
  EventListenable<A2uiClientAction> get onAction => _onAction;

  /// Adds a surface to the group.
  void addSurface(SurfaceModel<T> surface) {
    if (_surfaces.containsKey(surface.id)) {
      return;
    }
    _surfaces[surface.id] = surface;
    void forwarder(A2uiClientAction action) {
      _onAction.emit(action);
    }

    surface.onAction.addListener(forwarder);
    _actionForwarders[surface.id] = forwarder;
    _onSurfaceCreated.emit(surface);
  }

  /// Removes a surface from the group by its ID.
  void deleteSurface(String id) {
    final SurfaceModel<T>? surface = _surfaces.remove(id);
    if (surface != null) {
      final void Function(A2uiClientAction)? forwarder = _actionForwarders
          .remove(id);
      if (forwarder != null) {
        surface.onAction.removeListener(forwarder);
      }
      surface.dispose();
      _onSurfaceDeleted.emit(id);
    }
  }

  /// Retrieves a surface by its ID.
  SurfaceModel<T>? getSurface(String id) => _surfaces[id];

  /// Returns all active surfaces.
  Iterable<SurfaceModel<T>> get allSurfaces => _surfaces.values;

  /// Disposes of the group and all its surfaces.
  void dispose() {
    for (final id in List<String>.from(_surfaces.keys)) {
      deleteSurface(id);
    }
    _onSurfaceCreated.dispose();
    _onSurfaceDeleted.dispose();
    _onAction.dispose();
  }
}
