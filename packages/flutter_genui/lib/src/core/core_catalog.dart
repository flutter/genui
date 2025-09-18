// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../catalog/core_widgets/checkbox_group.dart' as checkbox_group_item;
import '../catalog/core_widgets/column.dart' as column_item;
import '../catalog/core_widgets/elevated_button.dart' as elevated_button_item;
import '../catalog/core_widgets/image.dart' as image_item;
import '../catalog/core_widgets/radio_group.dart' as radio_group_item;
import '../catalog/core_widgets/text.dart' as text_item;
import '../catalog/core_widgets/text_field.dart' as text_field_item;
import '../model/catalog.dart';
import '../model/catalog_item.dart';

/// A collection of standard catalog items that can be used to build simple
/// interactive UIs.
class CoreCatalogItems {
  CoreCatalogItems._();

  /// A material design elevated button.
  static final CatalogItem elevatedButton = elevated_button_item.elevatedButton;

  /// A widget that displays its children in a vertical array.
  static final CatalogItem column = column_item.column;

  /// A string of text.
  static final CatalogItem text = text_item.text;

  /// A group of checkboxes.
  static final CatalogItem checkboxGroup = checkbox_group_item.checkboxGroup;

  /// A group of radio buttons.
  static final CatalogItem radioGroup = radio_group_item.radioGroup;

  /// A material design text field.
  static final CatalogItem textField = text_field_item.textField;

  /// A widget that displays an image.
  static final CatalogItem image = image_item.image;

  /// Creates a catalog containing all core catalog items.
  static Catalog asCatalog() {
    return Catalog([
      elevatedButton,
      column,
      text,
      checkboxGroup,
      radioGroup,
      textField,
      image,
    ]);
  }
}
