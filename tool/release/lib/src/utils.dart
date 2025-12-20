// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const excludedPackages = ['json_schema_builder', 'genai_primitives'];

Future<List<Directory>> findPackages(
  Directory repoRoot,
  Printer printer,
) async {
  final Directory packagesDir = repoRoot.childDirectory('packages');
  if (!await packagesDir.exists()) {
    printer('Error: packages directory not found at ${packagesDir.path}');
    return [];
  }

  final packages = <Directory>[];
  await for (final FileSystemEntity entity in packagesDir.list()) {
    if (entity is Directory) {
      final String packageName = p.basename(entity.path);
      if (excludedPackages.contains(packageName)) {
        printer('Skipping excluded package: $packageName');
        continue;
      }
      final File pubspecFile = entity.childFile('pubspec.yaml');
      if (await pubspecFile.exists()) {
        packages.add(entity);
      }
    }
  }
  return packages;
}

Future<String> getPackageVersion(Directory packageDir) async {
  final File pubspecFile = packageDir.childFile('pubspec.yaml');
  final String content = await pubspecFile.readAsString();
  final yamlMap = loadYaml(content) as Map;
  return yamlMap['version'] as String;
}

typedef Printer = void Function(String message);
