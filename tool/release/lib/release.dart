import 'dart:io';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';
import 'package:yaml/yaml.dart';

import 'src/bump.dart';
import 'src/publish.dart';

export 'src/bump.dart';
export 'src/publish.dart';

const _excludedPackages = ['json_schema_builder'];

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
  }) {
    _bumpCommand = BumpCommand(
      fileSystem: fileSystem,
      processRunner: processRunner,
      repoRoot: repoRoot,
    );
    _publishCommand = PublishCommand(
      fileSystem: fileSystem,
      processRunner: processRunner,
      repoRoot: repoRoot,
      stdinReader: stdinReader,
    );
  }

  Future<void> bump(String bumpLevel) => _bumpCommand.run(bumpLevel);

  Future<void> publish({required bool force}) =>
      _publishCommand.run(force: force);

  Future<void> run(String bumpLevel) async {
    final List<Directory> packages = await _findPackages();

    for (final packageDir in packages) {
      print('Processing package: ${p.basename(packageDir.path)}');
      await _bumpVersion(packageDir, bumpLevel);
      final String newVersion = await _getNewVersion(packageDir);
      await _updateChangelog(packageDir, newVersion);
    }

    print('Upgrading dependencies in the monorepo...');
    await _upgradeDependencies();
    print('Release tool finished.');
  }

  Future<List<Directory>> _findPackages() async {
    final Directory packagesDir = repoRoot.childDirectory('packages');
    if (!await packagesDir.exists()) {
      print('Error: packages directory not found at ${packagesDir.path}');
      return [];
    }

    final packages = <Directory>[];
    await for (final FileSystemEntity entity in packagesDir.list()) {
      if (entity is Directory) {
        final String packageName = p.basename(entity.path);
        if (_excludedPackages.contains(packageName)) {
          print('Skipping excluded package: $packageName');
          continue;
        }
        final File pubspecFile =
            fileSystem.file(p.join(entity.path, 'pubspec.yaml'));
        if (await pubspecFile.exists()) {
          packages.add(entity);
        }
      }
    }
    return packages;
  }

  Future<void> _bumpVersion(Directory packageDir, String level) async {
    final ProcessRunnerResult result = await processRunner.runProcess(
      ['dart', 'pub', 'bump', level],
      workingDirectory: packageDir,
      failOk: true,
    );
    if (result.exitCode != 0) {
      print('Error bumping version in ${packageDir.path}: ${result.stderr}');
      exit(1);
    }
    print('Bumped $level version in ${p.basename(packageDir.path)}');
  }

  Future<String> _getNewVersion(Directory packageDir) async {
    final File pubspecFile =
        fileSystem.file(p.join(packageDir.path, 'pubspec.yaml'));
    final String content = await pubspecFile.readAsString();
    final yamlMap = loadYaml(content) as Map;
    return yamlMap['version'] as String;
  }

  Future<void> _updateChangelog(Directory packageDir, String newVersion) async {
    final File changelogFile =
        fileSystem.file(p.join(packageDir.path, 'CHANGELOG.md'));
    if (!await changelogFile.exists()) {
      print('Warning: CHANGELOG.md not found in ${packageDir.path}');
      await changelogFile.writeAsString('## $newVersion (in progress)\n\n');
      return;
    }

    String content = await changelogFile.readAsString();
    content = content.replaceAllMapped(
      RegExp(r'^## (.*) \(in progress\)', multiLine: true),
      (match) => '## ${match[1]}',
    );

    final newEntry = '## $newVersion (in progress)\n\n';
    content = newEntry + content;

    await changelogFile.writeAsString(content);
    print('Updated CHANGELOG.md in ${p.basename(packageDir.path)}');
  }

  Future<void> _upgradeDependencies() async {
    final ProcessRunnerResult result = await processRunner.runProcess(
      ['dart', 'pub', 'upgrade', '--major-versions'],
      workingDirectory: fileSystem.directory(repoRoot),
      failOk: true,
    );
    if (result.exitCode != 0) {
      print('Error running pub upgrade: ${result.stderr}');
    }
  }
}
