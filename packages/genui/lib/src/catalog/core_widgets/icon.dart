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
    'component': S.string(enumValues: ['Icon']),
    'name': A2uiSchemas.stringReference(
      description:
          '''The name of the icon to display. This can be a literal string ('literalString') or a reference to a value in the data model ('path', e.g. '/icon/name').''',
      enumValues: AvailableIcons.allAvailable,
    ),
  },
  required: ['component', 'name'],
);

extension type _IconData.fromMap(JsonMap _json) {
  factory _IconData({required Object name}) =>
      _IconData.fromMap({'name': name});

  Object? get _name => _json['name'];

  String? get literalName {
    final Object? name = _name;
    if (name is String) return name;
    if (name is JsonMap) return name['literalString'] as String?;
    return null;
  }

  String? get namePath {
    final Object? name = _name;
    if (name is JsonMap) return name['path'] as String?;
    return null;
  }
}

enum AvailableIcons {
  accountCircle(Icons.account_circle),
  add(Icons.add),
  arrowBack(Icons.arrow_back),
  arrowForward(Icons.arrow_forward),
  attachFile(Icons.attach_file),
  calendarToday(Icons.calendar_today),
  call(Icons.call),
  camera(Icons.camera_alt),
  check(Icons.check),
  close(Icons.close),
  delete(Icons.delete),
  download(Icons.download),
  edit(Icons.edit),
  error(Icons.error),
  event(Icons.event),
  favorite(Icons.favorite),
  favoriteOff(Icons.favorite_outline),
  folder(Icons.folder),
  help(Icons.help),
  home(Icons.home),
  info(Icons.info_outline),
  locationOn(Icons.location_on),
  lock(Icons.lock_outline),
  lockOpen(Icons.lock_open_outlined),
  mail(Icons.mail_outline),
  menu(Icons.menu),
  moreHoriz(Icons.more_horiz),
  moreVert(Icons.more_vert),
  notifications(Icons.notifications),
  notificationsOff(Icons.notifications_none),
  payment(Icons.payment),
  person(Icons.person),
  phone(Icons.phone),
  photo(Icons.photo),
  print(Icons.print),
  refresh(Icons.refresh),
  search(Icons.search),
  send(Icons.send),
  settings(Icons.settings),
  share(Icons.share),
  shoppingCart(Icons.shopping_cart),
  star(Icons.star),
  starHalf(Icons.star_half_outlined),
  starOff(Icons.star_outline),
  upload(Icons.upload),
  visibility(Icons.visibility),
  visibilityOff(Icons.visibility_off),
  warning(Icons.warning);

  const AvailableIcons(this.iconData);

  final IconData iconData;

  static List<String> get allAvailable =>
      values.map<String>((icon) => icon.name).toList();

  static AvailableIcons? fromName(String name) {
    for (final AvailableIcons iconName in AvailableIcons.values) {
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
    final String? literalName = iconData.literalName;
    final String? namePath = iconData.namePath;

    if (literalName != null) {
      final IconData icon =
          AvailableIcons.fromName(literalName)?.iconData ?? Icons.broken_image;
      return Icon(icon);
    }

    if (namePath == null) {
      return const Icon(Icons.broken_image);
    }

    final ValueNotifier<String?> notifier = itemContext.dataContext
        .subscribe<String>(DataPath(namePath));

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, currentValue, child) {
        final String iconName = currentValue ?? '';
        final IconData icon =
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
          "component": "Icon",
          "name": "add"
        }
      ]
    ''',
  ],
);
