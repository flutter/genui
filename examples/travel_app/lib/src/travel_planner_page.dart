// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';

import 'asset_images.dart';
import 'catalog.dart';
import 'config/configuration.dart';
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
/// It initializes the [A2uiMessageProcessor] and [ContentGenerator], maintains
/// the conversation history, and handles the interaction between the user, the
/// AI, and the dynamically generated UI.
///
/// The page allows users to interact with the generative AI to plan trips. It
/// features a text field to send prompts, a view to display the dynamically
/// generated UI, and a menu to switch between different AI models.
class TravelPlannerPage extends StatefulWidget {
  /// Creates a new [TravelPlannerPage].
  ///
  /// An optional [contentGenerator] can be provided, which is useful for
  /// testing or using a custom AI client implementation. If not provided, a
  /// default [FirebaseAiContentGenerator] is created.
  const TravelPlannerPage({this.contentGenerator, super.key});

  /// The AI client to use for the application.
  ///
  /// If null, a default instance of [FirebaseAiContentGenerator] will be
  /// created within the page's state.
  final ContentGenerator? contentGenerator;

  @override
  State<TravelPlannerPage> createState() => _TravelPlannerPageState();
}

class _TravelPlannerPageState extends State<TravelPlannerPage>
    with AutomaticKeepAliveClientMixin {
  late final GenUiConversation _uiConversation;
  late final StreamSubscription<ChatMessage> _userMessageSubscription;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final a2uiMessageProcessor = A2uiMessageProcessor(
      catalogs: [travelAppCatalog],
    );
    _userMessageSubscription = a2uiMessageProcessor.onSubmit.listen(
      _handleUserMessageFromUi,
    );

    // Create the appropriate content generator based on configuration
    final ContentGenerator contentGenerator =
        widget.contentGenerator ??
        switch (aiBackend) {
          AiBackend.googleGenerativeAi => () {
            return GoogleGenerativeAiContentGenerator(
              catalog: travelAppCatalog,
              systemInstruction: prompt,
              additionalTools: [
                ListHotelsTool(
                  onListHotels: BookingService.instance.listHotels,
                ),
              ],
              apiKey: getApiKey(),
            );
          }(),
          AiBackend.firebase => FirebaseAiContentGenerator(
            catalog: travelAppCatalog,
            systemInstruction: prompt,
            additionalTools: [
              ListHotelsTool(onListHotels: BookingService.instance.listHotels),
            ],
          ),
        };

    _uiConversation = GenUiConversation(
      a2uiMessageProcessor: a2uiMessageProcessor,
      contentGenerator: contentGenerator,
      onSurfaceUpdated: (update) {
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

  @override
  void dispose() {
    _userMessageSubscription.cancel();
    _uiConversation.dispose();
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

  void _handleUserMessageFromUi(ChatMessage message) {
    _scrollToBottom();
  }

  void _sendPrompt(String text) {
    if (_uiConversation.isProcessing.value || text.trim().isEmpty) return;
    _scrollToBottom();
    _textController.clear();
    _triggerInference(UserMessage.text(text));
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
                      manager: _uiConversation.a2uiMessageProcessor,
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

Use the provided tools to build and manage the user interface in response to the
user's requests. To display or update a UI, you must first call the
`surfaceUpdate` tool to define all the necessary components. After defining the
components, you must call the `beginRendering` tool to specify the root
component that should be displayed.

- Adding surfaces: Most of the time, you should only add new surfaces to the
  conversation. This is less confusing for the user, because they can easily
  find this new content at the bottom of the conversation.
- Updating surfaces: You should update surfaces when you are running an
  iterative search flow, e.g. the user is adjusting filter values and generating
  an itinerary or a booking accommodation etc. This is less confusing for the
  user because it avoids confusing the conversation with many versions of the
  same itinerary etc.

Once you add or update a surface and are waiting for user input, the
conversation turn is complete, and you should call the provideFinalOutput tool.

If you are displaying more than one component, you should use a `Column` widget
as the root and add the other components as children.

## UI style

Always prefer to communicate using UI elements rather than text. Only respond
with text if you need to provide a short explanation of how you've updated the
UI.

- TravelCarousel: Always make sure there are at least four options in the
  carousel. If there are only 2 or 3 obvious options, just think of some
  relevant alternatives that the user might be interested in.

- Guiding the user: When the user has completed some action, e.g. they confirm
  they want to book some accommodation or activity, always show a trailhead
  suggesting what the user might want to do next (e.g. book the next detail in
  the itinerary, repeat a search, research some related topic) so that they can
  click rather than typing.

- Itinerary Structure: Itineraries have a three-level structure. The root is
  `itineraryWithDetails`, which provides an overview. Inside the modal view of
  an `itineraryWithDetails`, you should use one or more `itineraryDay` widgets
  to represent each day of the trip. Each `itineraryDay` should then contain a
  list of `itineraryEntry` widgets, which represent specific activities,
  bookings, or transport for that day.

- Inputs: When you are asking for information from the user, you should always
  include a submit button of some kind so that the user can indicate that they
  are done providing information. Suggest initial values for number of people
  and travel dates (e.g. 2 guests, dates of nearest weekend). The `InputGroup`
  has a submit button, but if you are not using that, you can use an
  `ElevatedButton`. Only use `OptionsFilterChipInput` widgets inside of a
  `InputGroup`. **It is a strict requirement that all input chip widgets bind
  their state to the data model. Under no circumstances should you use a literal
  value for their state.** You should invent a suitable path in the data model
  for each input. For example: `/search/destination`,
  `/search/preferredActivities`, `/search/budget`. Specifically:

  - For `OptionsFilterChipInput`, `DateInputChip`, and `TextInputChip`, the
    `value` parameter MUST be bound to the data model using a `path`.
  - For `CheckboxFilterChipsInput`, the `selectedOptions` parameter MUST be
    bound to the data model using a `path`.

- State management: Try to maintain state by being aware of the user's
  selections and preferences and setting them in the initial value fields of
  input elements when updating surfaces or generating new ones.

## Images

If you need to use any images, find the most relevant ones from the following
list of asset images:

${_imagesJson ?? ''}

- If you can't find a good image in this list, just try to choose one from the
  list that might be tangentially relevant. DO NOT USE ANY IMAGES NOT IN THE
  LIST. It is fine if the image is unrelated, as long as it is from the list.

- Image location always should be an asset path (e.g. assets/...).

## Example

Here is an example of the arguments to the `surfaceUpdate` tool. Note that the
`root` widget ID must be present in the `widgets` list, and it should contain
the other widgets.

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
            "children": ["trip_title", "itinerary"]
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
            "location": "assets/travel_images/mexico_city.jpg"
          }
        }
      },
      {
        "id": "itinerary_details",
        "widget": {
          "Column": {
            "children": ["day1"]
          }
        }
      },
      {
        "id": "day1",
        "widget": {
          "ItineraryDay": {
            "title": "Day 1",
            "subtitle": "Arrival and Exploration",
            "description": "Your first day in Mexico City will be focused on settling in and exploring the historic center.",
            "imageChildId": "day1_image",
            "children": ["day1_entry1", "day1_entry2"]
          }
        }
      },
      {
        "id": "day1_image",
        "widget": {
          "Image": {
            "location": "assets/travel_images/mexico_city.jpg"
          }
        }
      },
      {
        "id": "day1_entry1",
        "widget": {
          "ItineraryEntry": {
            "type": "transport",
            "title": "Arrival at MEX Airport",
            "time": "2:00 PM",
            "bodyText": "Arrive at Mexico City International Airport (MEX), clear customs, and pick up your luggage.",
            "status": "noBookingRequired"
          }
        }
      },
      {
        "id": "day1_entry2",
        "widget": {
          "ItineraryEntry": {
            "type": "activity",
            "title": "Explore the Zocalo",
            "subtitle": "Historic Center",
            "time": "4:00 PM - 6:00 PM",
            "address": "Plaza de la Constitución S/N, Centro Histórico, Ciudad de México",
            "bodyText": "Head to the Zocalo, the main square of Mexico City. Visit the Metropolitan Cathedral and the National Palace.",
            "status": "noBookingRequired"
          }
        }
      }
    ]
  }
}
```

When updating or showing UIs, **ALWAYS** use the surfaceUpdate tool to supply
them. Prefer to collect and show information by creating a UI for it.
''';
