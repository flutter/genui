import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@visibleForTesting
const assetImageCatalogPath = 'assets/travel_images';
@visibleForTesting
const assetImageCatalogJsonFile = '$assetImageCatalogPath/.images.json';

Future<String> assetImageCatalogJson() async {
  var result = await rootBundle.loadString(assetImageCatalogJsonFile);
  result = result.replaceAll(
    '"image_file_name": "',
    '"image_file_name": "$assetImageCatalogPath/',
  );
  return result;
}
