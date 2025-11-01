// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/catalog/core_widgets/image.dart';
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
                data: {
                  'url': {
                    'literalString':
                        'https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_horizontal.c823e53b3a1a7b0d36a9.png',
                  },
                },
                id: 'test_image',
                buildChild: (_, [_]) => const SizedBox(),
                dispatchEvent: (UiEvent event) {},
                context: context,
                dataContext: DataContext(DataModel(), '/'),
                getComponent: (String componentId) => null,
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
        'https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_horizontal.c823e53b3a1a7b0d36a9.png',
      );
    });
  });
}
