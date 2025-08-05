import 'package:flutter_genui/flutter_genui.dart';

import 'catalog/filter_chip_group.dart';
import 'catalog/itinerary_item.dart';
import 'catalog/itinerary_with_details.dart';
import 'catalog/options_filter_chip.dart';
import 'catalog/section_header.dart';
import 'catalog/tabbed_sections.dart';
import 'catalog/trailhead.dart';
import 'catalog/travel_carousel.dart';
import 'catalog/travel_icon.dart';

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
  travelIcon,
]);
