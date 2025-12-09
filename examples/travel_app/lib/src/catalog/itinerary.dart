// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../utils.dart';
import '../widgets/dismiss_notification.dart';

enum ItineraryEntryType { accommodation, transport, activity }

enum ItineraryEntryStatus { noBookingRequired, choiceRequired, chosen }

final _schema = S.object(
  description: 'Widget to show an itinerary or a plan for travel.',
  properties: {
    'title': A2uiSchemas.stringReference(
      description: 'The title of the itinerary.',
    ),
    'subheading': A2uiSchemas.stringReference(
      description: 'The subheading of the itinerary.',
    ),
    'imageChildId': A2uiSchemas.componentReference(
      description:
          'The ID of the Image widget to display. The Image fit '
          "should typically be 'cover'. Be sure to create an Image widget "
          'with a matching ID.',
    ),
    'days': S.list(
      description: 'A list of days in the itinerary.',
      items: S.object(
        properties: {
          'title': A2uiSchemas.stringReference(
            description: 'The title for the day, e.g., "Day 1".',
          ),
          'subtitle': A2uiSchemas.stringReference(
            description: 'The subtitle for the day, e.g., "Arrival in Tokyo".',
          ),
          'description': A2uiSchemas.stringReference(
            description:
                'A short description of the day\'s plan. '
                'This supports markdown.',
          ),
          'imageChildId': A2uiSchemas.componentReference(
            description:
                'The ID of the Image widget to display. The Image fit should '
                'typically be \'cover\'.',
          ),
          'entries': S.list(
            description:
                'A list of widget IDs for the ItineraryEntry '
                'children for this day.',
            items: S.object(
              properties: {
                'title': A2uiSchemas.stringReference(
                  description: 'The title of the itinerary entry.',
                ),
                'subtitle': A2uiSchemas.stringReference(
                  description: 'The subtitle of the itinerary entry.',
                ),
                'bodyText': A2uiSchemas.stringReference(
                  description:
                      'The body text for the entry. This supports markdown.',
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
                  enumValues: ItineraryEntryType.values
                      .map((e) => e.name)
                      .toList(),
                ),
                'status': S.string(
                  description:
                      'The booking status of the itinerary entry. '
                      'Use "noBookingRequired" for activities that do not '
                      'require a booking, like visiting a public park. '
                      'Use "choiceRequired" when the user needs to make a '
                      'decision, like selecting a specific hotel or flight. '
                      'Use "chosen" after the user has made a selection and '
                      'the booking is confirmed.',
                  enumValues: ItineraryEntryStatus.values
                      .map((e) => e.name)
                      .toList(),
                ),
                'choiceRequiredAction': A2uiSchemas.action(
                  description:
                      'The action to perform when the user needs to '
                      'make a choice. This is only used when the status is '
                      '"choiceRequired". The context for this action should '
                      'include the title of this itinerary entry.',
                ),
              },
              required: ['title', 'bodyText', 'time', 'type', 'status'],
            ),
          ),
        },
        required: [
          'title',
          'subtitle',
          'description',
          'imageChildId',
          'entries',
        ],
      ),
    ),
  },
  required: ['title', 'subheading', 'imageChildId', 'days'],
);

extension type _ItineraryData.fromMap(Map<String, Object?> _json) {
  JsonMap get title => _json['title'] as JsonMap;
  JsonMap get subheading => _json['subheading'] as JsonMap;
  String get imageChildId => _json['imageChildId'] as String;
  List<JsonMap> get days => (_json['days'] as List).cast<JsonMap>();
}

extension type _ItineraryDayData.fromMap(Map<String, Object?> _json) {
  JsonMap get title => _json['title'] as JsonMap;
  JsonMap get subtitle => _json['subtitle'] as JsonMap;
  JsonMap get description => _json['description'] as JsonMap;
  String get imageChildId => _json['imageChildId'] as String;
  List<JsonMap> get entries => (_json['entries'] as List).cast<JsonMap>();
}

extension type _ItineraryEntryData.fromMap(Map<String, Object?> _json) {
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

final itinerary = CatalogItem(
  name: 'Itinerary',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Itinerary": {
              "title": {
                "literalString": "My Awesome Trip"
              },
              "subheading": {
                "literalString": "A 3-day adventure"
              },
              "imageChildId": "image1",
              "days": [
                {
                  "title": {
                    "literalString": "Day 1"
                  },
                  "subtitle": {
                    "literalString": "Arrival and Exploration"
                  },
                  "description": {
                    "literalString": "Welcome to the city!"
                  },
                  "imageChildId": "image2",
                  "entries": [
                    {
                      "title": {
                        "literalString": "Check-in to Hotel"
                      },
                      "bodyText": {
                        "literalString": "Check-in to your hotel and relax."
                      },
                      "time": {
                        "literalString": "3:00 PM"
                      },
                      "type": "accommodation",
                      "status": "noBookingRequired"
                    }
                  ]
                }
              ]
            }
          }
        },
        {
          "id": "image1",
          "component": {
            "Image": {
              "url": {
                "literalString": "assets/travel_images/canyonlands_national_park_utah.jpg"
              }
            }
          }
        },
        {
          "id": "image2",
          "component": {
            "Image": {
              "url": {
                "literalString": "assets/travel_images/brooklyn_bridge_new_york.jpg"
              }
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final itineraryData = _ItineraryData.fromMap(
      context.data as Map<String, Object?>,
    );

    final ValueNotifier<String?> titleNotifier = context.dataContext
        .subscribeToString(itineraryData.title);
    final ValueNotifier<String?> subheadingNotifier = context.dataContext
        .subscribeToString(itineraryData.subheading);
    final Widget imageChild = context.buildChild(itineraryData.imageChildId);

    return _Itinerary(
      titleNotifier: titleNotifier,
      subheadingNotifier: subheadingNotifier,
      imageChild: imageChild,
      days: itineraryData.days,
      widgetId: context.id,
      buildChild: context.buildChild,
      dispatchEvent: context.dispatchEvent,
      dataContext: context.dataContext,
    );
  },
);

class _Itinerary extends StatelessWidget {
  final ValueNotifier<String?> titleNotifier;
  final ValueNotifier<String?> subheadingNotifier;
  final Widget imageChild;
  final List<JsonMap> days;
  final String widgetId;
  final ChildBuilderCallback buildChild;
  final DispatchEventCallback dispatchEvent;
  final DataContext dataContext;

  const _Itinerary({
    required this.titleNotifier,
    required this.subheadingNotifier,
    required this.imageChild,
    required this.days,
    required this.widgetId,
    required this.buildChild,
    required this.dispatchEvent,
    required this.dataContext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return NotificationListener<DismissNotification>(
              onNotification: (notification) {
                Navigator.of(context).pop();
                return true;
              },
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: Scaffold(
                  body: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 200,
                              child: imageChild,
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: ValueListenableBuilder<String?>(
                                valueListenable: titleNotifier,
                                builder: (context, title, _) => Text(
                                  title ?? '',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            for (final dayData in days)
                              _ItineraryDay(
                                data: _ItineraryDayData.fromMap(dayData),
                                widgetId: widgetId,
                                buildChild: buildChild,
                                dispatchEvent: dispatchEvent,
                                dataContext: dataContext,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16.0,
                        right: 16.0,
                        child: Material(
                          color: Colors.white.withAlpha((255 * 0.8).round()),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Card(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox(height: 100, width: 100, child: imageChild),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: titleNotifier,
                    builder: (context, title, _) => Text(
                      title ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: subheadingNotifier,
                    builder: (context, subheading, _) => Text(
                      subheading ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryDay extends StatelessWidget {
  const _ItineraryDay({
    required this.data,
    required this.widgetId,
    required this.buildChild,
    required this.dispatchEvent,
    required this.dataContext,
  });

  final _ItineraryDayData data;
  final String widgetId;
  final ChildBuilderCallback buildChild;
  final DispatchEventCallback dispatchEvent;
  final DataContext dataContext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ValueNotifier<String?> titleNotifier = dataContext.subscribeToString(
      data.title,
    );
    final ValueNotifier<String?> subtitleNotifier = dataContext
        .subscribeToString(data.subtitle);
    final ValueNotifier<String?> descriptionNotifier = dataContext
        .subscribeToString(data.description);
    final Widget imageChild = buildChild(data.imageChildId);

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(height: 80, width: 80, child: imageChild),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<String?>(
                        valueListenable: titleNotifier,
                        builder: (context, value, _) => Text(
                          value ?? '',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      ValueListenableBuilder<String?>(
                        valueListenable: subtitleNotifier,
                        builder: (context, value, _) => Text(
                          value ?? '',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            ValueListenableBuilder<String?>(
              valueListenable: descriptionNotifier,
              builder: (context, description, _) =>
                  MarkdownWidget(text: description ?? ''),
            ),
            const SizedBox(height: 8.0),
            const Divider(),
            for (final entryData in data.entries)
              _ItineraryEntry(
                data: _ItineraryEntryData.fromMap(entryData),
                widgetId: widgetId,
                dispatchEvent: dispatchEvent,
                dataContext: dataContext,
              ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryEntry extends StatelessWidget {
  final _ItineraryEntryData data;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;
  final DataContext dataContext;

  const _ItineraryEntry({
    required this.data,
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
    final ThemeData theme = Theme.of(context);
    final ValueNotifier<String?> titleNotifier = dataContext.subscribeToString(
      data.title,
    );
    final ValueNotifier<String?> subtitleNotifier = dataContext
        .subscribeToString(data.subtitle);
    final ValueNotifier<String?> bodyTextNotifier = dataContext
        .subscribeToString(data.bodyText);
    final ValueNotifier<String?> addressNotifier = dataContext
        .subscribeToString(data.address);
    final ValueNotifier<String?> timeNotifier = dataContext.subscribeToString(
      data.time,
    );
    final ValueNotifier<String?> totalCostNotifier = dataContext
        .subscribeToString(data.totalCost);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForType(data.type), color: theme.primaryColor),
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
                    if (data.status == ItineraryEntryStatus.chosen)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else if (data.status == ItineraryEntryStatus.choiceRequired)
                      ValueListenableBuilder<String?>(
                        valueListenable: titleNotifier,
                        builder: (context, title, _) => FilledButton(
                          onPressed: () {
                            final JsonMap? actionData =
                                data.choiceRequiredAction;
                            if (actionData == null) {
                              return;
                            }
                            final actionName = actionData['name'] as String;
                            final List<Object?> contextDefinition =
                                (actionData['context'] as List<Object?>?) ??
                                <Object>[];
                            final JsonMap resolvedContext = resolveContext(
                              dataContext,
                              contextDefinition,
                            );
                            dispatchEvent(
                              UserActionEvent(
                                name: actionName,
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
