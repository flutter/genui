import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';

class GCliProcess {
  final ValueNotifier<String> status;
  Process? _process;

  GCliProcess(this.status);

  void _updateStatus(String update) {
    status.value += '\n$update';
  }

  Future<void> run() async {
    try {
      final process = _process = await Process.start(
        'gemini',
        [],
        runInShell: true,
      );

      _updateStatus('pid: ${process.pid}');

      // Read output from the tool
      process.stdout.listen((event) {
        _updateStatus('Stdout: ${event.toString()}');
      });

      // Handle potential errors from the tool
      process.stderr.listen((event) {
        _updateStatus('Stderr: ${event.toString()}');
      });

      // Write input to the tool
      process.stdin.writeln('some command');

      final code = await process.exitCode;

      _updateStatus('Process exited with code $code');
    } catch (e) {
      _updateStatus('Failed to start process: $e');
    }
  }
}
