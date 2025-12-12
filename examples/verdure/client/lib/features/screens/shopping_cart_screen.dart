// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';

import '../../core/logging.dart';
import '../../core/theme/theme.dart';
import '../ai/ai_provider.dart';

class ShoppingCartScreen extends ConsumerWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appLogger.info('ShoppingCartScreen: Back button tapped');
            context.pop();
          },
        ),
        title: const Text('Shopping Cart'),
        centerTitle: true,
      ),
      body: ref
          .watch(aiProvider)
          .when(
            data: (aiState) {
              return ValueListenableBuilder<UiDefinition?>(
                valueListenable: aiState.a2uiMessageProcessor
                    .getSurfaceNotifier('cart'),
                builder: (context, definition, child) {
                  if (definition == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return GenUiSurface(
                    host: aiState.a2uiMessageProcessor,
                    surfaceId: 'cart',
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
          ),
    );
  }
}
