// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'name': A2uiSchemas.stringReference(
      description:
          '''The name of the icon to display. This can be a literal string ('literalString') or a reference to a value in the data model ('path', e.g. '/icon/name').''',
      enumValues: AvailableIcons.allAvailable,
    ),
  },
  required: ['name'],
);

extension type _IconData.fromMap(JsonMap _json) {
  factory _IconData({required JsonMap name}) =>
      _IconData.fromMap({'name': name});

  JsonMap get nameMap => _json['name'] as JsonMap;

  String? get literalName => nameMap['literalString'] as String?;
  String? get namePath => nameMap['path'] as String?;
}

enum AvailableIcons {
  add(Icons.add),
  arrowBack(Icons.arrow_back),
  arrowForward(Icons.arrow_forward),
  build(Icons.build),
  cameraAlt(Icons.camera_alt),
  check(Icons.check),
  close(Icons.close),
  delete(Icons.delete),
  download(Icons.download),
  edit(Icons.edit),
  event(Icons.event),
  favorite(Icons.favorite),
  home(Icons.home),
  info(Icons.info),
  locationOn(Icons.location_on),
  lockOpen(Icons.lock_open),
  lock(Icons.lock),
  mail(Icons.mail),
  menu(Icons.menu),
  notificationsActive(Icons.notifications_active),
  notifications(Icons.notifications),
  payment(Icons.payment),
  person(Icons.person),
  phone(Icons.phone),
  photoLibrary(Icons.photo_library),
  search(Icons.search),
  settings(Icons.settings),
  share(Icons.share),
  shoppingCart(Icons.shopping_cart),
  upload(Icons.upload),
  visibilityOff(Icons.visibility_off),
  visibility(Icons.visibility);

  const AvailableIcons(this.iconData);

  final IconData iconData;

  static List<String> get allAvailable =>
      values.map<String>((icon) => icon.name).toList();

  static AvailableIcons? fromName(String name) {
    for (final iconName in AvailableIcons.values) {
      if (iconName.name == name) {
        return iconName;
      }
    }
    return null;
  }
}

/// A catalog item for an icon.
///
/// ### Parameters:
///
/// - `name`: The name of the icon to display.
final icon = CatalogItem(
  name: 'Icon',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final iconData = _IconData.fromMap(itemContext.data as JsonMap);
    final literalName = iconData.literalName;
    final namePath = iconData.namePath;

    if (literalName != null) {
      final icon =
          AvailableIcons.fromName(literalName)?.iconData ?? Icons.broken_image;
      return Icon(icon);
    }

    if (namePath == null) {
      return const Icon(Icons.broken_image);
    }

    final notifier = itemContext.dataContext.subscribe<String>(
      DataPath(namePath),
    );

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, currentValue, child) {
        final iconName = currentValue ?? '';
        final icon =
            AvailableIcons.fromName(iconName)?.iconData ?? Icons.broken_image;
        return Icon(icon);
      },
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Icon": {
              "name": {
                "literalString": "add"
              }
            }
          }
        }
      ]
    ''',
  ],
);
