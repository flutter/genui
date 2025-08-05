import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'catalog/filter_chip_group.dart';
import 'catalog/itinerary_item.dart';
import 'catalog/itinerary_with_details.dart';
import 'catalog/options_filter_chip.dart';
import 'catalog/section_header.dart';
import 'catalog/tabbed_sections.dart';
import 'catalog/trailhead.dart';
import 'catalog/travel_carousel.dart';

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

final catalog = Catalog([
  elevatedButtonCatalogItem,
  columnCatalogItem,
  text,
  checkboxGroup,
  radioGroup,
  textField,
  filterChipGroup,
  optionsFilterChip,
  travelCarousel,
  itineraryWithDetails,
  itineraryItem,
  tabbedSections,
  sectionHeaderCatalogItem,
  trailheadCatalogItem,
  image,
]);
