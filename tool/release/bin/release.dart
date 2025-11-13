// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process_runner/process_runner.dart';
import 'package:release/release.dart';
import 'package:release/src/exceptions.dart';

void main(List<String> arguments) async {
  final parser = ArgParser();

  final bumpParser = ArgParser()
    ..addOption(
      'level',
      abbr: 'l',
      allowed: ['breaking', 'major', 'minor', 'patch'],
      help: 'The level to bump the version by.',
      mandatory: true,
    );
  parser.addCommand('bump', bumpParser);

  final publishParser = ArgParser()
    ..addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Actually publish packages and create tags.',
    );
  parser.addCommand('publish', publishParser);

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(
      'Usage: dart run tool/release/bin/release.dart <command> [options]',
    );
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (argResults.command == null) {
    stderr.writeln(
      'Usage: dart run tool/release/bin/release.dart <command> [options]',
    );
    stderr.writeln(parser.usage);
    exit(1);
  }

  final fileSystem = const LocalFileSystem();
  final processRunner = ProcessRunner();

  // Find the repo root, assuming the script is in <repo_root>/tool/release/bin
  final File scriptFile = fileSystem.file(Platform.script.toFilePath());
  final Directory repoDir = scriptFile.parent.parent.parent.parent;
  final tool = ReleaseTool(
    fileSystem: fileSystem,
    processRunner: processRunner,
    repoRoot: repoDir,
    stdinReader: stdin.readLineSync,
  );

  final ArgResults command = argResults.command!;
  try {
    switch (command.name) {
      case 'bump':
        await tool.bump(command['level'] as String);
        break;
      case 'publish':
        await tool.publish(force: command['force'] as bool);
        break;
    }
  } on ReleaseException catch (e) {
    stderr.writeln(e);
    exit(1);
  }
}
