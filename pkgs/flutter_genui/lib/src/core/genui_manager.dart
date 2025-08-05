import 'dart:async';
import 'package:collection/collection.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../ai_client/llm_connection.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';
import 'conversation_widget.dart';
import 'ui_event_manager.dart';

class GenUiManager {
  GenUiManager.conversation(
    this.catalog,
    this.systemInstruction,
    this.llmConnection,
  ) {
    _eventManager = UiEventManager(callback: handleEvents);
  }

  final Catalog catalog;
  final String systemInstruction;
  final LlmConnection llmConnection;
  late final UiEventManager _eventManager;

  // Context used for future LLM inferences
  final masterConversation = <Content>[];
  final conversationsBySurfaceId = <String, List<Content>>{};

  // The current chat data that is shown.
  final _chatHistory = <ChatMessage>[];

  int _outstandingRequests = 0;

  // Stream of updates to the ui data which are used to build the
  // Conversation Widget every time the conversation is updated.
  final StreamController<List<ChatMessage>> _uiDataStreamController =
      StreamController<List<ChatMessage>>.broadcast();

  final StreamController<bool> _loadingStreamController =
      StreamController<bool>.broadcast();

  Stream<List<ChatMessage>> get uiDataStream => _uiDataStreamController.stream;
  Stream<bool> get loadingStream => _loadingStreamController.stream;

  void dispose() {
    _uiDataStreamController.close();
    _loadingStreamController.close();
    _eventManager.dispose();
  }

  /// Sends a prompt on behalf of the end user. This should update the UI and
  /// also trigger an LLM inference via the llmConnection.
  void sendUserPrompt(String prompt) {
    if (prompt.isEmpty) {
      return;
    }
    _chatHistory.add(UserPrompt(text: prompt));
    _uiDataStreamController.add(List.from(_chatHistory));

    masterConversation.add(Content.text(prompt));
    _generateAndSendResponse(conversation: masterConversation);
  }

  void handleEvents(List<UiEvent> events) {
    final eventsBySurface = <String, List<UiEvent>>{};
    for (final event in events) {
      final surfaceId = event.surfaceId;
      if (surfaceId != null) {
        (eventsBySurface[surfaceId] ??= []).add(event);
      }
    }

    for (final entry in eventsBySurface.entries) {
      final surfaceId = entry.key;
      final surfaceConversation = conversationsBySurfaceId[surfaceId];
      if (surfaceConversation == null) {
        // TODO: Handle error - unknown surfaceId
        print('Unknown surfaceId: $surfaceId');
        continue;
      }
      for (final event in entry.value) {
        final functionResponse = FunctionResponse(
          event.widgetId,
          event.toMap(),
        );
        surfaceConversation.add(
          Content.functionResponse(
            functionResponse.name,
            functionResponse.response,
          ),
        );
      }
      surfaceConversation.add(
        Content.text(
          'The user has interacted with the UI surface named "$surfaceId". '
          'Consolidate the UI events and update the UI accordingly. Respond '
          'with an updated UI definition. You may update any of the '
          'surfaces, or delete them if they are no longer needed.',
        ),
      );
      _generateAndSendResponse(conversation: surfaceConversation);
    }
  }

  Future<void> _generateAndSendResponse({
    required List<Content> conversation,
  }) async {
    _outstandingRequests++;
    _loadingStreamController.add(true);
    try {
      final response = await llmConnection.generateContent(
        conversation,
        outputSchema,
        systemInstruction: Content.system(systemInstruction),
      );
      if (response == null) {
        return;
      }
      final responseMap = response as Map<String, Object?>;
      if (responseMap['responseText'] case final String responseText) {
        _chatHistory.add(TextResponse(text: responseText));
      }
      if (responseMap['actions'] case final List<Object?> actions) {
        for (final actionMap in actions.cast<Map<String, Object?>>()) {
          final action = actionMap['action'] as String;
          final surfaceId = actionMap['surfaceId'] as String?;
          if (surfaceId == null) {
            throw FormatException(
              'surfaceId is required for all actions. This action is missing '
              'it: $actionMap',
            );
          }
          switch (action) {
            case 'add':
              final definition =
                  actionMap['definition'] as Map<String, Object?>;
              final newConversation = List<Content>.from(conversation);
              conversationsBySurfaceId[surfaceId] = newConversation;
              _chatHistory.add(
                UiResponse(
                  definition: {'surfaceId': surfaceId, ...definition},
                  surfaceId: surfaceId,
                ),
              );
            case 'update':
              final definition =
                  actionMap['definition'] as Map<String, Object?>;
              final oldResponse = _chatHistory
                  .whereType<UiResponse>()
                  .firstWhereOrNull(
                    (response) => response.surfaceId == surfaceId,
                  );
              if (oldResponse != null) {
                final index = _chatHistory.indexOf(oldResponse);
                _chatHistory[index] = UiResponse(
                  definition: {'surfaceId': surfaceId, ...definition},
                  surfaceId: surfaceId,
                );
              }
            case 'delete':
              conversationsBySurfaceId.remove(surfaceId);
              _chatHistory.removeWhere(
                (message) =>
                    message is UiResponse && message.surfaceId == surfaceId,
              );
          }
        }
      }
      _uiDataStreamController.add(List.from(_chatHistory));
    } catch (e) {
      print('Error generating content: $e');
      _chatHistory.add(SystemMessage(text: 'Error: $e'));
      _uiDataStreamController.add(List.from(_chatHistory));
    } finally {
      _outstandingRequests--;
      if (_outstandingRequests == 0) {
        _loadingStreamController.add(false);
      }
    }
  }

  /// A schema for defining a simple UI tree to be rendered by Flutter.
  ///
  /// This schema is a Dart conversion of a more complex JSON schema.
  /// Due to limitations in the Dart `Schema` builder API (specifically the lack
  /// of support for discriminated unions or `anyOf`), this conversion makes a
  /// practical compromise.
  ///
  /// It strictly enforces the structure of the `root` object, requiring `id`
  /// and `type` for every widget in the `widgets` list. The `props` field
  /// within each widget is defined as a `Schema.object` with all possible
  /// properties for all widget types. The application logic should validate the
  /// contents of `props` based on the widget's `type`.
  ///
  /// This approach ensures that the fundamental structure of the UI definition
  /// is always valid according to the schema.
  Schema get outputSchema => Schema.object(
    properties: {
      'responseText': Schema.string(
        description:
            'The text response to the user query. This should be used '
            'when the query is fully satisfied and no more information is '
            'needed.',
      ),
      'actions': Schema.array(
        description: 'A list of actions to be performed on the UI surfaces.',
        items: Schema.object(
          properties: {
            'action': Schema.enumString(
              description: 'The action to perform on the UI surface.',
              enumValues: ['add', 'update', 'delete'],
            ),
            'surfaceId': Schema.string(
              description:
                  'The ID of the surface to perform the action on. For the '
                  '`add` action, this will be a new surface ID. '
                  'For `update` and '
                  '`delete`, this will be an existing surface ID.',
            ),
            'definition': Schema.object(
              properties: {
                'root': Schema.string(
                  description: 'The ID of the root widget.',
                ),
                'widgets': Schema.array(
                  items: catalog.schema,
                  description: 'A list of widget definitions.',
                ),
              },
              description:
                  'A schema for defining a simple UI tree to be rendered by '
                  'Flutter.',
            ),
          },
          optionalProperties: ['surfaceId', 'definition'],
        ),
      ),
    },
    description:
        'A schema for defining a simple UI tree to be rendered by '
        'Flutter.',
    optionalProperties: ['actions', 'responseText'],
  );

  Widget widget() {
    return StreamBuilder(
      stream: uiDataStream,
      initialData: const <ChatMessage>[],
      builder: (context, snapshot) {
        return ConversationWidget(
          messages: snapshot.data!,
          catalog: catalog,
          onEvent: (event) {
            _eventManager.add(UiEvent.fromMap(event));
          },
        );
      },
    );
  }
}
