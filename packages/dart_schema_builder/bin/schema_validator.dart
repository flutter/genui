// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()..addOption('schema', abbr: 's', mandatory: true);
  final argResults = parser.parse(arguments);

  final schemaFile = File(argResults['schema'] as String);
  if (!schemaFile.existsSync()) {
    print('Error: Schema file not found: ${schemaFile.path}');
    exit(1);
  }

  final schemaJson =
      jsonDecode(schemaFile.readAsStringSync()) as Map<String, Object?>;
  final schema = Schema.fromMap(schemaJson);

  if (argResults.rest.isEmpty) {
    print('No JSON files provided to validate.');
    return;
  }

  for (final filePath in argResults.rest) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('Error: JSON file not found: ${file.path}');
      continue;
    }

    print('Validating ${file.path}...');
    final fileContent = file.readAsStringSync();
    final jsonData = jsonDecode(fileContent);

    final errors = await schema.validate(jsonData);

    if (errors.isEmpty) {
      print('  SUCCESS: ${file.path} is valid.');
    } else {
      print('  FAILURE: ${file.path} is invalid:');
      for (final error in errors) {
        print('    - ${error.toErrorString()}');
      }
    }
  }
}
