import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:process_runner/process_runner.dart';
import 'package:process_runner/test/fake_process_manager.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  group('PublishCommand', () {
    late MemoryFileSystem fileSystem;
    late FakeProcessManager processManager;
    late Directory repoRoot;
    late Directory packageADir;
    late List<String> fakeStdinLines;
    late int stdinReadIndex;

    String? fakeStdinReader() {
      if (stdinReadIndex < fakeStdinLines.length) {
        return fakeStdinLines[stdinReadIndex++];
      }
      return null;
    }

    ReleaseTool buildReleaseTool() {
      return ReleaseTool(
        fileSystem: fileSystem,
        processRunner: ProcessRunner(processManager: processManager),
        repoRoot: repoRoot,
        stdinReader: fakeStdinReader,
      );
    }

    setUp(() {
      fileSystem = MemoryFileSystem();
      repoRoot = fileSystem.systemTempDirectory.createTempSync('genui_repo');
      processManager = FakeProcessManager((input) {}); // Stdin callback
      fakeStdinLines = [];
      stdinReadIndex = 0;

      final Directory packagesDir = repoRoot.childDirectory('packages');
      packagesDir.createSync(recursive: true);

      packageADir = packagesDir.childDirectory('package_a');
      packageADir.createSync();
      packageADir.childFile('pubspec.yaml').writeAsStringSync('''
name: package_a
version: 1.2.3
''');

      final Directory excludedPackage =
          packagesDir.childDirectory('json_schema_builder');
      excludedPackage.createSync();
      excludedPackage.childFile('pubspec.yaml').writeAsStringSync('''
name: json_schema_builder
version: 0.1.0
''');
    });

    test('PublishCommand dry run should only call dry-run', () async {
      final ReleaseTool releaseTool = buildReleaseTool();
      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--dry-run'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await releaseTool.publish(force: false);

      expect(processManager.invocations.length, 1);
      expect(processManager.invocations[0].invocation[0], 'dart');
      expect(processManager.invocations[0].invocation.skip(1),
          ['pub', 'publish', '--dry-run']);
    });

    test(
        'PublishCommand publish --force with yes should publish, tag, and bump',
        () async {
      fakeStdinLines = ['yes'];
      final ReleaseTool releaseTool = buildReleaseTool();
      packageADir.childFile('CHANGELOG.md').writeAsStringSync('''
# `package_a` Changelog

## 1.2.3

- Release version.
''');

      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--dry-run'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--force'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const ['git', 'tag', 'package_a-1.2.3'],
            workingDirectory: repoRoot.path): [
          ProcessResult(0, 0, '', ''),
        ],
        FakeInvocationRecord(const ['dart', 'pub', 'bump', 'minor'],
            workingDirectory: packageADir.path): [
          () {
            packageADir.childFile('pubspec.yaml').writeAsStringSync('''
name: package_a
version: 1.3.0
''');
            return ProcessResult(0, 0, '', '');
          }(),
        ],
      };

      await releaseTool.publish(force: true);

      expect(processManager.invocations.length, 4);
      expect(processManager.invocations[0].invocation.skip(1),
          ['pub', 'publish', '--dry-run']);
      expect(processManager.invocations[1].invocation.skip(1),
          ['pub', 'publish', '--force']);
      expect(processManager.invocations[2].invocation.skip(1),
          ['tag', 'package_a-1.2.3']);
      expect(processManager.invocations[3].invocation.skip(1),
          ['pub', 'bump', 'minor']);

      final String pubspecContent =
          packageADir.childFile('pubspec.yaml').readAsStringSync();
      expect(pubspecContent, contains('version: 1.3.0'));

      final String changelogContent =
          packageADir.childFile('CHANGELOG.md').readAsStringSync();
      expect(
        changelogContent,
        startsWith(
            '# `package_a` Changelog\n\n## 1.3.0 (in progress)\n\n## 1.2.3\n\n- Release version.'),
      );
    });

    test('PublishCommand publish --force with no should abort', () async {
      fakeStdinLines = ['no'];
      final ReleaseTool releaseTool = buildReleaseTool();

      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--dry-run'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await releaseTool.publish(force: true);
      expect(processManager.invocations.length, 1);
      expect(processManager.invocations[0].invocation.skip(1),
          ['pub', 'publish', '--dry-run']);
    });
  });
}
