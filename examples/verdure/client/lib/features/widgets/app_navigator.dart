// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/logging.dart';

import '../ai/ai_provider.dart';

class AppNavigator extends ConsumerStatefulWidget {
  const AppNavigator({super.key, required this.child, required this.router});

  final Widget child;
  final GoRouter router;

  @override
  ConsumerState<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends ConsumerState<AppNavigator> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    // It's safe to use ref.read here because we are not rebuilding the widget
    // when the provider changes, but instead subscribing to a stream.
    final AsyncValue<AiClientState> aiState = ref.read(aiProvider);
    if (aiState case AsyncData(:final value)) {
      _subscription = value.surfaceUpdateController.stream.listen(
        _onSurfaceUpdate,
      );
    }
  }

  void _onSurfaceUpdate(String surfaceId) {
    switch (surfaceId) {
      case 'questionnaire':
        widget.router.push('/questionnaire');
      case 'options':
        widget.router.push('/presentation');
      case 'cart':
        widget.router.push('/shopping_cart');
      case 'confirmation':
        widget.router.push('/order_confirmation');
      default:
        appLogger.warning('Unknown surfaceId: $surfaceId');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AiClientState?>>(aiProvider, (previous, next) {
      if (next case AsyncData(:final value?)) {
        _subscription?.cancel();
        _subscription = value.surfaceUpdateController.stream.listen(
          _onSurfaceUpdate,
        );
      }
    });

    return widget.child;
  }
}
