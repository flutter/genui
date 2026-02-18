// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A base class for events related to the AI generation process.
abstract class AiGenerationEvent {
  const AiGenerationEvent();
}

/// Fired when a tool execution starts.
class ToolStartEvent extends AiGenerationEvent {
  const ToolStartEvent({required this.toolName, required this.args});

  final String toolName;
  final Map<String, Object?> args;
}

/// Fired when a tool execution completes.
class ToolEndEvent extends AiGenerationEvent {
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
class TokenUsageEvent extends AiGenerationEvent {
  const TokenUsageEvent({
    required this.inputTokens,
    required this.outputTokens,
  });

  final int inputTokens;
  final int outputTokens;
}
