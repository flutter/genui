// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('release.dart CLI', () {
    late String releaseScript;

    setUp(() {
      // Find the release.dart script relative to the current working directory.
      // This supports running tests from the monorepo root or the package root.
      final List<String> relativePaths = [
        path.join('tool', 'release', 'bin', 'release.dart'),
        path.join('bin', 'release.dart'),
      ];

      var found = false;
      for (final relativePath in relativePaths) {
        final script = File(path.join(Directory.current.path, relativePath));
        if (script.existsSync()) {
          releaseScript = script.path;
          found = true;
          break;
        }
      }

      if (!found) {
        throw StateError(
          'Could not find release.dart script. '
          'Checked: ${relativePaths.join(', ')} from ${Directory.current.path}',
        );
      }
    });

    test('--help prints usage to stdout', () async {
      final ProcessResult result = await Process.run(Platform.executable, [
        'run',
        releaseScript,
        '--help',
      ]);
      expect(result.exitCode, 0, reason: 'Exit code should be 0');
      expect(
        result.stdout,
        contains('Usage: dart run tool/release/bin/release.dart'),
        reason: 'Stdout should contain usage',
      );
      expect(
        result.stdout,
        contains('Print this usage information.'),
        reason: 'Stdout should contain help description',
      );
      expect(result.stderr, isEmpty, reason: 'Stderr should be empty');
    });

    test('help command prints usage to stdout', () async {
      final ProcessResult result = await Process.run(Platform.executable, [
        'run',
        releaseScript,
        'help',
      ]);
      expect(result.exitCode, 0);
      expect(
        result.stdout,
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
      expect(result.stderr, isEmpty);
    });

    test('no arguments prints usage to stderr and exits with 1', () async {
      final ProcessResult result = await Process.run(Platform.executable, [
        'run',
        releaseScript,
      ]);
      expect(result.exitCode, 1);
      expect(
        result.stderr,
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
      expect(result.stdout, isEmpty);
    });

    test('unknown command prints usage to stderr and exits with 1', () async {
      final ProcessResult result = await Process.run(Platform.executable, [
        'run',
        releaseScript,
        'unknown',
      ]);
      expect(result.exitCode, 1);
      expect(
        result.stderr,
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
    });

    test('help unknown_command prints error to stderr', () async {
      final ProcessResult result = await Process.run(Platform.executable, [
        'run',
        releaseScript,
        'help',
        'unknown',
      ]);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Unknown command: unknown'));
      expect(
        result.stderr,
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
    });
  });
}
