// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types, avoid_print

import 'dart:io';

void main() {
  final scriptFile = File(Platform.script.toFilePath());
  final packageDir = scriptFile.parent.parent;
  final repoRoot = packageDir.parent.parent;

  final sourceDir = Directory(
    '${repoRoot.path}/submodules/a2ui/specification/v0_9/json',
  );
  final targetFile = File(
    '${packageDir.path}/lib/src/primitives/embedded_schemas.dart',
  );

  if (!sourceDir.existsSync()) {
    stderr.writeln(
      'Error: Source directory ${sourceDir.path} does not exist.\n'
      'Make sure git submodules are checked out and up to date.',
    );
    exit(1);
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
  buffer.writeln(
    '// To regenerate, run: dart run packages/genui/tool/generate_embedded_schemas.dart',
  );
  buffer.writeln();

  for (final entry in files.entries) {
    final filename = entry.key;
    final variableName = entry.value;
    final sourceFile = File('${sourceDir.path}/$filename');

    if (!sourceFile.existsSync()) {
      stderr.writeln('Error: Source file ${sourceFile.path} not found.');
      exit(1);
    }

    final content = sourceFile.readAsStringSync().trim();
    buffer.writeln('/// Embedded schema contents of \'$filename\'.');
    buffer.writeln('const String $variableName = r\'\'\'');
    buffer.writeln(content);
    buffer.writeln('\'\'\';');
    buffer.writeln();
  }

  targetFile.writeAsStringSync(buffer.toString());
  print('Successfully generated ${targetFile.path}');
}
