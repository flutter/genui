import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';

class GCliProcess {
  final ValueChanged<String> update;

  GCliProcess(this.update);

  Future<void> ask(String question) async {
    try {
      final process = await Process.start(
        includeParentEnvironment: true,
        mode: ProcessStartMode.normal,
        runInShell: true,
        'gemini',
        [question, '--prompt-interactive'],
      );

      update('pid: ${process.pid}');

      // Read output from the tool
      _subscribe(process.stdout, (message) {
        update('Stdout: $message');
      });

      // Handle errors from the tool
      _subscribe(process.stderr, (message) {
        update('Stderr: $message');
      });

      // Write input to the tool
      // process.stdin.writeln('some command');

      final code = await process.exitCode;

      update('Process exited with code $code');
    } catch (e) {
      update('Failed to start process: $e');
    }
  }

  static void _subscribe(
    Stream<List<int>> stream,
    void Function(String) onMessage,
  ) {
    stream
        .transform(utf8.decoder) // Decode bytes to UTF-8 strings
        .transform(const LineSplitter()) // Split the string stream into lines
        .listen(onMessage);
  }
}
