// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_genui/flutter_genui.dart';

import 'catalog/information_card.dart';
import 'catalog/input_group.dart';
import 'catalog/itinerary_item.dart';
import 'catalog/itinerary_with_details.dart';
import 'catalog/options_filter_chip_input.dart';
import 'catalog/padded_body_text.dart';
import 'catalog/section_header.dart';
import 'catalog/tabbed_sections.dart';
import 'catalog/text_input_chip.dart';
import 'catalog/trailhead.dart';
import 'catalog/travel_carousel.dart';

/// Defines the collection of UI components that the generative AI model can use
/// to construct the user interface for the travel app.
///
/// This catalog includes a mix of standard widgets (like [column] and [text])
/// and custom, domain-specific widgets tailored for a travel planning
/// experience, such as [travelCarousel], [itineraryItem], and
/// [inputGroup]. The AI selects from these components to build a dynamic
/// and interactive UI in response to user prompts.
final travelAppCatalog = Catalog([
  column,
  inputGroup,
  optionsFilterChipInput,
  travelCarousel,
  itineraryWithDetails,
  itineraryItem,
  tabbedSections,
  sectionHeader,
  trailhead,
  image,
  paddedBodyText,
  textInputChip,
  informationCard,
]);
