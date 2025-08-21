// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

/// Defines the collection of UI components that the generative AI model can use
/// to construct the user interface for the travel app.
///
/// This catalog includes a mix of standard widgets (like [column] and [text])
/// and custom, domain-specific widgets tailored for a travel planning
/// experience, such as [travelCarousel], [itineraryItem], and
/// [filterChipGroup]. The AI selects from these components to build a dynamic
/// and interactive UI in response to user prompts.
final catalog = Catalog([
  elevatedButton,
  column,
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
  sectionHeader,
  trailhead,
  image,
  travelIcon,
]);
