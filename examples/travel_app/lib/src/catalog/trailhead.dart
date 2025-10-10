// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  properties: {
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
  required: ['topics', 'action'],
);

extension type _TrailheadData.fromMap(Map<String, Object?> _json) {
  factory _TrailheadData({
    required List<JsonMap> topics,
    required JsonMap action,
  }) => _TrailheadData.fromMap({'topics': topics, 'action': action});

  List<JsonMap> get topics => (_json['topics'] as List).cast<JsonMap>();
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
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final trailheadData = _TrailheadData.fromMap(
          data as Map<String, Object?>,
        );
        return _Trailhead(
          topics: trailheadData.topics,
          action: trailheadData.action,
          widgetId: id,
          dispatchEvent: dispatchEvent,
          dataContext: dataContext,
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

  final List<JsonMap> topics;
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
          final notifier = dataContext.subscribeToString(topicRef);

          return ValueListenableBuilder<String?>(
            valueListenable: notifier,
            builder: (context, topic, child) {
              if (topic == null) {
                return const SizedBox.shrink();
              }
              return InputChip(
                label: Text(topic),
                onPressed: () {
                  final actionName = action['actionName'] as String;
                  final contextDefinition =
                      (action['context'] as List<Object?>?) ?? <Object?>[];
                  final resolvedContext = resolveContext(
                    dataContext,
                    contextDefinition,
                  );
                  resolvedContext['topic'] = topic;
                  dispatchEvent(
                    UserActionEvent(
                      actionName: actionName,
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
