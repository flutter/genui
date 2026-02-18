// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui/src/functions/functions.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:logging/logging.dart';

void main() {
  group('Error Reporting Tests', () {
    late Logger logger;
    late List<LogRecord> logs;

    setUp(() {
      logs = [];
      hierarchicalLoggingEnabled = true;
      logger = Logger('genui');
      logger.level = Level.ALL;
      logger.onRecord.listen((record) => logs.add(record));
    });

    test(
      'A2uiMessage.fromJson throws A2uiValidationException for unknown message '
      'type',
      () {
        final json = <String, Object?>{
          'version': 'v0.9',
          'unknownAction': <String, Object?>{},
        };

        try {
          A2uiMessage.fromJson(json);
          fail('Should have thrown A2uiValidationException');
        } on A2uiValidationException catch (e) {
          expect(e.message, contains('Unknown A2UI message type'));
        }
      },
    );

    testWidgets('Surface reports error when catalog item is missing', (
      tester,
    ) async {
      final dataModel = DataModel();
      final context = MockSurfaceContext('test_surface', dataModel);

      final definition = SurfaceDefinition(
        surfaceId: 'test_surface',
        catalogId: 'test_catalog',
        components: {
          'root': const Component(
            id: 'root',
            type: 'NonExistentComponent',
            properties: {},
          ),
        },
      );

      context.updateDefinition(definition);

      await tester.pumpWidget(
        MaterialApp(home: Surface(surfaceContext: context)),
      );

      // Should show FallbackWidget
      expect(find.byType(FallbackWidget), findsOneWidget);
      expect(context.reportedErrors, isNotEmpty);
      expect(
        context.reportedErrors.first.toString(),
        contains('NonExistentComponent'),
      );
    });

    testWidgets('Surface reports error when FunctionRegistry throws', (
      tester,
    ) async {
      // Register a failing function
      FunctionRegistry().register('failFunc', (args) {
        throw Exception('Function failed explicitly');
      });

      final dataModel = DataModel();
      final context = MockSurfaceContext('test_surface', dataModel);

      final definition = SurfaceDefinition(
        surfaceId: 'test_surface',
        catalogId: 'test_catalog',
        components: {
          'root': const Component(
            id: 'root',
            type: 'Text',
            properties: <String, Object?>{
              'text': {'call': 'failFunc', 'args': <String, Object?>{}},
            },
          ),
        },
      );

      context.updateDefinition(definition);

      await tester.pumpWidget(
        MaterialApp(home: Surface(surfaceContext: context)),
      );

      // Verify FallbackWidget and reported error
      expect(find.byType(FallbackWidget), findsOneWidget);
      expect(context.reportedErrors, isNotEmpty);
      expect(
        context.reportedErrors.first.toString(),
        contains('Function failed explicitly'),
      );
    });

    testWidgets('FunctionRegistry._regex throws on invalid regex', (
      tester,
    ) async {
      // We can test this directly via FunctionRegistry
      // 'regex' function: { 'value': 'foo', 'pattern': '(' } -> Should throw

      final registry = FunctionRegistry();
      try {
        registry.invoke('regex', {'value': 'foo', 'pattern': '('});
        fail('Should have thrown FormatException or similar');
      } catch (e) {
        expect(e.toString(), contains('Invalid regex pattern'));
      }
    });
  });
}

class MockSurfaceContext implements SurfaceContext {
  MockSurfaceContext(this.surfaceId, this.dataModel);

  @override
  final String surfaceId;

  @override
  final DataModel dataModel;

  final ValueNotifier<SurfaceDefinition?> _definition = ValueNotifier(null);

  @override
  ValueListenable<SurfaceDefinition?> get definition => _definition;

  void updateDefinition(SurfaceDefinition def) {
    _definition.value = def;
  }

  @override
  Catalog? get catalog => _testCatalog;

  final List<Object> reportedErrors = [];

  @override
  void reportError(Object error, StackTrace? stack) {
    reportedErrors.add(error);
  }

  @override
  void handleUiEvent(UiEvent event) {}
}

// Minimal catalog for testing
final Catalog _testCatalog = Catalog(catalogId: 'test_catalog', [
  CatalogItem(
    name: 'Text',
    dataSchema: S.object(),
    widgetBuilder: (ctx) {
      try {
        final Object? text = (ctx.data as Map<String, Object?>?)?['text'];
        if (text is Map && text.containsKey('call')) {
          FunctionRegistry().invoke(
            text['call'] as String,
            (text['args'] as Map<String, Object?>?) ?? {},
          );
        }
      } catch (e) {
        rethrow;
      }
      return const Text('Placeholder');
    },
  ),
]);
