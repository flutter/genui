// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Fixes the copyright headers on various file types to conform with the Flutter
// repo copyright header. This is especially useful when updating platform
// runners that don't contain copyrights when generated.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:fix_copyright/src/fix_copyright.dart';
import 'package:path/path.dart' as path;

Future<int> main(List<String> arguments) async {
  // This is the real main entrypoint. It's separated from the logic so that
  // the logic can be tested with a memory file system.
  const fileSystem = LocalFileSystem();
  int width;
  try {
    width = stdout.terminalColumns;
  } on StdoutException {
    width = 80;
  }
  final argParser = ArgParser(usageLineLength: width);
  argParser.addFlag(
    'force',
    negatable: false,
    help:
        'Overwrite original file with updated output. Without this flag, '
        'this program will only list the files that need to be updated and '
        'exit with a non-zero exit code.',
  );
  argParser.addOption(
    'year',
    defaultsTo: '2025',
    help: 'Set the year to use for the copyright year.',
  );
  argParser.addFlag(
    'help',
    negatable: false,
    help: 'Print help for this command.',
  );

  void usage() {
    stderr.writeln(
      'dart ${path.basename(Platform.executable)} [--force] '
      '[<file-or-directory1> <file-or-directory2> ...] ',
    );
    stderr.writeln(argParser.usage);
  }

  final ArgResults parsedArguments;
  try {
    parsedArguments = argParser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    usage();
    exit(1);
  }

  if (parsedArguments['help'] as bool) {
    usage();
    exit(0);
  }

  final exitCode = await fixCopyrights(
    fileSystem,
    force: parsedArguments['force'] as bool,
    year: parsedArguments['year']! as String,
    paths: parsedArguments.rest,
  );
  exit(exitCode);
}
