// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:io' show IOSink, Platform, exit;

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process_runner/process_runner.dart';
import 'package:release/release.dart';
import 'package:release/src/exceptions.dart';

Future<void> main(List<String> arguments) async {
  exit(await run(arguments));
}

Future<int> run(
  List<String> arguments, {
  IOSink? stdout,
  IOSink? stderr,
}) async {
  final IOSink actualStdout = stdout ?? io.stdout;
  final IOSink actualStderr = stderr ?? io.stderr;
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    );

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
  parser.addCommand('help');

  void printUsage({IOSink? sink}) {
    final IOSink actualSink = sink ?? actualStdout;
    actualSink.writeln(
      'Usage: dart run tool/release/bin/release.dart <command> [options]',
    );
    actualSink.writeln(parser.usage);
  }

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    actualStderr.writeln(e.message);
    printUsage(sink: actualStderr);
    return 1;
  }

  if (argResults['help'] as bool) {
    printUsage();
    return 0;
  }

  if (argResults.command == null) {
    printUsage(sink: actualStderr);
    return 1;
  }

  final fileSystem = const LocalFileSystem();
  final processRunner = ProcessRunner();

  // Find the repo root, assuming the script is in <repo_root>/tool/release/bin
  final File scriptFile = fileSystem.file(Platform.script.toFilePath());
  Directory repoDir = scriptFile.parent.parent.parent.parent;

  if (!repoDir.childFile('pubspec.yaml').existsSync()) {
    // Fallback or check if we are in the wrong place?
    // Try to find the root by looking up.
    Directory current = scriptFile.parent;
    while (current.path != current.parent.path) {
      if (current.childFile('pubspec.yaml').existsSync() &&
          current.childDirectory('packages').existsSync()) {
        repoDir = current;
        break;
      }
      current = current.parent;
    }
  }

  final tool = ReleaseTool(
    fileSystem: fileSystem,
    processRunner: processRunner,
    repoRoot: repoDir,
    stdinReader: io.stdin.readLineSync,
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
      case 'help':
        if (command.rest.isEmpty) {
          printUsage();
        } else {
          final String subcommand = command.rest.first;
          final ArgParser? subParser = parser.commands[subcommand];
          if (subParser == null) {
            actualStderr.writeln('Unknown command: $subcommand');
            printUsage(sink: actualStderr);
            return 1;
          }
          actualStdout.writeln(
            'Usage: dart run tool/release/bin/release.dart $subcommand [options]',
          );
          actualStdout.writeln(subParser.usage);
        }
        break;
    }
  } on ReleaseException catch (e) {
    actualStderr.writeln(e);
    return 1;
  }
  return 0;
}
