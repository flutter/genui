// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../primitives/event_notifier.dart';
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
  final Map<String, dynamic> surfaceProperties;
  final bool sendDataModel;

  final DataModel dataModel;
  final SurfaceComponentsModel componentsModel;

  final _onAction = EventNotifier<A2uiClientAction>();
  final _onError = EventNotifier<A2uiClientError>();

  /// Pending actions awaiting an `actionResponse` from the server, keyed by
  /// actionId. The value is the optional JSON Pointer path where the
  /// response value should be written in the data model.
  final Map<String, String?> _pendingActions = {};
  int _nextActionId = 0;

  /// Fires whenever an action is dispatched from this surface.
  EventListenable<A2uiClientAction> get onAction => _onAction;

  /// Fires whenever an error occurs on this surface.
  EventListenable<A2uiClientError> get onError => _onError;

  SurfaceModel(
    this.id, {
    required this.catalog,
    this.surfaceProperties = const {},
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
      final bool wantResponse = event['wantResponse'] as bool? ?? false;
      String? actionId;
      if (wantResponse) {
        actionId = '$id-action-${_nextActionId++}';
        _pendingActions[actionId] = event['responsePath'] as String?;
      }
      final action = A2uiClientAction(
        name: (event['name'] as String?) ?? 'unknown',
        surfaceId: id,
        sourceComponentId: sourceComponentId,
        timestamp: DateTime.now(),
        context: Map<String, dynamic>.from(
          (event['context'] ?? <String, dynamic>{}) as Map,
        ),
        wantResponse: wantResponse,
        actionId: actionId,
      );
      _onAction.emit(action);
    } else if (payload.containsKey('functionCall')) {
      final callJson = payload['functionCall'] as Map<String, dynamic>;
      final call = FunctionCall.fromJson(callJson);
      final FunctionImplementation? fn = catalog.functions[call.call];
      if (fn != null && !fn.callableFrom.isClientCallable) {
        await dispatchError(
          A2uiClientError(
            code: 'INVALID_FUNCTION_CALL',
            surfaceId: id,
            message:
                "Function '${call.call}' is configured as "
                "'${fn.callableFrom.jsonValue}' and cannot be invoked from "
                'the client.',
          ),
        );
        return;
      }
      catalog.invoke(
        call.call,
        Map<String, dynamic>.from(call.args),
        DataContext(dataModel, catalog.invoke, '/'),
      );
    }
  }

  /// Applies a server [ActionResponseMessage] to this surface.
  ///
  /// Returns true if the response corresponds to an action dispatched from
  /// this surface, false otherwise.
  bool applyActionResponse(ActionResponseMessage message) {
    if (!_pendingActions.containsKey(message.actionId)) {
      return false;
    }
    final String? responsePath = _pendingActions.remove(message.actionId);
    final A2uiActionError? error = message.error;
    if (error != null) {
      _onError.emit(
        A2uiClientError(
          code: error.code,
          surfaceId: id,
          message: error.message,
        ),
      );
    } else if (responsePath != null) {
      dataModel.set(responsePath, message.value);
    }
    return true;
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
