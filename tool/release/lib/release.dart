// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:process_runner/process_runner.dart';

import 'src/bump.dart';
import 'src/publish.dart';
import 'src/utils.dart';

export 'src/bump.dart';
export 'src/publish.dart';

class ReleaseTool {
  final FileSystem fileSystem;
  final ProcessRunner processRunner;
  final Directory repoRoot;

  late final BumpCommand _bumpCommand;
  late final PublishCommand _publishCommand;

  ReleaseTool({
    required this.fileSystem,
    required this.processRunner,
    required this.repoRoot,
    required StdinReader stdinReader,
    Printer? printer,
  }) {
    final Printer print =
        printer ?? ((String message) => stdout.writeln(message));
    _bumpCommand = BumpCommand(
      fileSystem: fileSystem,
      processRunner: processRunner,
      repoRoot: repoRoot,
      printer: print,
    );
    _publishCommand = PublishCommand(
      fileSystem: fileSystem,
      processRunner: processRunner,
      repoRoot: repoRoot,
      stdinReader: stdinReader,
      printer: print,
    );
  }

  Future<void> bump(String bumpLevel) => _bumpCommand.run(bumpLevel);

  Future<void> publish({required bool force}) =>
      _publishCommand.run(force: force);
}
