// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:process_runner/process_runner.dart';

class TestAndFix {
  TestAndFix({
    this.fs = const LocalFileSystem(),
    ProcessManager? processManager,
  }) : processRunner = ProcessRunner(
         processManager: processManager ?? const LocalProcessManager(),
       );

  final FileSystem fs;
  final ProcessRunner processRunner;

  Future<bool> run({
    Directory? root,
    bool verbose = false,
    bool all = false,
  }) async {
    root ??= fs.currentDirectory;
    final projects = await findProjects(root, all: all);
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
        final isFlutter = project
            .childFile('pubspec.yaml')
            .readAsStringSync()
            .contains('sdk: flutter');
        final command = isFlutter ? 'flutter' : 'dart';
        jobs.add(
          WorkerJob(
            [command, 'test'],
            name: '$command test in ${path.relative(project.path)}',
            workingDirectory: project,
            dependsOn: {copyrightJob},
          ),
        );
      }
    }

    print('Found ${projects.length} projects and created ${jobs.length} jobs.');

    final pool = ProcessPool(
      numWorkers: Platform.numberOfProcessors,
      processRunner: processRunner,
    );
    ProcessPool.defaultPrintReport(jobs.length, 0, 0, jobs.length, 0);
    final results = await pool.runToCompletion(jobs);

    final successfulJobs = results
        .where((job) => job.result.exitCode == 0)
        .toList();
    final failedJobs = results
        .where((job) => job.result.exitCode != 0)
        .toList();

    print('--- Successful Jobs ---');
    for (final job in successfulJobs) {
      print('  - ${job.name} (exit code ${job.result.exitCode})');
      if (verbose && job.result.output.isNotEmpty) {
        print(job.result.output);
      }
    }

    if (failedJobs.isNotEmpty) {
      print('\n--- Failed Jobs ---');
      for (final job in failedJobs) {
        print('  - ${job.name} (exit code ${job.result.exitCode})');
        if (job.result.output.isNotEmpty) {
          print(job.result.output);
        }
      }
      return false;
    }

    print('\nAll jobs completed successfully!');
    return true;
  }

  Future<List<Directory>> findProjects(
    Directory root, {
    bool all = false,
  }) async {
    final projects = <Directory>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File || path.basename(entity.path) != 'pubspec.yaml') {
        continue;
      }
      final pubspec = entity;
      final projectDir = pubspec.parent;
      if (isProjectAllowed(projectDir, all: all)) {
        projects.add(projectDir);
      }
    }
    return projects;
  }

  bool isProjectAllowed(Directory projectPath, {bool all = false}) {
    // Skip the things that we really don't ever want to traverse, but skip the
    // non-essential packages unless --all is specified.
    final excluded = [
      '.dart_tool',
      'ephemeral',
      'firebase_core',
      'build',
      if (!all) 'spikes',
      if (!all) 'fix_copyright',
      if (!all) 'test_and_fix',
    ];
    final components = fs.path.split(projectPath.path);
    for (final exclude in excluded) {
      if (components.contains(exclude)) {
        return false;
      }
    }
    return true;
  }
}
