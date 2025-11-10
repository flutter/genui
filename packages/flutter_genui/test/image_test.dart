// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/catalog/core_widgets/image.dart';
import 'package:flutter_genui/src/model/catalog_item.dart';
import 'package:flutter_genui/src/model/data_model.dart';
import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  testWidgets('Image widget renders network image', (
    WidgetTester tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: image.widgetBuilder(
                CatalogItemContext(
                  data: {
                    'url': {
                      'literalString':
                          'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png',
                    },
                  },
                  id: 'test_image',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(DataModel(), '/'),
                  getComponent: (String componentId) => null,
                  surfaceId: 'surface1',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<NetworkImage>());
      expect(
        (imageWidget.image as NetworkImage).url,
        'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png',
      );
    });
  });

  testWidgets('Image widget renders with avatar hint', (
    WidgetTester tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: image.widgetBuilder(
                CatalogItemContext(
                  data: {
                    'url': {'literalString': 'https://example.com/avatar.png'},
                    'hint': 'avatar',
                  },
                  id: 'test_image_avatar',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(DataModel(), '/'),
                  getComponent: (String componentId) => null,
                  surfaceId: 'surface1',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      final sizeBoxFinder = find.ancestor(
        of: find.byType(Image),
        matching: find.byType(SizedBox),
      );
      expect(sizeBoxFinder, findsOneWidget);
      final sizeBox = tester.widget<SizedBox>(sizeBoxFinder);
      expect(sizeBox.width, 48.0);
      expect(sizeBox.height, 48.0);
    });
  });

  testWidgets('Image widget renders with header hint', (
    WidgetTester tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: image.widgetBuilder(
                CatalogItemContext(
                  data: {
                    'url': {'literalString': 'https://example.com/header.png'},
                    'hint': 'header',
                  },
                  id: 'test_image_header',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(DataModel(), '/'),
                  getComponent: (String componentId) => null,
                  surfaceId: 'surface1',
                ),
              ),
            ),
          ),
        ),
      );

      final sizeBoxFinder = find.ancestor(
        of: find.byType(Image),
        matching: find.byType(SizedBox),
      );
      expect(sizeBoxFinder, findsOneWidget);
      final sizeBox = tester.widget<SizedBox>(sizeBoxFinder);
      expect(sizeBox.width, double.infinity);
      expect(sizeBox.height, null);
    });
  });
}
