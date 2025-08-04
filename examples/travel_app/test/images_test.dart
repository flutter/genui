import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'images.json accurately lists all images in the assets/travel_images directory',
    () {
      final imageDirectory = Directory('assets/travel_images');
      final imageFiles =
          imageDirectory
              .listSync()
              .where(
                (file) =>
                    file.path.endsWith('.jpg') || file.path.endsWith('.png'),
              )
              .map((file) => file.path.split('/').last)
              .toList()
            ..sort();

      final jsonFile = File('assets/travel_images/.images.json');
      final jsonString = jsonFile.readAsStringSync();
      final jsonList = json.decode(jsonString) as List;
      final jsonImageFiles =
          jsonList.map((item) => item['image_file_name'] as String).toList()
            ..sort();

      expect(imageFiles, equals(jsonImageFiles));
    },
  );
}
