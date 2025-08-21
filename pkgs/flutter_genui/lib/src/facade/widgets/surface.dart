// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../flutter_genui.dart';

class GenUiSurface extends StatefulWidget {
  const GenUiSurface(this.genUiManager, {super.key, required this.surfaceId});

  final GenUiManager genUiManager;
  final String surfaceId;

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  ValueNotifier<UiDefinition?>? _definition;
  StreamSubscription<GenUiUpdate>? _allUpdates;

  @override
  void didUpdateWidget(covariant GenUiSurface oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.surfaceId != widget.surfaceId ||
        oldWidget.genUiManager != widget.genUiManager) {
      initState();
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    // Reset previous subscription for updates.
    _allUpdates?.cancel();
    _allUpdates = widget.genUiManager.updates.listen((update) {
      if (update.surfaceId == widget.surfaceId) _init();
    });

    // Update definition if it is changed.
    final newDefinition = widget.genUiManager.surface(widget.surfaceId);
    if (newDefinition == _definition) return;
    _definition = newDefinition;
    setState(() {});
  }

  @override
  void dispose() {
    // _definition is owned by genUiManager, no need to dispose.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definition = _definition;
    if (definition == null) return const SizedBox.shrink();

    return ValueListenableBuilder<UiDefinition?>(
      valueListenable: definition,
      builder: (context, definition, child) {
        if (definition == null) {
          return const SizedBox.shrink();
        }
        // return definition.
        return Container(); // Replace with your actual widget
      },
    );
  }
}
