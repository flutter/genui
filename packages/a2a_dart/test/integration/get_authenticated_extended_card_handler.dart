// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart';

class GetAuthenticatedExtendedCardHandler implements RequestHandler {
  @override
  String get method => 'agent/getAuthenticatedExtendedCard';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) {
    return SingleResult(
      const AgentCard(
        name: 'Extended Test Agent',
        protocolVersion: '0.1.0',
        url: '',
        version: '0.1.0',
        description: 'A test agent.',
        capabilities: AgentCapabilities(streaming: false),
        defaultInputModes: [],
        defaultOutputModes: [],
        skills: [],
      ).toJson(),
    );
  }
}
