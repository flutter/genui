// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types

import 'dart:io';
import 'package:build/build.dart';

Builder schemaBuilder(BuilderOptions options) => SchemaBuilder();

class SchemaBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    'pubspec.yaml': ['lib/src/primitives/embedded_schemas.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Find repository root by traversing upwards until we find .gitmodules.
    Directory dir = Directory.current;
    while (dir.path != dir.parent.path) {
      if (File('${dir.path}/.gitmodules').existsSync()) {
        break;
      }
      dir = dir.parent;
    }
    final repoRoot = dir;
    final sourceDir = Directory(
      '${repoRoot.path}/submodules/a2ui/specification/v0_9/json',
    );

    if (!sourceDir.existsSync()) {
      throw StateError(
        'A2UI specification submodule not found at ${sourceDir.path}.\n'
        'Please initialize git submodules by running:\n'
        '  git submodule update --init --recursive\n'
        'and then rebuild.',
      );
    }

    final files = {
      'common_types.json': 'commonTypesSchemaJson',
      'server_to_client.json': 'serverToClientSchemaJson',
    };

    final buffer = StringBuffer();
    buffer.writeln('// Copyright 2025 The Flutter Authors.');
    buffer.writeln(
      '// Use of this source code is governed by a BSD-style license that can be',
    );
    buffer.writeln('// found in the LICENSE file.');
    buffer.writeln();
    buffer.writeln('// GENERATED FILE. DO NOT EDIT MANUALLY.');
    buffer.writeln('// To regenerate, run: dart run build_runner build');
    buffer.writeln();

    for (final entry in files.entries) {
      final filename = entry.key;
      final variableName = entry.value;
      final sourceFile = File('${sourceDir.path}/$filename');

      if (!sourceFile.existsSync()) {
        log.warning('Source file ${sourceFile.path} not found.');
        return;
      }

      final content = sourceFile.readAsStringSync().trim();
      buffer.writeln('/// Embedded schema contents of \'$filename\'.');
      buffer.writeln('const String $variableName = r\'\'\'');
      buffer.writeln(content);
      buffer.writeln('\'\'\';');
      buffer.writeln();
    }

    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/src/primitives/embedded_schemas.g.dart',
    );
    await buildStep.writeAsString(outputId, buffer.toString());
  }
}
