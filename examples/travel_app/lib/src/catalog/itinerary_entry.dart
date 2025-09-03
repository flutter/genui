// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

enum ItineraryEntryType {
  accomodation,
  transport,
  activity,
}

final _schema = S.object(
  description: 'A specific activity within a day in an itinerary. '
      'This should be nested inside an ItineraryDay.',
  properties: {
    'title': S.string(description: 'The title of the itinerary entry.'),
    'subtitle': S.string(description: 'The subtitle of the itinerary entry.'),
    'bodyText': S.string(description: 'The body text for the entry.'),
    'address': S.string(description: 'The address for the entry.'),
    'time': S.string(description: 'The time for the entry (formatted string).'),
    'totalCost': S.string(description: 'The total cost for the entry.'),
    'type': S.string(
      description: 'The type of the itinerary entry.',
      enumValues: ItineraryEntryType.values.map((e) => e.name).toList(),
    ),
  },
  required: ['title', 'bodyText', 'time', 'type'],
);

extension type _ItineraryEntryData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryEntryData({
    required String title,
    String? subtitle,
    required String bodyText,
    String? address,
    required String time,
    String? totalCost,
    required String type,
  }) =>
      _ItineraryEntryData.fromMap({
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'bodyText': bodyText,
        if (address != null) 'address': address,
        'time': time,
        if (totalCost != null) 'totalCost': totalCost,
        'type': type,
      });

  String get title => _json['title'] as String;
  String? get subtitle => _json['subtitle'] as String?;
  String get bodyText => _json['bodyText'] as String;
  String? get address => _json['address'] as String?;
  String get time => _json['time'] as String;
  String? get totalCost => _json['totalCost'] as String?;
  ItineraryEntryType get type =>
      ItineraryEntryType.values.byName(_json['type'] as String);
}

final itineraryEntry = CatalogItem(
  name: 'ItineraryEntry',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required values,
  }) {
    final itineraryEntryData =
        _ItineraryEntryData.fromMap(data as Map<String, Object?>);
    return _ItineraryEntry(
      title: itineraryEntryData.title,
      subtitle: itineraryEntryData.subtitle,
      bodyText: itineraryEntryData.bodyText,
      address: itineraryEntryData.address,
      time: itineraryEntryData.time,
      totalCost: itineraryEntryData.totalCost,
      type: itineraryEntryData.type,
    );
  },
);

class _ItineraryEntry extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String bodyText;
  final String? address;
  final String time;
  final String? totalCost;
  final ItineraryEntryType type;

  const _ItineraryEntry({
    required this.title,
    this.subtitle,
    required this.bodyText,
    this.address,
    required this.time,
    this.totalCost,
    required this.type,
  });

  IconData _getIconForType(ItineraryEntryType type) {
    switch (type) {
      case ItineraryEntryType.accomodation:
        return Icons.hotel;
      case ItineraryEntryType.transport:
        return Icons.train;
      case ItineraryEntryType.activity:
        return Icons.local_activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForType(type), color: theme.primaryColor),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4.0),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text(time, style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (address != null) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16.0),
                      const SizedBox(width: 4.0),
                      Expanded(
                          child: Text(address!,
                              style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ],
                if (totalCost != null) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16.0),
                      const SizedBox(width: 4.0),
                      Text(totalCost!, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
                const SizedBox(height: 8.0),
                Text(bodyText, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
