// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_and_fix/test_and_fix.dart';

void main() {
  group('findProjects', () {
    late MemoryFileSystem fs;
    late Directory root;
    late TestAndFix testAndFix;

    setUp(() {
      fs = MemoryFileSystem();
      root = fs.directory('root')..createSync();
      testAndFix = TestAndFix(fs: fs);
    });

    test('finds Flutter projects', () async {
      final project1 = fs.directory(path.join(root.path, 'project1'))
        ..createSync();
      fs
          .file(path.join(project1.path, 'pubspec.yaml'))
          .writeAsStringSync('sdk: flutter');
      final project2 = fs.directory(path.join(root.path, 'project2'))
        ..createSync();
      fs
          .file(path.join(project2.path, 'pubspec.yaml'))
          .writeAsStringSync('sdk: flutter');

      final projects = await testAndFix.findProjects(root);

      expect(
        projects.map((d) => d.path).toList()..sort(),
        [path.join('root', 'project1'), path.join('root', 'project2')]..sort(),
      );
    });

    test('ignores excluded directories', () async {
      final excluded = [
        '.dart_tool',
        'build',
        'ephemeral',
        'firebase_core',
        'packages/spikes',
        'tool/fix_copyright',
        'tool/test_and_fix',
      ];

      for (final exclude in excluded) {
        final project = fs.directory(path.join(root.path, exclude))
          ..createSync(recursive: true);
        fs
            .file(path.join(project.path, 'pubspec.yaml'))
            .writeAsStringSync('sdk: flutter');
      }

      final projects = await testAndFix.findProjects(root);

      expect(projects, isEmpty);
    });

    test('ignores some excluded directories with --all', () async {
      final excluded = ['.dart_tool', 'ephemeral', 'firebase_core', 'build'];

      for (final exclude in excluded) {
        final project = fs.directory(path.join(root.path, exclude))
          ..createSync(recursive: true);
        fs
            .file(path.join(project.path, 'pubspec.yaml'))
            .writeAsStringSync('sdk: flutter');
      }

      final projects = await testAndFix.findProjects(root, all: true);

      expect(projects, isEmpty);
    });
  });
}
