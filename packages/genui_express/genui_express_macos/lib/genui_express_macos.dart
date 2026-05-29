// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:genui_express_platform_interface/genui_express_platform_interface.dart';

/// The macOS-specific implementation of the GenuiExpress plugin.
///
/// Connects directly to macOS Apple Intelligence local foundation models
/// via method channels.
class GenuiExpressMacos extends GenuiExpressPlatform {
  /// Registers this class as the active instance of [GenuiExpressPlatform].
  static void registerWith() {
    GenuiExpressPlatform.instance = GenuiExpressMacos();
  }

  /// The method channel used to query general status and configuration.
  final MethodChannel _methodChannel = const MethodChannel(
    'genui_express/local_ai',
  );

  /// The event channel used to stream LLM token generation responses.
  final EventChannel _eventChannel = const EventChannel(
    'genui_express/local_ai_stream',
  );

  @override
  Future<bool> checkAvailability() async {
    return await _methodChannel.invokeMethod<bool>('checkAvailability') ??
        false;
  }

  @override
  Stream<String> generateStream(String prompt, String? systemPrompt) {
    return _eventChannel.receiveBroadcastStream({
      'prompt': prompt,
      'systemPrompt': systemPrompt,
    }).cast<String>();
  }
}
