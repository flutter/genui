// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../common/reactivity.dart';
import '../protocol/catalog.dart';
import '../protocol/common.dart';
import '../protocol/messages.dart';
import '../rendering/contexts.dart';
import 'component_model.dart';
import 'data_model.dart';

/// The state model for a single UI surface.
class SurfaceModel<T extends ComponentApi> {
  final String id;
  final Catalog<T> catalog;
  final Map<String, dynamic> theme;
  final bool sendDataModel;

  final DataModel dataModel;
  final SurfaceComponentsModel componentsModel;

  final _onAction = ValueNotifier<A2uiClientAction?>(null);
  final _onError = ValueNotifier<A2uiClientError?>(null);

  /// Fires whenever an action is dispatched from this surface.
  ValueListenable<A2uiClientAction?> get onAction => _onAction;

  /// Fires whenever an error occurs on this surface.
  ValueListenable<A2uiClientError?> get onError => _onError;

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
      _onAction.value = action;
    } else if (payload.containsKey('functionCall')) {
      final callJson = payload['functionCall'] as Map<String, dynamic>;
      final call = FunctionCall.fromJson(callJson);
      catalog.invoker(
        call.call,
        Map<String, dynamic>.from(call.args),
        DataContext(this, '/'),
      );
    }
  }

  /// Dispatches an error from this surface.
  Future<void> dispatchError(A2uiClientError error) async {
    _onError.value = error;
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
  final Map<String, void Function()> _actionForwarders = {};

  final _onSurfaceCreated = ValueNotifier<SurfaceModel<T>?>(null);
  final _onSurfaceDeleted = ValueNotifier<String?>(null);
  final _onAction = ValueNotifier<A2uiClientAction?>(null);

  /// Fires when a new surface is added.
  ValueListenable<SurfaceModel<T>?> get onSurfaceCreated => _onSurfaceCreated;

  /// Fires when a surface is removed.
  ValueListenable<String?> get onSurfaceDeleted => _onSurfaceDeleted;

  /// Fires when an action is dispatched from ANY surface in the group.
  ValueListenable<A2uiClientAction?> get onAction => _onAction;

  /// Adds a surface to the group.
  void addSurface(SurfaceModel<T> surface) {
    if (_surfaces.containsKey(surface.id)) {
      return;
    }
    _surfaces[surface.id] = surface;
    void forwarder() {
      final A2uiClientAction? action = surface.onAction.value;
      if (action != null) {
        _onAction.value = action;
      }
    }
    surface.onAction.addListener(forwarder);
    _actionForwarders[surface.id] = forwarder;
    _onSurfaceCreated.value = surface;
  }

  /// Removes a surface from the group by its ID.
  void deleteSurface(String id) {
    final SurfaceModel<T>? surface = _surfaces.remove(id);
    if (surface != null) {
      final void Function()? forwarder = _actionForwarders.remove(id);
      if (forwarder != null) {
        surface.onAction.removeListener(forwarder);
      }
      surface.dispose();
      _onSurfaceDeleted.value = id;
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
