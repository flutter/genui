// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'a2ui_message.dart';

/// A base class for events related to the GenUI generation process.
sealed class GenerationEvent {
  const GenerationEvent();
}

/// Fired when a tool execution starts.
class ToolStartEvent extends GenerationEvent {
  const ToolStartEvent({required this.toolName, required this.args});

  final String toolName;
  final Map<String, Object?> args;
}

/// Fired when a tool execution completes.
class ToolEndEvent extends GenerationEvent {
  const ToolEndEvent({
    required this.toolName,
    required this.result,
    required this.duration,
  });

  final String toolName;
  final Object? result;
  final Duration duration;
}

/// Fired to report token usage.
class TokenUsageEvent extends GenerationEvent {
  const TokenUsageEvent({
    required this.inputTokens,
    required this.outputTokens,
  });

  final int inputTokens;
  final int outputTokens;
}

/// Fired when the AI emits a "thinking" chunk (if supported).
class ThinkingEvent extends GenerationEvent {
  const ThinkingEvent({required this.content});

  final String content;
}

/// An event containing a text chunk from the LLM.
class TextEvent extends GenerationEvent {
  /// Creates a [TextEvent] with the given [text].
  const TextEvent(this.text);

  /// The text content.
  final String text;
}

/// An event containing a parsed [A2uiMessage].
class A2uiMessageEvent extends GenerationEvent {
  /// Creates an [A2uiMessageEvent] with the given [message].
  const A2uiMessageEvent(this.message);

  /// The parsed message.
  final A2uiMessage message;
}
