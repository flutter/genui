// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:flutter_genui/flutter_genui.dart';

sealed class Turn {
  const Turn();

  firebase_ai.Content? toContent();
}

class UserTurn extends Turn {
  final String text;

  const UserTurn(this.text);

  @override
  firebase_ai.Content toContent() {
    return firebase_ai.Content('user', [firebase_ai.TextPart(text)]);
  }
}

class UserUiInteractionTurn extends Turn {
  final String text;

  const UserUiInteractionTurn(this.text);

  @override
  firebase_ai.Content toContent() {
    return firebase_ai.Content('user', [firebase_ai.TextPart(text)]);
  }
}

class AiTextTurn extends Turn {
  final String text;

  const AiTextTurn(this.text);

  @override
  firebase_ai.Content toContent() {
    return firebase_ai.Content.model([firebase_ai.TextPart(text)]);
  }
}

class GenUiTurn extends Turn {
  final String surfaceId;
  final UiDefinition definition;

  GenUiTurn({required this.surfaceId, required this.definition});

  @override
  firebase_ai.Content? toContent() {
    final text = definition.asContextDescriptionText();
    return firebase_ai.Content.model([firebase_ai.TextPart(text)]);
  }
}
