// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:fix_copyright/fix_copyright.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

void main() {
  const year = '2025';
  const copyright =
      '''
// Copyright $year The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.''';
  String getBadCopyright({String prefix = '//'}) =>
      '''
$prefix Copyright 2019 The Flutter Authors. All rights reserved.
$prefix Use of this source code is governed by a BSD-style license that can be
$prefix found in the LICENSE file.''';
  const wrongCopyright = '''
// Copyright 1992 The Other Authors. All rights reserved.
// Use of this source code is governed by a different license that can be
// found in the LICENSE file.''';
  const randomPreamble = '''
// A random preamble.

// More random preamble.''';
  const randomShellPreamble = '''
# A random preamble.

# More random preamble.''';
  const bashShebang = '#!/usr/bin/env bash';
  const badShebang = '#!/usr/bin/env ruby';

  late MemoryFileSystem fileSystem;
  late List<String> log;
  late List<String> error;
  late FakeProcessManager processManager;

  setUp(() {
    fileSystem = MemoryFileSystem();
    log = <String>[];
    error = <String>[];
    processManager = FakeProcessManager();
    processManager.mockCommands = [
      MockCommand(
        command: ['git', 'rev-parse', '--show-toplevel'],
        exitCode: 128,
      ),
    ];
  });

  Future<int> runFixCopyrights({
    List<String> paths = const <String>[],
    bool force = false,
    bool skipSubmodules = true,
    String year = year,
  }) async {
    return fixCopyrights(
      fileSystem,
      force: force,
      year: year,
      paths: paths,
      skipSubmodules: skipSubmodules,
      processManager: processManager,
      log: log.add,
      error: error.add,
    );
  }

  test('updates a file with an incorrect date', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright());
    final result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals(getBadCopyright()));
  });

  test('updates a file with an incorrect date when forced', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright());
    final result = await runFixCopyrights(paths: ['test.dart'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates a file with a non-matching copyright', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(wrongCopyright);
    final result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals(wrongCopyright));
  });

  test('updates a file with a non-matching copyright when forced', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(wrongCopyright);
    final result = await runFixCopyrights(paths: ['test.dart'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates a file with no copyright', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(randomPreamble);
    final result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals(randomPreamble));
  });

  test('updates a file with no copyright when forced', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(randomPreamble);
    final result = await runFixCopyrights(paths: ['test.dart'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(
      testFile.readAsStringSync(),
      equals('$copyright\n\n$randomPreamble'),
    );
  });

  test('updates a shell script with a shebang and bad copyright', () async {
    final testFile = fileSystem.file('test.sh')
      ..writeAsStringSync(
        '$bashShebang\n${getBadCopyright(prefix: '#')}\n$randomShellPreamble',
      );
    final result = await runFixCopyrights(paths: ['test.sh'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.sh']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    final shCopyright = copyright.replaceAll('//', '#');
    expect(
      testFile.readAsStringSync(),
      equals('$bashShebang\n$shCopyright\n\n$randomShellPreamble'),
    );
  });

  test('updates a file with an unrecognized shebang', () async {
    final testFile = fileSystem.file('test.sh')
      ..writeAsStringSync(
        '$badShebang\n${getBadCopyright(prefix: "#")}\n$randomPreamble',
      );
    final result = await runFixCopyrights(paths: ['test.sh'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.sh']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    final shCopyright = copyright.replaceAll('//', '#');
    expect(
      testFile.readAsStringSync(),
      equals('$badShebang\n$shCopyright\n\n$randomPreamble'),
    );
  });

  test('does not update a file that is OK', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync('$copyright\n\n$randomPreamble');
    final result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(0));
    expect(log, isEmpty);
    expect(
      error,
      contains('Warning: not a git repository. Cannot check for submodules.'),
    );
    expect(
      testFile.readAsStringSync(),
      equals('$copyright\n\n$randomPreamble'),
    );
  });

  test('updates a directory of files', () async {
    final testFile1 = fileSystem.file('test1.dart')
      ..writeAsStringSync(getBadCopyright());
    final testFile2 = fileSystem.file('test2.dart')
      ..writeAsStringSync(wrongCopyright);
    final testFile3 = fileSystem.file('test3.dart')
      ..writeAsStringSync(randomPreamble);
    final testFile4 = fileSystem.file('test4.dart')
      ..writeAsStringSync('$copyright\n\n$randomPreamble');
    final result = await runFixCopyrights(force: true);
    expect(result, equals(1));
    expect(log, unorderedEquals(['/test1.dart', '/test2.dart', '/test3.dart']));
    expect(
      error,
      contains('Found 3 files which have out-of-compliance copyrights.'),
    );
    expect(testFile1.readAsStringSync(), equals('$copyright\n\n'));
    expect(testFile2.readAsStringSync(), equals('$copyright\n\n'));
    expect(
      testFile3.readAsStringSync(),
      equals('$copyright\n\n$randomPreamble'),
    );
    expect(
      testFile4.readAsStringSync(),
      equals('$copyright\n\n$randomPreamble'),
    );
  });

  test('does not update an empty file', () async {
    final testFile = fileSystem.file('test.dart')..writeAsStringSync('');
    final result = await runFixCopyrights(paths: ['test.dart'], force: true);
    expect(result, equals(0));
    expect(log, isEmpty);
    expect(
      error,
      contains('Warning: not a git repository. Cannot check for submodules.'),
    );
    expect(testFile.readAsStringSync(), isEmpty);
  });

  test('updates a file with case-insensitive copyright', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright().toLowerCase());
    final result = await runFixCopyrights(paths: ['test.dart'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates a file with windows line endings', () async {
    final testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright().replaceAll('\n', '\r\n'));
    final result = await runFixCopyrights(paths: ['test.dart'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates an xml file', () async {
    const xmlPreamble = '<?xml version="1.0" encoding="utf-8"?>\n<root/>';
    const xmlCopyright = '''
<!-- Copyright 2025 The Flutter Authors.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file. -->''';
    final testFile = fileSystem.file('test.xml')
      ..writeAsStringSync(xmlPreamble);
    final result = await runFixCopyrights(paths: ['test.xml'], force: true);
    expect(result, equals(1));
    expect(log, equals(['/test.xml']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(
      testFile.readAsStringSync(),
      equals(
        '<?xml version="1.0" encoding="utf-8"?>\n$xmlCopyright\n\n<root/>',
      ),
    );
  });

  group('submodule handling', () {
    setUp(() {
      fileSystem.directory('/submodule').createSync();
      fileSystem
          .file('/submodule/test.dart')
          .writeAsStringSync(getBadCopyright());
      fileSystem.file('/test.dart').writeAsStringSync(getBadCopyright());
    });

    test('skips submodules by default', () async {
      processManager.mockCommands = [
        MockCommand(
          command: ['git', 'rev-parse', '--show-toplevel'],
          stdout: '/',
        ),
        MockCommand(
          command: ['git', 'submodule', 'status', '--recursive'],
          stdout:
              ' 1234567890abcdef1234567890abcdef12345678 submodule (v1.2.3)',
        ),
      ];

      final result = await runFixCopyrights(force: true);

      expect(result, equals(1));
      expect(log, contains('/test.dart'));
      expect(log, contains('Skipping submodule: ./submodule'));
      expect(log, isNot(contains('/submodule/test.dart')));
      expect(
        error,
        contains('Found 1 files which have out-of-compliance copyrights.'),
      );
      expect(
        fileSystem.file('/test.dart').readAsStringSync(),
        startsWith(copyright),
      );
      expect(
        fileSystem.file('/submodule/test.dart').readAsStringSync(),
        equals(getBadCopyright()),
      );
      expect(processManager.commands, hasLength(2));
    });

    test('processes submodules when --no-skip-submodules is passed', () async {
      processManager.mockCommands = []; // No git commands should be run.

      final result = await runFixCopyrights(force: true, skipSubmodules: false);

      expect(result, equals(1));
      expect(log, unorderedEquals(['/test.dart', '/submodule/test.dart']));
      expect(
        error,
        contains('Found 2 files which have out-of-compliance copyrights.'),
      );
      expect(
        fileSystem.file('/test.dart').readAsStringSync(),
        startsWith(copyright),
      );
      expect(
        fileSystem.file('/submodule/test.dart').readAsStringSync(),
        startsWith(copyright),
      );
      expect(processManager.commands, isEmpty);
    });

    test('handles non-git repository gracefully', () async {
      processManager.mockCommands = [
        MockCommand(
          command: ['git', 'rev-parse', '--show-toplevel'],
          exitCode: 128,
        ),
      ];

      final result = await runFixCopyrights(force: true);

      expect(result, equals(1));
      expect(log, unorderedEquals(['/test.dart', '/submodule/test.dart']));
      expect(
        error,
        contains('Warning: not a git repository. Cannot check for submodules.'),
      );
      expect(
        error,
        contains('Found 2 files which have out-of-compliance copyrights.'),
      );
      expect(
        fileSystem.file('/test.dart').readAsStringSync(),
        startsWith(copyright),
      );
      expect(
        fileSystem.file('/submodule/test.dart').readAsStringSync(),
        startsWith(copyright),
      );
      expect(processManager.commands, hasLength(1));
    });

    test('handles git submodule status failure gracefully', () async {
      processManager.mockCommands = [
        MockCommand(
          command: ['git', 'rev-parse', '--show-toplevel'],
          stdout: '/',
        ),
        MockCommand(
          command: ['git', 'submodule', 'status', '--recursive'],
          exitCode: 1,
        ),
      ];

      final result = await runFixCopyrights(force: true);

      expect(result, equals(1));
      expect(log, unorderedEquals(['/test.dart', '/submodule/test.dart']));
      expect(
        error,
        contains(
          'Warning: could not get submodule status. Not skipping any '
          'submodules.',
        ),
      );
      expect(
        error,
        contains('Found 2 files which have out-of-compliance copyrights.'),
      );
      expect(
        fileSystem.file('/test.dart').readAsStringSync(),
        startsWith(copyright),
      );
      expect(
        fileSystem.file('/submodule/test.dart').readAsStringSync(),
        startsWith(copyright),
      );
      expect(processManager.commands, hasLength(2));
    });
  });
}

class MockCommand {
  MockCommand({
    required this.command,
    this.stdout = '',
    this.stderr = '',
    this.exitCode = 0,
    this.exception,
  });

  final List<String> command;
  final String stdout;
  final String stderr;
  final int exitCode;
  final Exception? exception;
}

class FakeProcessManager implements ProcessManager {
  List<MockCommand> mockCommands = [];
  final List<List<String>> commands = [];

  @override
  bool canRun(dynamic executable, {String? workingDirectory}) => true;

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  Future<ProcessResult> run(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    commands.add(command.cast<String>());
    final mock = mockCommands.firstWhere(
      (mock) => mock.command.join(' ') == command.join(' '),
      orElse: () => MockCommand(command: command.cast<String>(), exitCode: 1),
    );

    if (mock.exception != null) {
      throw mock.exception!;
    }

    return Future.value(
      ProcessResult(1, mock.exitCode, mock.stdout, mock.stderr),
    );
  }

  @override
  ProcessResult runSync(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    commands.add(command.cast<String>());
    final mock = mockCommands.firstWhere(
      (mock) => mock.command.join(' ') == command.join(' '),
      orElse: () => MockCommand(command: command.cast<String>(), exitCode: 1),
    );

    if (mock.exception != null) {
      throw mock.exception!;
    }

    return ProcessResult(1, mock.exitCode, mock.stdout, mock.stderr);
  }

  @override
  Future<Process> start(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    throw UnimplementedError();
  }
}
