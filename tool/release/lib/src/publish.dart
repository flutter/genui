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
  final Printer printer;

  PublishCommand({
    required this.fileSystem,
    required this.processRunner,
    required this.repoRoot,
    required this.stdinReader,
    required this.printer,
  });

  Future<void> run({required bool force}) async {
    final List<Directory> packages = await findPackages(repoRoot, printer);

    if (!await _performDryRun(packages)) {
      exit(1);
    }

    if (!force) {
      printer('Dry run successful. The following tags would be created:');
      for (final packageDir in packages) {
        final String packageName = p.basename(packageDir.path);
        final String version = await getPackageVersion(packageDir);
        printer('  $packageName-$version');
      }
      printer('Run with --force to publish.');
      return;
    }

    printer('\nProceed with publishing? (yes/No)');
    final String? confirmation = stdinReader()?.toLowerCase();
    if (confirmation != 'yes' && confirmation != 'y') {
      printer('Publish aborted.');
      return;
    }

    final Map<String, String> versionsToPublish =
        await _getVersionsToPublish(packages);

    await _performPublish(packages);
    await _createTags(versionsToPublish);
    await _prepareNextCycle(packages);
  }

  Future<bool> _performDryRun(List<Directory> packages) async {
    printer('--- Starting Dry Run ---');
    var dryRunFailed = false;
    final accumulatedProblems = <String>[];
    for (final packageDir in packages) {
      final String packageName = p.basename(packageDir.path);
      printer('Dry running publish for $packageName...');
      final ProcessRunnerResult result = await processRunner.runProcess(
        ['dart', 'pub', 'publish', '--dry-run'],
        workingDirectory: packageDir,
        failOk: true,
      );
      printer(result.stdout);
      if (result.exitCode != 0) {
        // Check and see if the problem was actual errors or just warnings, etc.
        // Warning output includes "Package has 2 warnings."
        // Failed output includes:
        //   "your package is missing some requirements"
        if (result.stderr
            .contains('your package is missing some requirements')) {
          accumulatedProblems.add('ERROR: Dry run failed for $packageName');
          dryRunFailed = true;
        } else {
          accumulatedProblems.add(
              'WARNING: Dry run has some warnings or hints for $packageName');
        }
        printer(result.stderr);
      } else {
        accumulatedProblems.add('Dry run for $packageName successful.');
      }
    }
    printer('--- Dry Run Finished ---');
    print(accumulatedProblems.join('\n'));
    return !dryRunFailed;
  }

  Future<Map<String, String>> _getVersionsToPublish(
      List<Directory> packages) async {
    final versionsToPublish = <String, String>{};
    for (final packageDir in packages) {
      final String packageName = p.basename(packageDir.path);
      versionsToPublish[packageName] = await getPackageVersion(packageDir);
    }
    return versionsToPublish;
  }

  Future<void> _performPublish(List<Directory> packages) async {
    printer('--- Starting Actual Publish ---');
    for (final packageDir in packages) {
      final String packageName = p.basename(packageDir.path);
      printer('Publishing $packageName...');
      final ProcessRunnerResult result = await processRunner.runProcess(
        ['dart', 'pub', 'publish', '--force'],
        workingDirectory: packageDir,
        failOk: true,
      );
      if (result.exitCode != 0) {
        printer('ERROR: Failed to publish $packageName');
        printer(result.stdout);
        printer(result.stderr);
        exit(1);
      }
      printer('$packageName published successfully.');
    }
    printer('--- Publish Finished ---');
  }

  Future<void> _createTags(Map<String, String> versionsToPublish) async {
    printer('\n--- Creating Git Tags ---');
    for (final String packageName in versionsToPublish.keys) {
      final String version = versionsToPublish[packageName]!;
      final tagName = '$packageName-$version';
      printer('Creating tag: $tagName');
      final ProcessRunnerResult result = await processRunner.runProcess(
        ['git', 'tag', tagName],
        workingDirectory: repoRoot,
        failOk: true,
      );
      if (result.exitCode != 0) {
        printer('ERROR: Failed to create tag $tagName');
        printer(result.stderr);
        // Don't exit, just warn
      }
    }
    printer('--- Tagging Finished ---');
    printer('\nTo push tags, run: git push --tags');
  }

  Future<void> _prepareNextCycle(List<Directory> packages) async {
    printer('\n--- Preparing for next development cycle ---');
    for (final packageDir in packages) {
      final String packageName = p.basename(packageDir.path);
      printer('Bumping version for $packageName...');
      final ProcessRunnerResult bumpResult = await processRunner.runProcess(
        ['dart', 'pub', 'bump', 'minor'],
        workingDirectory: packageDir,
        failOk: true,
      );
      if (bumpResult.exitCode != 0) {
        printer(
            'Error bumping version for $packageName:\n${bumpResult.stderr}');
        continue;
      }
      printer('Version bumped for $packageName.');
      await _addNewChangelogSection(packageDir);
    }
    printer('--- Next cycle preparation finished ---');
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
      printer('Created and updated CHANGELOG.md in ${packageDir.path}');
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
    printer('Added new section to CHANGELOG.md in ${packageDir.path}');
  }
}
