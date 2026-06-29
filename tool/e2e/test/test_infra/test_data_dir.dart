// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Returns the data directory for the currently running test.
///
/// The directory is named after the test file (without its `.dart` extension)
/// and lives next to it. For example, a test defined in
/// `test/veo_chat/generate_video_test.dart` produces the directory
/// `test/veo_chat/generate_video_test/`. The directory is created if it does
/// not already exist.
Directory currentTestDataDir() {
  final String testFile = _currentTestFilePath();
  final file = File(testFile);
  final String fileName = file.uri.pathSegments.last;
  final String name = fileName.endsWith('.dart')
      ? fileName.substring(0, fileName.length - '.dart'.length)
      : fileName;
  return Directory('${file.parent.path}/$name')..createSync(recursive: true);
}

/// Walks the current stack trace to find the path of the running
/// `*_test.dart` file.
String _currentTestFilePath() {
  final framePattern = RegExp(r'\((file://.*?\.dart):\d+:\d+\)');
  final List<String> frames = StackTrace.current.toString().split('\n');
  for (final line in frames) {
    final Match? match = framePattern.firstMatch(line);
    if (match == null) continue;
    final String path = Uri.parse(match.group(1)!).toFilePath();
    if (path.endsWith('_test.dart')) return path;
  }
  throw StateError(
    'Could not determine the current test file from the stack trace. '
    'currentTestDataDir() must be called from within a *_test.dart file.',
  );
}
