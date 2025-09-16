import 'dart:io';

import 'package:flutter/foundation.dart';

class GCliProcess {
  final ValueNotifier<String> status;
  GCliProcess(this.status);

  void _updateStatus(String update) {
    status.value += '\n$update';
  }

  Future<void> run() async {
    final result = await Process.run('echo', ['Hello, World!']);

    if (result.exitCode == 0) {
      _updateStatus('Command executed successfully.');
      _updateStatus('Output:\n${result.stdout}');
    } else {
      _updateStatus('Command failed with exit code ${result.exitCode}');
      _updateStatus('Error:\n${result.stderr}');
    }
  }
}
