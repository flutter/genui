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
import 'core_widgets/icon.dart' as icon_item;
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

  /// Represents a UI element for playing audio content.
  ///
  /// This typically includes controls like play/pause, seek, and volume.
  static final CatalogItem audioPlayer = audio_player_item.audioPlayer;

  /// Represents an interactive button that triggers an action when pressed.
  ///
  /// Conforms to Material Design guidelines for elevated buttons.
  static final CatalogItem button = button_item.button;

  /// Represents a Material Design card, a container for related information and
  /// actions.
  ///
  /// Often used to group content visually.
  static final CatalogItem card = card_item.card;

  /// Represents a checkbox that allows the user to toggle a boolean state.
  static final CatalogItem checkBox = check_box_item.checkBox;

  /// Represents a layout widget that arranges its children in a vertical
  /// sequence.
  static final CatalogItem column = column_item.column;

  /// Represents a widget for selecting a date and/or time.
  static final CatalogItem dateTimeInput = date_time_input_item.dateTimeInput;

  /// Represents a thin horizontal line used to separate content.
  static final CatalogItem divider = divider_item.divider;

  /// An icon.
  static final CatalogItem icon = icon_item.icon;

  /// Represents a UI element for displaying image data from a URL or other
  /// source.
  static final CatalogItem image = image_item.image;

  /// Represents a UI element for displaying image data from a URL or other
  /// source without letting the LLM determine the size.
  ///
  /// This is not included in the core catalog by default - instead it is a
  /// variant of a core catalog item that can be included in custom catalogs.
  static final CatalogItem imageFixedSize = image_item.imageFixedSize;

  /// Represents a scrollable list of child widgets.
  ///
  /// Can be configured to lay out items linearly.
  static final CatalogItem list = list_item.list;

  /// Represents a modal overlay that slides up from the bottom of the screen.
  ///
  /// Used to present a set of options or a piece of content requiring user
  /// interaction.
  static final CatalogItem modal = modal_item.modal;

  /// Represents a widget allowing the user to select one or more options from a
  /// list.
  static final CatalogItem multipleChoice = multiple_choice_item.multipleChoice;

  /// Represents a layout widget that arranges its children in a horizontal
  /// sequence.
  static final CatalogItem row = row_item.row;

  /// Represents a slider control for selecting a value from a range.
  static final CatalogItem slider = slider_item.slider;

  /// Represents a set of tabs for navigating between different views or
  /// sections.
  static final CatalogItem tabs = tabs_item.tabs;

  /// Represents a block of styled text.
  static final CatalogItem text = text_item.text;

  /// Represents an input field where the user can enter text.
  static final CatalogItem textField = text_field_item.textField;

  /// Represents a UI element for playing video content.
  ///
  /// This typically includes controls like play/pause, seek, and volume.
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
      icon,
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
