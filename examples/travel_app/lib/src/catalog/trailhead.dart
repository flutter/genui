// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['Trailhead']),
    'topics': S.list(
      description: 'A list of topics to display as chips.',
      items: A2uiSchemas.stringReference(description: 'A topic to explore.'),
    ),
    'action': A2uiSchemas.action(
      description:
          'The action to perform when a topic is selected. The selected topic '
          'will be added to the context with the key "topic".',
    ),
  },
  required: ['component', 'topics', 'action'],
);

extension type _TrailheadData.fromMap(Map<String, Object?> _json) {
  factory _TrailheadData({
    required List<JsonMap> topics,
    required JsonMap action,
  }) => _TrailheadData.fromMap({'topics': topics, 'action': action});

  List<Object> get topics => (_json['topics'] as List).cast<Object>();
  JsonMap get action => _json['action'] as JsonMap;
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
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Trailhead",
          "topics": [
            "Topic 1",
            "Topic 2",
            "Topic 3"
          ],
          "action": {
            "event": {
              "name": "select_topic"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final trailheadData = _TrailheadData.fromMap(
      itemContext.data as Map<String, Object?>,
    );
    return _Trailhead(
      topics: trailheadData.topics,
      action: trailheadData.action,
      widgetId: itemContext.id,
      dispatchEvent: itemContext.dispatchEvent,
      dataContext: itemContext.dataContext,
    );
  },
);

class _Trailhead extends StatelessWidget {
  const _Trailhead({
    required this.topics,
    required this.action,
    required this.widgetId,
    required this.dispatchEvent,
    required this.dataContext,
  });

  final List<Object> topics;
  final JsonMap action;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;
  final DataContext dataContext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: topics.map((topicRef) {
          final ValueNotifier<String?> notifier = dataContext.subscribeToString(
            topicRef,
          );

          return ValueListenableBuilder<String?>(
            valueListenable: notifier,
            builder: (context, topic, child) {
              if (topic == null) {
                return const SizedBox.shrink();
              }
              return InputChip(
                label: Text(topic),
                onPressed: () {
                  final event = action['event'] as JsonMap?;
                  final String name = event?['name'] as String? ?? 'unknown';
                  final contextDefinition = event?['context'] as JsonMap?;
                  final JsonMap resolvedContext = resolveContext(
                    dataContext,
                    contextDefinition,
                  );
                  resolvedContext['topic'] = topic;
                  dispatchEvent(
                    UserActionEvent(
                      name: name,
                      sourceComponentId: widgetId,
                      context: resolvedContext,
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
