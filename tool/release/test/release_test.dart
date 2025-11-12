import 'dart:io';

import 'package:file/memory.dart';
import 'package:file/src/interface/directory.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';
import 'package:process_runner/test/fake_process_manager.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseTool', () {
    late MemoryFileSystem fileSystem;
    late FakeProcessManager processManager;
    late ReleaseTool releaseTool;
    late String repoRoot;
    late Directory packageADir;

    setUp(() {
      fileSystem = MemoryFileSystem();
      repoRoot =
          fileSystem.systemTempDirectory.createTempSync('genui_repo').path;
      processManager = FakeProcessManager((input) {}); // Stdin callback
      releaseTool = ReleaseTool(
        fileSystem: fileSystem,
        processRunner: ProcessRunner(processManager: processManager),
        repoRoot: repoRoot,
      );

      final Directory packagesDir =
          fileSystem.directory(p.join(repoRoot, 'packages'));
      packagesDir.createSync(recursive: true);

      packageADir = packagesDir.childDirectory('package_a');
      packageADir.createSync();
      packageADir.childFile('pubspec.yaml').writeAsStringSync('''
name: package_a
version: 1.0.0
''');
      packageADir.childFile('CHANGELOG.md').writeAsStringSync('''
## 1.0.0

- Initial release.
''');

      final Directory excludedPackage =
          packagesDir.childDirectory('json_schema_builder');
      excludedPackage.createSync();
      excludedPackage.childFile('pubspec.yaml').writeAsStringSync('''
name: json_schema_builder
version: 0.1.0
''');
    });

    test('should bump patch version and update CHANGELOG', () async {
      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'bump', 'patch'],
            workingDirectory: packageADir.path): [
          () {
            packageADir.childFile('pubspec.yaml').writeAsStringSync('''
name: package_a
version: 1.0.1
''');
            return ProcessResult(0, 0, '', '');
          }()
        ],
        FakeInvocationRecord(
            const ['dart', 'pub', 'upgrade', '--major-versions'],
            workingDirectory: repoRoot): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await releaseTool.run('patch');

      final String pubspecContent =
          packageADir.childFile('pubspec.yaml').readAsStringSync();
      expect(pubspecContent, contains('version: 1.0.1'));

      final String changelogContent =
          packageADir.childFile('CHANGELOG.md').readAsStringSync();
      expect(
          changelogContent, startsWith('## 1.0.1 (in progress)\n\n## 1.0.0'));

      final String excludedPubspec = fileSystem
          .file(p.join(
              repoRoot, 'packages', 'json_schema_builder', 'pubspec.yaml'))
          .readAsStringSync();
      expect(excludedPubspec, contains('version: 0.1.0'));

      expect(processManager.invocations.length, 2);
    });

    test('should remove old (in progress) from CHANGELOG', () async {
      packageADir.childFile('CHANGELOG.md').writeAsStringSync('''
## 1.0.0 (in progress)

- Initial release.
''');

      processManager.fakeResults = {
        FakeInvocationRecord(const ['dart', 'pub', 'bump', 'minor'],
            workingDirectory: packageADir.path): [
          () {
            packageADir.childFile('pubspec.yaml').writeAsStringSync('''
name: package_a
version: 1.1.0
''');
            return ProcessResult(0, 0, '', '');
          }()
        ],
        FakeInvocationRecord(
            const ['dart', 'pub', 'upgrade', '--major-versions'],
            workingDirectory: repoRoot): [
          ProcessResult(0, 0, '', ''),
        ],
      };

      await releaseTool.run('minor');

      final String changelogContent =
          packageADir.childFile('CHANGELOG.md').readAsStringSync();
      expect(
          changelogContent, startsWith('## 1.1.0 (in progress)\n\n## 1.0.0'));
    });
  });
}
