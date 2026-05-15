// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:test_and_fix/test_and_fix.dart';

Future<int> main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln(record.message);
  });

  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Prints this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help:
          'Prints all output from the commands. If not specified, only outputs '
          'failed commands.',
    )
    ..addFlag(
      'all',
      negatable: false,
      help:
          'Runs tests and analysis on all projects, including those usually '
          'skipped.',
    )
    ..addFlag(
      'coverage',
      abbr: 'c',
      negatable: false,
      help:
          'Runs tests with coverage and verifies against thresholds and '
          'baseline.',
    )
    ..addFlag(
      'update-baseline',
      abbr: 'u',
      negatable: false,
      help: 'Updates the coverage baseline file with current high-water marks.',
    );

  final ArgResults argResults = parser.parse(arguments);

  if (argResults['help'] as bool) {
    stdout.writeln(parser.usage);
    return 0;
  }

  final bool success = await TestAndFix().run(
    verbose: argResults['verbose'] as bool,
    all: argResults['all'] as bool,
    coverage: argResults['coverage'] as bool,
    updateBaseline: argResults['update-baseline'] as bool,
  );
  exitCode = success ? 0 : 1;
  return success ? 0 : 1;
}
