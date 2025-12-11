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

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  bool _initialRequestSent = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AiClientState>>(aiProvider, (previous, next) {
      if (next is AsyncData && !_initialRequestSent) {
        setState(() {
          _initialRequestSent = true;
        });
        // The presentation screen is populated by the action on the previous
        // screen, so we don't need to send a message here.
      }
    });

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appLogger.info('AiPresentationScreen: Back button tapped');
            context.pop();
          },
        ),
        title: const Text('Your Custom Designs'),
        centerTitle: true,
      ),
      body: ref
          .watch(aiProvider)
          .when(
            data: (aiState) {
              return ValueListenableBuilder<UiDefinition?>(
                valueListenable: aiState.a2uiMessageProcessor
                    .getSurfaceNotifier('options'),
                builder: (context, definition, child) {
                  if (definition == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: GenUiSurface(
                      host: aiState.a2uiMessageProcessor,
                      surfaceId: 'options',
                    ),
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
