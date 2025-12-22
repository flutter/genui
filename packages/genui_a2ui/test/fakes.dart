// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui/genui.dart' as genui;
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart' as a2a;

class FakeA2AClient implements a2a.A2AClient {
  a2a.AgentCard? agentCard;
  Stream<a2a.Event> Function(a2a.Message)? messageStreamHandler;
  Future<a2a.Task> Function(a2a.Message)? messageSendHandler;

  int getAgentCardCalled = 0;
  int messageStreamCalled = 0;
  int messageSendCalled = 0;

  a2a.Message? lastMessageSendParams;
  a2a.Message? lastMessageStreamParams;

  @override
  Future<a2a.AgentCard> getAgentCard() async {
    getAgentCardCalled++;
    if (agentCard != null) {
      return agentCard!;
    }
    return const a2a.AgentCard(
      name: 'Test Agent',
      description: 'A test agent',
      version: '1.0.0',
      protocolVersion: '0.1.0',
      url: 'http://localhost:8080',
      capabilities: a2a.AgentCapabilities(),
      defaultInputModes: ['text/plain'],
      defaultOutputModes: ['text/plain'],
      skills: [],
    );
  }

  @override
  Stream<a2a.Event> messageStream(a2a.Message message) {
    messageStreamCalled++;
    lastMessageStreamParams = message;
    if (messageStreamHandler != null) {
      return messageStreamHandler!(message);
    }
    return const Stream.empty();
  }

  @override
  Future<a2a.Task> messageSend(a2a.Message message) async {
    messageSendCalled++;
    lastMessageSendParams = message;
    if (messageSendHandler != null) {
      return messageSendHandler!(message);
    }
    return const a2a.Task(
      id: 'task1',
      contextId: 'context1',
      status: a2a.TaskStatus(state: a2a.TaskState.completed),
    );
  }

  @override
  String get url => 'http://localhost:8080';

  @override
  void close() {}

  // Unimplemented methods
  @override
  Future<a2a.Task> cancelTask(String taskId) => throw UnimplementedError();

  @override
  Future<void> deletePushNotificationConfig(String taskId, String configId) =>
      throw UnimplementedError();

  @override
  Future<a2a.AgentCard> getAuthenticatedExtendedCard(String token) =>
      throw UnimplementedError();

  @override
  Future<a2a.TaskPushNotificationConfig> getPushNotificationConfig(
    String taskId,
    String configId,
  ) => throw UnimplementedError();

  @override
  Future<a2a.Task> getTask(String taskId) => throw UnimplementedError();

  @override
  Future<List<a2a.PushNotificationConfig>> listPushNotificationConfigs(
    String taskId,
  ) => throw UnimplementedError();

  @override
  Future<a2a.ListTasksResult> listTasks([a2a.ListTasksParams? params]) =>
      throw UnimplementedError();

  @override
  Stream<a2a.Event> resubscribeToTask(String taskId) =>
      throw UnimplementedError();

  @override
  Future<a2a.TaskPushNotificationConfig> setPushNotificationConfig(
    a2a.TaskPushNotificationConfig params,
  ) => throw UnimplementedError();
}

class FakeA2uiAgentConnector implements A2uiAgentConnector {
  FakeA2uiAgentConnector({required this.url}) {
    client = FakeA2AClient();
  }

  @override
  final Uri url;

  final _streamController = StreamController<genui.A2uiMessage>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  @override
  Stream<genui.A2uiMessage> get stream => _streamController.stream;

  @override
  Stream<Object> get errorStream => _errorController.stream;

  @override
  String? contextId;

  @override
  String? taskId;

  @override
  late a2a.A2AClient client;

  genui.ChatMessage? lastConnectAndSendChatMessage;
  genui.A2UiClientCapabilities? lastClientCapabilities;

  @override
  Future<String?> connectAndSend(
    genui.ChatMessage chatMessage, {
    genui.A2UiClientCapabilities? clientCapabilities,
  }) async {
    lastConnectAndSendChatMessage = chatMessage;
    lastClientCapabilities = clientCapabilities;
    // Simulate sending a message and receiving a response
    return Future.value('Fake AI Response');
  }

  @override
  void dispose() {
    _streamController.close();
    _errorController.close();
  }

  @override
  Future<AgentCard> getAgentCard() {
    return Future.value(
      const AgentCard(
        name: 'Fake Agent',
        description: 'Fake Description',
        version: '1.0.0',
        protocolVersion: '0.1.0',
        url: 'http://localhost:8080',
        capabilities: a2a.AgentCapabilities(),
        defaultInputModes: ['text/plain'],
        defaultOutputModes: ['text/plain'],
        skills: [],
      ),
    );
  }

  @override
  Future<void> sendEvent(Map<String, Object?> event) async {
    // Simulate sending an event
  }

  // Helper methods for tests to control the streams
  void addMessage(genui.A2uiMessage message) {
    _streamController.add(message);
  }

  void addError(Object error) {
    _errorController.add(error);
  }
}
