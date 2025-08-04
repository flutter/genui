// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/src/catalog.dart';

void main() {
  test(
    '.images.json accurately lists all images in the assets/travel_images directory',
    () async {
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

      final jsonString = await imagesJson();
      final jsonList = json.decode(jsonString) as List;
      final jsonImageFiles =
          jsonList.map((item) => item['image_file_name'] as String).toList()
            ..sort();

      expect(imageFiles, equals(jsonImageFiles));
    },
  );
}
