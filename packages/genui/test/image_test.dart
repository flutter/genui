// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/catalog/basic_catalog_widgets/image.dart';
import 'package:genui/src/model/catalog_item.dart';
import 'package:genui/src/model/data_model.dart';
import 'package:genui/src/model/ui_models.dart';
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
                  type: 'Image',
                  data: {
                    'url':
                        'https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_horizontal.c823e53b3a1a7b0d36a9.png',
                  },
                  id: 'test_image',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(InMemoryDataModel(), DataPath.root),
                  getComponent: (String componentId) => null,
                  getCatalogItem: (String type) => null,
                  surfaceId: 'surface1',
                  reportError: (e, s) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      final Image imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<NetworkImage>());
      expect(
        (imageWidget.image as NetworkImage).url,
        'https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_horizontal.c823e53b3a1a7b0d36a9.png',
      );
    });
  });

  testWidgets('Image widget renders with avatar usage hint', (
    WidgetTester tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: image.widgetBuilder(
                CatalogItemContext(
                  type: 'Image',
                  data: {
                    'url': 'https://example.com/avatar.png',
                    'variant': 'avatar',
                  },
                  id: 'test_image_avatar',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(InMemoryDataModel(), DataPath.root),
                  getComponent: (String componentId) => null,
                  getCatalogItem: (String type) => null,
                  surfaceId: 'surface1',
                  reportError: (e, s) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      final Finder sizeBoxFinder = find.ancestor(
        of: find.byType(Image),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width == 32.0 &&
              widget.height == 32.0,
        ),
      );
      expect(sizeBoxFinder, findsOneWidget);
      final SizedBox sizeBox = tester.widget<SizedBox>(sizeBoxFinder);
      expect(sizeBox.width, 32.0);
      expect(sizeBox.height, 32.0);
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
                  type: 'Image',
                  data: {
                    'url': 'https://example.com/header.png',
                    'variant': 'header',
                  },
                  id: 'test_image_header',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(InMemoryDataModel(), DataPath.root),
                  getComponent: (String componentId) => null,
                  getCatalogItem: (String type) => null,
                  surfaceId: 'surface1',
                  reportError: (e, s) {},
                ),
              ),
            ),
          ),
        ),
      );

      final Finder sizeBoxFinder = find.ancestor(
        of: find.byType(Image),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width == double.infinity &&
              widget.height == null,
        ),
      );
      expect(sizeBoxFinder, findsOneWidget);
    });
  });

  testWidgets('Image announces its description', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: image.widgetBuilder(
                CatalogItemContext(
                  type: 'Image',
                  data: {
                    'url': 'https://example.com/chart.png',
                    'description': 'Chart of weekly usage',
                  },
                  id: 'test_image_description',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(InMemoryDataModel(), DataPath.root),
                  getComponent: (String componentId) => null,
                  getCatalogItem: (String type) => null,
                  surfaceId: 'surface1',
                  reportError: (e, s) {},
                ),
              ),
            ),
          ),
        ),
      );

      final SemanticsData data = tester
          .getSemantics(find.byType(Image))
          .getSemanticsData();
      expect(data.label, 'Chart of weekly usage');
      // Without the image role a screen reader reads the name and gives no
      // hint that it belongs to a picture.
      expect(data.flagsCollection.isImage, isTrue);

      handle.dispose();
    });
  });

  testWidgets('Image takes its description from the data model', (
    WidgetTester tester,
  ) async {
    await mockNetworkImagesFor(() async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final model = InMemoryDataModel();
      model.update(DataPath('/alt'), 'A bicycle leaning against a wall');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: image.widgetBuilder(
                CatalogItemContext(
                  type: 'Image',
                  data: {
                    'url': 'https://example.com/bike.png',
                    'description': {'path': '/alt'},
                  },
                  id: 'test_image_bound_description',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(model, DataPath.root),
                  getComponent: (String componentId) => null,
                  getCatalogItem: (String type) => null,
                  surfaceId: 'surface1',
                  reportError: (e, s) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(Image)).label,
        'A bicycle leaning against a wall',
      );

      handle.dispose();
    });
  });

  testWidgets('Image without a description announces nothing', (
    WidgetTester tester,
  ) async {
    await mockNetworkImagesFor(() async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: image.widgetBuilder(
                CatalogItemContext(
                  type: 'Image',
                  data: {'url': 'https://example.com/plain.png'},
                  id: 'test_image_plain',
                  buildChild: (_, [_]) => const SizedBox(),
                  dispatchEvent: (UiEvent event) {},
                  buildContext: context,
                  dataContext: DataContext(InMemoryDataModel(), DataPath.root),
                  getComponent: (String componentId) => null,
                  getCatalogItem: (String type) => null,
                  surfaceId: 'surface1',
                  reportError: (e, s) {},
                ),
              ),
            ),
          ),
        ),
      );

      // No name is the honest outcome: there is nothing in an image to infer
      // one from, and inventing one would be worse than silence.
      expect(tester.getSemantics(find.byType(Image)).label, isEmpty);
      expect(find.byType(Image), findsOneWidget);

      handle.dispose();
    });
  });
}
