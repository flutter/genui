import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fcp_client/fcp_client.dart';

void main() {
  runApp(const CosmicComplimentApp());
}

/// A whimsical example app that displays cosmic compliments using FCP.
class CosmicComplimentApp extends StatefulWidget {
  const CosmicComplimentApp({super.key});

  @override
  State<CosmicComplimentApp> createState() => _CosmicComplimentAppState();
}

class _CosmicComplimentAppState extends State<CosmicComplimentApp> {
  late final FcpViewController _controller;
  late final WidgetCatalogRegistry _registry;
  late final WidgetCatalog _catalog;

  final _random = Random();
  int _complimentCount = 0;
  bool _detailsVisible = false;

  final _compliments = [
    'You are as bright as a supernova!',
    'Your gravitational pull is irresistible.',
    'You shine like a newly formed star.',
    'You have the courage of a comet.',
    'Your heart is as big as a galaxy.',
  ];

  final _cosmicDetails = [
    'A supernova is the largest explosion that takes place in space.',
    'Gravity is the universal force of attraction acting between all matter.',
    'Stars are born within the clouds of dust and scattered throughout most galaxies.',
    'A comet is an icy, small Solar System body that, when passing close to the Sun, warms and begins to release gases.',
    'A galaxy is a gravitationally bound system of stars, stellar remnants, interstellar gas, dust, and dark matter.',
  ];

  @override
  void initState() {
    super.initState();
    _controller = FcpViewController();
    _registry = _createAndRegisterWidgets();
    _catalog = _registry.buildCatalog(
      catalogVersion: '1.0.0',
      dataTypes: {
        'fact': {
          'type': 'object',
          'properties': {
            'text': {'type': 'string'},
          },
          'required': ['text'],
        },
      },
    );
    // Set the initial compliment.
    _getNewCompliment();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _getNewCompliment() {
    final newIndex = _random.nextInt(_compliments.length);
    _complimentCount++;

    // Use StateUpdate to patch the compliment and the count.
    _controller.patchState(
      StateUpdate({
        'patches': [
          {
            'op': 'replace',
            'path': '/compliment',
            'value': _compliments[newIndex],
          },
          {'op': 'replace', 'path': '/count', 'value': _complimentCount},
          {
            'op': 'replace',
            'path': '/detail',
            'value': _cosmicDetails[newIndex],
          },
        ],
      }),
    );
  }

  void _setMood(String mood) {
    // Use StateUpdate to patch the mood.
    _controller.patchState(
      StateUpdate({
        'patches': [
          {'op': 'replace', 'path': '/mood', 'value': mood},
        ],
      }),
    );
  }

  void _toggleDetails() {
    _detailsVisible = !_detailsVisible;

    // First, update the state to reflect the new visibility.
    _controller.patchState(
      StateUpdate({
        'patches': [
          {
            'op': 'replace',
            'path': '/detailsVisible',
            'value': _detailsVisible,
          },
        ],
      }),
    );

    // Next, send a LayoutUpdate to modify the UI structure.
    final operation = _detailsVisible ? 'add' : 'remove';
    final childrenList = [
      'compliment_text_padding',
      if (_detailsVisible) 'details_text', // Conditionally include the widget
      'compliment_button_padding',
      'mood_selector',
      'details_row', // The Checkbox is now in a Row
      'facts_list',
    ];

    _controller.patchLayout(
      LayoutUpdate({
        'operations': [
          {
            'op': operation,
            'nodes': [
              {
                'id': 'details_text',
                'type': 'Text',
                'properties': {'style': 'body', 'key': 'details_text'},
                'bindings': {
                  'data': {'path': 'detail'},
                },
              },
            ],
          },
          {
            'op': 'update',
            'nodes': [
              {
                'id': 'main_column',
                'type': 'Column',
                'properties': {'children': childrenList},
              },
            ],
          },
        ],
      }),
    );
  }

  /// Creates a [WidgetCatalogRegistry] and registers the widgets used in this
  /// example.
  WidgetCatalogRegistry _createAndRegisterWidgets() {
    return WidgetCatalogRegistry()
      ..register(
        CatalogItem(
          name: 'Scaffold',
          builder: (context, node, properties, children) {
            return Scaffold(
              appBar: children['appBar'] as PreferredSizeWidget?,
              body: children['body'] as Widget?,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'appBar': {'type': 'WidgetId'},
              'body': {'type': 'WidgetId'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'AppBar',
          builder: (context, node, properties, children) {
            return AppBar(title: children['title'] as Widget?);
          },
          definition: WidgetDefinition({
            'properties': {
              'title': {'type': 'WidgetId'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Center',
          builder: (context, node, properties, children) =>
              Center(child: children['child'] as Widget?),
          definition: WidgetDefinition({
            'properties': {
              'child': {'type': 'WidgetId'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Column',
          builder: (context, node, properties, children) {
            final childWidgets =
                (children['children'] as List<dynamic>?)?.cast<Widget>() ?? [];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: childWidgets,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'children': {'type': 'ListOfWidgetIds'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Row',
          builder: (context, node, properties, children) {
            final childWidgets =
                (children['children'] as List<dynamic>?)?.cast<Widget>() ?? [];
            return Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: childWidgets,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'children': {'type': 'ListOfWidgetIds'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'SizedBox',
          builder: (context, node, properties, children) =>
              SizedBox(width: properties['width'] as double?),
          definition: WidgetDefinition({
            'properties': {
              'width': {'type': 'Number'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Padding',
          builder: (context, node, properties, children) {
            return Padding(
              padding: EdgeInsets.all(properties['all'] as double? ?? 0.0),
              child: children['child'] as Widget?,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'all': {'type': 'Number'},
              'child': {'type': 'WidgetId'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Text',
          builder: (context, node, properties, children) {
            final style = properties['style'] as String?;
            final color = properties['color'] as Color?;
            TextStyle? textStyle;
            if (style == 'headline') {
              textStyle = Theme.of(context).textTheme.headlineMedium;
            } else if (style == 'body') {
              textStyle = Theme.of(context).textTheme.bodyLarge;
            }
            return Text(
              properties['data'] as String? ?? '',
              key: properties['key'] != null
                  ? ValueKey(properties['key'])
                  : null,
              style: textStyle?.copyWith(color: color),
              textAlign: TextAlign.center,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'data': {'type': 'String'},
              'style': {
                'type': 'Enum',
                'values': ['headline', 'body'],
              },
              'key': {'type': 'String'},
              'color': {'type': 'Color'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'ElevatedButton',
          builder: (context, node, properties, children) {
            return ElevatedButton(
              key: properties['key'] != null
                  ? ValueKey(properties['key'])
                  : null,
              onPressed: () {
                FcpProvider.of(context)?.onEvent?.call(
                  EventPayload({
                    'sourceNodeId': node.id,
                    'eventName':
                        properties['eventName'] as String? ?? 'onPressed',
                    'arguments': {'mood': properties['mood']},
                  }),
                );
              },
              child: children['child'] as Widget?,
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'child': {'type': 'WidgetId'},
              'key': {'type': 'String'},
              'eventName': {'type': 'String'},
              'mood': {'type': 'String'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'Checkbox',
          builder: (context, node, properties, children) {
            return Checkbox(
              value: properties['value'] as bool? ?? false,
              onChanged: (newValue) {
                FcpProvider.of(context)?.onEvent?.call(
                  EventPayload({
                    'sourceNodeId': node.id,
                    'eventName': 'onChanged',
                    'arguments': {'value': newValue},
                  }),
                );
              },
            );
          },
          definition: WidgetDefinition({
            'properties': {
              'value': {'type': 'Boolean'},
              'key': {'type': 'String'},
            },
          }),
        ),
      )
      ..register(
        CatalogItem(
          name: 'ListViewBuilder',
          builder: (context, node, properties, children) =>
              const SizedBox.shrink(),
          definition: WidgetDefinition({
            'properties': {},
            'bindings': {
              'data': {'path': 'string'},
            },
          }),
        ),
      );
  }

  /// Creates the initial [DynamicUIPacket] that defines the app's UI.
  DynamicUIPacket _createUiPacket() {
    return DynamicUIPacket({
      'formatVersion': '1.0.0',
      'layout': {
        'root': 'root_scaffold',
        'nodes': [
          // Structure
          {
            'id': 'root_scaffold',
            'type': 'Scaffold',
            'properties': {'appBar': 'main_app_bar', 'body': 'main_center'},
          },
          {
            'id': 'main_app_bar',
            'type': 'AppBar',
            'properties': {'title': 'title_text'},
          },
          {
            'id': 'title_text',
            'type': 'Text',
            'bindings': {
              'data': {'path': 'count', 'format': 'Cosmic Dashboard ({})'},
            },
          },
          {
            'id': 'main_center',
            'type': 'Center',
            'properties': {'child': 'main_column'},
          },
          {
            'id': 'main_column',
            'type': 'Column',
            'properties': {
              'children': [
                'compliment_text_padding',
                'compliment_button_padding',
                'mood_selector',
                'details_row',
                'facts_list',
              ],
            },
          },
          // Padding for compliment text
          {
            'id': 'compliment_text_padding',
            'type': 'Padding',
            'properties': {'all': 12.0, 'child': 'compliment_text'},
          },
          // Padding for compliment button
          {
            'id': 'compliment_button_padding',
            'type': 'Padding',
            'properties': {'all': 12.0, 'child': 'compliment_button'},
          },
          // Compliment Text
          {
            'id': 'compliment_text',
            'type': 'Text',
            'properties': {'style': 'headline', 'key': 'compliment_text'},
            'bindings': {
              'data': {'path': 'compliment'},
              'color': {
                'path': 'mood',
                'map': {
                  'mapping': {
                    'happy': Colors.blue,
                    'excited': Colors.orange,
                    'calm': Colors.green,
                  },
                  'fallback': Colors.black,
                },
              },
            },
          },
          // Main Action Button
          {
            'id': 'compliment_button',
            'type': 'ElevatedButton',
            'properties': {'child': 'button_text', 'key': 'compliment_button'},
          },
          {
            'id': 'button_text',
            'type': 'Text',
            'properties': {'data': 'Get another compliment'},
          },
          // Mood Selectors
          {
            'id': 'mood_selector',
            'type': 'Row',
            'properties': {
              'children': [
                'mood_happy',
                'spacer1',
                'mood_excited',
                'spacer2',
                'mood_calm',
              ],
            },
          },
          {
            'id': 'mood_happy',
            'type': 'ElevatedButton',
            'properties': {
              'child': 'mood_happy_text',
              'eventName': 'setMood',
              'mood': 'happy',
            },
          },
          {
            'id': 'mood_happy_text',
            'type': 'Text',
            'properties': {'data': 'Happy'},
          },
          {
            'id': 'mood_excited',
            'type': 'ElevatedButton',
            'properties': {
              'child': 'mood_excited_text',
              'eventName': 'setMood',
              'mood': 'excited',
            },
          },
          {
            'id': 'mood_excited_text',
            'type': 'Text',
            'properties': {'data': 'Excited'},
          },
          {
            'id': 'mood_calm',
            'type': 'ElevatedButton',
            'properties': {
              'child': 'mood_calm_text',
              'eventName': 'setMood',
              'mood': 'calm',
            },
          },
          {
            'id': 'mood_calm_text',
            'type': 'Text',
            'properties': {'data': 'Calm'},
          },
          // Details Toggle
          {
            'id': 'details_row',
            'type': 'Row',
            'properties': {
              'children': ['details_toggle_text', 'details_toggle'],
            },
          },
          {
            'id': 'details_toggle',
            'type': 'Checkbox',
            'properties': {'key': 'details_toggle'},
            'bindings': {
              'value': {'path': 'detailsVisible'},
            },
          },
          {
            'id': 'details_toggle_text',
            'type': 'Text',
            'properties': {'data': 'Show Details'},
          },
          // Facts List
          {
            'id': 'facts_list',
            'type': 'ListViewBuilder',
            'bindings': {
              'data': {'path': 'facts'},
            },
            'itemTemplate': {
              'id': 'fact_template',
              'type': 'Text',
              'properties': {'style': 'body'},
              'bindings': {
                'data': {'path': 'item.text'},
              },
            },
          },
          // Spacers
          {
            'id': 'spacer1',
            'type': 'SizedBox',
            'properties': {'width': 16.0},
          },
          {
            'id': 'spacer2',
            'type': 'SizedBox',
            'properties': {'width': 16.0},
          },
        ],
      },
      'state': {
        'compliment': 'Welcome to the Cosmic Dashboard!',
        'count': 0,
        'mood': 'happy',
        'detail': '',
        'detailsVisible': false,
        'facts': [
          {'text': 'The universe is estimated to be 13.8 billion years old.'},
          {'text': 'A day on Venus is longer than a year on Venus.'},
          {
            'text':
                'There are more trees on Earth than stars in the Milky Way.',
          },
        ],
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmic Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FcpView(
        registry: _registry,
        catalog: _catalog,
        packet: _createUiPacket(),
        controller: _controller,
        onEvent: (payload) {
          switch (payload.eventName) {
            case 'onPressed':
              _getNewCompliment();
              break;
            case 'setMood':
              _setMood(payload.arguments!['mood'] as String);
              break;
            case 'onChanged':
              if (payload.sourceNodeId == 'details_toggle') {
                _toggleDetails();
              }
              break;
          }
        },
      ),
    );
  }
}
