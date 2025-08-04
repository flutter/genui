import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/image.dart';

import 'utils.dart';

void main() {
  testWidgets('Image builds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      testCatalogItem(
        image,
        {
          'source': 'assets/travel_images/paris.jpg',
          'width': 100.0,
          'height': 100.0,
          'fit': 'cover',
        },
      ),
    );

    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.width, 100.0);
    expect(imageWidget.height, 100.0);
    expect(imageWidget.fit, BoxFit.cover);
    expect(
      (imageWidget.image as AssetImage).assetName,
      'assets/travel_images/paris.jpg',
    );
  });
}