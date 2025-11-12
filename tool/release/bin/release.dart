import 'dart:io';

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';
import 'package:release/release.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('breaking')
    ..addCommand('major')
    ..addCommand('minor')
    ..addCommand('patch');

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    print(parser.usage);
    exit(1);
  }

  if (argResults.command == null) {
    print('Usage: dart run tool/release/bin/release.dart <level>');
    print('  <level> can be one of: breaking, major, minor, patch');
    print(parser.usage);
    exit(1);
  }

  final String bumpLevel = argResults.command!.name!;

  final fileSystem = const LocalFileSystem();
  final processRunner = ProcessRunner();

  final String scriptPath = Platform.script.toFilePath();
  final String binDir = p.dirname(scriptPath);
  final String toolDir = p.dirname(binDir);
  final String repoRoot = p.dirname(toolDir);

  final tool = ReleaseTool(
    fileSystem: fileSystem,
    processRunner: processRunner,
    repoRoot: repoRoot,
  );

  await tool.run(bumpLevel);
}
