import 'package:flutter/services.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'catalog/filter_chip_group.dart';
import 'catalog/itinerary_item.dart';
import 'catalog/itinerary_with_details.dart';
import 'catalog/options_filter_chip.dart';
import 'catalog/tabbed_sections.dart';
import 'catalog/travel_carousel.dart';

Future<String> imagesJson() async {
  const imagesPath = 'assets/travel_images';
  var result = await rootBundle.loadString('$imagesPath/.images.json');
  result = result.replaceAll(
    '"image_file_name": "',
    '"image_file_name": "$imagesPath/',
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
