// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/model/a2ui_schemas.dart';
import 'package:json_schema_builder/src/schema/schema.dart';

void main() {
  group('A2uiSchemas', () {
    test('clientFunctions schema contains pluralize and openUrl', () {
      final Schema schema = A2uiSchemas.clientFunctions();
      final String jsonStr = schema.toJson();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(json['type'], 'array');
      final items = json['items'] as Map<String, dynamic>;
      expect(items['oneOf'], isA<List<dynamic>>());
      final oneOf = items['oneOf'] as List<dynamic>;

      var hasPluralize = false;
      var hasOpenUrl = false;

      for (final item in oneOf) {
        final itemMap = item as Map<String, dynamic>;
        final properties = itemMap['properties'] as Map<String, dynamic>?;
        if (properties != null) {
          final call = properties['call'] as Map<String, dynamic>?;
          if (call != null) {
            final constValue = call['const'] as String?;
            if (constValue == 'pluralize') {
              hasPluralize = true;
            } else if (constValue == 'openUrl') {
              hasOpenUrl = true;
            }
          }
        }
      }

      expect(hasPluralize, isTrue, reason: 'Missing pluralize function');
      expect(hasOpenUrl, isTrue, reason: 'Missing openUrl function');
    });
  });
}
