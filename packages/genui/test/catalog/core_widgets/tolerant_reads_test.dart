// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import '../../test_infra/message_builders.dart';

/// Renders one component and returns whatever it threw, or null.
Future<Object?> renderAndCatch(WidgetTester tester, JsonMap component) async {
  final controller = SurfaceController(
    catalogs: [BasicCatalogItems.asCatalog().copyWith(catalogId: 'tolerant')],
  );
  addTearDown(controller.dispose);
  controller.handleMessage(
    updateComponents(surfaceId: 's', components: [component]),
  );
  controller.handleMessage(
    createSurface(surfaceId: 's', catalogId: 'tolerant'),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Surface(surfaceContext: controller.contextFor('s')),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 20));
  return tester.takeException();
}

void main() {
  group('a property of the wrong type does not take the surface down', () {
    // Everything here is something a model can put on the wire. The schema
    // pins the shape it should have, not the shape it will have.
    const cases = <String, JsonMap>{
      'Slider max as a string': {
        'id': 'root',
        'component': 'Slider',
        'value': 0.5,
        'max': 'ten',
      },
      'Slider max as a list': {
        'id': 'root',
        'component': 'Slider',
        'value': 0.5,
        'max': <Object?>[],
      },
      'Slider max as an unresolved binding': {
        'id': 'root',
        'component': 'Slider',
        'value': 0.5,
        'max': {'path': '/nothing/here'},
      },
      'Slider checks as a string': {
        'id': 'root',
        'component': 'Slider',
        'value': 0.5,
        'checks': 'required',
      },
      'TextField variant as a list': {
        'id': 'root',
        'component': 'TextField',
        'label': 'Name',
        'variant': <Object?>[],
      },
      'TextField variant as a number': {
        'id': 'root',
        'component': 'TextField',
        'label': 'Name',
        'variant': 42,
      },
      'DateTimeInput value as a number': {
        'id': 'root',
        'component': 'DateTimeInput',
        'value': 42,
      },
      'DateTimeInput value as a list': {
        'id': 'root',
        'component': 'DateTimeInput',
        'value': <Object?>[],
      },
      'DateTimeInput enableDate as a string': {
        'id': 'root',
        'component': 'DateTimeInput',
        'value': '2026-01-15',
        'enableDate': 'yes',
      },
      'Tabs tabs as a string': {
        'id': 'root',
        'component': 'Tabs',
        'tabs': 'one',
      },
      'Tabs tabs as a number': {'id': 'root', 'component': 'Tabs', 'tabs': 7},
      'Tabs with no tabs at all': {'id': 'root', 'component': 'Tabs'},
      'Tabs with an empty list': {
        'id': 'root',
        'component': 'Tabs',
        'tabs': <Object?>[],
      },
      'Tabs with a tab that names no content': {
        'id': 'root',
        'component': 'Tabs',
        'tabs': [
          {'label': 'One'},
        ],
      },
    };

    cases.forEach((name, component) {
      testWidgets(name, (tester) async {
        expect(await renderAndCatch(tester, component), isNull);
      });
    });
  });

  group('a property of the right type still works', () {
    testWidgets('Slider keeps its range', (tester) async {
      expect(
        await renderAndCatch(tester, {
          'id': 'root',
          'component': 'Slider',
          'value': 5,
          'min': 0,
          'max': 10,
        }),
        isNull,
      );
      expect(find.byType(Slider), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).max, 10);
    });

    testWidgets('Tabs still builds the tabs it was given', (tester) async {
      expect(
        await renderAndCatch(tester, {
          'id': 'root',
          'component': 'Tabs',
          'tabs': [
            {'label': 'One', 'content': 'c1'},
          ],
        }),
        isNull,
      );
      expect(find.text('One'), findsOneWidget);
    });
  });
}
