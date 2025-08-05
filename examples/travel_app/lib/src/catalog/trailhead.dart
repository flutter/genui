import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'topics': Schema.array(
      description: 'A list of topics to display as chips.',
      items: Schema.string(description: 'A topic to explore.'),
    ),
  },
);

extension type _TrailheadData.fromMap(Map<String, Object?> _json) {
  factory _TrailheadData({required List<String> topics}) =>
      _TrailheadData.fromMap({'topics': topics});

  List<String> get topics => (_json['topics'] as List).cast<String>();
}

final trailheadCatalogItem = CatalogItem(
  name: 'trailhead',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
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
