// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';
import 'package:process_runner/process_runner.dart';
import 'package:yaml/yaml.dart';

import 'src/verifiers/coverage_verifier.dart';
import 'src/verifiers/workspace_verifier.dart';

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

    final workspaceVerifier = WorkspaceVerifier(fs: fs, logger: _log);
    final bool workspaceValid = await workspaceVerifier.verify(
      repoRoot: root,
      projects: projects,
    );
    if (!workspaceValid) {
      return false;
    }

    final testedProjects = <Directory>[];
    final jobs = <WorkerJob>[];
    final bool skipNonTestJobs = coverage || updateBaseline;

    WorkerJob? copyrightJob;
    if (!skipNonTestJobs) {
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
      copyrightJob = WorkerJob(
        ['dart', 'run', 'tool/fix_copyright/bin/fix_copyright.dart', '--force'],
        name: 'fix copyrights',
        dependsOn: {formatJob},
        workingDirectory: root,
      );
      jobs.addAll([fixJob, formatJob, copyrightJob]);
    }

    // Project-specific jobs
    for (final project in projects) {
      if (!skipNonTestJobs) {
        jobs.add(
          WorkerJob(
            ['dart', 'analyze'],
            name: 'dart analyze in ${fs.path.relative(project.path)}',
            workingDirectory: project,
            dependsOn: copyrightJob != null ? {copyrightJob} : {},
          ),
        );
      }
      if (fs.directory(fs.path.join(project.path, 'test')).existsSync()) {
        testedProjects.add(project);
        final bool isFlutter = _isFlutterPackage(project);
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
          name: '$command test in ${fs.path.relative(project.path)}',
          workingDirectory: project,
          dependsOn: copyrightJob != null ? {copyrightJob} : {},
        );
        jobs.add(testJob);

        if (!isFlutter && (coverage || updateBaseline)) {
          jobs.add(
            WorkerJob(
              [
                'dart',
                'run',
                'coverage:format_coverage',
                '--lcov',
                '--in=coverage',
                '--out=coverage/lcov.info',
                '--package=${root.path}',
                '--report-on=lib',
              ],
              name: 'format coverage in ${fs.path.relative(project.path)}',
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

  bool _isFlutterPackage(Directory project) {
    final File pubspecFile = project.childFile('pubspec.yaml');
    if (!pubspecFile.existsSync()) return false;
    try {
      final String content = pubspecFile.readAsStringSync();
      final Object? yaml = loadYaml(content);
      if (yaml is YamlMap) {
        final Object? deps = yaml['dependencies'];
        final Object? devDeps = yaml['dev_dependencies'];
        if ((deps is YamlMap && deps.containsKey('flutter')) ||
            (devDeps is YamlMap && devDeps.containsKey('flutter'))) {
          return true;
        }
      }
      return content.contains('sdk: flutter');
    } catch (_) {}
    return false;
  }

  bool _isPartFile(File file) {
    try {
      final ParseStringResult parseResult = parseString(
        content: file.readAsStringSync(),
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false,
      );
      for (final Directive directive in parseResult.unit.directives) {
        if (directive is PartOfDirective) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  void _generateCoverageAllTest(Directory project) {
    final Directory libDir = fs.directory(fs.path.join(project.path, 'lib'));
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
    if (pkgName == null || pkgName.isEmpty) {
      _log.warning(
        'Warning: Package name is missing in ${pubspecFile.path}. '
        'Skipping full coverage test generation.',
      );
      return;
    }

    final validPathRegex = RegExp(r'^[a-zA-Z0-9_\-/\.]+$');
    if (!validPathRegex.hasMatch(pkgName)) {
      _log.warning(
        'Warning: Package name "$pkgName" contains invalid characters. '
        'Skipping full coverage test generation.',
      );
      return;
    }

    final Directory testDir = fs.directory(fs.path.join(project.path, 'test'));
    if (!testDir.existsSync()) return;

    final dartFiles = <String>[];
    for (final FileSystemEntity entity in libDir.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final String relPath = fs.path.relative(entity.path, from: libDir.path);
        final String normalized = relPath.replaceAll('\\', '/');
        if (!validPathRegex.hasMatch(normalized)) continue;
        if (!normalized.endsWith('.g.dart') &&
            !normalized.endsWith('.freezed.dart') &&
            !normalized.endsWith('.mocks.dart') &&
            !normalized.endsWith('_web.dart') &&
            !_isPartFile(entity)) {
          dartFiles.add(normalized);
        }
      }
    }

    if (dartFiles.isEmpty) return;

    final File ephemeralTest = fs.file(
      fs.path.join(testDir.path, 'ephemeral_coverage_all_test.dart'),
    );
    final buffer = StringBuffer();
    buffer.writeln(
      '// Auto-generated by test_and_fix for full coverage calculation.',
    );
    buffer.writeln(
      '// ignore_for_file: unused_import, non_constant_identifier_names',
    );
    for (var i = 0; i < dartFiles.length; i++) {
      buffer.writeln("import 'package:$pkgName/${dartFiles[i]}' as _i$i;");
    }
    buffer.writeln('void main() {}');
    ephemeralTest.writeAsStringSync(buffer.toString());
  }

  void _cleanupEphemeralCoverageTests(List<Directory> projects) {
    for (final project in projects) {
      final File f = fs.file(
        fs.path.join(project.path, 'test', 'ephemeral_coverage_all_test.dart'),
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
      'submodules',
      if (!all) 'spikes',
      if (!all) 'fix_copyright',
      if (!all) 'release',
      if (!all) 'test_and_fix',
      if (!all) 'e2e',
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
