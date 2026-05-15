// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:genui/genui.dart';
import 'package:simple_chat/agent/ai_client.dart';
import 'package:simple_chat/chat_session.dart';
import 'package:simple_chat/primitives/app_mode.dart';

import '../test_infra/issue_reporter.dart';

/// Helper class to manage a chat session from simple chat example.
class ChatSessionTester {
  ChatSessionTester() {
    _surfaceSub = chatSession.surfaceController.surfaceUpdates.listen(
      _onSurfaceUpdate,
    );
    chatSession.addListener(_onSessionChanged);
  }

  final IssueReporter reporter = IssueReporter();
  final List<String> _created = [];
  final List<String> _removed = [];
  final List<String> _updated = [];
  final List<int> _completedTurnCreates = [];
  final List<int> _completedTurnUpdates = [];
  final A2uiChatSession chatSession =
      ChatSession(aiClient: DartanticAiClient(), mode: AppMode.basicCatalog)
          as A2uiChatSession;

  late final StreamSubscription<SurfaceUpdate> _surfaceSub;

  bool _wasProcessing = false;
  bool _turnInProgress = false;
  int _currentTurnCreates = 0;
  int _currentTurnUpdates = 0;

  void _onSessionChanged() {
    if (chatSession.isProcessing && !_wasProcessing) {
      // false -> true: a new turn is starting. Flush the previous turn (if
      // any) and reset counters.
      if (_turnInProgress) {
        _completedTurnCreates.add(_currentTurnCreates);
        _completedTurnUpdates.add(_currentTurnUpdates);
      }
      _currentTurnCreates = 0;
      _currentTurnUpdates = 0;
      _turnInProgress = true;
    }
    _wasProcessing = chatSession.isProcessing;
  }

  void _onSurfaceUpdate(SurfaceUpdate update) {
    switch (update) {
      case SurfaceAdded(:final String surfaceId):
        _created.add(surfaceId);
        _currentTurnCreates++;
      case ComponentsUpdated(:final String surfaceId):
        _updated.add(surfaceId);
        _currentTurnUpdates++;
      case SurfaceRemoved(:final String surfaceId):
        _removed.add(surfaceId);
    }
  }

  Future<void> _waitForProcessingToComplete() async {
    if (!chatSession.isProcessing) return;

    final completer = Completer<void>();
    void listener() {
      if (!chatSession.isProcessing) {
        completer.complete();
      }
    }

    chatSession.addListener(listener);
    await completer.future;
    chatSession.removeListener(listener);
  }

  Future<void> sendMessageAndWaitForResponse(String message) async {
    await chatSession.sendMessage(message);
    await _waitForProcessingToComplete();
  }

  Iterable<String> surfaceIds() {
    return chatSession.messages
        .where((m) => !m.isUser)
        .map((m) => m.surfaceId)
        .whereType<String>();
  }

  void verifyEvents() {
    final List<int> turnCreates = [
      ..._completedTurnCreates,
      if (_turnInProgress) _currentTurnCreates,
    ];
    final List<int> turnUpdates = [
      ..._completedTurnUpdates,
      if (_turnInProgress) _currentTurnUpdates,
    ];

    final List<String> errors = chatSession.messages
        .where((m) => !m.isUser && (m.text?.startsWith('Error: ') ?? false))
        .map((m) => m.text!)
        .toList();

    print('Conversation summary:');
    print('  Created surfaces: $_created');
    print('  Removed surfaces: $_removed');
    print('  Updated surfaces: $_updated');
    print('  Turns: ${turnCreates.length}');
    print('  Errors: $errors');

    for (var i = 0; i < turnCreates.length; i++) {
      final int creates = turnCreates[i];
      final int updates = turnUpdates[i];
      reporter.expect(
        creates <= 1,
        'Turn ${i + 1} should create at most 1 surface',
      );
      reporter.expect(
        updates == creates,
        'Turn ${i + 1} should have matching creates ($creates) '
        'and updates ($updates)',
      );
    }

    reporter.expect(errors.isEmpty, 'No errors should occur');
    reporter.expect(
      _updated.length == _created.length,
      'In chat setup surfaces should not be updated after initial creation',
    );
    for (final String id in _created) {
      final int updateCount = _updated.where((u) => u == id).length;
      reporter.expect(
        updateCount == 1,
        'Surface $id should be updated exactly once',
      );
    }
  }

  void failIfIssuesFound() => reporter.failIfIssuesFound();

  void dispose() {
    chatSession.removeListener(_onSessionChanged);
    _surfaceSub.cancel();
    chatSession.dispose();
  }
}
