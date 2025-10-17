// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2ui_client/a2ui_client.dart';
import 'package:flutter/material.dart';

class AgentState with ChangeNotifier {
  AgentState() {
    unawaited(_fetchCard());
  }

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  A2uiInterpreter? _interpreter;
  A2uiAgentConnector? _connector;
  AgentCard? _agentCard;
  final _urlController = TextEditingController(text: 'http://localhost:10002');

  GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _scaffoldMessengerKey;
  A2uiInterpreter? get interpreter => _interpreter;
  A2uiAgentConnector? get connector => _connector;
  AgentCard? get agentCard => _agentCard;
  TextEditingController get urlController => _urlController;

  @override
  void dispose() {
    _urlController.dispose();
    _connector?.dispose();
    _interpreter?.dispose();
    super.dispose();
  }

  Future<void> fetchCard() async {
    final url = Uri.tryParse(_urlController.text);
    if (url == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
      return;
    }

    // Clean up previous connections
    _connector?.dispose();
    _interpreter?.dispose();

    final newConnector = A2uiAgentConnector(url: url);
    try {
      final card = await newConnector.getAgentCard();
      _connector = newConnector;
      _agentCard = card;
      _interpreter = A2uiInterpreter(stream: newConnector.stream);
      notifyListeners();
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error fetching agent card: $e')),
      );
    }
  }

  Future<void> _fetchCard() async {
    await fetchCard();
  }
}
