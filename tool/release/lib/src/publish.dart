import 'dart:io';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'utils.dart';

typedef StdinReader = String? Function();

class PublishCommand {
  final FileSystem fileSystem;
  final ProcessRunner processRunner;
  final String repoRoot;
  final StdinReader stdinReader;

  PublishCommand({
    required this.fileSystem,
    required this.processRunner,
    required this.repoRoot,
    required this.stdinReader,
  });

  Future<void> run({required bool force}) async {
    final List<Directory> packages = await findPackages(fileSystem, repoRoot);
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

    print('--- Starting Actual Publish ---');
    final publishedVersions = <String, String>{};
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
      publishedVersions[packageName] =
          await getPackageVersion(fileSystem, packageDir);
    }
    print('--- Publish Finished ---');

    print('\n--- Creating Git Tags ---');
    for (final String packageName in publishedVersions.keys) {
      final String version = publishedVersions[packageName]!;
      final tagName = '$packageName-$version';
      print('Creating tag: $tagName');
      final ProcessRunnerResult result = await processRunner.runProcess(
        ['git', 'tag', tagName],
        workingDirectory: fileSystem.directory(repoRoot),
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
  }
}
