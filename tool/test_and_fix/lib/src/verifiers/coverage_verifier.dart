// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:lcov_parser/lcov_parser.dart' as lcov;
// ignore: implementation_imports
import 'package:lcov_parser/src/models/lines.dart';
import 'package:logging/logging.dart';

import 'coverage_policy.dart';

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
      fs.path.join(repoRoot.path, 'coverage_policy.yaml'),
    );
    final CoveragePolicy policy = CoveragePolicy.load(policyFile);

    final String normalizedRoot = fs.path.normalize(
      fs.path.absolute(repoRoot.path),
    );
    final String resolvedBaseline = fs.path.normalize(
      fs.path.absolute(fs.path.join(repoRoot.path, policy.baselineFile)),
    );

    if (!fs.path.isWithin(normalizedRoot, resolvedBaseline)) {
      _log.severe(
        '❌ Security Error: baseline_file path (${policy.baselineFile}) points '
        'outside repository root.',
      );
      return false;
    }

    final File baselineFile = fs.file(resolvedBaseline);
    final CoverageBaseline baseline = CoverageBaseline.load(baselineFile);

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
      final String relativePackageDir = fs.path.relative(
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
        fs.path.join('coverage', 'lcov.info'),
      );
      if (!lcovFile.existsSync()) {
        _log.warning(
          'Warning: Missing lcov.info for $relativePackageDir. Ensure tests '
          'ran with coverage.',
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
        if (policy.enforceNoRegression && delta < -0.2) {
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
      final List<String> fileLines = lcovFile.readAsLinesSync();
      final List<lcov.Record> records = lcov.Parser.parseLines(fileLines);
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
