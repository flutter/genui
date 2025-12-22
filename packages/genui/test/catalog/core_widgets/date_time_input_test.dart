// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('renders and handles explicit updates', (tester) async {
    final robot = DateTimeInputRobot(tester);
    final (GenUiHost manager, String surfaceId) = setup('datetime', {
      'value': {'path': '/myDateTime'},
      'enableTime': false,
    });

    manager
        .dataModelForSurface(surfaceId)
        .update(DataPath('/myDateTime'), '2025-10-15');

    await robot.pumpSurface(manager, surfaceId);

    robot.expectInputText('datetime', 'Wednesday, October 15, 2025');
  });

  testWidgets('displays correct placeholder/initial text based on mode', (
    tester,
  ) async {
    final robot = DateTimeInputRobot(tester);

    var (GenUiHost manager, String surfaceId) = setup('datetime_default', {
      'value': {'path': '/myDateTimeDefault'},
    });
    await robot.pumpSurface(manager, surfaceId);
    robot.expectInputText('datetime_default', 'Select a date and time');

    (manager, surfaceId) = setup('datetime_date_only', {
      'value': {'path': '/myDateOnly'},
      'enableTime': false,
    });
    await robot.pumpSurface(manager, surfaceId);
    robot.expectInputText('datetime_date_only', 'Select a date');

    (manager, surfaceId) = setup('datetime_time_only', {
      'value': {'path': '/myTimeOnly'},
      'enableDate': false,
    });
    await robot.pumpSurface(manager, surfaceId);
    robot.expectInputText('datetime_time_only', 'Select a time');
  });

  group('combined mode', () {
    testWidgets('aborts update when time picker is cancelled', (tester) async {
      final robot = DateTimeInputRobot(tester);
      final (GenUiHost manager, String surfaceId) = setup('combined_mode', {
        'value': {'path': '/myDateTime'},
      });

      manager
          .dataModelForSurface(surfaceId)
          .update(DataPath('/myDateTime'), '2022-01-01T14:30:00');

      await robot.pumpSurface(manager, surfaceId);

      await robot.openPicker('combined_mode');
      await robot.selectDate('15');

      robot.expectTimePickerVisible();
      await robot.cancelPicker();

      final String? value = manager
          .dataModelForSurface(surfaceId)
          .getValue<String>(DataPath('/myDateTime'));
      expect(value, equals('2022-01-01T14:30:00'));
    });
  });

  group('time only mode', () {
    testWidgets('aborts when time picker is cancelled', (tester) async {
      final robot = DateTimeInputRobot(tester);
      final (GenUiHost manager, String surfaceId) = setup('time_only_mode', {
        'value': {'path': '/myTime'},
        'enableDate': false,
      });

      await robot.pumpSurface(manager, surfaceId);

      await robot.openPicker('time_only_mode');
      robot.expectTimePickerVisible();
      await robot.cancelPicker();

      final String? value = manager
          .dataModelForSurface(surfaceId)
          .getValue<String>(DataPath('/myTime'));
      expect(value, isNull);
    });

    testWidgets('parses initial value correctly', (tester) async {
      final robot = DateTimeInputRobot(tester);
      final (GenUiHost manager, String surfaceId) = setup('time_only_parsing', {
        'value': {'path': '/myTimeProp'},
        'enableDate': false,
      });

      manager
          .dataModelForSurface(surfaceId)
          .update(DataPath('/myTimeProp'), '14:32:00');

      await robot.pumpSurface(manager, surfaceId);

      await robot.openPicker('time_only_parsing');

      robot.expectPickerText('32');

      await robot.cancelPicker();
    });
  });

  group('date only mode', () {
    testWidgets('updates immediately with date-only string after '
        'date selection', (tester) async {
      final robot = DateTimeInputRobot(tester);
      final (GenUiHost manager, String surfaceId) = setup('date_only_mode', {
        'value': {'path': '/myDate'},
        'enableTime': false,
      });

      manager
          .dataModelForSurface(surfaceId)
          .update(DataPath('/myDate'), '2022-01-01');

      await robot.pumpSurface(manager, surfaceId);

      await robot.openPicker('date_only_mode');
      await robot.selectDate('20');

      final String? value = manager
          .dataModelForSurface(surfaceId)
          .getValue<String>(DataPath('/myDate'));
      expect(value, isNotNull);
      // Verify that no time is included in the value.
      expect(value, equals('2022-01-20'));
      robot.expectInputText('date_only_mode', 'Thursday, January 20, 2022');

      robot.expectTimePickerHidden();
    });
  });

  group('date range configuration', () {
    testWidgets('respects custom firstDate and lastDate', (tester) async {
      final robot = DateTimeInputRobot(tester);
      final (GenUiHost manager, String surfaceId) = setup('custom_range', {
        'value': {'path': '/myDate'},
        'firstDate': '2020-01-01',
        'lastDate': '2030-12-31',
      });

      await robot.pumpSurface(manager, surfaceId);

      await robot.openPicker('custom_range');

      final DatePickerDialog dialog = tester.widget(
        find.byType(DatePickerDialog),
      );
      expect(dialog.firstDate, DateTime(2020));
      expect(dialog.lastDate, DateTime(2030, 12, 31));

      await robot.cancelPicker();
    });

    testWidgets('defaults to -9999 to 9999 when not specified', (tester) async {
      final robot = DateTimeInputRobot(tester);
      final (GenUiHost manager, String surfaceId) = setup('default_range', {
        'value': {'path': '/myDate'},
      });

      await robot.pumpSurface(manager, surfaceId);
      await robot.openPicker('default_range');

      final DatePickerDialog dialog = tester.widget(
        find.byType(DatePickerDialog),
      );
      expect(dialog.firstDate, DateTime(-9999));
      expect(dialog.lastDate, DateTime(9999, 12, 31));

      await robot.cancelPicker();
    });
  });
}

(GenUiHost, String) setup(String componentId, Map<String, dynamic> props) {
  final catalog = Catalog([
    CoreCatalogItems.dateTimeInput,
  ], catalogId: 'test_catalog');

  final manager = A2uiMessageProcessor(catalogs: [catalog]);
  const surfaceId = 'testSurface';

  final components = [
    Component(id: componentId, componentProperties: {'DateTimeInput': props}),
  ];

  manager.handleMessage(
    SurfaceUpdate(surfaceId: surfaceId, components: components),
  );
  manager.handleMessage(
    BeginRendering(
      surfaceId: surfaceId,
      root: componentId,
      catalogId: 'test_catalog',
    ),
  );

  return (manager, surfaceId);
}

class DateTimeInputRobot {
  final WidgetTester tester;

  DateTimeInputRobot(this.tester);

  Future<void> pumpSurface(GenUiHost manager, String surfaceId) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPicker(String componentId) async {
    await tester.tap(find.byKey(Key(componentId)));
    await tester.pumpAndSettle();
  }

  Future<void> selectDate(String day) async {
    await tester.tap(find.text(day));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> cancelPicker() async {
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  }

  void expectInputText(String componentId, String text) {
    final Finder finder = find.byKey(Key('${componentId}_text'));
    expect(finder, findsOneWidget);
    final String actualText = tester.widget<Text>(finder).data!;
    if (actualText != text) {
      print('EXPECTATION FAILED: Expected "$text", found "$actualText"');
    }
    expect(actualText, text);
  }

  void expectPickerText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  void expectTimePickerVisible() {
    expect(find.text('Select time'), findsOneWidget);
  }

  void expectTimePickerHidden() {
    expect(find.text('Select time'), findsNothing);
  }
}
