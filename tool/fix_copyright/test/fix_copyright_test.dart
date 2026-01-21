// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:file/src/interface/file.dart';
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

  void mockGitLsFiles({List<String> paths = const [], required String stdout}) {
    processManager.mockCommands.add(
      MockCommand(command: ['git', 'ls-files', ...paths], stdout: stdout),
    );
  }

  setUp(() {
    fileSystem = MemoryFileSystem();
    log = <String>[];
    error = <String>[];
    processManager = FakeProcessManager();
    processManager.mockCommands = [
      MockCommand(
        command: ['git', 'rev-parse', '--show-toplevel'],
        stdout: '/',
      ),
    ];
  });

  Future<int> runFixCopyrights({
    List<String> paths = const <String>[],
    bool force = false,
    String year = year,
  }) async {
    return fixCopyrights(
      fileSystem,
      force: force,
      year: year,
      paths: paths,
      processManager: processManager,
      log: log.add,
      error: error.add,
    );
  }

  test('updates a file with an incorrect date', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright());
    final int result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals(getBadCopyright()));
  });

  test('updates a file with an incorrect date when forced', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright());
    final int result = await runFixCopyrights(
      paths: ['test.dart'],
      force: true,
    );
    expect(result, equals(0));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates a file with a non-matching copyright', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(wrongCopyright);
    final int result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals(wrongCopyright));
  });

  test('updates a file with a non-matching copyright when forced', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(wrongCopyright);
    final int result = await runFixCopyrights(
      paths: ['test.dart'],
      force: true,
    );
    expect(result, equals(0));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates a file with no copyright', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(randomPreamble);
    final int result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(1));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals(randomPreamble));
  });

  test('updates a file with no copyright when forced', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(randomPreamble);
    final int result = await runFixCopyrights(
      paths: ['test.dart'],
      force: true,
    );
    expect(result, equals(0));
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
    mockGitLsFiles(paths: ['test.sh'], stdout: 'test.sh');
    final File testFile = fileSystem.file('test.sh')
      ..writeAsStringSync(
        '$bashShebang\n${getBadCopyright(prefix: '#')}\n$randomShellPreamble',
      );
    final int result = await runFixCopyrights(paths: ['test.sh'], force: true);
    expect(result, equals(0));
    expect(log, equals(['/test.sh']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    final String shCopyright = copyright.replaceAll('//', '#');
    expect(
      testFile.readAsStringSync(),
      equals('$bashShebang\n$shCopyright\n\n$randomShellPreamble'),
    );
  });

  test('updates a file with an unrecognized shebang', () async {
    mockGitLsFiles(paths: ['test.sh'], stdout: 'test.sh');
    final File testFile = fileSystem.file('test.sh')
      ..writeAsStringSync(
        '$badShebang\n${getBadCopyright(prefix: "#")}\n$randomPreamble',
      );
    final int result = await runFixCopyrights(paths: ['test.sh'], force: true);
    expect(result, equals(0));
    expect(log, equals(['/test.sh']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    final String shCopyright = copyright.replaceAll('//', '#');
    expect(
      testFile.readAsStringSync(),
      equals('$badShebang\n$shCopyright\n\n$randomPreamble'),
    );
  });

  test('does not update a file that is OK', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync('$copyright\n\n$randomPreamble');
    final int result = await runFixCopyrights(paths: ['test.dart']);
    expect(result, equals(0));
    expect(log, isEmpty);
    expect(error, isEmpty);
    expect(
      testFile.readAsStringSync(),
      equals('$copyright\n\n$randomPreamble'),
    );
  });

  test('updates a directory of files', () async {
    mockGitLsFiles(stdout: 'test1.dart\ntest2.dart\ntest3.dart\ntest4.dart');
    final File testFile1 = fileSystem.file('test1.dart')
      ..writeAsStringSync(getBadCopyright());
    final File testFile2 = fileSystem.file('test2.dart')
      ..writeAsStringSync(wrongCopyright);
    final File testFile3 = fileSystem.file('test3.dart')
      ..writeAsStringSync(randomPreamble);
    final File testFile4 = fileSystem.file('test4.dart')
      ..writeAsStringSync('$copyright\n\n$randomPreamble');
    final int result = await runFixCopyrights(force: true);
    expect(result, equals(0));
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
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')..writeAsStringSync('');
    final int result = await runFixCopyrights(
      paths: ['test.dart'],
      force: true,
    );
    expect(result, equals(0));
    expect(log, isEmpty);
    expect(error, isEmpty);
    expect(testFile.readAsStringSync(), isEmpty);
  });

  test('updates a file with case-insensitive copyright', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright().toLowerCase());
    final int result = await runFixCopyrights(
      paths: ['test.dart'],
      force: true,
    );
    expect(result, equals(0));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates a file with windows line endings', () async {
    mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
    final File testFile = fileSystem.file('test.dart')
      ..writeAsStringSync(getBadCopyright().replaceAll('\n', '\r\n'));
    final int result = await runFixCopyrights(
      paths: ['test.dart'],
      force: true,
    );
    expect(result, equals(0));
    expect(log, equals(['/test.dart']));
    expect(
      error,
      contains('Found 1 files which have out-of-compliance copyrights.'),
    );
    expect(testFile.readAsStringSync(), equals('$copyright\n\n'));
  });

  test('updates an xml file', () async {
    mockGitLsFiles(paths: ['test.xml'], stdout: 'test.xml');
    const xmlPreamble = '<?xml version="1.0" encoding="utf-8"?>\n<root/>';
    const xmlCopyright = '''
<!-- Copyright 2025 The Flutter Authors.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file. -->''';
    final File testFile = fileSystem.file('test.xml')
      ..writeAsStringSync(xmlPreamble);
    final int result = await runFixCopyrights(paths: ['test.xml'], force: true);
    expect(result, equals(0));
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

  test(
    'ignores a file with a generated code header but no copyright',
    () async {
      mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
      final File testFile = fileSystem.file('test.dart')
        ..writeAsStringSync('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
      final int result = await runFixCopyrights(paths: ['test.dart']);
      expect(result, equals(0));
      expect(log, isEmpty);
      expect(error, isEmpty);
      expect(
        testFile.readAsStringSync(),
        '// GENERATED CODE - DO NOT MODIFY BY HAND\n',
      );
    },
  );

  test(
    'ignores a file with a generated code header but no copyright when forced',
    () async {
      mockGitLsFiles(paths: ['test.dart'], stdout: 'test.dart');
      final File testFile = fileSystem.file('test.dart')
        ..writeAsStringSync('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
      final int result = await runFixCopyrights(
        paths: ['test.dart'],
        force: true,
      );
      expect(result, equals(0));
      expect(log, isEmpty);
      expect(error, isEmpty);
      expect(
        testFile.readAsStringSync(),
        equals('// GENERATED CODE - DO NOT MODIFY BY HAND\n'),
      );
    },
  );
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
  bool canRun(Object? executable, {String? workingDirectory}) => true;

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  Future<ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    commands.add(command.cast<String>());
    final MockCommand mock = mockCommands.firstWhere(
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
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    commands.add(command.cast<String>());
    final MockCommand mock = mockCommands.firstWhere(
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
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    throw UnimplementedError();
  }
}
