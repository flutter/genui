// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:genai_primitives/genai_primitives.dart';
import 'package:test/test.dart';

base class CustomPart extends Part {
  final String customField;

  const CustomPart(this.customField);

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'Custom',
      'content': {'customField': customField},
    };
  }

  @override
  bool operator ==(Object other) =>
      other is CustomPart && other.customField == customField;

  @override
  int get hashCode => customField.hashCode;

  @override
  String toString() => 'CustomPart($customField)';
}

class CustomPartConverter extends Converter<Map<String, Object?>, Part> {
  const CustomPartConverter();

  @override
  Part convert(Map<String, Object?> input) {
    if (input['type'] == 'Custom') {
      final content = input['content'] as Map<String, Object?>;
      return CustomPart(content['customField'] as String);
    }
    throw UnimplementedError('Unknown custom part type: ${input['type']}');
  }
}

void main() {
  group('Custom Part Serialization', () {
    test('round trip serialization with custom type', () {
      const originalPart = CustomPart('custom_value');

      // Serialize
      final Map<String, Object?> json = originalPart.toJson();
      expect(json['type'], equals('Custom'));
      expect(
        (json['content'] as Map<String, Object?>)['customField'],
        equals('custom_value'),
      );

      // Deserialize using Part.fromJson with customConverter
      final reconstructedPart = Part.fromJson(
        json,
        converterRegistry: {'Custom': const CustomPartConverter()},
      );

      expect(reconstructedPart, isA<CustomPart>());
      expect(
        (reconstructedPart as CustomPart).customField,
        equals('custom_value'),
      );
      expect(reconstructedPart, equals(originalPart));
    });

    test('Part.fromJson throws UnimplementedError for custom type', () {
      final Map<String, Object> json = {
        'type': 'Custom',
        'content': {'customField': 'val'},
      };

      expect(
        () => Part.fromJson(
          json,
          converterRegistry: defaultPartConverterRegistry,
        ),
        throwsUnimplementedError,
      );
    });

    test('Part.fromJson handles standard types even with custom converter', () {
      const textPart = TextPart('hello');
      final Map<String, Object?> json = textPart.toJson();

      // Should still work for standard parts
      final reconstructed = Part.fromJson(
        json,
        converterRegistry: {
          ...defaultPartConverterRegistry,
          'Custom': const CustomPartConverter(),
        },
      );

      expect(reconstructed, equals(textPart));
    });
  });
}
