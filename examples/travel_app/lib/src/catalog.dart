import 'package:flutter/services.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'catalog/filter_chip_group.dart';
import 'catalog/itinerary_item.dart';
import 'catalog/itinerary_with_details.dart';
import 'catalog/options_filter_chip.dart';
import 'catalog/tabbed_sections.dart';
import 'catalog/travel_carousel.dart';

const imagesCatalogPath = 'assets/travel_images';
const imagesCatalogJsonFile = '$imagesCatalogPath/.images.json';

Future<String> imagesCatalogJson() async {
  var result = await rootBundle.loadString(imagesCatalogJsonFile);
  result = result.replaceAll(
    '"image_file_name": "',
    '"image_file_name": "$imagesCatalogPath/',
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
  image,
]);
