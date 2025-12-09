// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:json_schema_builder/src/logging_context.dart';
import 'package:json_schema_builder/src/schema_registry.dart';
import 'package:test/test.dart';

void main() {
  final testSuiteDir = Directory(
    'submodules/JSON-Schema-Test-Suite/tests/draft2020-12',
  );
  final remoteDir = Directory('submodules/JSON-Schema-Test-Suite/remotes');

  // Optional tests are not required to pass for full compliance.
  final optionalTestSuiteDir = Directory('${testSuiteDir.path}/optional');

  final Iterable<File> testFiles = testSuiteDir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>();

  final Iterable<File> optionalTestFiles = optionalTestSuiteDir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>();

  final Set<String> testFilePaths = testFiles.map((f) => f.path).toSet();
  final Set<String> optionalTestFilePaths = optionalTestFiles
      .map((f) => f.path)
      .toSet();

  // Exclude optional tests from the main suite.
  testFilePaths.removeAll(optionalTestFilePaths);

  final schemaRegistry = SchemaRegistry(loggingContext: LoggingContext());
  final Iterable<File> remoteFiles = remoteDir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>();

  for (final file in remoteFiles) {
    final String content = file.readAsStringSync();
    final data = jsonDecode(content) as Map<String, Object?>;
    final schema = Schema.fromMap(data);
    final Uri uri = Uri.parse(
      'http://localhost:1234/${file.path.substring(file.path.indexOf('remotes/') + 8)}',
    );
    schemaRegistry.addSchema(uri, schema);
  }

  for (final File file in testFilePaths.map(File.new)) {
    final String content = file.readAsStringSync();
    final tests = jsonDecode(content) as List;

    for (final Map<String, Object?> testGroup
        in tests.cast<Map<String, Object?>>()) {
      final groupDescription = testGroup['description'] as String;
      final Object? schemaMap = testGroup['schema'];
      final Schema schema;
      if (schemaMap is bool) {
        schema = Schema.fromMap({if (!schemaMap) 'not': {}});
      } else {
        schema = Schema.fromMap(schemaMap as Map<String, Object?>);
      }

      group('$groupDescription - ${file.path}', () {
        final testCases = testGroup['tests'] as List;
        for (final Map<String, Object?> testCase
            in testCases.cast<Map<String, Object?>>()) {
          final testDescription = testCase['description'] as String;
          final Object? data = testCase['data'];
          final expectedValidity = testCase['valid'] as bool;

          test(testDescription, () async {
            final loggingContext = LoggingContext(enabled: true);
            final List<ValidationError> errors = await schema.validate(
              data,
              sourceUri: file.uri,
              schemaRegistry: schemaRegistry,
              loggingContext: loggingContext,
            );
            if (expectedValidity) {
              final String errorString = errors
                  .map<String>((ValidationError e) => e.toErrorString())
                  .join(', ');
              expect(
                errors,
                isEmpty,
                reason:
                    'Expected data to be valid, but got errors: '
                    '$errorString\nLog:\n${loggingContext.buffer}',
              );
            } else {
              expect(
                errors,
                isNotEmpty,
                reason:
                    'Expected data to be invalid, but it was valid.\n'
                    'Log:\n${loggingContext.buffer}',
              );
            }
          });
        }
      });
    }
  }
}
