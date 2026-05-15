// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:test_and_fix/src/verifiers/coverage_policy.dart';
import 'package:test_and_fix/src/verifiers/coverage_verifier.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('PackagePolicy', () {
    test('fromYaml parses correctly', () {
      final map = loadYaml('enabled: false\nthreshold: 95.5') as YamlMap;
      final policy = PackagePolicy.fromYaml(map);
      expect(policy.enabled, isFalse);
      expect(policy.threshold, 95.5);
    });

    test('fromYaml handles defaults and invalid inputs', () {
      final policyNull = PackagePolicy.fromYaml(null);
      expect(policyNull.enabled, isTrue);
      expect(policyNull.threshold, isNull);

      final policyEmpty = PackagePolicy.fromYaml(loadYaml('{}'));
      expect(policyEmpty.enabled, isTrue);
      expect(policyEmpty.threshold, isNull);
    });
  });

  group('CoveragePolicy', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    test('load returns defaults for missing file', () {
      final File f = fs.file('missing.yaml');
      final CoveragePolicy policy = CoveragePolicy.load(f);
      expect(policy.defaultThreshold, 80.0);
      expect(policy.enforceNoRegression, isTrue);
      expect(policy.baselineFile, 'coverage_baseline.yaml');
    });

    test('load parses valid policy yaml', () {
      final File f = fs.file('policy.yaml');
      f.writeAsStringSync('''
default_threshold: 85.0
enforce_no_regression: false
baseline_file: my_baseline.yaml
exclude:
  - "**/generated/**"
  - "**/*.g.dart"
packages:
  pkg_a:
    threshold: 90.0
  pkg_b:
    enabled: false
''');
      final CoveragePolicy policy = CoveragePolicy.load(f);
      expect(policy.defaultThreshold, 85.0);
      expect(policy.enforceNoRegression, isFalse);
      expect(policy.baselineFile, 'my_baseline.yaml');

      expect(policy.isFileExcluded('lib/generated/foo.dart'), isTrue);
      expect(policy.isFileExcluded('lib/src/bar.g.dart'), isTrue);
      expect(policy.isFileExcluded('lib/src/baz.dart'), isFalse);

      final PackagePolicy pkgA = policy.getPackagePolicy('pkg_a');
      expect(pkgA.enabled, isTrue);
      expect(pkgA.threshold, 90.0);

      final PackagePolicy pkgB = policy.getPackagePolicy('pkg_b');
      expect(pkgB.enabled, isFalse);
      expect(pkgB.threshold, isNull);

      final PackagePolicy pkgC = policy.getPackagePolicy('unknown');
      expect(pkgC.enabled, isTrue);
      expect(pkgC.threshold, isNull);
    });
  });

  group('CoverageBaseline', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    test('load returns empty for missing file', () {
      final File f = fs.file('missing_baseline.yaml');
      final CoverageBaseline baseline = CoverageBaseline.load(f);
      expect(baseline.highWaterMarks, isEmpty);
    });

    test('load and save preserve high water marks', () {
      final File f = fs.file('baseline.yaml');
      f.writeAsStringSync('''
pkg_1: 92.50
pkg_2: 88.10
''');
      final CoverageBaseline baseline = CoverageBaseline.load(f);
      expect(baseline.highWaterMarks, {'pkg_1': 92.50, 'pkg_2': 88.10});

      baseline.highWaterMarks['pkg_3'] = 100.0;
      final File out = fs.file('out_baseline.yaml');
      baseline.save(out);

      final CoverageBaseline reloaded = CoverageBaseline.load(out);
      expect(reloaded.highWaterMarks, {
        'pkg_1': 92.50,
        'pkg_2': 88.10,
        'pkg_3': 100.0,
      });
    });
  });

  group('CoverageVerifier', () {
    late MemoryFileSystem fs;
    late Directory repoRoot;
    late Directory projectA;
    late Directory projectB;
    late Logger logger;
    final logMessages = <String>[];

    setUp(() {
      fs = MemoryFileSystem();
      repoRoot = fs.directory('/repo')..createSync();
      projectA = repoRoot.childDirectory('packages').childDirectory('pkg_a')
        ..createSync(recursive: true);
      projectB = repoRoot.childDirectory('packages').childDirectory('pkg_b')
        ..createSync(recursive: true);
      logMessages.clear();
      hierarchicalLoggingEnabled = true;
      logger = Logger('Test')..level = Level.ALL;
      logger.onRecord.listen((r) => logMessages.add(r.message));
    });

    void writePolicy({double defaultThreshold = 80.0}) {
      final File p = repoRoot.childFile('coverage_policy.yaml');
      p.writeAsStringSync('''
default_threshold: $defaultThreshold
enforce_no_regression: true
baseline_file: coverage_baseline.yaml
packages:
  packages/pkg_b:
    enabled: false
''');
    }

    void writeBaseline(Map<String, double> marks) {
      final File b = repoRoot.childFile('coverage_baseline.yaml');
      final buffer = StringBuffer();
      marks.forEach((k, v) => buffer.writeln('$k: $v'));
      b.writeAsStringSync(buffer.toString());
    }

    void writeLcov(Directory project, String content) {
      final Directory lcovDir = project.childDirectory('coverage')
        ..createSync();
      lcovDir.childFile('lcov.info').writeAsStringSync(content);
    }

    test('verify passes when coverage meets threshold and baseline', () async {
      writePolicy(defaultThreshold: 80.0);
      writeBaseline({'packages/pkg_a': 85.0});
      // 90% coverage (9/10)
      writeLcov(projectA, '''
SF:lib/foo.dart
DA:1,1
DA:2,1
DA:3,1
DA:4,1
DA:5,1
DA:6,1
DA:7,1
DA:8,1
DA:9,1
DA:10,0
LF:10
LH:9
end_of_record
''');

      final verifier = CoverageVerifier(fs: fs, logger: logger);
      final bool success = await verifier.verify(
        repoRoot: repoRoot,
        testedProjects: [projectA, projectB],
        updateBaseline: false,
      );

      expect(success, isTrue);
      expect(
        logMessages.any((m) => m.contains('✅ PASSED (New High!)')),
        isTrue,
      );
    });

    test('verify fails when coverage is below threshold', () async {
      writePolicy(defaultThreshold: 80.0);
      // 50% coverage (5/10)
      writeLcov(projectA, '''
SF:lib/foo.dart
DA:1,1
DA:2,1
DA:3,1
DA:4,1
DA:5,1
DA:6,0
DA:7,0
DA:8,0
DA:9,0
DA:10,0
LF:10
LH:5
end_of_record
''');

      final verifier = CoverageVerifier(fs: fs, logger: logger);
      final bool success = await verifier.verify(
        repoRoot: repoRoot,
        testedProjects: [projectA],
        updateBaseline: false,
      );

      expect(success, isFalse);
      expect(
        logMessages.any((m) => m.contains('❌ FAILED (Below Threshold)')),
        isTrue,
      );
    });

    test(
      'verify fails on baseline regression even if above minimum threshold',
      () async {
        writePolicy(defaultThreshold: 80.0);
        writeBaseline({'packages/pkg_a': 95.0});
        // 90% coverage (9/10), which is >80 threshold but <95 baseline
        writeLcov(projectA, '''
SF:lib/foo.dart
DA:1,1
DA:2,1
DA:3,1
DA:4,1
DA:5,1
DA:6,1
DA:7,1
DA:8,1
DA:9,1
DA:10,0
LF:10
LH:9
end_of_record
''');

        final verifier = CoverageVerifier(fs: fs, logger: logger);
        final bool success = await verifier.verify(
          repoRoot: repoRoot,
          testedProjects: [projectA],
          updateBaseline: false,
        );

        expect(success, isFalse);
        expect(logMessages.any((m) => m.contains('❌ REGRESSED')), isTrue);
      },
    );

    test('updateBaseline saves new high water marks', () async {
      writePolicy(defaultThreshold: 80.0);
      writeBaseline({'packages/pkg_a': 50.0});
      // 90% coverage (9/10)
      writeLcov(projectA, '''
SF:lib/foo.dart
DA:1,1
DA:2,1
DA:3,1
DA:4,1
DA:5,1
DA:6,1
DA:7,1
DA:8,1
DA:9,1
DA:10,0
LF:10
LH:9
end_of_record
''');

      final verifier = CoverageVerifier(fs: fs, logger: logger);
      final bool success = await verifier.verify(
        repoRoot: repoRoot,
        testedProjects: [projectA],
        updateBaseline: true,
      );

      expect(success, isTrue);
      final CoverageBaseline updated = CoverageBaseline.load(
        repoRoot.childFile('coverage_baseline.yaml'),
      );
      expect(updated.highWaterMarks['packages/pkg_a'], closeTo(90.0, 0.1));
    });

    test('missing lcov file fails check', () async {
      writePolicy(defaultThreshold: 80.0);
      // Do not write lcov for projectA
      final verifier = CoverageVerifier(fs: fs, logger: logger);
      final bool success = await verifier.verify(
        repoRoot: repoRoot,
        testedProjects: [projectA],
        updateBaseline: false,
      );
      expect(success, isFalse);
      expect(logMessages.any((m) => m.contains('Missing lcov.info')), isTrue);
    });

    test('verify fails when baseline_file points outside repository', () async {
      writePolicy(defaultThreshold: 80.0);
      final File p = repoRoot.childFile('coverage_policy.yaml');
      p.writeAsStringSync('baseline_file: ../../etc/passwd');

      final verifier = CoverageVerifier(fs: fs, logger: logger);
      final bool success = await verifier.verify(
        repoRoot: repoRoot,
        testedProjects: [projectA],
        updateBaseline: false,
      );

      expect(success, isFalse);
      expect(logMessages.any((m) => m.contains('Security Error')), isTrue);
    });
  });
}
