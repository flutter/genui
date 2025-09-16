import 'dart:io';

import 'package:flutter/foundation.dart';

class GCliProcess {
  final ValueNotifier<String> status;
  ProcessResult? _process;

  GCliProcess(this.status);

  void _updateStatus(String update) {
    status.value += '\n$update';
  }

  Future<void> run() async {
    final process = _process = await Process.run('gemini', [
      'hello',
    ], runInShell: true);

    if (process.exitCode == 0) {
      _updateStatus('Command executed successfully.');
      _updateStatus('Output:\n${process.stdout}');
    } else {
      _updateStatus('Command failed with exit code ${process.exitCode}');
      _updateStatus('Error:\n${process.stderr}');
    }
  }
}
