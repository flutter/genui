// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../genui.dart' show GenUiEngine, GenUiHost, GenUiSurface;

import '../model/ui_models.dart';

/// A widget that manages and displays multiple GenUI surfaces.
///
/// This widget listens to [GenUiHost.surfaceUpdates] and automatically
/// adds, updates, or removes [GenUiSurface] widgets based on the active
/// surfaces managed by the host.
///
/// By default, it displays surfaces in a [Column], but a custom [layoutBuilder]
/// can be provided to customize the arrangement (e.g., [Stack], [Row], or
/// custom layout).
class GenUiSurfaceManager extends StatefulWidget {
  /// Creates a [GenUiSurfaceManager].
  const GenUiSurfaceManager({
    super.key,
    required this.host,
    this.layoutBuilder,
    this.surfaceBuilder,
  });

  /// The host that manages the surfaces.
  final GenUiHost host;

  /// A builder that constructs the layout for the list of surface widgets.
  ///
  /// If null, a [Column] is used.
  final Widget Function(BuildContext context, List<Widget> surfaces)?
  layoutBuilder;

  /// A builder that constructs a [GenUiSurface] or custom widget for a given
  /// surface ID.
  ///
  /// If null, a default [GenUiSurface] is created.
  final Widget Function(BuildContext context, String surfaceId)? surfaceBuilder;

  @override
  State<GenUiSurfaceManager> createState() => _GenUiSurfaceManagerState();
}

class _GenUiSurfaceManagerState extends State<GenUiSurfaceManager> {
  late StreamSubscription<GenUiUpdate> _subscription;
  List<String> _activeSurfaceIds = [];

  @override
  void initState() {
    super.initState();
    // Initialize with existing surfaces if any (host doesn't expose list
    // directly in interface, but we can track updates. Ideally host should
    // expose active IDs).
    // Initialize with existing surfaces if any.
    if (widget.host is GenUiEngine) {
      _activeSurfaceIds = (widget.host as GenUiEngine).registry.surfaceOrder
          .toList();
    }
    _subscription = widget.host.surfaceUpdates.listen(_handleUpdate);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _handleUpdate(GenUiUpdate update) {
    setState(() {
      switch (update) {
        case SurfaceAdded():
          if (!_activeSurfaceIds.contains(update.surfaceId)) {
            _activeSurfaceIds.add(update.surfaceId);
          }
        case SurfaceRemoved():
          _activeSurfaceIds.remove(update.surfaceId);
        case ComponentsUpdated():
          // Updates handled by GenUiSurface listening to notifier.
          // We just ensure ID is known.
          if (!_activeSurfaceIds.contains(update.surfaceId)) {
            _activeSurfaceIds.add(update.surfaceId);
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> surfaceWidgets = _activeSurfaceIds.map((id) {
      if (widget.surfaceBuilder != null) {
        return widget.surfaceBuilder!(context, id);
      }
      return GenUiSurface(
        key: ValueKey(id),
        genUiContext: widget.host.contextFor(id),
      );
    }).toList();

    if (widget.layoutBuilder != null) {
      return widget.layoutBuilder!(context, surfaceWidgets);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: surfaceWidgets,
    );
  }
}
