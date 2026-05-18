// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Verifies that all internal dependencies within the workspace satisfy their
/// declared version constraints.
///
/// In a standard Dart workspace, if a local package's version falls outside
/// the constraint specified by a sibling consumer, `dart pub` will silently
/// fall back to resolving that package from `pub.dev`. This class prevents
/// that error-prone behavior by explicitly failing the build when local
/// workspace constraints are not met.
class WorkspaceVerifier {
  WorkspaceVerifier({required this.fs, Logger? logger})
    : _log = logger ?? Logger('WorkspaceVerifier');

  final FileSystem fs;
  final Logger _log;

  Future<bool> verify({
    required Directory repoRoot,
    required List<Directory> projects,
  }) async {
    _log.info('\n=== Workspace Version Constraints Verification ===\n');

    final Map<String, Version> localPackages = {};
    final Map<String, YamlMap> packagePubspecs = {};
    final Map<String, String> packagePaths = {};

    // 1. Gather all local workspace packages and their versions
    for (final project in projects) {
      final File pubspecFile = project.childFile('pubspec.yaml');
      if (!pubspecFile.existsSync()) continue;

      try {
        final Object? yaml = loadYaml(pubspecFile.readAsStringSync());
        if (yaml is YamlMap) {
          final String? name = yaml['name']?.toString();
          final String? versionStr = yaml['version']?.toString();

          if (name != null && name.isNotEmpty && versionStr != null) {
            try {
              final Version version = Version.parse(versionStr);
              localPackages[name] = version;
              packagePubspecs[name] = yaml;
              packagePaths[name] = fs.path.relative(
                project.path,
                from: repoRoot.path,
              );
            } on FormatException {
              _log.warning(
                'Warning: Could not parse version "$versionStr" for package $name.',
              );
            }
          }
        }
      } catch (e) {
        _log.warning('Failed to parse ${pubspecFile.path}: $e');
      }
    }

    // 2. Verify all internal dependencies against the actual local versions
    bool allPassed = true;

    for (final MapEntry<String, YamlMap> entry in packagePubspecs.entries) {
      final String consumerName = entry.key;
      final YamlMap consumerYaml = entry.value;
      final String consumerPath = packagePaths[consumerName]!;

      bool passedForPackage = true;

      void checkDependencies(String depsKey) {
        final Object? deps = consumerYaml[depsKey];
        if (deps is YamlMap) {
          for (final depEntry in deps.entries) {
            final String depName = depEntry.key.toString();

            // Only care about dependencies that exist in our workspace
            if (localPackages.containsKey(depName)) {
              final Object? constraintObj = depEntry.value;
              String constraintStr;

              if (constraintObj is String) {
                constraintStr = constraintObj;
              } else if (constraintObj is YamlMap &&
                  constraintObj.containsKey('version')) {
                constraintStr = constraintObj['version'].toString();
              } else {
                // Either a path dependency or unconstrained, skip
                continue;
              }

              try {
                final VersionConstraint constraint = VersionConstraint.parse(
                  constraintStr,
                );
                final Version actualVersion = localPackages[depName]!;

                if (!constraint.allows(actualVersion)) {
                  _log.severe(
                    '❌ Error in $consumerPath: depends on $depName $constraintStr '
                    'but local version is $actualVersion.',
                  );
                  passedForPackage = false;
                  allPassed = false;
                }
              } on FormatException {
                _log.warning(
                  'Warning: Could not parse constraint "$constraintStr" for dependency $depName in $consumerName.',
                );
              }
            }
          }
        }
      }

      checkDependencies('dependencies');
      checkDependencies('dev_dependencies');

      if (passedForPackage) {
        _log.info(
          '✅ $consumerPath: all internal workspace constraints satisfied.',
        );
      }
    }

    if (!allPassed) {
      _log.severe('\n❌ Workspace version constraint verification failed.');
      _log.severe(
        'Dart workspace resolution will silently fall back to pub.dev if local constraints are not met.',
      );
      _log.severe(
        'Please update the failing constraints to allow the local sibling version.',
      );
      return false;
    }

    _log.info('\n🎉 All workspace version constraints passed successfully!');
    return true;
  }
}
