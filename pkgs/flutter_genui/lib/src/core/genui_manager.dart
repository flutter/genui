// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../flutter_genui.dart';
import '../model/chat_message.dart';
import 'conversation_widget.dart';

class GenUiManager {
  GenUiManager.conversation({
    required this.llmConnection,
    this.catalog = const Catalog([]),
    this.userPromptBuilder,
    this.systemMessageBuilder,
    this.showInternalMessages = false,
  }) {
    _eventManager = UiEventManager(callback: handleEvents);
  }

  final bool showInternalMessages;

  final Catalog catalog;
  final LlmConnection llmConnection;
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
  }

  /// Sends a prompt on behalf of the end user. This should update the UI and
  /// also trigger an LLM inference via the llmConnection.
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

  List<Content> _contentForChatHistory() {
    final conversation = <Content>[];
    for (final message in _chatHistory) {
      switch (message) {
        case SystemMessage():
          conversation.add(Content.text(message.text));
        case UserPrompt():
          conversation.add(Content.text(message.text));
        case UiResponse():
          conversation.add(
            Content.model([TextPart(jsonEncode(message.definition))]),
          );
        case InternalMessage():
          conversation.add(Content.text(message.text));
        case UiEventMessage():
          conversation.add(
            Content('user', [
              FunctionResponse(message.event.widgetId, message.event.toMap()),
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
      final response = await llmConnection.generateContent(
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
  );

  Widget widget() {
    return StreamBuilder(
      stream: uiDataStream,
      initialData: const <ChatMessage>[],
      builder: (context, snapshot) {
        return ConversationWidget(
          messages: snapshot.data!,
          catalog: catalog,
          showInternalMessages: showInternalMessages,
          onEvent: (event) {
            _eventManager.add(UiEvent.fromMap(event));
          },
          systemMessageBuilder: systemMessageBuilder,
          userPromptBuilder: userPromptBuilder,
        );
      },
    );
  }
}
