// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../ai/ai_provider.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Order Confirmed!'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ref
          .watch(aiProvider)
          .when(
            data: (aiState) {
              return ValueListenableBuilder<UiDefinition?>(
                valueListenable: aiState.a2uiMessageProcessor
                    .getSurfaceNotifier('confirmation'),
                builder: (context, definition, child) {
                  if (definition == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return GenUiSurface(
                    host: aiState.a2uiMessageProcessor,
                    surfaceId: 'confirmation',
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
          ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to Start'),
        ),
      ),
    );
  }
}
