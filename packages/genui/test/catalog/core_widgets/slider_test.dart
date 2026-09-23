// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../../test_infra/message_builders.dart';

Future<SurfaceController> _pumpSlider(
  WidgetTester tester, {
  Map<String, Object?> properties = const {},
  double? initialModelValue,
}) async {
  final surfaceController = SurfaceController(
    catalogs: [
      Catalog([BasicCatalogItems.slider], catalogId: 'test_catalog'),
    ],
  );
  const surfaceId = 'testSurface';
  final List<JsonMap> components = [
    component(id: 'root', type: 'Slider', properties: properties),
  ];
  surfaceController.handleMessage(
    updateComponents(surfaceId: surfaceId, components: components),
  );
  surfaceController.handleMessage(
    createSurface(surfaceId: surfaceId, catalogId: 'test_catalog'),
  );
  if (initialModelValue != null && properties['value'] is Map) {
    final path = (properties['value'] as Map)['path'] as String?;
    if (path != null) {
      surfaceController
          .contextFor(surfaceId)
          .dataModel
          .update(DataPath(path), initialModelValue);
    }
  }

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Surface(surfaceContext: surfaceController.contextFor(surfaceId)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return surfaceController;
}

void main() {
  testWidgets('Slider widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final SurfaceController surfaceController = await _pumpSlider(
      tester,
      properties: {
        'value': {'path': '/myValue'},
      },
      initialModelValue: 0.5,
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 0.5);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    expect(
      surfaceController
          .contextFor('testSurface')
          .dataModel
          .getValue<double>(DataPath('/myValue')),
      greaterThan(0.5),
    );
  });

  testWidgets('Slider widget renders label', (WidgetTester tester) async {
    await _pumpSlider(
      tester,
      properties: {
        'value': {'path': '/myValue'},
        'label': 'Volume',
      },
      initialModelValue: 0.5,
    );

    expect(find.text('Volume'), findsOneWidget);
  });

  testWidgets('Slider widget is continuous (divisions is null) by default', (
    WidgetTester tester,
  ) async {
    await _pumpSlider(
      tester,
      properties: {
        'value': {'path': '/myValue'},
      },
      initialModelValue: 0.5,
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.divisions, isNull);
    expect(slider.min, 0.0);
    expect(slider.max, 1.0);
    expect(slider.value, 0.5);
  });

  testWidgets('Slider widget does not crash on sub-unit ranges', (
    WidgetTester tester,
  ) async {
    await _pumpSlider(
      tester,
      properties: {
        'value': {'path': '/myValue'},
        'min': 0.0,
        'max': 0.5,
      },
      initialModelValue: 0.2,
    );

    expect(tester.takeException(), isNull);
    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.divisions, isNull);
    expect(slider.min, 0.0);
    expect(slider.max, 0.5);
    expect(slider.value, 0.2);
  });

  testWidgets(
    'Slider widget applies discrete steps when steps property is specified',
    (WidgetTester tester) async {
      await _pumpSlider(
        tester,
        properties: {
          'value': {'path': '/myValue'},
          'min': 0.0,
          'max': 10.0,
          'steps': 5,
        },
        initialModelValue: 2.0,
      );

      final Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 5);
      expect(slider.min, 0.0);
      expect(slider.max, 10.0);
    },
  );

  testWidgets(
    'Slider widget displays literal value without data model binding',
    (WidgetTester tester) async {
      await _pumpSlider(
        tester,
        properties: {'value': 0.5, 'min': 0.0, 'max': 1.0},
      );

      final Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.5);
      expect(find.text('0.5'), findsOneWidget);
    },
  );

  testWidgets(
    'Slider widget formats whole numbers and decimal numbers correctly',
    (WidgetTester tester) async {
      final SurfaceController controller = await _pumpSlider(
        tester,
        properties: {
          'value': {'path': '/myValue'},
          'min': 0.0,
          'max': 100.0,
        },
        initialModelValue: 10.0,
      );

      // Whole numbers should not display trailing .0
      expect(find.text('10'), findsOneWidget);

      // Decimal numbers should preserve fractional part without trailing zeroes
      controller
          .contextFor('testSurface')
          .dataModel
          .update(DataPath('/myValue'), 0.25);
      await tester.pumpAndSettle();
      expect(find.text('0.25'), findsOneWidget);

      // Sub-unit / high precision values up to 6 decimals should be preserved
      controller
          .contextFor('testSurface')
          .dataModel
          .update(DataPath('/myValue'), 0.005);
      await tester.pumpAndSettle();
      expect(find.text('0.005'), findsOneWidget);
    },
  );

  testWidgets(
    'Slider widget clamps label display when initial value is out of bounds',
    (WidgetTester tester) async {
      await _pumpSlider(
        tester,
        properties: {'value': -5.0, 'min': 0.0, 'max': 10.0},
      );

      final Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.0);
      expect(find.text('0'), findsOneWidget);
    },
  );
}
