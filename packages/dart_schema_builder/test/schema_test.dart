// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: lines_longer_than_80_chars

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:test/test.dart';

void main() {
  /// Asserts that schema validation produces the expected errors, ignoring
  /// error paths. Expected errors should be defined without path information.
  void expectFailuresMatch(
    Schema schema,
    Object? data,
    List<ValidationErrorType> expectedErrorTypes, {
    String? reason,
    bool strictFormat = false,
  }) async {
    final actualErrors = await schema.validate(
      data,
      strictFormat: strictFormat,
    );
    final actualErrorTypes = actualErrors.map((e) => e.error).toSet();
    expect(
      actualErrorTypes,
      equals(expectedErrorTypes.toSet()),
      reason:
          reason ??
          'Data: $data. Expected (types): $expectedErrorTypes. Actual (types): $actualErrorTypes',
    );
  }

  /// Asserts that schema validation produces the exact expected errors, including error paths.
  void expectFailuresExact(
    Schema schema,
    Object? data,
    List<ValidationError> expectedErrorsWithPaths, {
    String? reason,
    bool strictFormat = false,
  }) async {
    final actualErrors = await schema.validate(
      data,
      strictFormat: strictFormat,
    );
    final actualErrorStrings = actualErrors
        .map((e) => e.toErrorString())
        .toSet();
    final expectedErrorStrings = expectedErrorsWithPaths
        .map((e) => e.toErrorString())
        .toSet();

    expect(
      actualErrorStrings,
      equals(expectedErrorStrings),
      reason:
          reason ??
          'Data: $data. Expected (exact): $expectedErrorStrings. Actual (exact): $actualErrorStrings',
    );
  }

  group('Schema Construction', () {
    test('ObjectSchema with new keywords', () {
      final schema = ObjectSchema(
        dependentRequired: {
          'credit_card': ['billing_address'],
        },
      );
      expect(schema['dependentRequired'], {
        'credit_card': ['billing_address'],
      });
    });

    test('ListSchema with new keywords', () {
      final schema = ListSchema(
        contains: StringSchema(),
        minContains: 1,
        maxContains: 5,
      );
      expect(schema['contains'], isA<StringSchema>());
      expect(schema['minContains'], 1);
      expect(schema['maxContains'], 5);
    });

    test('StringSchema with new keywords', () {
      final schema = StringSchema(format: 'email');
      expect(schema['format'], 'email');
    });

    test('Schema.combined with new keywords', () {
      final schema = Schema.combined(
        ifSchema: StringSchema(),
        thenSchema: StringSchema(minLength: 5),
        elseSchema: IntegerSchema(),
      );
      expect(schema['if'], isA<StringSchema>());
      expect(schema['then'], isA<StringSchema>());
      expect(schema['else'], isA<IntegerSchema>());
    });
  });

  group('Generic Keyword Validation', () {
    test('`const` keyword validation', () {
      final schema = Schema.fromMap({'const': 'hello'});
      expectFailuresMatch(schema, 'world', [ValidationErrorType.constMismatch]);
      expectFailuresMatch(schema, 'hello', []);
    });

    test('`const` with complex object', () {
      final schema = Schema.fromMap({
        'const': {
          'foo': 'bar',
          'baz': [1, 2],
        },
      });
      expectFailuresMatch(
        schema,
        {'foo': 'bar'},
        [ValidationErrorType.constMismatch],
      );
      expectFailuresMatch(schema, {
        'foo': 'bar',
        'baz': [1, 2],
      }, []);
    });

    test('`enum` keyword with various types', () {
      final schema = Schema.fromMap({
        'enum': ['red', 42, true, null],
      });
      expectFailuresMatch(schema, 'blue', [
        ValidationErrorType.enumValueNotAllowed,
      ]);
      expectFailuresMatch(schema, 24, [
        ValidationErrorType.enumValueNotAllowed,
      ]);
      expectFailuresMatch(schema, 'red', []);
      expectFailuresMatch(schema, 42, []);
      expectFailuresMatch(schema, true, []);
      expectFailuresMatch(schema, null, []);
    });

    test('`type` keyword with a list of types', () {
      final schema = Schema.fromMap({
        'type': ['string', 'number'],
      });
      expectFailuresMatch(schema, true, [ValidationErrorType.typeMismatch]);
      expectFailuresMatch(schema, 'hello', []);
      expectFailuresMatch(schema, 123.45, []);
    });
  });

  group('String Format Validation', () {
    test('format: date-time', () {
      final schema = StringSchema(format: 'date-time');
      expectFailuresMatch(
        schema,
        '2025-07-29T12:34:56Z',
        [],
        strictFormat: true,
      );
      expectFailuresMatch(
        schema,
        '2025-07-29T12:34:56.123Z',
        [],
        strictFormat: true,
      );
      expectFailuresMatch(
        schema,
        '2025-07-29T12:34:56+01:00',
        [],
        strictFormat: true,
      );
      expectFailuresMatch(schema, 'not-a-date', [
        ValidationErrorType.formatInvalid,
      ], strictFormat: true);
    });

    test('format: email', () {
      final schema = StringSchema(format: 'email');
      expectFailuresMatch(schema, 'test@example.com', [], strictFormat: true);
      expectFailuresMatch(schema, 'not-an-email', [
        ValidationErrorType.formatInvalid,
      ], strictFormat: true);
    });

    test('format: ipv4', () {
      final schema = StringSchema(format: 'ipv4');
      expectFailuresMatch(schema, '192.168.1.1', [], strictFormat: true);
      expectFailuresMatch(schema, '256.0.0.1', [
        ValidationErrorType.formatInvalid,
      ], strictFormat: true);
      expectFailuresMatch(schema, '1.2.3.4.5', [
        ValidationErrorType.formatInvalid,
      ], strictFormat: true);
    });
  });

  group('Conditional Validation', () {
    test('if/then validation', () {
      final schema = Schema.combined(
        ifSchema: ObjectSchema(
          properties: {'country': StringSchema(constValue: 'USA')},
        ),
        thenSchema: ObjectSchema(
          properties: {'zip_code': StringSchema(pattern: r'^\d{5}$')},
        ),
      );
      // If matches, then must match
      expectFailuresMatch(
        schema,
        {'country': 'USA', 'zip_code': 'abcde'},
        [ValidationErrorType.patternMismatch],
      );
      // If matches, then does match
      expectFailuresMatch(schema, {'country': 'USA', 'zip_code': '12345'}, []);
      // If does not match, then is ignored
      expectFailuresMatch(schema, {
        'country': 'Canada',
        'zip_code': 'abcde',
      }, []);
    });

    test('if/else validation', () {
      final schema = Schema.combined(
        ifSchema: ObjectSchema(
          properties: {'country': StringSchema(constValue: 'USA')},
        ),
        elseSchema: ObjectSchema(
          properties: {
            'zip_code': StringSchema(pattern: r'^[A-Z]\d[A-Z] \d[A-Z]\d$'),
          },
        ),
      );
      // If matches, else is ignored
      expectFailuresMatch(schema, {
        'country': 'USA',
        'zip_code': 'not-a-canadian-postal-code',
      }, []);
      // If does not match, else must match
      expectFailuresMatch(
        schema,
        {'country': 'Canada', 'zip_code': '12345'},
        [ValidationErrorType.patternMismatch],
      );
      // If does not match, else does match
      expectFailuresMatch(schema, {
        'country': 'Canada',
        'zip_code': 'K1A 0B1',
      }, []);
    });

    test('if/then/else validation', () {
      final schema = Schema.combined(
        ifSchema: ObjectSchema(
          properties: {'country': StringSchema(constValue: 'USA')},
        ),
        thenSchema: ObjectSchema(
          properties: {'zip_code': StringSchema(pattern: r'^\d{5}$')},
        ),
        elseSchema: ObjectSchema(
          properties: {
            'zip_code': StringSchema(pattern: r'^[A-Z]\d[A-Z] \d[A-Z]\d$'),
          },
        ),
      );
      // If matches, then fails
      expectFailuresMatch(
        schema,
        {'country': 'USA', 'zip_code': 'K1A 0B1'},
        [ValidationErrorType.patternMismatch],
      );
      // If does not match, else fails
      expectFailuresMatch(
        schema,
        {'country': 'Canada', 'zip_code': '12345'},
        [ValidationErrorType.patternMismatch],
      );
    });
  });

  group('Object Dependent Validation', () {
    test('dependentRequired validation', () {
      final schema = ObjectSchema(
        dependentRequired: {
          'credit_card': ['billing_address'],
        },
      );
      // Dependency key is present, required key is missing
      expectFailuresMatch(
        schema,
        {'credit_card': '1234-5678-9012-3456'},
        [ValidationErrorType.dependentRequiredMissing],
      );
      // Dependency key is present, required key is present
      expectFailuresMatch(schema, {
        'credit_card': '1234-5678-9012-3456',
        'billing_address': '...',
      }, []);
      // Dependency key is not present, so validation is skipped
      expectFailuresMatch(schema, {'name': 'John Doe'}, []);
    });
  });

  group('List Contains Validation', () {
    test('`contains` keyword validation', () {
      final schema = ListSchema(contains: IntegerSchema(minimum: 5));
      expectFailuresMatch(
        schema,
        [1, 2, 3, 4],
        [ValidationErrorType.containsInvalid],
      );
      expectFailuresMatch(schema, [1, 2, 3, 4, 5], []);
    });

    test('`minContains` keyword validation', () {
      final schema = ListSchema(
        contains: IntegerSchema(minimum: 5),
        minContains: 2,
      );
      expectFailuresMatch(
        schema,
        [1, 6, 3, 4],
        [ValidationErrorType.minContainsNotMet],
      );
      expectFailuresMatch(schema, [1, 6, 3, 7], []);
    });

    test('`maxContains` keyword validation', () {
      final schema = ListSchema(
        contains: IntegerSchema(minimum: 5),
        maxContains: 1,
      );
      expectFailuresMatch(
        schema,
        [6, 7, 3, 4],
        [ValidationErrorType.maxContainsExceeded],
      );
      expectFailuresMatch(schema, [1, 6, 3, 4], []);
    });

    test('`contains` without `minContains` defaults to 1', () {
      final schema = ListSchema(contains: IntegerSchema(minimum: 5));
      expectFailuresMatch(
        schema,
        [1, 2, 3],
        [ValidationErrorType.containsInvalid],
      );
    });
  });

  group('Schema Validation Path Tests (Exact Paths)', () {
    test('dependentRequired with correct path', () {
      final schema = ObjectSchema(
        properties: {
          'shipping': ObjectSchema(
            dependentRequired: {
              'address': ['city', 'state'],
            },
          ),
        },
      );
      expectFailuresExact(
        schema,
        {
          'shipping': {'address': '123 Main St'},
        },
        [
          ValidationError(
            ValidationErrorType.dependentRequiredMissing,
            path: ['shipping'],
            details:
                'Property "city" is required because property "address" is present.',
          ),
          ValidationError(
            ValidationErrorType.dependentRequiredMissing,
            path: ['shipping'],
            details:
                'Property "state" is required because property "address" is present.',
          ),
        ],
      );
    });

    test('minContains with correct path', () {
      final schema = ListSchema(
        items: ListSchema(contains: IntegerSchema(minimum: 10), minContains: 2),
      );
      expectFailuresExact(
        schema,
        [
          [5, 15, 2],
        ],
        [
          ValidationError(
            ValidationErrorType.minContainsNotMet,
            path: ['0'],
            details: 'Array must contain at least 2 valid items, but found 1',
          ),
        ],
      );
    });
  });
}
