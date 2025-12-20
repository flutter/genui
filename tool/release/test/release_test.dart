// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/release.dart' as app;

void main() {
  group('release.dart CLI', () {
    late InMemoryIOSink stdout;
    late InMemoryIOSink stderr;

    setUp(() {
      stdout = InMemoryIOSink();
      stderr = InMemoryIOSink();
    });

    test('--help prints usage to stdout', () async {
      final int exitCode = await app.run(
        ['--help'],
        stdout: stdout,
        stderr: stderr,
      );
      expect(exitCode, 0, reason: 'Exit code should be 0');
      expect(
        stdout.toString(),
        contains('Usage: dart run tool/release/bin/release.dart'),
        reason: 'Stdout should contain usage',
      );
      expect(
        stdout.toString(),
        contains('Print this usage information.'),
        reason: 'Stdout should contain help description',
      );
      expect(stderr.toString(), isEmpty, reason: 'Stderr should be empty');
    });

    test('help command prints usage to stdout', () async {
      final int exitCode = await app.run(
        ['help'],
        stdout: stdout,
        stderr: stderr,
      );
      expect(exitCode, 0);
      expect(
        stdout.toString(),
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
      expect(stderr.toString(), isEmpty);
    });

    test('no arguments prints usage to stderr and exits with 1', () async {
      final int exitCode = await app.run([], stdout: stdout, stderr: stderr);
      expect(exitCode, 1);
      expect(
        stderr.toString(),
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
      expect(stdout.toString(), isEmpty);
    });

    test('unknown command prints usage to stderr and exits with 1', () async {
      final int exitCode = await app.run(
        ['unknown'],
        stdout: stdout,
        stderr: stderr,
      );
      expect(exitCode, 1);
      expect(
        stderr.toString(),
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
    });

    test('help unknown_command prints error to stderr', () async {
      final int exitCode = await app.run(
        ['help', 'unknown'],
        stdout: stdout,
        stderr: stderr,
      );
      expect(exitCode, 1);
      expect(stderr.toString(), contains('Unknown command: unknown'));
      expect(
        stderr.toString(),
        contains('Usage: dart run tool/release/bin/release.dart'),
      );
    });
  });
}

class InMemoryIOSink implements IOSink {
  final StringBuffer _buffer = StringBuffer();
  final Completer<void> _doneCompleter = Completer<void>();

  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) {
    _buffer.write(encoding.decode(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _buffer.writeln('Error: $error');
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      add(chunk);
    }
  }

  @override
  Future<void> close() async {
    _doneCompleter.complete();
  }

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  Future<void> flush() async {}

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    _buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
  }

  @override
  void writeln([Object? object = '']) {
    _buffer.writeln(object);
  }

  @override
  String toString() => _buffer.toString();
}
