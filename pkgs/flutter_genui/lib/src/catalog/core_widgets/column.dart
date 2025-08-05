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
    'spacing': Schema.number(
      description: 'The spacing between children. Defaults to 8.0.',
    ),
  },
);

extension type _ColumnData.fromMap(Map<String, Object?> _json) {
  factory _ColumnData({
    List<String> children = const [],
    double? spacing,
    String? mainAxisAlignment,
    String? crossAxisAlignment,
  }) => _ColumnData.fromMap({
    'children': children,
    'spacing': spacing,
    'mainAxisAlignment': mainAxisAlignment,
    'crossAxisAlignment': crossAxisAlignment,
  });

  List<String> get children =>
      ((_json['children'] as List?) ?? []).cast<String>();
  double get spacing => (_json['spacing'] as num?)?.toDouble() ?? 8.0;
  String? get mainAxisAlignment => _json['mainAxisAlignment'] as String?;
  String? get crossAxisAlignment => _json['crossAxisAlignment'] as String?;
}

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

final columnCatalogItem = CatalogItem(
  name: 'Column',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final columnData = _ColumnData.fromMap(data as Map<String, Object?>);
        final childrenIds = columnData.children;
        final spacing = columnData.spacing;
        final childrenWithSpacing = <Widget>[];
        for (var i = 0; i < childrenIds.length; i++) {
          childrenWithSpacing.add(buildChild(childrenIds[i]));
          if (i < childrenIds.length - 1) {
            childrenWithSpacing.add(SizedBox(height: spacing));
          }
        }
        return Column(
          mainAxisAlignment: _parseMainAxisAlignment(
            columnData.mainAxisAlignment,
          ),
          crossAxisAlignment: _parseCrossAxisAlignment(
            columnData.crossAxisAlignment,
          ),
          children: childrenWithSpacing,
        );
      },
);
