// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  properties: {
    'topics': S.list(
      description: 'A list of topics to display as chips.',
      items: S.string(description: 'A topic to explore.'),
    ),
  },
  required: ['topics'],
);

extension type _TrailheadData.fromMap(Map<String, Object?> _json) {
  factory _TrailheadData({required List<String> topics}) =>
      _TrailheadData.fromMap({'topics': topics});

  List<String> get topics => (_json['topics'] as List).cast<String>();
}

/// A widget that presents a list of suggested topics or follow-up questions to
/// the user in the form of interactive chips.
///
/// This component is designed to guide the conversation and encourage further
/// exploration after a primary query has been addressed. For instance, after
/// generating a trip itinerary, the AI might use a [trailhead] to suggest
/// related topics like "local cuisine," "nightlife," or "day trips." When a
/// user taps a topic, it sends a new prompt to the AI, continuing the
/// conversation in a new direction.
final trailhead = CatalogItem(
  name: 'Trailhead',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final trailheadData = _TrailheadData.fromMap(
          data as Map<String, Object?>,
        );
        return _Trailhead(
          topics: trailheadData.topics,
          widgetId: id,
          dispatchEvent: dispatchEvent,
        );
      },
);

class _Trailhead extends StatelessWidget {
  const _Trailhead({
    required this.topics,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final List<String> topics;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: topics.map((topic) {
          return InputChip(
            label: Text(topic),
            onPressed: () {
              dispatchEvent(
                UiActionEvent(
                  widgetId: widgetId,
                  eventType: 'trailheadTopicSelected',
                  value: topic,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
