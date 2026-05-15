// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:process_runner/process_runner.dart';
import 'package:yaml/yaml.dart';

import 'src/coverage/coverage_verifier.dart';

class TestAndFix {
  TestAndFix({
    this.fs = const LocalFileSystem(),
    ProcessManager? processManager,
    Logger? logger,
  }) : processRunner = ProcessRunner(
         processManager: processManager ?? const LocalProcessManager(),
       ),
       _log = logger ?? Logger('TestAndFix');

  final FileSystem fs;
  final ProcessRunner processRunner;
  final Logger _log;

  Future<bool> run({
    Directory? root,
    bool verbose = false,
    bool all = false,
    bool coverage = false,
    bool updateBaseline = false,
  }) async {
    root ??= fs.currentDirectory;
    final List<Directory> projects = await findProjects(root, all: all);
    final testedProjects = <Directory>[];
    final jobs = <WorkerJob>[];

    // Global jobs
    final fixJob = WorkerJob(
      ['dart', 'fix', '--apply', '.'],
      name: 'dart fix',
      workingDirectory: root,
    );
    final formatJob = WorkerJob(
      ['dart', 'format', '.'],
      name: 'dart format',
      dependsOn: {fixJob},
      workingDirectory: root,
    );
    final copyrightJob = WorkerJob(
      ['dart', 'run', 'tool/fix_copyright/bin/fix_copyright.dart', '--force'],
      name: 'fix copyrights',
      dependsOn: {formatJob},
      workingDirectory: root,
    );
    jobs.addAll([fixJob, formatJob, copyrightJob]);

    // Project-specific jobs
    for (final project in projects) {
      jobs.add(
        WorkerJob(
          ['dart', 'analyze'],
          name: 'dart analyze in ${path.relative(project.path)}',
          workingDirectory: project,
          dependsOn: {copyrightJob},
        ),
      );
      if (fs.directory(path.join(project.path, 'test')).existsSync()) {
        testedProjects.add(project);
        final bool isFlutter = project
            .childFile('pubspec.yaml')
            .readAsStringSync()
            .contains('sdk: flutter');
        final command = isFlutter ? 'flutter' : 'dart';
        final testArgs = [command, 'test'];
        if (coverage || updateBaseline) {
          if (isFlutter) {
            testArgs.add('--coverage');
          } else {
            testArgs.add('--coverage=coverage');
          }
        }
        final testJob = WorkerJob(
          testArgs,
          name: '$command test in ${path.relative(project.path)}',
          workingDirectory: project,
          dependsOn: {copyrightJob},
        );
        jobs.add(testJob);

        if (!isFlutter && (coverage || updateBaseline)) {
          String packages = path.join(
            root.path,
            '.dart_tool',
            'package_config.json',
          );
          jobs.add(
            WorkerJob(
              [
                'dart',
                'run',
                'coverage:format_coverage',
                '--lcov',
                '--in=coverage',
                '--out=coverage/lcov.info',
                '--packages=$packages',
                '--report-on=lib',
              ],
              name: 'format coverage in ${path.relative(project.path)}',
              workingDirectory: project,
              dependsOn: {testJob},
            ),
          );
        }
      }
    }

    _log.info(
      'Found ${projects.length} projects and created ${jobs.length} jobs.',
    );

    if (coverage || updateBaseline) {
      for (final project in testedProjects) {
        _generateCoverageAllTest(project);
      }
    }

    final pool = ProcessPool(
      numWorkers: Platform.numberOfProcessors,
      processRunner: processRunner,
    );
    ProcessPool.defaultPrintReport(jobs.length, 0, 0, jobs.length, 0);

    List<WorkerJob> results = [];
    try {
      results = await pool.runToCompletion(jobs);
    } finally {
      if (coverage || updateBaseline) {
        _cleanupEphemeralCoverageTests(testedProjects);
      }
    }

    final List<WorkerJob> successfulJobs = results
        .where((job) => job.result.exitCode == 0)
        .toList();
    final List<WorkerJob> failedJobs = results
        .where((job) => job.result.exitCode != 0)
        .toList();

    _log.info('\n--- Successful Jobs ---');
    for (final job in successfulJobs) {
      _log.info('  - ${job.name} (exit code ${job.result.exitCode})');
      if (verbose && job.result.output.isNotEmpty) {
        _log.info(job.result.output);
      }
    }

    if (failedJobs.isNotEmpty) {
      _log.severe('\n--- Failed Jobs ---');
      for (final job in failedJobs) {
        _log.severe('  - ${job.name} (exit code ${job.result.exitCode})');
        if (job.result.output.isNotEmpty) {
          _log.severe(job.result.output);
        }
      }
      return false;
    }

    if (coverage || updateBaseline) {
      final verifier = CoverageVerifier(fs: fs, logger: _log);
      final bool covSuccess = await verifier.verify(
        repoRoot: root,
        testedProjects: testedProjects,
        updateBaseline: updateBaseline,
      );
      if (!covSuccess) {
        return false;
      }
    }

    _log.info('\nAll jobs completed successfully!');
    return true;
  }

  void _generateCoverageAllTest(Directory project) {
    final Directory libDir = fs.directory(path.join(project.path, 'lib'));
    if (!libDir.existsSync()) return;

    final File pubspecFile = project.childFile('pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    String? pkgName;
    try {
      final Object? yaml = loadYaml(pubspecFile.readAsStringSync());
      if (yaml is YamlMap) {
        pkgName = yaml['name']?.toString();
      }
    } catch (_) {}
    if (pkgName == null || pkgName.isEmpty) return;

    final Directory testDir = fs.directory(path.join(project.path, 'test'));
    if (!testDir.existsSync()) return;

    final dartFiles = <String>[];
    for (final FileSystemEntity entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final String relPath = path.relative(entity.path, from: libDir.path);
        if (!relPath.endsWith('.g.dart') &&
            !relPath.endsWith('.freezed.dart') &&
            !relPath.endsWith('.mocks.dart')) {
          dartFiles.add(relPath);
        }
      }
    }

    if (dartFiles.isEmpty) return;

    final File ephemeralTest = fs.file(
      path.join(testDir.path, 'ephemeral_coverage_all_test.dart'),
    );
    final buffer = StringBuffer();
    buffer.writeln(
      '// Auto-generated by test_and_fix for full coverage calculation.',
    );
    buffer.writeln(
      '// ignore_for_file: unused_import, non_constant_identifier_names',
    );
    for (var i = 0; i < dartFiles.length; i++) {
      final String normalized = dartFiles[i].replaceAll('\\', '/');
      buffer.writeln("import 'package:$pkgName/$normalized' as _i$i;");
    }
    buffer.writeln('void main() {}');
    ephemeralTest.writeAsStringSync(buffer.toString());
  }

  void _cleanupEphemeralCoverageTests(List<Directory> projects) {
    for (final project in projects) {
      final File f = fs.file(
        path.join(project.path, 'test', 'ephemeral_coverage_all_test.dart'),
      );
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  Future<List<Directory>> findProjects(
    Directory root, {
    bool all = false,
  }) async {
    final projects = <Directory>[];
    await _findProjectsRecursive(root, projects, all: all);
    return projects;
  }

  Future<void> _findProjectsRecursive(
    Directory dir,
    List<Directory> projects, {
    required bool all,
  }) async {
    final Set<String> excludedDirs = _getExcludedDirectories(all: all);
    try {
      await for (final FileSystemEntity entity in dir.list(
        followLinks: false,
      )) {
        if (entity is File && fs.path.basename(entity.path) == 'pubspec.yaml') {
          final Directory projectDir = entity.parent;
          if (isProjectAllowed(projectDir, all: all)) {
            projects.add(projectDir);
          }
        } else if (entity is Directory) {
          if (!excludedDirs.contains(fs.path.basename(entity.path))) {
            await _findProjectsRecursive(entity, projects, all: all);
          }
        }
      }
    } on FileSystemException catch (exception) {
      _log.warning(
        'Warning: Failed to list directory contents while searching for '
        'projects: $exception',
      );
    }
  }

  Set<String> _getExcludedDirectories({required bool all}) {
    return {
      '.dart_tool',
      'ephemeral',
      'firebase_core',
      'build',
      if (!all) 'spikes',
      if (!all) 'fix_copyright',
      if (!all) 'release',
      if (!all) 'test_and_fix',
    };
  }

  bool isProjectAllowed(Directory projectPath, {bool all = false}) {
    final Set<String> excluded = _getExcludedDirectories(all: all);
    final List<String> components = fs.path.split(projectPath.path);
    for (final exclude in excluded) {
      if (components.contains(exclude)) {
        return false;
      }
    }
    return true;
  }
}
