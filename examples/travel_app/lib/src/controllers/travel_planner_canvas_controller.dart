// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../catalog.dart';

/// Controller for managing travel planner canvas state and interactions.
///
/// This class manages the state of UI surfaces and text messages for the
/// travel planner application. It handles communication with the AI client
/// and provides streams for UI updates.
class TravelPlannerCanvasController {
  /// Creates a new [TravelPlannerCanvasController].
  ///
  /// [enableChatOutput] determines whether the AI can output text messages
  /// in addition to UI surfaces. If false, the AI communicates only through UI.
  ///
  /// Optional [genUiManager] and [aiClient] can be provided for testing.
  TravelPlannerCanvasController({
    required this.enableChatOutput,
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

    _aiClient =
        aiClient ??
        FirebaseAiClient(
          tools: _genUiManager.getTools(),
          systemInstruction: _buildSystemPrompt(),
        );

    _initialize();
  }

  final bool enableChatOutput;
  late final GenUiManager _genUiManager;
  late final AiClient _aiClient;

  /// The GenUiManager instance used by this controller.
  GenUiManager get genUiManager => _genUiManager;
  late final StreamSubscription<UserMessage> _userMessageSubscription;

  final List<ChatMessage> _persistentTextMessages = [];
  final List<AiUiMessage> _surfaces = [];

  final _surfacesController =
      StreamController<Iterable<AiUiMessage>>.broadcast();
  final _textMessagesController =
      StreamController<Iterable<ChatMessage>>.broadcast();
  final _isThinkingController = StreamController<bool>.broadcast();

  bool _isThinking = false;

  /// A stream of UI surfaces to render.
  Stream<Iterable<AiUiMessage>> get surfaces => _surfacesController.stream;

  /// A stream of text messages to render in chat.
  Stream<Iterable<ChatMessage>> get textMessages =>
      _textMessagesController.stream;

  /// A stream indicating whether the LLM is currently processing.
  Stream<bool> get isThinking => _isThinkingController.stream;

  /// Current list of surfaces.
  Iterable<AiUiMessage> get currentSurfaces => List.unmodifiable(_surfaces);

  /// Current list of text messages.
  Iterable<ChatMessage> get currentTextMessages =>
      List.unmodifiable(_persistentTextMessages);

  /// Current thinking state.
  bool get currentIsThinking => _isThinking;

  void _initialize() {
    _userMessageSubscription = _genUiManager.onSubmit.listen(
      _handleUserMessageFromUi,
    );

    _genUiManager.surfaceUpdates.listen((update) {
      switch (update) {
        case SurfaceAdded(:final surfaceId, :final definition):
          _surfaces.add(
            AiUiMessage(definition: definition, surfaceId: surfaceId),
          );
          _limitSurfaces();
          _surfacesController.add(currentSurfaces);

        case SurfaceRemoved(:final surfaceId):
          _surfaces.removeWhere((m) => m.surfaceId == surfaceId);
          _surfacesController.add(currentSurfaces);

        case SurfaceUpdated(:final surfaceId, :final definition):
          final index = _surfaces.lastIndexWhere(
            (m) => m.surfaceId == surfaceId,
          );
          if (index != -1) {
            _surfaces[index] = AiUiMessage(
              definition: definition,
              surfaceId: surfaceId,
            );
            _surfacesController.add(currentSurfaces);
          }
      }
    });

    // Emit initial empty states
    _surfacesController.add(currentSurfaces);
    _textMessagesController.add(currentTextMessages);
    _isThinkingController.add(_isThinking);
  }

  /// Limits the number of surfaces to a maximum of 4, removing oldest first.
  void _limitSurfaces() {
    while (_surfaces.length > 4) {
      final oldestSurface = _surfaces.removeAt(0);
      _genUiManager.deleteSurface(oldestSurface.surfaceId);
    }
  }

  /// Sends a user text message.
  void sendUserTextMessage(String message) {
    if (_isThinking || message.trim().isEmpty) return;

    final userMessage = UserMessage.text(message);
    _persistentTextMessages.add(userMessage);
    _textMessagesController.add(currentTextMessages);

    _triggerInference(userMessage);
  }

  void _handleUserMessageFromUi(UserMessage message) {
    final uiInteractionMessage = UserUiInteractionMessage.text(message.text);
    _persistentTextMessages.add(uiInteractionMessage);
    _textMessagesController.add(currentTextMessages);

    _triggerInference(uiInteractionMessage);
  }

  Future<void> _triggerInference(ChatMessage triggeringEvent) async {
    _setThinking(true);

    try {
      // Build conversation in the specified order:
      // 1. Persistent text messages (already seen by LLM)
      // 2. Current surfaces
      // 3. The triggering event
      final conversation = <ChatMessage>[
        ..._persistentTextMessages.where((m) => m != triggeringEvent),
        ..._surfaces,
        triggeringEvent,
      ];

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

      final result = await _aiClient.generateContent(conversation, schema);

      if (result == null) {
        return;
      }

      if (enableChatOutput) {
        final message =
            (result as Map).cast<String, Object?>()['message'] as String? ?? '';
        if (message.isNotEmpty) {
          _persistentTextMessages.add(AiTextMessage.text(message));
          _textMessagesController.add(currentTextMessages);
        }
      }
    } finally {
      _setThinking(false);
    }
  }

  void _setThinking(bool thinking) {
    _isThinking = thinking;
    _isThinkingController.add(_isThinking);
  }

  String _buildSystemPrompt() {
    final basePrompt = '''
You are a helpful travel agent assistant that communicates by creating and
updating UI elements. Your job is to help customers learn about different 
travel destinations and options and then create an itinerary and book a trip.

# Surface Management

You should maintain a focused set of UI surfaces. Follow these rules:
- Keep a MAXIMUM of 4 surfaces active at any time
- Delete irrelevant or outdated surfaces to make room for new ones
- Prioritize the most recent and relevant surfaces for the current conversation

When managing surfaces:
- Delete old surfaces that are no longer relevant to the current flow
- Update existing surfaces when iterating on the same content (e.g., refining an itinerary)
- Add new surfaces for new topics or when exploring side journeys
''';

    final chatSection = enableChatOutput
        ? '''
# Communication Style

You can communicate through both UI surfaces and text messages. Use text messages 
for brief explanations, confirmations, or when you need to provide context about 
the UI you've created. Always prefer UI over text when possible.
'''
        : '''
# Communication Style

You communicate ONLY through UI surfaces. You cannot send text messages - all 
communication must be through creating, updating, or deleting UI elements. 
Make sure your UI is self-explanatory and guides the user clearly.
''';

    final remainingPrompt = '''
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

When updating or showing UIs, **ALWAYS** use the addOrUpdateSurface tool to supply them. Prefer to collect and show information by creating a UI for it.
''';

    return basePrompt + chatSection + remainingPrompt;
  }

  /// Disposes of resources used by this controller.
  void dispose() {
    _userMessageSubscription.cancel();
    _surfacesController.close();
    _textMessagesController.close();
    _isThinkingController.close();
    _genUiManager.dispose();
  }
}
