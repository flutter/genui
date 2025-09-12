// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../asset_images.dart';
import '../catalog.dart';

/// Global variable to store the asset images JSON for prompt injection
String? _imagesJson;

/// Controller for managing travel planner canvas state and interactions.
///
/// This class extracts the core logic from the original TravelPlannerPage
/// to make it reusable across different UI layouts (inline chat, side chat, no
/// chat).
/// It maintains the same approach as the legacy code without external
/// dependencies.
class TravelPlannerCanvasController {
  /// Initializes the asset images JSON for use in prompts.
  /// This should be called once at app startup, similar to main.dart.
  static Future<void> initializeAssetImages() async {
    _imagesJson = await assetImageCatalogJson();
  }

  /// Creates a new [TravelPlannerCanvasController].
  ///
  /// [enableChatOutput] determines whether the AI can output text messages
  /// in addition to UI surfaces. If false, the AI communicates only through UI.
  ///
  /// Optional [genUiManager] and [aiClient] can be provided for testing.
  TravelPlannerCanvasController({
    this.enableChatOutput = true,
    GenUiManager? genUiManager,
    AiClient? aiClient,
  }) {
    _genUiManager =
        genUiManager ??
        GenUiManager(
          catalog: travelAppCatalog,
          configuration: const GenUiConfiguration(
            actions: ActionsConfig(
              allowCreate: true,
              allowUpdate: true,
              allowDelete: true,
            ),
          ),
        );

    _userMessageSubscription = _genUiManager.onSubmit.listen(
      _handleUserMessageFromUi,
    );

    _aiClient =
        aiClient ??
        FirebaseAiClient(
          tools: _genUiManager.getTools(),
          systemInstruction: _getPrompt(),
        );

    _genUiManager.surfaceUpdates.listen((update) {
      switch (update) {
        case SurfaceAdded(:final surfaceId, :final definition):
          _conversation.add(
            AiUiMessage(definition: definition, surfaceId: surfaceId),
          );
          _limitSurfaces();
          _notifyListeners();

        case SurfaceRemoved(:final surfaceId):
          _conversation.removeWhere(
            (m) => m is AiUiMessage && m.surfaceId == surfaceId,
          );
          _notifyListeners();

        case SurfaceUpdated(:final surfaceId, :final definition):
          final index = _conversation.lastIndexWhere(
            (m) => m is AiUiMessage && m.surfaceId == surfaceId,
          );
          if (index != -1) {
            _conversation[index] = AiUiMessage(
              definition: definition,
              surfaceId: surfaceId,
            );
            _notifyListeners();
          }
      }
    });
  }

  final bool enableChatOutput;
  late final GenUiManager _genUiManager;
  late final AiClient _aiClient;
  late final StreamSubscription<UserMessage> _userMessageSubscription;

  final List<ChatMessage> _conversation = [];
  bool _isThinking = false;

  // Stream controllers for reactive updates
  final _surfacesController =
      StreamController<Iterable<AiUiMessage>>.broadcast();
  final _textMessagesController =
      StreamController<Iterable<ChatMessage>>.broadcast();
  final _isThinkingController = StreamController<bool>.broadcast();

  /// Stream of UI surfaces to render
  Stream<Iterable<AiUiMessage>> get surfaces => _surfacesController.stream;

  /// Stream of text messages to render in chat
  Stream<Iterable<ChatMessage>> get textMessages =>
      _textMessagesController.stream;

  /// Stream indicating whether the LLM is currently processing
  Stream<bool> get isThinking => _isThinkingController.stream;

  /// The GenUiManager instance used by this controller
  GenUiManager get genUiManager => _genUiManager;

  /// Current list of surfaces
  Iterable<AiUiMessage> get currentSurfaces =>
      _conversation.whereType<AiUiMessage>();

  /// Current list of text messages
  Iterable<ChatMessage> get currentTextMessages =>
      _conversation.where((m) => m is! AiUiMessage);

  /// Current thinking state
  bool get currentIsThinking => _isThinking;

  /// Current list of all messages
  Iterable<ChatMessage> get conversation => List.unmodifiable(_conversation);

  void dispose() {
    _genUiManager.dispose();
    _userMessageSubscription.cancel();
    _surfacesController.close();
    _textMessagesController.close();
    _isThinkingController.close();
  }

  /// Sends a user text message and triggers AI inference
  void sendUserTextMessage(String message) {
    if (_isThinking || message.trim().isEmpty) return;

    _conversation.add(UserMessage.text(message));
    _notifyListeners();
    _triggerInference();
  }

  void _handleUserMessageFromUi(UserMessage message) {
    _conversation.add(UserUiInteractionMessage.text(message.text));
    _notifyListeners();
    _triggerInference();
  }

  /// Limits surfaces to 4 maximum, removing oldest first
  void _limitSurfaces() {
    final surfaces = _conversation.whereType<AiUiMessage>().toList();
    while (surfaces.length > 4) {
      final oldestSurface = surfaces.removeAt(0);
      _conversation.removeWhere(
        (m) => m is AiUiMessage && m.surfaceId == oldestSurface.surfaceId,
      );
      _genUiManager.deleteSurface(oldestSurface.surfaceId);
    }
  }

  Future<void> _triggerInference() async {
    _isThinking = true;
    _isThinkingController.add(_isThinking);

    try {
      final schema = enableChatOutput
          ? S.object(
              properties: {
                'result': S.boolean(
                  description: 'Successfully generated a response UI.',
                ),
                'message': S.string(
                  description:
                      'A message about what went wrong, or a message responding'
                      'to the request. Take into account any UI that has been '
                      "generated, so there's no need to duplicate requests or "
                      'information already present in the UI.',
                ),
              },
              required: ['result'],
            )
          : S.object(
              properties: {
                'result': S.boolean(
                  description: 'Successfully generated a response UI.',
                ),
              },
              required: ['result'],
            );

      final result = await _aiClient.generateContent(_conversation, schema);

      if (result == null) return;

      if (enableChatOutput) {
        final message =
            (result as Map).cast<String, Object?>()['message'] as String? ?? '';
        if (message.isNotEmpty) {
          _conversation.add(AiTextMessage.text(message));
          _notifyListeners();
        }
      }
    } finally {
      _isThinking = false;
      _isThinkingController.add(_isThinking);
    }
  }

  void _notifyListeners() {
    _surfacesController.add(currentSurfaces);
    _textMessagesController.add(currentTextMessages);
  }

  String _getPrompt() {
    final basePrompt =
        '''
You are a helpful travel agent assistant that communicates by creating and
updating UI elements${enableChatOutput ? ' that appear in the chat' : ''}. Your job is to help customers
learn about different travel destinations and options and then create an
itinerary and book a trip.

# Surface Management

${enableChatOutput ? '' : '''
IMPORTANT: You communicate ONLY through UI surfaces. You cannot send text messages - all 
communication must be through creating, updating, or deleting UI elements. 
Make sure your UI is self-explanatory and guides the user clearly.

'''}You should maintain a focused set of UI surfaces. Follow these rules:
- Keep a MAXIMUM of 4 surfaces active at any time
- Delete irrelevant or outdated surfaces to make room for new ones
- Prioritize the most recent and relevant surfaces for the current conversation

When managing surfaces:
- Delete old surfaces that are no longer relevant to the current flow
- Update existing surfaces when iterating on the same content (e.g., refining an itinerary)
- Add new surfaces for new topics or when exploring side journeys

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

    At this step, you should first show an inputGroup which contains
    several input chips like the number of people, the destination, the length
    of time, the budget, preferred activity types etc.

    Then, when the user clicks search, you should update the surface to have
    a Column with the existing inputGroup, an itineraryWithDetails. When
    creating the itinerary, include all necessary `itineraryEntry` items for
    hotels and transport with generic details and a status of `choiceRequired`.
    
    Note that during this step, the user may change their search parameters and
    resubmit, in which case you should regenerate the itinerary to match their
    desires, updating the existing surface.

4.  Booking: Booking each part of the itinerary one step at a time. This
    involves booking every accommodation, transport and activity in the itinerary
    one step at a time.

    Here, you should just focus on one item at a time, using an `inputGroup`
    with chips to ask the user for preferences, and the `travelCarousel` to show
    the user different options. When the user chooses an option, you can confirm
    it has been chosen and immediately prompt the user to book the next detail,
    e.g. an activity, accommodation, transport etc. When a booking is confirmed,
    update the original `itineraryWithDetails` to reflect the booking by
    updating the relevant `itineraryEntry` to have the status `chosen` and
    including the booking details in the `bodyText`.

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

Always prefer to communicate using UI elements rather than text. ${enableChatOutput ? 'Only respond with text if you need to provide a short explanation of how you\'ve updated the UI.' : ''}

- TravelCarousel: Always make sure there are at least four options in the
carousel. If there are only 2 or 3 obvious options, just think of some relevant
alternatives that the user might be interested in.

- Guiding the user: When the user has completes some action, e.g. they confirm
they want to book some accomodation or activity, always show a trailhead
suggesting what the user might want to do next (e.g. book the next detail in the
itinerary, repeat a search, research some related topic) so that they can click
rather than typing.

- Itinerary Structure: Itineraries have a three-level structure. The root is
`itineraryWithDetails`, which provides an overview. Inside the modal view of an
`itineraryWithDetails`, you should use one or more `itineraryDay` widgets to
represent each day of the trip. Each `itineraryDay` should then contain a list
of `itineraryEntry` widgets, which represent specific activities, bookings, or
transport for that day.

- Inputs: When you are asking for information from the user, you should always include a
submit button of some kind so that the user can indicate that they are done
providing information. The `InputGroup` has a submit button, but if
you are not using that, you can use an `ElevatedButton`. Only use
`OptionsFilterChipInput` widgets inside of a `InputGroup`.

- State management: Try to maintain state by being aware of the user's
  selections and preferences and setting them in the initial value fields of
  input elements when updating surfaces or generating new ones.

# Images

If you need to use any images, find the most relevant ones from the following
list of asset images:

${_imagesJson ?? ''}

- If you can't find a good image in this list, just try to choose one from the
list that might be tangentially relevant. DO NOT USE ANY IMAGES NOT IN THE LIST.
It is fine if the image is irrelevant, as long as it is from the list.

- Use assetName for images from the list only - NEVER use `url` and reference
images from wikipedia or other sites.

When updating or showing UIs, **ALWAYS** use the addOrUpdateSurface tool to supply them. Prefer to collect and show information by creating a UI for it.
''';

    return basePrompt;
  }
}
