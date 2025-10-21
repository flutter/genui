// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:process_runner/test/fake_process_manager.dart';
import 'package:test/test.dart';
import 'package:test_and_fix/test_and_fix.dart';

void main() {
  group('TestAndFix', () {
    late MemoryFileSystem fs;
    late FakeProcessManager processManager;
    late TestAndFix testAndFix;

    setUp(() {
      fs = MemoryFileSystem();
      processManager = FakeProcessManager((input) {
        print('Stdin supplied: $input');
      });
      testAndFix = TestAndFix(fs: fs, processManager: processManager);
    });

    test('handles no projects found', () async {
      final root = fs.directory('test_root').absolute..createSync();
      processManager.fakeResults = {
        FakeInvocationRecord(const [
          'dart',
          'fix',
          '--apply',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'format',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'run',
          'tool/fix_copyright/bin/fix_copyright.dart',
          '--force',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };
      await testAndFix.run(root: root);
      final commands = processManager.invocations
          .map((e) => e.invocation)
          .toList();
      expect(commands, hasLength(3));
      expect(
        commands,
        contains(orderedEquals(const ['dart', 'fix', '--apply', '.'])),
      );
      expect(commands, contains(orderedEquals(const ['dart', 'format', '.'])));
      expect(
        commands,
        contains(
          orderedEquals(const [
            'dart',
            'run',
            'tool/fix_copyright/bin/fix_copyright.dart',
            '--force',
          ]),
        ),
      );
    });

    test('creates jobs for a single project', () async {
      final root = fs.directory('test_root').absolute..createSync();
      final project = root.childDirectory('project')..createSync();
      project.childFile('pubspec.yaml').writeAsStringSync('sdk: flutter');
      project.childDirectory('test').createSync();

      processManager.fakeResults = {
        FakeInvocationRecord(const [
          'dart',
          'fix',
          '--apply',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'format',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'run',
          'tool/fix_copyright/bin/fix_copyright.dart',
          '--force',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'analyze',
        ], workingDirectory: project.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'flutter',
          'test',
        ], workingDirectory: project.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await testAndFix.run(root: root);

      expect(processManager.invocations, hasLength(5));
    });

    test('disallowed projects are not skipped with --all', () async {
      final root = fs.directory('test_root').absolute..createSync();
      final project =
          root
              .childDirectory('packages')
              .childDirectory('spikes')
              .childDirectory('project')
            ..createSync(recursive: true);
      project.childFile('pubspec.yaml').writeAsStringSync('sdk: flutter');
      project.childDirectory('test').createSync();

      processManager.fakeResults = {
        FakeInvocationRecord(const [
          'dart',
          'fix',
          '--apply',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'format',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'run',
          'tool/fix_copyright/bin/fix_copyright.dart',
          '--force',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'analyze',
        ], workingDirectory: project.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'flutter',
          'test',
        ], workingDirectory: project.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await testAndFix.run(root: root, all: true);
      expect(processManager.invocations, hasLength(5));

      processManager.invocations.clear();
      processManager.fakeResults = {
        FakeInvocationRecord(const [
          'dart',
          'fix',
          '--apply',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'format',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'run',
          'tool/fix_copyright/bin/fix_copyright.dart',
          '--force',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await testAndFix.run(root: root, all: false);
      expect(processManager.invocations, hasLength(3));
    });

    test('handles command failure', () async {
      final root = fs.directory('test_root').absolute..createSync();
      processManager.fakeResults = {
        FakeInvocationRecord(const [
          'dart',
          'fix',
          '--apply',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 1, '', 'error'),
        ],
        FakeInvocationRecord(const [
          'dart',
          'format',
          '.',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const [
          'dart',
          'run',
          'tool/fix_copyright/bin/fix_copyright.dart',
          '--force',
        ], workingDirectory: root.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };
      final printOutput = <String>[];
      await runZoned(
        () async {
          await testAndFix.run(root: root);
        },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String message) {
            printOutput.add(message);
          },
        ),
      );

      expect(printOutput, contains('\n--- Failed Jobs ---'));
      expect(
        printOutput.any((line) => line.contains('dart fix (exit code 1)')),
        isTrue,
      );
    });
  });
}
