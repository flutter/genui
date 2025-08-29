// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'src/asset_images.dart';
import 'src/catalog.dart';
import 'src/widgets/conversation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('debug'),
  );
  _imagesJson = await assetImageCatalogJson();
  configureGenUiLogging(level: Level.ALL);
  runApp(const TravelApp());
}

/// The root widget for the travel application.
///
/// This widget sets up the [MaterialApp], which configures the overall theme,
/// title, and home page for the app. It serves as the main entry point for the
/// user interface.
class TravelApp extends StatelessWidget {
  /// Creates a new [TravelApp].
  ///
  /// The optional [aiClient] can be used to inject a specific AI client,
  /// which is useful for testing with a mock implementation.
  const TravelApp({this.aiClient, super.key});

  /// The AI client to use for the application.
  ///
  /// If null, a default [GeminiAiClient] will be created by the
  /// [TravelPlannerPage].
  final AiClient? aiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dynamic UI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: TravelPlannerPage(aiClient: aiClient),
    );
  }
}

/// The main page for the travel planner application.
///
/// This stateful widget manages the core user interface and application logic.
/// It initializes the [GenUiManager] and [AiClient], maintains the
/// conversation history, and handles the interaction between the user, the AI,
/// and the dynamically generated UI.
///
/// The page allows users to interact with the generative AI to plan trips. It
/// features a text field to send prompts, a view to display the dynamically
/// generated UI, and a menu to switch between different AI models.
class TravelPlannerPage extends StatefulWidget {
  /// Creates a new [TravelPlannerPage].
  ///
  /// An optional [aiClient] can be provided, which is useful for testing
  /// or using a custom AI client implementation. If not provided, a default
  /// [GeminiAiClient] is created.
  const TravelPlannerPage({this.aiClient, super.key});

  /// The AI client to use for the application.
  ///
  /// If null, a default instance of [GeminiAiClient] will be created within
  /// the page's state.
  final AiClient? aiClient;

  @override
  State<TravelPlannerPage> createState() => _TravelPlannerPageState();
}

class _TravelPlannerPageState extends State<TravelPlannerPage> {
  late final GenUiManager _genUiManager;
  late final AiClient _aiClient;
  late final UiEventManager _eventManager;
  final List<ChatMessage> _conversation = [];
  final _textController = TextEditingController();
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _genUiManager = GenUiManager(catalog: catalog);
    _eventManager = UiEventManager(callback: _onUiEvents);
    _aiClient =
        widget.aiClient ??
        GeminiAiClient(
          tools: _genUiManager.getTools(),
          systemInstruction: prompt,
        );
    _genUiManager.surfaceUpdates.listen((update) {
      setState(() {
        switch (update) {
          case SurfaceAdded(:final surfaceId, :final definition):
            _conversation.add(
              AiUiMessage(definition: definition, surfaceId: surfaceId),
            );

          case SurfaceRemoved(:final surfaceId):
            _conversation.removeWhere(
              (m) => m is AiUiMessage && m.surfaceId == surfaceId,
            );
          case SurfaceUpdated(:final surfaceId, :final definition):
            final index = _conversation.lastIndexWhere(
              (m) => m is AiUiMessage && m.surfaceId == surfaceId,
            );
            if (index != -1) {
              _conversation[index] = AiUiMessage(
                definition: definition,
                surfaceId: surfaceId,
              );
            }
        }
      });
    });
  }

  @override
  void dispose() {
    _genUiManager.dispose();
    _eventManager.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _triggerInference() async {
    setState(() {
      _isThinking = true;
    });
    try {
      final result = await _aiClient.generateContent(
        _conversation,
        S.object(
          properties: {
            'result': S.boolean(
              description: 'Successfully generated a response UI.',
            ),
            'message': S.string(
              description:
                  'A message about what went wrong, or a message responding to '
                  'the request. Take into account any UI that has been '
                  "generated, so there's no need to duplicate requests or "
                  'information already present in the UI.',
            ),
          },
          required: ['result'],
        ),
      );
      if (result == null) {
        return;
      }
      final value =
          (result as Map).cast<String, Object?>()['message'] as String? ?? '';
      if (value.isNotEmpty) {
        setState(() {
          _conversation.add(AiTextMessage.text(value));
        });
      }
    } finally {
      setState(() {
        _isThinking = false;
      });
    }
    return;
  }

  void _onUiEvents(String surfaceId, List<UiEvent> events) {
    final actionEvent = events.firstWhere((e) => e.isAction);
    final message = StringBuffer(
      'The user triggered the "${actionEvent.eventType}" event on widget '
      '"${actionEvent.widgetId}"',
    );
    final value = actionEvent.value;
    if (value is String && value.isNotEmpty) {
      message.write(' with value "$value"');
    }
    message.write('.');

    final changeEvents = events.where((e) => !e.isAction).toList();
    if (changeEvents.isNotEmpty) {
      message.writeln(' Current values of other widgets:');
      for (final event in changeEvents) {
        message.writeln('- Widget "${event.widgetId}": ${event.value}');
      }
    }

    setState(() {
      _conversation.add(UserMessage.text(message.toString()));
    });
    _triggerInference();
  }

  void _handleUiEvent(UiEvent event) {
    _eventManager.add(event);
  }

  void _sendPrompt(String text) {
    if (_isThinking || text.trim().isEmpty) return;
    setState(() {
      _conversation.add(UserMessage.text(text));
    });
    _textController.clear();
    _triggerInference();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: const Icon(Icons.menu),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 16.0), // Add spacing between icon and text
            Text('Dynamic UI Demo'),
          ],
        ),
        actions: [
          ValueListenableBuilder<AiModel>(
            valueListenable: _aiClient.model,
            builder: (context, currentModel, child) {
              return PopupMenuButton<AiModel>(
                icon: const Icon(Icons.psychology_outlined),
                onSelected: (AiModel value) {
                  // Handle model selection
                  _aiClient.switchModel(value);
                },
                itemBuilder: (BuildContext context) {
                  return _aiClient.models.map((model) {
                    return PopupMenuItem<AiModel>(
                      value: model,
                      child: Row(
                        children: [
                          Text(model.displayName),
                          if (currentModel == model) const Icon(Icons.check),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
          const Icon(Icons.person_outline),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Conversation(
                    messages: _conversation,
                    manager: _genUiManager,
                    onEvent: _handleUiEvent,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _ChatInput(
                  controller: _textController,
                  isThinking: _isThinking,
                  onSend: _sendPrompt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isThinking,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isThinking;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(25.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isThinking,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Enter your prompt...',
                ),
                onSubmitted: isThinking ? null : onSend,
              ),
            ),
            if (isThinking)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            else
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => onSend(controller.text),
              ),
          ],
        ),
      ),
    );
  }
}

String? _imagesJson;

final prompt =
    '''
You are a helpful travel agent assistant. Use the provided tools to build and
manage the user interface in response to the user's requests. Call the
`addOrUpdateSurface` tool to show new content or update existing content. Use
the `deleteSurface` tool to remove UI that is no longer relevant.

The user will ask questions, and you will respond by generating appropriate UI
elements. Instead of asking for information via text, prefer using UI elements
like `FilterChipGroup` or `OptionsFilterChip` to get user input. Typically, you
will first elicit more information to understand the user's needs, then you
will start displaying information and the user's plans.

You should typically first show some options with a TravelCarousel and also
ask more about the user request using filter chips.

After you refine the search, show a 'ItineraryWithDetails' widget with the
final trip.

# Example
For example, a user may say "I want to plan a trip to Mexico".
You will first find out more information by showing filter chips etc.

Then you will generate a result which includes a detailed itinerary, which
uses the ItineraryWithDetails widget. Typically, you should keep the filter
chips *and* the ItineraryWithDetails together in a Column, so the user can
refine their search.

When you provide results like this, you should show another set of "Trailhead"
buttons below to allow the user to explore more topics. E.g. for mexico, after
generating an itinerary, you might include a Trailhead with directions like
"top culinary experiences in Mexico" or "nightlife areas in Mexico city".

The user may ask followup questions e.g. to book a specific part of the
existing trip, or start a new trip. In this case, just follow the user and
repeat the process above. You are always moving in cycles of asking for
information and then making suggestions. If the user requests something other
than a complete trip booking, e.g. ideas about jazz clubs or food tours etc,
use something like a TravelCarousel to show options, rather than a full
ItineraryWithDetails. If the followup question seems to be a departure from
the previous context, 'add' a new surface rather than updating an existing one.

# UI style

When generating content to go inside ItineraryWithDetails, use
ItineraryItem, but try to occasionally break it up with other widgets e.g.
SectionHeader items to break up the section, or TravelCarousel with related
content. E.g. after an itinerary item like a beach visit, you could include a
carousel of local fish, or alternative beaches to visit.

When you are asking for information from the user, you should always include a
submit button of some kind so that the user can indicate that they are done
providing information. The `FilterChipGroup` has a submit button, but if you
are not using that, you can use an `ElevatedButton`. Only use `OptionsFilterChip`
widgets inside of a `FilterChipGroup`.

If you need to use any images, try to find the most relevant ones from the
following asset images. Do not make up new image names, only use these:
${_imagesJson ?? ''}

Here is an example of the arguments to the `addOrUpdateSurface` tool. Note that
the `root` widget ID must be present in the `widgets` list, and it should
contain the other widgets.
```json
{
  "surfaceId": "mexico_trip_planner",
  "definition": {
    "root": "root_column",
    "widgets": [
      {
        "id": "root_column",
        "widget": {
          "Column": {
            "children": [
              "trip_title",
              "itinerary"
            ]
          }
        }
      },
      {
        "id": "trip_title",
        "widget": {
          "Text": {
            "text": "Trip to Mexico City"
          }
        }
      },
      {
        "id": "itinerary",
        "widget": {
          "ItineraryWithDetails": {
            "title": "Mexico City Adventure",
            "subheading": "3-day Itinerary",
            "imageChildId": "mexico_city_image",
            "child": "itinerary_details"
          }
        }
      },
      {
        "id": "mexico_city_image",
        "widget": {
          "Image": {
            "assetName": "assets/travel_images/mexico_city.jpg"
          }
        }
      },
      {
        "id": "itinerary_details",
        "widget": {
          "Column": {
            "children": [
              "day1",
              "day2",
              "day3"
            ]
          }
        }
      },
      {
        "id": "day1",
        "widget": {
          "ItineraryItem": {
            "title": "Day 1: Arrival and Exploration",
            "subtitle": "Arrival and Zocalo",
            "detailText": "Arrive at Mexico City International Airport (MEX) and check into your hotel. In the afternoon, explore the Zocalo, the main square of Mexico City."
          }
        }
      },
      {
        "id": "day2",
        "widget": {
          "ItineraryItem": {
            "title": "Day 2: Teotihuacan",
            "subtitle": "Ancient pyramids",
            "detailText": "Visit the ancient city of Teotihuacan and climb the Pyramids of the Sun and Moon."
          }
        }
      },
      {
        "id": "day3",
        "widget": {
          "ItineraryItem": {
            "title": "Day 3: Frida Kahlo Museum",
            "subtitle": "Casa Azul",
            "detailText": "Explore the life and art of Frida Kahlo at her former home, the Casa Azul."
          }
        }
      }
    ]
  }
}
```

When updating or showing UIs, **ALWAYS** use the addOrUpdateSurface tool to supply them. Prefer to collect and show information by creating a UI for it. When showing an itinerary, don't return it as text, use an ItineraryWithDetails widget.
''';
