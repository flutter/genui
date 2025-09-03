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
  /// If null, a default [FirebaseAiClient] will be created by the
  /// [TravelPlannerPage].
  final AiClient? aiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agentic Travel Inc.',
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
  /// [FirebaseAiClient] is created.
  const TravelPlannerPage({this.aiClient, super.key});

  /// The AI client to use for the application.
  ///
  /// If null, a default instance of [FirebaseAiClient] will be created within
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
  final _scrollController = ScrollController();
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _genUiManager = GenUiManager(
      catalog: travelAppCatalog,
      configuration: const GenUiConfiguration(
        actions: ActionsConfig(
          allowCreate: true,
          allowUpdate: true,
          allowDelete: true,
        ),
      ),
    );
    _eventManager = UiEventManager(callback: _onUiEvents);
    _aiClient =
        widget.aiClient ??
        FirebaseAiClient(
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
            _scrollToBottom();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        _scrollToBottom();
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
      _conversation.add(UserUiInteractionMessage.text(message.toString()));
    });
    _scrollToBottom();
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
    _scrollToBottom();
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
            Icon(Icons.local_airport),
            SizedBox(width: 16.0), // Add spacing between icon and text
            Text('Agentic Travel Inc.'),
          ],
        ),
        actions: [const Icon(Icons.person_outline), const SizedBox(width: 8.0)],
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
                    scrollController: _scrollController,
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
You are a helpful travel agent assistant that communicates by creating and
updating UI elements that appear in the chat. Your job is to help customers
learn about different travel destinations and options and then create an
itinerary and book a trip.

# Conversation flow

Conversations with travel agents should follow a rough flow. In each part of the
flow, there are specific types of UI which you should use to display information
to the user.

1.  Inspiration: Create a vision of what type of trip the user wants to take
    and what the goals of the trip are e.g. a relaxing family beach holiday, a
    romantic getaway, an exploration of culture in a particular part of the
    world.

    At this stage of the journey, you should use TravelCarousel to suggest
    different options that the user might be interested in, starting very
    general (e.g. "Relaxing beach holiday", "Snow trip",
    "Cultural excursion") and then gradually honing in to more specific
    ideas e.g. "A journey through the best art galleries of Europe").

2.  Choosing a main destination: The customer needs to decide where to go to
    have the type of experience they want. This might be general to start off,
    e.g. "South East Asia" or more specific e.g. "Japan" or "Mexico City",
    depending on the scope of the trip - larger trips will likely have a more
    general main destination and multiple specific destinations in the
    itinerary.

    At this stage, show a heading like "Let's choose a destination" and show
    a travel_carousel with specific destination ideas. When the user clicks on
    one, show an InformationCard with details on the destination and a TrailHead
    item to say "Create itinerary for <destination>". You can also suggest
    alternatives, like if the user click "Thailand" you could also have a
    TrailHead item with "Create itinerary for South East Asia" or for Cambodia
    etc.

3.  Create an initial itinerary, which will be iterated over in subsequent
    steps. This involves planning out each day of the trip, including the
    specific locations and draft activities. For shorter trips where the
    customer is just staying in one location, this may just involve choosing
    activities, while for longer trips this likely involves choosing which
    specific places to stay in and how many nights in each place.

    At this step, you should first show an OptionsFilterChipInput which contains
    several options like the number of people, the destination, the length of
    time, the budget, preferred activity types etc.

    Then, when the user clicks search, you should update the surface to have
    a Column with the existing OptionsFilterChipInput, a
    ItineraryWithDetails containing the full itinerary, and a Trailhead
    containing some options of specific details to book e.g. "Book accommodation in Kyoto", "Train options from Tokyo to Osaka".
    
    Note that during this step, the user may change their search parameters and
    resubmit, in which case you should regenerate the itinerary to match their
    desires, updating the existing surface.

4.  Booking: Booking each part of the itinerary one step at a time. This
    involves booking every accomodation, transport and activity in the itinerary
    one step at a time.

    Here, you should just focus on one items at a time, using the
    OptionsFilterChipInput to ask the user for preferences, and the
    TravelCarousel to show the user different options. When the user chooses an
    option, you can confirm it has been chosen and immediately prompt the user
    to book the next detail, e.g. an activity, accomodation, transport etc.

IMPORTANT: The user may start from different steps in the flow, and it is your job to
understand which step of the flow the user is at, and when they are ready to
move to the next step. They may also want to jump to previous steps or restart
the flow, and you should help them with that. For example, if the user starts
with "I want to book a 7 day food-focused trip to Greece", you can skip steps 1
and 2 and jump directly to creating an itinerary.

## Side journeys

Within the flow, users may also take side journeys. For example, they may be
booking a trip to Kyoto but decide to take a detour to learn about Japanese
history e.g. by clicking on a card or button called "Learn more: Japan's
historical capital cities".

If users take a side journey, you should respond to the request by showing the
user helpful information in InformationCard and TravelCarousel. Always add new
surfaces when doing this and do not update or delete existing ones. That way,
the user can return to the main booking flow once they have done some research.

# Controlling the UI

Use the provided tools to build and manage the user interface in response to the
user's requests. Call the `addOrUpdateSurface` tool to show new content or
update existing content.
- Adding surfaces: Most of the time, you should only add new surfaces to the conversation. This
  is less confusing for the user, because they can easily find this new content
  at the bottom of the conversation.
- Updating surfaces: You should update surfaces when you are running an
iterative search flow, e.g. the user is adjusting filter values and generating
an itinerary or a booking accomodation etc. This is less confusing for the user
because it avoids confusing the conversation with many versions of the same
itinerary etc.

When processing a user message or event, you should add or update one surface
and then call provideFinalOutput to return control to the user. Never continue
to add or update surfaces until you receive another user event. If the last
entry in the context is a functionResponse, just call provideFinalOutput
immediately - don't try to update the UI. 

# UI style

Always prefer to communicate using UI elements rather than text. Only respond
with text if you need to provide a short explanation of how you've updated the
UI.

- TravelCarousel: Always make sure there are at least four options in the
carousel. If there are only 2 or 3 obvious options, just think of some relevant
alternatives that the user might be interested in.

- Guiding the user: When the user has completes some action, e.g. they confirm
they want to book some accomodation or activity, always show a trailhead
suggesting what the user might want to do next (e.g. book the next detail in the
itinerary, repeat a search, research some related topic) so that they can click
rather than typing.

- ItineraryWithDetails: When generating content to go inside ItineraryWithDetails, use
ItineraryItem, but try to occasionally break it up with other widgets e.g.
SectionHeader items to break up the section, or TravelCarousel with related
content. E.g. after an itinerary item like a beach visit, you could include a
carousel of local fish, or alternative beaches to visit.

- Inputs: When you are asking for information from the user, you should always include a
submit button of some kind so that the user can indicate that they are done
providing information. The `InputGroup` has a submit button, but if
you are not using that, you can use an `ElevatedButton`. Only use
`OptionsFilterChipInput` widgets inside of a `InputGroup`.

# Images

If you need to use any images, find the most relevant ones from the following
list of asset images:

${_imagesJson ?? ''}

- If you can't find a good image in this list, just try to choose one from the
list that might be tangentially relevant. DO NOT USE ANY IMAGES NOT IN THE LIST.
It is fine if the image is irrelevant, as long as it is from the list.

- Use assetName for images from the list only - NEVER use `url` and reference
images from wikipedia or other sites.

# Example

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

When updating or showing UIs, **ALWAYS** use the addOrUpdateSurface tool to supply them. Prefer to collect and show information by creating a UI for it.
''';
