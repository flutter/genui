// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'itinerary_with_details.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  description: 'A container for a single day in an itinerary. '
      'It should contain a list of ItineraryEntry widgets. '
      'This should be nested inside an ItineraryWithDetails.',
  properties: {
    'title': S.string(description: 'The title for the day, e.g., "Day 1".'),
    'subtitle':
        S.string(description: 'The subtitle for the day, e.g., "Arrival in Tokyo".'),
    'description':
        S.string(description: 'A short description of the day\'s plan.'),
    'children': S.list(
      description:
          'A list of widget IDs for the ItineraryEntry children for this day.',
      items: S.string(),
    ),
  },
  required: ['title', 'subtitle', 'description', 'children'],
);

extension type _ItineraryDayData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryDayData({
    required String title,
    required String subtitle,
    required String description,
    required List<String> children,
  }) =>
      _ItineraryDayData.fromMap({
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'children': children,
      });

  String get title => _json['title'] as String;
  String get subtitle => _json['subtitle'] as String;
  String get description => _json['description'] as String;
  List<String> get children => (_json['children'] as List).cast<String>();
}

final itineraryDay = CatalogItem(
  name: 'ItineraryDay',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required values,
  }) {
    final itineraryDayData =
        _ItineraryDayData.fromMap(data as Map<String, Object?>);
    return _ItineraryDay(
      title: itineraryDayData.title,
      subtitle: itineraryDayData.subtitle,
      description: itineraryDayData.description,
      children: itineraryDayData.children.map(buildChild).toList(),
    );
  },
);

class _ItineraryDay extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final List<Widget> children;

  const _ItineraryDay({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4.0),
            Text(subtitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8.0),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8.0),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}