// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// The web-specific implementation of the GenuiExpress plugin.
class GenuiExpressWeb {
  /// Registers this class as the web implementation of [GenuiExpressPlatform].
  static void registerWith(Registrar registrar) {
    // We do not need custom web method channels, but this is required by Flutter
    // web compilation tools to compile the project successfully.
  }
}
