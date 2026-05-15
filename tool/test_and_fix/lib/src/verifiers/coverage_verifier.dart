// Copyright 2026 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:lcov_parser/lcov_parser.dart' as lcov;
// ignore: implementation_imports
import 'package:lcov_parser/src/models/lines.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'coverage_policy.dart';

class PackageCoverageResult {
  PackageCoverageResult({
    required this.packageDir,
    required this.threshold,
    required this.baseline,
    required this.currentCoverage,
    required this.passed,
    required this.delta,
    required this.message,
  });

  final String packageDir;
  final double threshold;
  final double? baseline;
  final double currentCoverage;
  final bool passed;
  final double delta;
  final String message;
}

class CoverageVerifier {
  CoverageVerifier({required this.fs, Logger? logger})
    : _log = logger ?? Logger('CoverageVerifier');

  final FileSystem fs;
  final Logger _log;

  Future<bool> verify({
    required Directory repoRoot,
    required List<Directory> testedProjects,
    required bool updateBaseline,
  }) async {
    final File policyFile = fs.file(
      path.join(repoRoot.path, 'coverage_policy.yaml'),
    );
    final CoveragePolicy policy = CoveragePolicy.load(policyFile);

    final File baselineFile = fs.file(
      path.join(repoRoot.path, policy.baselineFile),
    );
    final CoverageBaseline baseline = CoverageBaseline.load(baselineFile);

    final results = <PackageCoverageResult>[];
    final newWaterMarks = <String, double>{};
    var allPassed = true;

    _log.info('\n=== Monorepo Test Coverage Verification ===\n');
    _log.info(
      '${'Package'.padRight(30)}${'Threshold'.padRight(12)}'
      '${'Baseline'.padRight(12)}${'Current'.padRight(12)}'
      '${'Delta'.padRight(10)}Status',
    );
    _log.info('-' * 85);

    for (final project in testedProjects) {
      final String relativePackageDir = path.relative(
        project.path,
        from: repoRoot.path,
      );
      final PackagePolicy pkgPolicy = policy.getPackagePolicy(
        relativePackageDir,
      );

      if (!pkgPolicy.enabled) {
        continue;
      }

      final File lcovFile = project.childFile(
        path.join('coverage', 'lcov.info'),
      );
      if (!lcovFile.existsSync()) {
        _log.warning(
          'Warning: Missing lcov.info for $relativePackageDir. Ensure tests '
          'ran with coverage.',
        );
        results.add(
          PackageCoverageResult(
            packageDir: relativePackageDir,
            threshold: pkgPolicy.threshold ?? policy.defaultThreshold,
            baseline: baseline.highWaterMarks[relativePackageDir],
            currentCoverage: 0.0,
            passed: false,
            delta: 0.0,
            message: 'Missing lcov.info',
          ),
        );
        allPassed = false;
        continue;
      }

      final double currentCoverage = await _calculateCoverage(lcovFile, policy);
      final double threshold = pkgPolicy.threshold ?? policy.defaultThreshold;
      final double? prevBaseline = baseline.highWaterMarks[relativePackageDir];

      var passed = true;
      var statusMessage = '✅ PASSED';
      var delta = 0.0;

      if (currentCoverage < threshold) {
        passed = false;
        statusMessage = '❌ FAILED (Below Threshold)';
      } else if (prevBaseline != null) {
        delta = currentCoverage - prevBaseline;
        if (policy.enforceNoRegression && delta < -0.01) {
          passed = false;
          statusMessage = '❌ REGRESSED';
        } else if (delta > 0.01) {
          statusMessage = '✅ PASSED (New High!)';
        }
      }

      if (!passed) {
        allPassed = false;
      }

      newWaterMarks[relativePackageDir] =
          (prevBaseline == null ||
              currentCoverage > prevBaseline ||
              updateBaseline)
          ? currentCoverage
          : prevBaseline;

      results.add(
        PackageCoverageResult(
          packageDir: relativePackageDir,
          threshold: threshold,
          baseline: prevBaseline,
          currentCoverage: currentCoverage,
          passed: passed,
          delta: delta,
          message: statusMessage,
        ),
      );

      final String thresholdStr = '${threshold.toStringAsFixed(1)}%'.padRight(
        12,
      );
      final String baselineStr =
          (prevBaseline != null ? '${prevBaseline.toStringAsFixed(1)}%' : '-')
              .padRight(12);
      final String currentStr = '${currentCoverage.toStringAsFixed(1)}%'
          .padRight(12);
      final String deltaStr =
          (prevBaseline != null
                  ? '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%'
                  : '-')
              .padRight(10);

      _log.info(
        relativePackageDir.padRight(30) +
            thresholdStr +
            baselineStr +
            currentStr +
            deltaStr +
            statusMessage,
      );
    }

    _log.info('-' * 85);

    if (updateBaseline) {
      final updatedBaseline = CoverageBaseline(newWaterMarks);
      updatedBaseline.save(baselineFile);
      _log.info('Successfully updated baseline file: ${policy.baselineFile}');
    }

    if (!allPassed && !updateBaseline) {
      _log.severe('❌ Coverage verification failed for one or more packages.');
      return false;
    }

    _log.info('🎉 All package coverage checks passed successfully!');
    return true;
  }

  Future<double> _calculateCoverage(
    File lcovFile,
    CoveragePolicy policy,
  ) async {
    try {
      final List<lcov.Record> records = await lcov.Parser.parse(lcovFile.path);
      var totalHits = 0;
      var totalFound = 0;

      for (final record in records) {
        final String? filePath = record.file;
        if (filePath == null || policy.isFileExcluded(filePath)) {
          continue;
        }

        final LcovLinesDetails? lines = record.lines;
        if (lines != null) {
          totalFound += lines.found ?? 0;
          totalHits += lines.hit ?? 0;
        }
      }

      if (totalFound == 0) {
        return 100.0; // No executable lines found in non-excluded files
      }

      return (totalHits / totalFound) * 100.0;
    } catch (e) {
      _log.warning('Failed to parse ${lcovFile.path}: $e');
      return 0.0;
    }
  }
}
