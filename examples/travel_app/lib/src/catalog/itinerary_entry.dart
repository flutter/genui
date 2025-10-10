// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../utils.dart';
import '../widgets/dismiss_notification.dart';

enum ItineraryEntryType { accommodation, transport, activity }

enum ItineraryEntryStatus { noBookingRequired, choiceRequired, chosen }

final _schema = S.object(
  description:
      'A specific activity within a day in an itinerary. '
      'This should be nested inside an ItineraryDay.',
  properties: {
    'title': A2uiSchemas.stringReference(
      description: 'The title of the itinerary entry.',
    ),
    'subtitle': A2uiSchemas.stringReference(
      description: 'The subtitle of the itinerary entry.',
    ),
    'bodyText': A2uiSchemas.stringReference(
      description: 'The body text for the entry. This supports markdown.',
    ),
    'address': A2uiSchemas.stringReference(
      description: 'The address for the entry.',
    ),
    'time': A2uiSchemas.stringReference(
      description: 'The time for the entry (formatted string).',
    ),
    'totalCost': A2uiSchemas.stringReference(
      description: 'The total cost for the entry.',
    ),
    'type': S.string(
      description: 'The type of the itinerary entry.',
      enumValues: ItineraryEntryType.values.map((e) => e.name).toList(),
    ),
    'status': S.string(
      description:
          'The booking status of the itinerary entry. '
          'Use "noBookingRequired" for activities that do not require a '
          'booking, like visiting a public park. '
          'Use "choiceRequired" when the user needs to make a decision, '
          'like selecting a specific hotel or flight. '
          'Use "chosen" after the user has made a selection and the booking '
          'is confirmed.',
      enumValues: ItineraryEntryStatus.values.map((e) => e.name).toList(),
    ),
    'choiceRequiredAction': A2uiSchemas.action(
      description:
          'The action to perform when the user needs to make a choice. '
          'This is only used when the status is "choiceRequired". The context '
          'for this action should include the title of this itinerary entry.',
    ),
  },
  required: ['title', 'bodyText', 'time', 'type', 'status'],
);

extension type _ItineraryEntryData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryEntryData({
    required JsonMap title,
    JsonMap? subtitle,
    required JsonMap bodyText,
    JsonMap? address,
    required JsonMap time,
    JsonMap? totalCost,
    required String type,
    required String status,
    JsonMap? choiceRequiredAction,
  }) => _ItineraryEntryData.fromMap({
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'bodyText': bodyText,
    if (address != null) 'address': address,
    'time': time,
    if (totalCost != null) 'totalCost': totalCost,
    'type': type,
    'status': status,
    if (choiceRequiredAction != null)
      'choiceRequiredAction': choiceRequiredAction,
  });

  JsonMap get title => _json['title'] as JsonMap;
  JsonMap? get subtitle => _json['subtitle'] as JsonMap?;
  JsonMap get bodyText => _json['bodyText'] as JsonMap;
  JsonMap? get address => _json['address'] as JsonMap?;
  JsonMap get time => _json['time'] as JsonMap;
  JsonMap? get totalCost => _json['totalCost'] as JsonMap?;
  ItineraryEntryType get type =>
      ItineraryEntryType.values.byName(_json['type'] as String);
  ItineraryEntryStatus get status =>
      ItineraryEntryStatus.values.byName(_json['status'] as String);
  JsonMap? get choiceRequiredAction =>
      _json['choiceRequiredAction'] as JsonMap?;
}

final itineraryEntry = CatalogItem(
  name: 'ItineraryEntry',
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
        final itineraryEntryData = _ItineraryEntryData.fromMap(
          data as Map<String, Object?>,
        );

        final titleNotifier = dataContext.subscribeToString(
          itineraryEntryData.title,
        );
        final subtitleNotifier = dataContext.subscribeToString(
          itineraryEntryData.subtitle,
        );
        final bodyTextNotifier = dataContext.subscribeToString(
          itineraryEntryData.bodyText,
        );
        final addressNotifier = dataContext.subscribeToString(
          itineraryEntryData.address,
        );
        final timeNotifier = dataContext.subscribeToString(
          itineraryEntryData.time,
        );
        final totalCostNotifier = dataContext.subscribeToString(
          itineraryEntryData.totalCost,
        );

        return _ItineraryEntry(
          titleNotifier: titleNotifier,
          subtitleNotifier: subtitleNotifier,
          bodyTextNotifier: bodyTextNotifier,
          addressNotifier: addressNotifier,
          timeNotifier: timeNotifier,
          totalCostNotifier: totalCostNotifier,
          type: itineraryEntryData.type,
          status: itineraryEntryData.status,
          choiceRequiredAction: itineraryEntryData.choiceRequiredAction,
          widgetId: id,
          dispatchEvent: dispatchEvent,
          dataContext: dataContext,
        );
      },
);

class _ItineraryEntry extends StatelessWidget {
  final ValueNotifier<String?> titleNotifier;
  final ValueNotifier<String?> subtitleNotifier;
  final ValueNotifier<String?> bodyTextNotifier;
  final ValueNotifier<String?> addressNotifier;
  final ValueNotifier<String?> timeNotifier;
  final ValueNotifier<String?> totalCostNotifier;
  final ItineraryEntryType type;
  final ItineraryEntryStatus status;
  final JsonMap? choiceRequiredAction;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;
  final DataContext dataContext;

  const _ItineraryEntry({
    required this.titleNotifier,
    required this.subtitleNotifier,
    required this.bodyTextNotifier,
    required this.addressNotifier,
    required this.timeNotifier,
    required this.totalCostNotifier,
    required this.type,
    required this.status,
    this.choiceRequiredAction,
    required this.widgetId,
    required this.dispatchEvent,
    required this.dataContext,
  });

  IconData _getIconForType(ItineraryEntryType type) {
    switch (type) {
      case ItineraryEntryType.accommodation:
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForType(type), color: theme.primaryColor),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: titleNotifier,
                        builder: (context, title, _) => Text(
                          title ?? '',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    if (status == ItineraryEntryStatus.chosen)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else if (status == ItineraryEntryStatus.choiceRequired)
                      ValueListenableBuilder<String?>(
                        valueListenable: titleNotifier,
                        builder: (context, title, _) => FilledButton(
                          onPressed: () {
                            final actionData = choiceRequiredAction;
                            if (actionData == null) {
                              return;
                            }
                            final actionName =
                                actionData['actionName'] as String;
                            final contextDefinition =
                                (actionData['context'] as List<Object?>?) ??
                                <Object>[];
                            final resolvedContext = resolveContext(
                              dataContext,
                              contextDefinition,
                            );
                            dispatchEvent(
                              UserActionEvent(
                                actionName: actionName,
                                sourceComponentId: widgetId,
                                context: resolvedContext,
                              ),
                            );
                            DismissNotification().dispatch(context);
                          },
                          child: const Text('Choose'),
                        ),
                      ),
                  ],
                ),
                OptionalValueBuilder(
                  listenable: subtitleNotifier,
                  builder: (context, subtitle) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(subtitle, style: theme.textTheme.bodySmall),
                    );
                  },
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16.0),
                    const SizedBox(width: 4.0),
                    ValueListenableBuilder<String?>(
                      valueListenable: timeNotifier,
                      builder: (context, time, _) =>
                          Text(time ?? '', style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
                OptionalValueBuilder(
                  listenable: addressNotifier,
                  builder: (context, address) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16.0),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              address,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                OptionalValueBuilder(
                  listenable: totalCostNotifier,
                  builder: (context, totalCost) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, size: 16.0),
                          const SizedBox(width: 4.0),
                          Text(totalCost, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8.0),
                ValueListenableBuilder<String?>(
                  valueListenable: bodyTextNotifier,
                  builder: (context, bodyText, _) =>
                      MarkdownWidget(text: bodyText ?? ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
