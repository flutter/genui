// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/method_channel_genui_express.dart';

/// The common platform interface contract for GenuiExpress local AI models.
abstract class GenuiExpressPlatform extends PlatformInterface {
  /// Constructs a GenuiExpressPlatform.
  GenuiExpressPlatform() : super(token: _token);

  static const Object _token = Object();

  static GenuiExpressPlatform _instance = MethodChannelGenuiExpress();

  /// The default instance of [GenuiExpressPlatform] to use.
  ///
  /// Defaults to [MethodChannelGenuiExpress].
  static GenuiExpressPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GenuiExpressPlatform] when
  /// they register themselves.
  static set instance(GenuiExpressPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks if local, on-device LLM capabilities are available and configured
  /// on the host platform.
  Future<bool> checkAvailability() {
    throw UnimplementedError('checkAvailability() has not been implemented.');
  }

  /// Generates a stream of response chunks from the local model for the given
  /// [prompt] and optional [systemPrompt].
  Stream<String> generateStream(String prompt, String? systemPrompt) {
    throw UnimplementedError('generateStream() has not been implemented.');
  }
}
