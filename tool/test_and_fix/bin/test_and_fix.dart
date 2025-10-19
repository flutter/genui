// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:test_and_fix/test_and_fix.dart';

Future<int> main(List<String> arguments) async {
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
    );

  final argResults = parser.parse(arguments);

  if (argResults['help'] as bool) {
    print(parser.usage);
    return 0;
  }

  final success = await TestAndFix().run(
    verbose: argResults['verbose'] as bool,
    all: argResults['all'] as bool,
  );
  return success ? 0 : 1;
}
