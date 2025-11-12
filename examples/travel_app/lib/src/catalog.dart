// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genui/genui.dart';

import 'catalog/checkbox_filter_chips_input.dart';
import 'catalog/date_input_chip.dart';
import 'catalog/information_card.dart';
import 'catalog/input_group.dart';
import 'catalog/itinerary.dart';
import 'catalog/listings_booker.dart';
import 'catalog/options_filter_chip_input.dart';
import 'catalog/tabbed_sections.dart';
import 'catalog/text_input_chip.dart';
import 'catalog/trailhead.dart';
import 'catalog/travel_carousel.dart';

/// Defines the collection of UI components that the generative AI model can use
/// to construct the user interface for the travel app.
///
/// This catalog includes a mix of core widgets (like [CoreCatalogItems.column]
/// and [CoreCatalogItems.text]) and custom, domain-specific widgets tailored
/// for a travel planning experience, such as [travelCarousel], [itinerary],
/// and [inputGroup]. The AI selects from these components to build a dynamic
/// and interactive UI in response to user prompts.
final Catalog travelAppCatalog = CoreCatalogItems.asCatalog()
    .copyWithout([
      CoreCatalogItems.audioPlayer,
      CoreCatalogItems.card,
      CoreCatalogItems.checkBox,
      CoreCatalogItems.dateTimeInput,
      CoreCatalogItems.divider,
      CoreCatalogItems.textField,
      CoreCatalogItems.list,
      CoreCatalogItems.modal,
      CoreCatalogItems.multipleChoice,
      CoreCatalogItems.slider,
      CoreCatalogItems.tabs,
      CoreCatalogItems.video,
    ])
    .copyWith([
      checkboxFilterChipsInput,
      dateInputChip,
      informationCard,
      inputGroup,
      itinerary,
      listingsBooker,
      optionsFilterChipInput,
      tabbedSections,
      textInputChip,
      trailhead,
      travelCarousel,
    ]);
