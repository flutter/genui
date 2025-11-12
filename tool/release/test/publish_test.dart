import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';
import 'package:process_runner/test/fake_process_manager.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  group('PublishCommand', () {
    late MemoryFileSystem fileSystem;
    late FakeProcessManager processManager;
    late String repoRoot;
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
      repoRoot =
          fileSystem.systemTempDirectory.createTempSync('genui_repo').path;
      processManager = FakeProcessManager((input) {}); // Stdin callback
      fakeStdinLines = [];
      stdinReadIndex = 0;

      final Directory packagesDir =
          fileSystem.directory(p.join(repoRoot, 'packages'));
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

    test('dry run should only call dry-run', () async {
      final ReleaseTool releaseTool = buildReleaseTool();
      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--dry-run'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, 'Dry run success', ''),
        ],
      };

      await releaseTool.publish(force: false);

      expect(processManager.invocations.length, 1);
      expect(processManager.invocations.first.invocation,
          ['dart', 'pub', 'publish', '--dry-run']);
    });

    test('publish --force with yes should publish and tag', () async {
      fakeStdinLines.add('yes');
      final ReleaseTool releaseTool = buildReleaseTool();

      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--dry-run'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, 'Dry run success', ''),
        ],
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--force'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, 'Publish success', ''),
        ],
        FakeInvocationRecord(const ['git', 'tag', 'package_a-1.2.3'],
            workingDirectory: repoRoot): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await releaseTool.publish(force: true);

      expect(stdinReadIndex, 1);
      expect(processManager.invocations.length, 3);
      expect(processManager.invocations[0].invocation,
          ['dart', 'pub', 'publish', '--dry-run']);
      expect(processManager.invocations[1].invocation,
          ['dart', 'pub', 'publish', '--force']);
      expect(processManager.invocations[2].invocation,
          ['git', 'tag', 'package_a-1.2.3']);
    });

    test('publish --force with no should abort', () async {
      fakeStdinLines.add('no');
      final ReleaseTool releaseTool = buildReleaseTool();

      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'publish', '--dry-run'],
            workingDirectory: packageADir.path): [
          ProcessResult(0, 0, 'Dry run success', ''),
        ],
      };

      await releaseTool.publish(force: true);

      expect(stdinReadIndex, 1);
      expect(processManager.invocations.length, 1);
      expect(processManager.invocations[0].invocation,
          ['dart', 'pub', 'publish', '--dry-run']);
    });
  });
}
