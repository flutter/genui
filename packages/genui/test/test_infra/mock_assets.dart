// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configures a mock handler for the 'flutter/assets' channel to load assets
/// directly from the local file system.
///
/// This is necessary because PromptBuilder loads schemas from assets,
/// and Flutter tests do not load package assets automatically.
/// It automatically handles running from the package root or example directory.
void setUpMockPackageAssets() {
  final String cwd = Directory.current.path;
  String packageRoot;
  if (cwd.endsWith('packages/genui')) {
    packageRoot = cwd;
  } else if (cwd.contains('examples/')) {
    packageRoot = '${cwd.substring(0, cwd.indexOf('examples/'))}packages/genui';
  } else {
    packageRoot = '$cwd/packages/genui';
  }

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final String key = utf8.decode(message!.buffer.asUint8List());
        var relativePath = key;
        if (key.startsWith('packages/genui/')) {
          relativePath = key.substring('packages/genui/'.length);
        }
        final file = File('$packageRoot/$relativePath');
        if (file.existsSync()) {
          return ByteData.view(utf8.encode(file.readAsStringSync()).buffer);
        }
        return null;
      });
}
