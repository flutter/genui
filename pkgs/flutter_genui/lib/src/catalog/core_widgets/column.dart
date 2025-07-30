// ignore_for_file: avoid_dynamic_calls

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';

final _schema = Schema.object(
  properties: {
    'mainAxisAlignment': Schema.enumString(
      description:
          'How children are aligned on the main axis. '
          'See Flutter\'s MainAxisAlignment for values.',
      enumValues: [
        'start',
        'center',
        'end',
        'spaceBetween',
        'spaceAround',
        'spaceEvenly',
      ],
    ),
    'crossAxisAlignment': Schema.enumString(
      description:
          'How children are aligned on the cross axis. '
          'See Flutter\'s CrossAxisAlignment for values.',
      enumValues: ['start', 'center', 'end', 'stretch', 'baseline'],
    ),
    'children': Schema.array(
      items: Schema.string(),
      description: 'A list of widget IDs for the children.',
    ),
  },
);

MainAxisAlignment _parseMainAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return MainAxisAlignment.start;
    case 'center':
      return MainAxisAlignment.center;
    case 'end':
      return MainAxisAlignment.end;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start;
  }
}

CrossAxisAlignment _parseCrossAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return CrossAxisAlignment.start;
    case 'center':
      return CrossAxisAlignment.center;
    case 'end':
      return CrossAxisAlignment.end;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    default:
      return CrossAxisAlignment.center;
  }
}

Widget _builder(
  dynamic data,
  String id,
  Widget Function(String id) buildChild,
  void Function(String widgetId, String eventType, Object? value) dispatchEvent,
  BuildContext context,
) {
  final children = (data['children'] as List<dynamic>).cast<String>();
  return Column(
    mainAxisAlignment: _parseMainAxisAlignment(
      data['mainAxisAlignment'] as String?,
    ),
    crossAxisAlignment: _parseCrossAxisAlignment(
      data['crossAxisAlignment'] as String?,
    ),
    children: children.map(buildChild).toList(),
  );
}

final columnCatalogItem = CatalogItem(
  name: 'Column',
  dataSchema: _schema,
  widgetBuilder: _builder,
);
