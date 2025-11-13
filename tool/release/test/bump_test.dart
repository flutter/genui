// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/memory.dart';
import 'package:file/src/interface/directory.dart';
import 'package:process_runner/process_runner.dart';
import 'package:process_runner/test/fake_process_manager.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  group('BumpCommand', () {
    late MemoryFileSystem fileSystem;
    late FakeProcessManager processManager;
    late ReleaseTool releaseTool;
    late Directory repoRoot;
    late Directory packageADir;

    setUp(() {
      fileSystem = MemoryFileSystem();
      repoRoot = fileSystem.systemTempDirectory.createTempSync('genui_repo');
      processManager = FakeProcessManager((input) {}); // Stdin callback
      releaseTool = ReleaseTool(
        fileSystem: fileSystem,
        processRunner: ProcessRunner(processManager: processManager),
        repoRoot: repoRoot,
        stdinReader: () => null, // Not used in bump tests
        printer: (_) {},
      );

      final Directory packagesDir = repoRoot.childDirectory('packages');
      packagesDir.createSync(recursive: true);

      packageADir = packagesDir.childDirectory('package_a');
      packageADir.createSync();
      packageADir.childFile('pubspec.yaml').writeAsStringSync('''
name: package_a
version: 1.0.0
''');
      packageADir.childFile('CHANGELOG.md').writeAsStringSync('''
## 1.0.0

- Initial release.
''');

      final Directory excludedPackage = packagesDir.childDirectory(
        'json_schema_builder',
      );
      excludedPackage.createSync();
      excludedPackage.childFile('pubspec.yaml').writeAsStringSync('''
name: json_schema_builder
version: 0.1.0
''');
    });

    test('should bump patch version and update CHANGELOG', () async {
      packageADir.childFile('CHANGELOG.md').writeAsStringSync('''
# `package_a` Changelog

## 1.0.1 (in progress)

- Work in progress.

## 1.0.0

- Initial release.
''');
      processManager.fakeResults = {
        FakeInvocationRecord(const [
          'dart',
          'pub',
          'bump',
          'patch',
        ], workingDirectory: packageADir.path): [
          () {
            packageADir.childFile('pubspec.yaml').writeAsStringSync('''
name: package_a
version: 1.0.1
''');
            return ProcessResult(0, 0, '', '');
          }(),
        ],
        FakeInvocationRecord(const [
          'dart',
          'pub',
          'upgrade',
          '--major-versions',
        ], workingDirectory: repoRoot.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await releaseTool.bump('patch');

      final String pubspecContent = packageADir
          .childFile('pubspec.yaml')
          .readAsStringSync();
      expect(pubspecContent, contains('version: 1.0.1'));

      final String changelogContent = packageADir
          .childFile('CHANGELOG.md')
          .readAsStringSync();
      expect(
        changelogContent,
        startsWith(
          '# `package_a` Changelog\n\n## 1.0.1\n\n- Work in progress.',
        ),
      );
    });
  });
}
