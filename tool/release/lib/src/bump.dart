import 'dart:io';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'utils.dart';

class BumpCommand {
  final FileSystem fileSystem;
  final ProcessRunner processRunner;
  final String repoRoot;

  BumpCommand({
    required this.fileSystem,
    required this.processRunner,
    required this.repoRoot,
  });

  Future<void> run(String bumpLevel) async {
    final List<Directory> packages = await findPackages(fileSystem, repoRoot);

    for (final packageDir in packages) {
      print('Processing package: ${p.basename(packageDir.path)}');
      await _bumpVersion(packageDir, bumpLevel);
      final String newVersion = await getPackageVersion(fileSystem, packageDir);
      await _updateChangelog(packageDir, newVersion);
    }

    print('Upgrading dependencies in the monorepo...');
    await _upgradeDependencies();
    print('Bump command finished.');
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
