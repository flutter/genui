// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/catalog.dart';
import '../model/catalog_item.dart';
import 'core_widgets/audio_player.dart' as audio_player_item;
import 'core_widgets/button.dart' as button_item;
import 'core_widgets/card.dart' as card_item;
import 'core_widgets/check_box.dart' as check_box_item;
import 'core_widgets/column.dart' as column_item;
import 'core_widgets/date_time_input.dart' as date_time_input_item;
import 'core_widgets/divider.dart' as divider_item;
import 'core_widgets/heading.dart' as heading_item;
import 'core_widgets/image.dart' as image_item;
import 'core_widgets/list.dart' as list_item;
import 'core_widgets/modal.dart' as modal_item;
import 'core_widgets/multiple_choice.dart' as multiple_choice_item;
import 'core_widgets/row.dart' as row_item;
import 'core_widgets/slider.dart' as slider_item;
import 'core_widgets/tabs.dart' as tabs_item;
import 'core_widgets/text.dart' as text_item;
import 'core_widgets/text_field.dart' as text_field_item;
import 'core_widgets/video.dart' as video_item;

/// A collection of standard catalog items that can be used to build simple
/// interactive UIs.
class CoreCatalogItems {
  CoreCatalogItems._();

  /// A placeholder for an audio player.
  static final CatalogItem audioPlayer = audio_player_item.audioPlayer;

  /// A material design elevated button.
  static final CatalogItem button = button_item.button;

  /// A material design card.
  static final CatalogItem card = card_item.card;

  /// A material design checkbox.
  static final CatalogItem checkBox = check_box_item.checkBox;

  /// A widget that displays its children in a vertical array.
  static final CatalogItem column = column_item.column;

  /// A material design date/time input.
  static final CatalogItem dateTimeInput = date_time_input_item.dateTimeInput;

  /// A material design divider.
  static final CatalogItem divider = divider_item.divider;

  /// A heading.
  static final CatalogItem heading = heading_item.heading;

  /// A widget that displays an image.
  static final CatalogItem image = image_item.image;

  /// A list of widgets.
  static final CatalogItem list = list_item.list;

  /// A modal bottom sheet.
  static final CatalogItem modal = modal_item.modal;

  /// A multiple choice widget.
  static final CatalogItem multipleChoice = multiple_choice_item.multipleChoice;

  /// A widget that displays its children in a horizontal array.
  static final CatalogItem row = row_item.row;

  /// A material design slider.
  static final CatalogItem slider = slider_item.slider;

  /// A material design tab bar.
  static final CatalogItem tabs = tabs_item.tabs;

  /// A string of text.
  static final CatalogItem text = text_item.text;

  /// A material design text field.
  static final CatalogItem textField = text_field_item.textField;

  /// A placeholder for a video player.
  static final CatalogItem video = video_item.video;

  /// Creates a catalog containing all core catalog items.
  static Catalog asCatalog() {
    return Catalog([
      audioPlayer,
      button,
      card,
      checkBox,
      column,
      dateTimeInput,
      divider,
      heading,
      image,
      list,
      modal,
      multipleChoice,
      row,
      slider,
      tabs,
      text,
      textField,
      video,
    ]);
  }
}
