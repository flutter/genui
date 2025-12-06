// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a/a2a.dart' as a2a;
import 'package:genui/genui.dart' as genui;
import 'package:genui_a2ui/genui_a2ui.dart';

class FakeA2AClient implements a2a.A2AClient {
  a2a.A2AAgentCard? agentCard;
  Stream<a2a.A2ASendStreamMessageResponse> Function(a2a.A2AMessageSendParams)?
  sendMessageStreamHandler;
  Future<a2a.A2ASendMessageResponse> Function(a2a.A2AMessageSendParams)?
  sendMessageHandler;

  int getAgentCardCalled = 0;
  int sendMessageStreamCalled = 0;
  int sendMessageCalled = 0;

  a2a.A2AMessageSendParams? lastSendMessageParams;

  @override
  Future<a2a.A2AAgentCard> getAgentCard({
    String? agentBaseUrl,
    String agentCardPath = '/agent_card',
  }) async {
    getAgentCardCalled++;
    if (agentCard != null) {
      return agentCard!;
    }
    return a2a.A2AAgentCard()
      ..name = 'Test Agent'
      ..description = 'A test agent'
      ..version = '1.0.0';
  }

  @override
  Stream<a2a.A2ASendStreamMessageResponse> sendMessageStream(
    a2a.A2AMessageSendParams params,
  ) {
    sendMessageStreamCalled++;
    lastSendMessageParams = params;
    if (sendMessageStreamHandler != null) {
      return sendMessageStreamHandler!(params);
    }
    return Stream<a2a.A2ASendStreamMessageResponse>.fromIterable([]);
  }

  @override
  Future<a2a.A2ASendMessageResponse> sendMessage(
    a2a.A2AMessageSendParams params,
  ) async {
    sendMessageCalled++;
    lastSendMessageParams = params;
    if (sendMessageHandler != null) {
      return sendMessageHandler!(params);
    }
    return a2a.A2ASendMessageResponse();
  }

  // Unimplemented methods
  @override
  Future<a2a.A2ACancelTaskResponse> cancelTask(a2a.A2ATaskIdParams params) {
    throw UnimplementedError();
  }

  @override
  Future<a2a.A2ADeleteTaskPushNotificationConfigResponse>
  deleteTaskPushNotificationConfig(
    a2a.A2ADeleteTaskPushNotificationConfigParams params,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<a2a.A2AGetTaskResponse> getTask(a2a.A2ATaskQueryParams params) {
    throw UnimplementedError();
  }

  @override
  Future<a2a.A2AGetTaskPushNotificationConfigResponse>
  getTaskPushNotificationConfig(
    a2a.A2AGetTaskPushNotificationConfigParams params,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<a2a.A2ASetTaskPushNotificationConfigResponse>
  setTaskPushNotificationConfig(a2a.A2ATaskPushNotificationConfig params) {
    throw UnimplementedError();
  }

  @override
  String agentBaseUrl = '';

  @override
  String agentCardPath = '';

  @override
  Future<a2a.A2AListTaskPushNotificationConfigResponse>
  listTaskPushNotificationConfig(
    a2a.A2AListTaskPushNotificationConfigParams params,
  ) {
    // TODO: implement listTaskPushNotificationConfig
    throw UnimplementedError();
  }

  @override
  Stream<a2a.A2ASendStreamMessageResponse> resubscribeTask(
    a2a.A2ATaskIdParams params,
  ) {
    // TODO: implement resubscribeTask
    throw UnimplementedError();
  }

  @override
  // TODO: implement serviceEndpoint
  Future<String> get serviceEndpoint => throw UnimplementedError();
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
      AgentCard(
        name: 'Fake Agent',
        description: 'Fake Description',
        version: '1.0.0',
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
