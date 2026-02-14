// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln(record.message);
  });
  final log = Logger('SchemaValidator');

  final parser = ArgParser()..addOption('schema', abbr: 's', mandatory: true);
  final ArgResults argResults = parser.parse(arguments);

  final schemaFile = File(argResults['schema'] as String);
  if (!schemaFile.existsSync()) {
    log.severe('Error: Schema file not found: ${schemaFile.path}');
    exit(1);
  }

  final schemaJson =
      jsonDecode(schemaFile.readAsStringSync()) as Map<String, Object?>;
  final schema = Schema.fromMap(schemaJson);

  if (argResults.rest.isEmpty) {
    if (argResults.rest.isEmpty) {
      log.info('No JSON files provided to validate.');
      return;
    }
    return;
  }

  for (final String filePath in argResults.rest) {
    final file = File(filePath);
    if (!file.existsSync()) {
      log.severe('Error: JSON file not found: ${file.path}');
      continue;
    }

    log.info('Validating ${file.path}...');
    final String fileContent = file.readAsStringSync();
    final Object? jsonData = jsonDecode(fileContent);

    final List<ValidationError> errors = await schema.validate(jsonData);

    if (errors.isEmpty) {
      log.info('  SUCCESS: ${file.path} is valid.');
    } else {
      log.severe('  FAILURE: ${file.path} is invalid:');
      for (final error in errors) {
        log.severe('    - ${error.toErrorString()}');
      }
    }
  }
}
