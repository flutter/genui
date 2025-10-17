// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_client/src/models/component.dart';
import 'package:a2ui_client/src/widgets/component_properties_visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('ComponentPropertiesVisitor', () {
    late FakeA2uiInterpreter fakeInterpreter;
    late ComponentPropertiesVisitor visitor;

    setUp(() {
      fakeInterpreter = FakeA2uiInterpreter();
      visitor = ComponentPropertiesVisitor(fakeInterpreter);
    });

    test('visit TextProperties with literal value', () {
      const properties = TextProperties(
        text: BoundValue(literalString: 'Hello'),
      );
      final result = visitor.visit(properties, null);
      expect(result, {'text': 'Hello'});
    });

    test('visit TextProperties with bound value', () {
      fakeInterpreter.onResolveDataBinding('path.to.text', 'World');
      const properties = TextProperties(text: BoundValue(path: 'path.to.text'));
      final result = visitor.visit(properties, null);
      expect(result, {'text': 'World'});
    });

    test('visit HeadingProperties', () {
      const properties = HeadingProperties(
        text: BoundValue(literalString: 'Title'),
        level: 'h1',
      );
      final result = visitor.visit(properties, null);
      expect(result, {'text': 'Title', 'level': 'h1'});
    });
  });
}
