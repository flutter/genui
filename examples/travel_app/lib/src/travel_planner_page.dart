// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'ai_client/ai_client.dart';
import 'ai_client/google_generative_ai_client.dart';
import 'asset_images.dart';
import 'catalog.dart';
// Conditionally import non-web version so we can read from shell env vars in
// non-web version.
import 'config/io_get_api_key.dart'
    if (dart.library.html) 'config/web_get_api_key.dart';
import 'tools/booking/booking_service.dart';
import 'tools/booking/list_hotels_tool.dart';
import 'widgets/conversation.dart';

Future<void> loadImagesJson() async {
  _imagesJson = await assetImageCatalogJson();
}

/// The main page for the travel planner application.
///
/// This stateful widget manages the core user interface and application logic.
/// It initializes the [A2uiMessageProcessor] and [GenUiController], maintains
/// the conversation history, and handles the interaction between the user, the
/// AI, and the dynamically generated UI.
///
/// The page allows users to interact with the generative AI to plan trips. It
/// features a text field to send prompts, a view to display the dynamically
/// generated UI, and a menu to switch between different AI models.
class TravelPlannerPage extends StatefulWidget {
  /// Creates a new [TravelPlannerPage].
  ///
  /// An optional [aiClient] can be provided, which is useful for
  /// testing or using a custom AI client implementation. If not provided, a
  /// default [GoogleGenerativeAiClient] is created.
  const TravelPlannerPage({this.aiClient, super.key});

  /// The AI client to use for the application.
  ///
  /// If null, a default instance will be created.
  /// This must be an instance of [AiClient].
  final AiClient? aiClient;

  @override
  State<TravelPlannerPage> createState() => _TravelPlannerPageState();
}

class _TravelPlannerPageState extends State<TravelPlannerPage>
    with AutomaticKeepAliveClientMixin {
  late final GenUiConversation _uiConversation;
  late final GenUiController _controller;
  // We keep a reference to the client to dispose it if we created it.
  AiClient? _client;
  bool _didCreateClient = false;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = GenUiController(catalogs: [travelAppCatalog]);

    // Create the appropriate content generator based on configuration
    _client = widget.aiClient;
    if (_client == null) {
      _didCreateClient = true;
      _client = GoogleGenerativeAiClient(
        catalog: travelAppCatalog,
        systemInstruction: prompt,
        additionalTools: [
          ListHotelsTool(onListHotels: BookingService.instance.listHotels),
        ],
        apiKey: getApiKey(),
      );
    }

    _wireClient(_client!, _controller);

    _uiConversation = GenUiConversation(
      controller: _controller,
      onSend: (message, history) => _sendRequest(_client!, message, history),
      onComponentsUpdated: (update) {
        _scrollToBottom();
      },
      onSurfaceAdded: (update) {
        _scrollToBottom();
      },
      onTextResponse: (text) {
        if (!mounted) return;
        if (text.isNotEmpty) {
          _scrollToBottom();
        }
      },
    );
  }

  void _wireClient(AiClient client, GenUiController controller) {
    client.a2uiMessageStream.listen(controller.addMessage);
    client.textResponseStream.listen(controller.addChunk);
  }

  Future<void> _sendRequest(
    AiClient client,
    ChatMessage message,
    Iterable<ChatMessage> history,
  ) {
    return client.sendRequest(message, history: history);
  }

  ValueListenable<bool> get isProcessing => _uiConversation.isProcessing;

  @override
  void dispose() {
    _uiConversation.dispose();
    if (_didCreateClient) {
      _client?.dispose();
    }
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

  Future<void> _triggerInference(ChatMessage message) async {
    await _uiConversation.sendRequest(message);
  }

  void _sendPrompt(String text) {
    if (_uiConversation.isProcessing.value || text.trim().isEmpty) return;
    _scrollToBottom();
    _textController.clear();
    _triggerInference(ChatMessage.user(text));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Center(
        child: Column(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: _uiConversation.conversation,
                  builder: (context, messages, child) {
                    return Conversation(
                      messages: messages,
                      manager: _uiConversation.host,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: _uiConversation.isProcessing,
                builder: (context, isThinking, child) {
                  return _ChatInput(
                    controller: _textController,
                    isThinking: isThinking,
                    onSend: _sendPrompt,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
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
# Instructions

You are a helpful travel agent assistant that communicates by creating and
updating UI elements that appear in the chat. Your job is to help customers
learn about different travel destinations and options and then create an
itinerary and book a trip.

## Conversation flow

Conversations with travel agents should follow a rough flow. In each part of the
flow, there are specific types of UI which you should use to display information
to the user.

1.  Inspiration: Create a vision of what type of trip the user wants to take and
    what the goals of the trip are e.g. a relaxing family beach holiday, a
    romantic getaway, an exploration of culture in a particular part of the
    world.

    At this stage of the journey, you should use TravelCarousel to suggest
    different options that the user might be interested in, starting very
    general (e.g. "Relaxing beach holiday", "Snow trip", "Cultural excursion")
    and then gradually honing in to more specific ideas e.g. "A journey through
    the best art galleries of Europe").

2.  Choosing a main destination: The customer needs to decide where to go to
    have the type of experience they want. This might be general to start off,
    e.g. "South East Asia" or more specific e.g. "Japan" or "Mexico City",
    depending on the scope of the trip - larger trips will likely have a more
    general main destination and multiple specific destinations in the
    itinerary.

    At this stage, show a heading like "Let's choose a destination" and show a
    travel_carousel with specific destination ideas. When the user clicks on
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

    At this step, you should first show an inputGroup which contains several
    input chips like the number of people, the destination, the length of time,
    the budget, preferred activity types etc.

    Then, when the user clicks search, you should update the surface to have a
    Column with the existing inputGroup, an itineraryWithDetails. When creating
    the itinerary, include all necessary `itineraryEntry` items for hotels and
    transport with generic details and a status of `choiceRequired`.

    Note that during this step, the user may change their search parameters and
    resubmit, in which case you should regenerate the itinerary to match their
    desires, updating the existing surface.

4.  Booking: Booking each part of the itinerary one step at a time. This
    involves booking every accommodation, transport and activity in the
    itinerary one step at a time.

    Here, you should just focus on one item at a time, using an `inputGroup`
    with chips to ask the user for preferences, and the `travelCarousel` to show
    the user different options. When the user chooses an option, you can confirm
    it has been chosen and immediately prompt the user to book the next detail,
    e.g. an activity, hotels, transport etc. When a booking is confirmed, update
    the original `itineraryWithDetails` to reflect the booking by updating the
    relevant `itineraryEntry` to have the status `chosen` and including the
    booking details in the `bodyText`.

    When booking a hotel, use inputGroup, providing initial values for check-in
    and check-out dates (nearest weekend). Then use the `listHotels` tool to
    search for hotels and pass the values with their `listingSelectionId` to a
    `travelCarousel` to show the user different options. When user selects a
    hotel, pass the `listingSelectionId` of the selected hotel the parameter
    `listingSelectionIds` of `listingsBooker`.

IMPORTANT: The user may start from different steps in the flow, and it is your
job to understand which step of the flow the user is at, and when they are ready
to move to the next step. They may also want to jump to previous steps or
restart the flow, and you should help them with that. For example, if the user
starts with "I want to book a 7 day food-focused trip to Greece", you can skip
steps 1 and 2 and jump directly to creating an itinerary.

### Side journeys

Within the flow, users may also take side journeys. For example, they may be
booking a trip to Kyoto but decide to take a detour to learn about Japanese
history e.g. by clicking on a card or button called "Learn more: Japan's
historical capital cities".

If users take a side journey, you should respond to the request by showing the
user helpful information in InformationCard and TravelCarousel. Always add new
surfaces when doing this and do not update or delete existing ones. That way,
the user can return to the main booking flow once they have done some research.

## Controlling the UI

You can control the UI by outputting valid A2UI JSON messages wrapped in markdown code blocks.
Supported messages are: `createSurface` and `updateComponents`.

To show a new UI:
1. Output a `createSurface` message to define the surface ID and catalog.
2. Output an `updateComponents` message to populate the surface with components.

To update an existing UI (e.g. adding items to an itinerary):
1. Output an `updateComponents` message with the existing `surfaceId` and the new component definitions.

Properties:
- `createSurface`: requires `surfaceId`, `catalogId` (use the standard catalog ID provided in system instructions), and `attachDataModel: true`.
- `updateComponents`: requires `surfaceId` and a list of `components`. One component MUST have `id: "root"`.

IMPORTANT:
- Do not use tools or function calls for UI generation. Use JSON text blocks.
- Ensure all JSON is valid and fenced with ```json ... ```.

## Images

If you need to use any images, find the most relevant ones from the following
list of asset images:

${_imagesJson ?? ''}

- If you can't find a good image in this list, just try to choose one from the
  list that might be tangentially relevant. DO NOT USE ANY IMAGES NOT IN THE
  LIST. It is fine if the image is unrelated, as long as it is from the list.

- Image location always should be an asset path (e.g. assets/...).

## Example

Here is an example of creating a trip planner UI.

```json
{
  "createSurface": {
    "surfaceId": "mexico_trip_planner",
    "catalogId": "https://a2ui.dev/specification/v0_9/standard_catalog.json",
    "attachDataModel": true
  }
}
```

```json
{
  "updateComponents": {
    "surfaceId": "mexico_trip_planner",
    "components": [
      {
        "id": "root",
        "component": "Column",
        "children": ["trip_title", "itinerary"]
      },
      {
        "id": "trip_title",
        "component": "Text",
        "text": "Trip to Mexico City",
        "variant": "h2"
      },
      {
        "id": "itinerary",
        "component": "ItineraryWithDetails",
        "title": "Mexico City Adventure",
        "subheading": "3-day Itinerary",
        "imageChildId": "mexico_city_image",
        "child": "itinerary_details"
      },
      {
        "id": "mexico_city_image",
        "component": "Image",
        "url": { "literalString": "assets/travel_images/mexico_city.jpg" }
      },
      {
        "id": "itinerary_details",
        "component": "Column",
        "children": ["day1"]
      },
      {
        "id": "day1",
        "component": "ItineraryDay",
        "title": "Day 1",
        "subtitle": "Arrival and Exploration",
        "description": "Your first day in Mexico City...",
        "imageChildId": "day1_image",
        "children": ["day1_entry1"]
      },
      {
        "id": "day1_image",
        "component": "Image",
        "url": { "literalString": "assets/travel_images/mexico_city.jpg" }
      },
      {
        "id": "day1_entry1",
        "component": "ItineraryEntry",
        "type": "transport",
        "title": "Arrival at MEX Airport",
        "time": "2:00 PM",
        "bodyText": "Arrive at Mexico City...",
        "status": "noBookingRequired"
      }
    ]
  }
}
```

When updating or showing UIs, **ALWAYS** use the JSON messages as described above. Prefer to collect and show information by creating a UI for it.
''';
