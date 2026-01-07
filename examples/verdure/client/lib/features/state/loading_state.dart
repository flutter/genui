// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

const _defaultMessages = [
  'Reimagining our outdoor architecture...',
  'Scrubbing grout...',
  'Scaling palm trees...',
  'Watering the virtual plants...',
  'Trimming the digital hedges...',
  'Reticulating splines...',
  'Polishing the garden gnomes...',
  'Sowing the seeds of design...',
  'Cultivating creativity...',
  'Designing your dreamscape...',
  'Fertilizing the pixels...',
  'Consulting with the garden gnomes...',
  'Drafting botanical blueprints...',
  'Aligning the digital sun...',
  'Sourcing virtual soil...',
  'Calibrating the sprinklers...',
  'Unrolling the artificial turf...',
  'Choosing the perfect pebbles...',
  'Generating tranquil vibes...',
  'Harmonizing the elements...',
];

class LoadingState {
  LoadingState._() {
    // When the processing state changes from true to false, reset messages.
    isProcessing.addListener(() {
      if (!_isProcessingValue && isProcessing.value) {
        // Went from false to true
      } else if (_isProcessingValue && !isProcessing.value) {
        // Went from true to false, reset messages after a short delay
        // to allow the fade-out animation to complete.
        Future<void>.delayed(const Duration(milliseconds: 500), clearMessages);
      }
      _isProcessingValue = isProcessing.value;
    });
  }

  static final instance = LoadingState._();

  final messages = ValueNotifier<List<String>>(_defaultMessages);
  final isProcessing = ValueNotifier<bool>(false);
  bool _isProcessingValue = false;

  List<String> _defaults = _defaultMessages;

  void setMessages(List<String> newMessages) {
    messages.value = newMessages;
  }

  void setDefaults(List<String> newDefaults) {
    _defaults = newDefaults;
  }

  void clearMessages() {
    messages.value = _defaults;
  }
}
