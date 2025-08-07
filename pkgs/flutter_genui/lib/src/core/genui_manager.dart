// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart' show S, Schema;
import 'package:firebase_ai/firebase_ai.dart'
    as firebase_ai
    show Content, FunctionResponse, TextPart;
import 'package:flutter/material.dart';

import '../ai_client/ai_client.dart';
import '../model/catalog.dart';
import '../model/chat_message.dart';
import '../model/ui_models.dart';
import 'core_catalog.dart';
import 'ui_event_manager.dart';
import 'widgets/chat_widget.dart';
import 'widgets/conversation_widget.dart';

enum GenUiStyle { flexible, chat }

class GenUiManager {
  void _init(Catalog? catalog) {
    this.catalog = catalog ?? coreCatalog;
    _eventManager = UiEventManager(callback: handleEvents);
  }

  GenUiManager({
    required this.aiClient,
    Catalog? catalog,
    this.userPromptBuilder,
    this.systemMessageBuilder,
    this.showInternalMessages = false,
  }) : style = GenUiStyle.flexible {
    _init(catalog);
    _chatController = null;
  }

  GenUiManager.chat({
    required this.aiClient,
    Catalog? catalog,
    this.userPromptBuilder,
    this.systemMessageBuilder,
    this.showInternalMessages = false,
  }) : style = GenUiStyle.chat {
    _init(catalog);
    _chatController = GenUiChatController();
    loadingStream.listen((bool data) {
      print('!!! Loading state changed: $data');
      if (data) {
        _chatController?.setAiRequestSent();
      }
    });
  }

  final GenUiStyle style;

  late final GenUiChatController? _chatController;

  final bool showInternalMessages;

  late final Catalog catalog;
  final AiClient aiClient;
  final UserPromptBuilder? userPromptBuilder;
  final SystemMessageBuilder? systemMessageBuilder;
  late final UiEventManager _eventManager;

  @visibleForTesting
  List<ChatMessage> get chatHistoryForTesting => _chatHistory;

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
    _chatController?.dispose();
  }

  /// Sends a prompt on behalf of the end user. This should update the UI and
  /// also trigger an AI inference via the [aiClient].
  void sendUserPrompt(String prompt) {
    if (prompt.isEmpty) {
      return;
    }
    _chatHistory.add(UserPrompt(text: prompt));
    _uiDataStreamController.add(List.from(_chatHistory));

    _generateAndSendResponse();
  }

  void handleEvents(String surfaceId, List<UiEvent> events) {
    for (final event in events) {
      _chatHistory.add(UiEventMessage(event: event));
    }

    _chatHistory.add(
      InternalMessage(
        'The user has interacted with the UI surface named "$surfaceId". '
        'Consolidate the UI events and update the UI accordingly. You can '
        'choose to update this surface if the previous content is no-longer '
        'needed, or add a new surface to show additional content.',
      ),
    );
    _uiDataStreamController.add(List.from(_chatHistory));

    _generateAndSendResponse();
  }

  List<firebase_ai.Content> _contentForChatHistory() {
    final conversation = <firebase_ai.Content>[];
    for (final message in _chatHistory) {
      switch (message) {
        case SystemMessage():
          conversation.add(firebase_ai.Content.text(message.text));
        case UserPrompt():
          conversation.add(firebase_ai.Content.text(message.text));
        case UiResponse():
          conversation.add(
            firebase_ai.Content.model([
              firebase_ai.TextPart(jsonEncode(message.definition)),
            ]),
          );
        case InternalMessage():
          conversation.add(firebase_ai.Content.text(message.text));
        case UiEventMessage():
          conversation.add(
            firebase_ai.Content('user', [
              firebase_ai.FunctionResponse(
                message.event.widgetId,
                message.event.toMap(),
              ),
            ]),
          );
      }
    }
    return conversation;
  }

  Future<void> _generateAndSendResponse() async {
    _outstandingRequests++;
    _loadingStreamController.add(true);
    try {
      final response = await aiClient.generateContent(
        _contentForChatHistory(),
        outputSchema,
      );
      if (response == null) {
        return;
      }
      final responseMap = response as Map<String, Object?>;
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
                _chatHistory.add(
                  InternalMessage(
                    'The existing surface with id $surfaceId has been updated '
                    'in response to user input.',
                  ),
                );
              }
            case 'delete':
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
        _chatController?.setAiResponseReceived();
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
  /// within each widget is defined as a `S.object` with all possible
  /// properties for all widget types. The application logic should validate the
  /// contents of `props` based on the widget's `type`.
  ///
  /// This approach ensures that the fundamental structure of the UI definition
  /// is always valid according to the schema.
  Schema get outputSchema => S.object(
    properties: {
      'actions': S.list(
        description: 'A list of actions to be performed on the UI surfaces.',
        items: S.object(
          properties: {
            'action': S.string(
              description: 'The action to perform on the UI surface.',
              enumValues: ['add', 'update', 'delete'],
            ),
            'surfaceId': S.string(
              description:
                  'The ID of the surface to perform the action on. For the '
                  '`add` action, this will be a new surface ID. '
                  'For `update` and '
                  '`delete`, this will be an existing surface ID.',
            ),
            'definition': S.object(
              properties: {
                'root': S.string(description: 'The ID of the root widget.'),
                'widgets': S.list(
                  items: catalog.schema,
                  description: 'A list of widget definitions.',
                  minItems: 1,
                ),
              },
              description:
                  'A schema for a simple UI tree to be rendered by '
                  'Flutter.',
              required: ['root', 'widgets'],
            ),
          },
          required: ['action', 'surfaceId'],
        ),
      ),
    },
    description:
        'A schema for defining a simple UI tree to be rendered by '
        'Flutter.',
    required: ['actions'],
  );

  Widget widget() {
    return StreamBuilder(
      stream: uiDataStream,
      initialData: const <ChatMessage>[],
      builder: (context, snapshot) {
        return switch (style) {
          GenUiStyle.flexible => ConversationWidget(
            messages: snapshot.data!,
            catalog: catalog,
            showInternalMessages: showInternalMessages,
            onEvent: (event) {
              _eventManager.add(UiEvent.fromMap(event));
            },
            systemMessageBuilder: systemMessageBuilder,
            userPromptBuilder: userPromptBuilder,
          ),
          GenUiStyle.chat => GenUiChat(
            messages: snapshot.data!,
            catalog: catalog,
            showInternalMessages: showInternalMessages,
            onEvent: (event) {
              _eventManager.add(UiEvent.fromMap(event));
            },
            systemMessageBuilder: systemMessageBuilder,
            userPromptBuilder: userPromptBuilder,
            onChatMessage: sendUserPrompt,
            controller: _chatController!,
          ),
        };
      },
    );
  }
}
