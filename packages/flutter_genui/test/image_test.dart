// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/catalog/core_widgets/image.dart';
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
                  'location':
                      'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png',
                },
                id: 'test_image',
                buildChild: (String id) => const SizedBox(),
                dispatchEvent: (UiEvent event) {},
                context: context,
                values: {},
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
}
