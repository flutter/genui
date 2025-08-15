// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// Manages a collection of UI surfaces, each with its own
/// [FcpViewController] and [DynamicUIPacket].
///
/// This class is responsible for the lifecycle of the surfaces, including
/// creation, retrieval, and removal.
class FcpSurfaceManager with ChangeNotifier {
  final Map<String, FcpViewController> _controllers = {};
  final Map<String, DynamicUIPacket> _packets = {};
  final _log = Logger('FcpSurfaceManager');

  /// A map of surface IDs to their respective [FcpViewController]s.
  Map<String, FcpViewController> get controllers => _controllers;

  /// A map of surface IDs to their respective [DynamicUIPacket]s.
  Map<String, DynamicUIPacket> get packets => _packets;

  /// Creates or updates a surface with the given [surfaceId] and [packet].
  ///
  /// If a surface with the same ID does not exist, a new controller will be
  /// created.
  void setSurface(String surfaceId, DynamicUIPacket packet) {
    _log.info('Setting surface "$surfaceId".');
    _packets[surfaceId] = packet;
    if (!_controllers.containsKey(surfaceId)) {
      _log.info('Creating new controller for surface "$surfaceId".');
      _controllers[surfaceId] = FcpViewController();
    }
    notifyListeners();
  }

  /// Returns the [FcpViewController] for the given [surfaceId].
  ///
  /// Returns `null` if no surface with the given ID exists.
  FcpViewController? getController(String surfaceId) {
    _log.fine('Getting controller for surface "$surfaceId".');
    return _controllers[surfaceId];
  }

  /// Returns the [DynamicUIPacket] for the given [surfaceId].
  ///
  /// Returns `null` if no surface with the given ID exists.
  DynamicUIPacket? getPacket(String surfaceId) {
    _log.fine('Getting packet for surface "$surfaceId".');
    return _packets[surfaceId];
  }

  /// Returns a list of all active surface IDs.
  List<String> listSurfaces() {
    _log.fine('Listing surfaces: ${_controllers.keys}');
    return _controllers.keys.toList();
  }

  /// Removes the surface with the given [surfaceId].
  void removeSurface(String surfaceId) {
    _log.info('Removing surface "$surfaceId".');
    _controllers[surfaceId]?.dispose();
    _controllers.remove(surfaceId);
    _packets.remove(surfaceId);
    notifyListeners();
  }

  @override
  void dispose() {
    _log.info('Disposing FcpSurfaceManager.');
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _packets.clear();
    super.dispose();
  }
}
