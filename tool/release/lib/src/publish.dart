import 'dart:io';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'utils.dart';

typedef StdinReader = String? Function();

class PublishCommand {
  final FileSystem fileSystem;
  final ProcessRunner processRunner;
  final Directory repoRoot;
  final StdinReader stdinReader;

  PublishCommand({
    required this.fileSystem,
    required this.processRunner,
    required this.repoRoot,
    required this.stdinReader,
  });

  Future<void> run({required bool force}) async {
    final List<Directory> packages = await findPackages(repoRoot);
    final dryRunResults = <Directory, ProcessRunnerResult>{};
    var dryRunFailed = false;

    print('--- Starting Dry Run ---');
    for (final packageDir in packages) {
      final String packageName = p.basename(packageDir.path);
      print('Dry running publish for $packageName...');
      final ProcessRunnerResult result = await processRunner.runProcess(
        ['dart', 'pub', 'publish', '--dry-run'],
        workingDirectory: packageDir,
        failOk: true,
      );
      dryRunResults[packageDir] = result;
      print(result.stdout);
      if (result.exitCode != 0) {
        print('ERROR: Dry run failed for $packageName');
        print(result.stderr);
        dryRunFailed = true;
      } else {
        print('Dry run for $packageName successful.');
      }
    }
    print('--- Dry Run Finished ---');

    if (dryRunFailed) {
      print('One or more dry runs failed. Aborting.');
      exit(1);
    }

    if (!force) {
      print('Dry run successful. Run with --force to publish.');
      return;
    }

    print('\nProceed with publishing? (yes/No)');
    final String? confirmation = stdinReader();
    if (confirmation?.toLowerCase() != 'yes') {
      print('Publish aborted.');
      return;
    }

    final versionsToPublish = <String, String>{};
    for (final packageDir in packages) {
      final String packageName = p.basename(packageDir.path);
      versionsToPublish[packageName] = await getPackageVersion(packageDir);
    }

    print('--- Starting Actual Publish ---');
    for (final packageDir in packages) {
      final String packageName = p.basename(packageDir.path);
      print('Publishing $packageName...');
      final ProcessRunnerResult result = await processRunner.runProcess(
        ['dart', 'pub', 'publish', '--force'],
        workingDirectory: packageDir,
        failOk: true,
      );
      if (result.exitCode != 0) {
        print('ERROR: Failed to publish $packageName');
        print(result.stdout);
        print(result.stderr);
        exit(1);
      }
      print('$packageName published successfully.');
    }
    print('--- Publish Finished ---');

    print('\n--- Creating Git Tags ---');
    for (final String packageName in versionsToPublish.keys) {
      final String version = versionsToPublish[packageName]!;
      final tagName = '$packageName-$version';
      print('Creating tag: $tagName');
      final ProcessRunnerResult result = await processRunner.runProcess(
        ['git', 'tag', tagName],
        workingDirectory: repoRoot,
        failOk: true,
      );
      if (result.exitCode != 0) {
        print('ERROR: Failed to create tag $tagName');
        print(result.stderr);
        // Don't exit, just warn
      }
    }

    print('--- Tagging Finished ---');
    print('\nTo push tags, run: git push --tags');

    print('\n--- Preparing for next development cycle ---');
    final List<Directory> packagesToBump = await findPackages(repoRoot);
    for (final packageDir in packagesToBump) {
      final String packageName = p.basename(packageDir.path);
      print('Bumping version for $packageName...');
      final ProcessRunnerResult bumpResult = await processRunner.runProcess(
        ['dart', 'pub', 'bump', 'minor'],
        workingDirectory: packageDir,
        failOk: true,
      );
      if (bumpResult.exitCode != 0) {
        print('Error bumping version for $packageName:\n${bumpResult.stderr}');
        continue;
      }
      print('Version bumped for $packageName.');
      await _addNewChangelogSection(packageDir);
    }
    print('--- Next cycle preparation finished ---');
  }

  Future<void> _addNewChangelogSection(Directory packageDir) async {
    final String packageName = p.basename(packageDir.path);
    final String newVersion = await getPackageVersion(packageDir);

    final File changelogFile =
        fileSystem.file(p.join(packageDir.path, 'CHANGELOG.md'));
    final title = '# `$packageName` Changelog\n';
    String content;
    if (!await changelogFile.exists()) {
      content = '$title\n## $newVersion (in progress)\n\n';
      await changelogFile.writeAsString(content);
      print('Created and updated CHANGELOG.md in ${packageDir.path}');
      return;
    }

    content = await changelogFile.readAsString();
    List<String> lines = content.split('\n');

    // Ensure the title is present and correct
    if (lines.isEmpty || !lines[0].startsWith('# `$packageName` Changelog')) {
      if (lines.isNotEmpty && lines[0].startsWith('# ')) {
        lines.removeAt(0);
        while (lines.isNotEmpty && lines[0].trim().isEmpty) {
          lines.removeAt(0);
        }
      }
      lines.insert(0, title);
    }

    // Insert the new entry after the title and any blank lines
    var insertIndex = 1;
    while (insertIndex < lines.length && lines[insertIndex].trim().isEmpty) {
      insertIndex++;
    }

    final newEntry = '## $newVersion (in progress)';
    lines.insert(insertIndex, ''); // Blank line before new entry
    lines.insert(insertIndex, newEntry);

    await changelogFile.writeAsString(lines.join('\n'));
    print('Added new section to CHANGELOG.md in ${packageDir.path}');
  }
}
