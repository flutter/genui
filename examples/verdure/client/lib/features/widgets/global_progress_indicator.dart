// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_provider.dart';
import '../state/loading_state.dart';

class GlobalProgressIndicator extends ConsumerWidget {
  const GlobalProgressIndicator({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAiProviderLoading = ref.watch(aiProvider) is AsyncLoading;

    return ValueListenableBuilder<bool>(
      valueListenable: LoadingState.instance.isProcessing,
      builder: (context, isProcessing, _) {
        return Stack(
          children: [
            child,
            if (isProcessing || isAiProviderLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.6),
                child: const _LoadingMessages(),
              ),
          ],
        );
      },
    );
  }
}

class _LoadingMessages extends StatefulWidget {
  const _LoadingMessages();

  @override
  State<_LoadingMessages> createState() => _LoadingMessagesState();
}

class _LoadingMessagesState extends State<_LoadingMessages> {
  int _messageIndex = 0;
  Timer? _timer;
  List<String> _messages = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _messages = LoadingState.instance.messages.value;
    if (_messages.isNotEmpty) {
      _messageIndex = _random.nextInt(_messages.length);
    }
    _startTimerIfNeeded();
    LoadingState.instance.messages.addListener(_onMessagesChanged);
  }

  void _onMessagesChanged() {
    if (mounted) {
      setState(() {
        _messages = LoadingState.instance.messages.value;
        if (_messages.isNotEmpty) {
          _messageIndex = _random.nextInt(_messages.length);
        }
      });
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (_messages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          setState(() {
            int newIndex;
            do {
              newIndex = _random.nextInt(_messages.length);
            } while (newIndex == _messageIndex);
            _messageIndex = newIndex;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    LoadingState.instance.messages.removeListener(_onMessagesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _messages.length > 1
                          ? _messages[_messageIndex]
                          : _messages.first,
                      key: ValueKey<String>(
                        _messages.length > 1
                            ? _messages[_messageIndex]
                            : _messages.first,
                      ),
                      textAlign: TextAlign.left,
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
