import 'dart:io';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'utils.dart';

class BumpCommand {
  final FileSystem fileSystem;
  final ProcessRunner processRunner;
  final Directory repoRoot;

  BumpCommand({
    required this.fileSystem,
    required this.processRunner,
    required this.repoRoot,
  });

  Future<void> run(String bumpLevel) async {
    final List<Directory> packages = await findPackages(repoRoot);

    for (final packageDir in packages) {
      print('Processing package: ${p.basename(packageDir.path)}');
      await _bumpVersion(packageDir, bumpLevel);
      final String newVersion = await getPackageVersion(packageDir);
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
    final String packageName = p.basename(packageDir.path);
    final File changelogFile =
        fileSystem.file(p.join(packageDir.path, 'CHANGELOG.md'));
    final title = '# `$packageName` Changelog\n';

    if (!await changelogFile.exists()) {
      print('Warning: CHANGELOG.md not found in ${packageDir.path}');
      await changelogFile
          .writeAsString('$title\n## $newVersion (in progress)\n\n');
      return;
    }

    String content = await changelogFile.readAsString();
    List<String> lines = content.split('\n');

    // Ensure the title is present and correct
    if (lines.isEmpty || !lines[0].startsWith('# `$packageName` Changelog')) {
      // Remove any existing incorrect title
      if (lines.isNotEmpty && lines[0].startsWith('# ')) {
        lines.removeAt(0);
        // Remove potential blank lines after the old title
        while (lines.isNotEmpty && lines[0].trim().isEmpty) {
          lines.removeAt(0);
        }
      }
      content = '$title\n${lines.join('\n')}';
      lines = content.split('\n');
    }

    // Find the top-most version entry and update it.
    final versionHeader = '## $newVersion';
    var versionHeaderIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('## ')) {
        versionHeaderIndex = i;
        break;
      }
    }

    if (versionHeaderIndex != -1) {
      lines[versionHeaderIndex] = versionHeader;
    } else {
      // If no version entry exists, add one.
      var insertIndex = 1;
      while (insertIndex < lines.length && lines[insertIndex].trim().isEmpty) {
        insertIndex++;
      }
      lines.insert(insertIndex, versionHeader);
      lines.insert(insertIndex + 1, ''); // Blank line after new entry
    }


    await changelogFile.writeAsString(lines.join('\n'));
    print('Updated CHANGELOG.md in ${packageDir.path}');
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
