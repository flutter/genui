// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/data_type_validator.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataTypeValidator', () {
    late DataTypeValidator validator;
    late WidgetCatalog catalog;

    setUp(() {
      validator = DataTypeValidator();
      catalog = WidgetCatalog({
        'catalogVersion': '1.0.0',
        'items': <String, Object?>{},
        'dataTypes': {
          'user': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'email': {'type': 'string', 'format': 'email'},
              'age': {'type': 'integer'},
            },
            'required': ['name', 'email'],
          },
        },
      });
    });

    test('returns true for valid data', () {
      final data = {'name': 'Alice', 'email': 'alice@example.com', 'age': 30};
      final isValid = validator.validate(
        dataType: 'user',
        data: data,
        catalog: catalog,
      );
      expect(isValid, isTrue);
    });

    test('returns false for invalid data (missing required property)', () {
      final data = {'age': 30};
      final isValid = validator.validate(
        dataType: 'user',
        data: data,
        catalog: catalog,
      );
      expect(isValid, isFalse);
    });

    test('returns false for invalid data (wrong type)', () {
      final data = {
        'name': 'Alice',
        'email': 'alice@example.com',
        'age': 'thirty',
      };
      final isValid = validator.validate(
        dataType: 'user',
        data: data,
        catalog: catalog,
      );
      expect(isValid, isFalse);
    });

    test('returns false for invalid data (wrong format)', () {
      final data = {'name': 'Alice', 'email': 'not-an-email'};
      final isValid = validator.validate(
        dataType: 'user',
        data: data,
        catalog: catalog,
      );
      expect(isValid, isFalse);
    });

    test('returns true for a data type not in the catalog', () {
      final data = {'any': 'data'};
      final isValid = validator.validate(
        dataType: 'unknown_type',
        data: data,
        catalog: catalog,
      );
      expect(isValid, isTrue);
    });
    test('returns true when dataTypes map is empty', () {
      catalog = WidgetCatalog({
        'catalogVersion': '1.0.0',
        'items': <String, Object?>{},
        'dataTypes': <String, Object?>{},
      });
      final data = {'any': 'data'};
      final isValid = validator.validate(
        dataType: 'user',
        data: data,
        catalog: catalog,
      );
      expect(isValid, isTrue);
    });
  });
}
