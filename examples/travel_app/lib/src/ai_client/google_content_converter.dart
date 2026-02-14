// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;

/// An exception thrown by this package.
class GoogleAiClientException implements Exception {
  /// Creates an [GoogleAiClientException] with the given [message].
  GoogleAiClientException(this.message);

  /// The message associated with the exception.
  final String message;

  @override
  String toString() => '$GoogleAiClientException: $message';
}

/// A class to convert between the generic `ChatMessage` and the `google_ai`
/// specific `Content` classes.
class GoogleContentConverter {
  /// Converts a list of [ChatMessage]s to a list of [google_ai.Content]s.
  List<google_ai.Content> toGoogleAiContent(Iterable<ChatMessage> messages) {
    final result = <google_ai.Content>[];
    for (final message in messages) {
      final String? role = switch (message.role) {
        ChatMessageRole.user => 'user',
        ChatMessageRole.model => 'model',
        ChatMessageRole.system => null,
      };

      if (role == null) continue;

      final List<google_ai.Part> parts = _convertParts(message.parts);
      if (parts.isNotEmpty) {
        result.add(google_ai.Content(role: role, parts: parts));
      }
    }
    return result;
  }

  List<google_ai.Part> _convertParts(List<StandardPart> parts) {
    final result = <google_ai.Part>[];
    for (final part in parts) {
      switch (part) {
        case TextPart(:final text):
          result.add(google_ai.Part(text: text));
        case DataPart():
          if (part.isUiPart) {
            final UiPart uiPart = part.asUiPart!;
            result.add(
              google_ai.Part(
                text: uiPart.definition.asContextDescriptionText(),
              ),
            );
          } else if (part.mimeType ==
              'application/vnd.genui.interaction+json') {
            result.add(google_ai.Part(text: utf8.decode(part.bytes)));
          } else {
            // Treat as Blob (image or other)
            result.add(
              google_ai.Part(
                inlineData: google_ai.Blob(
                  mimeType: part.mimeType,
                  data: part.bytes,
                ),
              ),
            );
          }
        case LinkPart(:final url):
          result.add(
            google_ai.Part(
              fileData: google_ai.FileData(fileUri: url.toString()),
            ),
          );
        case ToolPart(
          :final callId,
          :final toolName,
          :final arguments,
          result: final toolResult,
        ):
          if (toolResult != null) {
            // Tool Result
            Map<String, Object?> mapResult;
            if (toolResult is String) {
              try {
                mapResult = jsonDecode(toolResult) as Map<String, Object?>;
              } catch (_) {
                mapResult = {'result': toolResult};
              }
            } else if (toolResult is Map) {
              mapResult = toolResult as Map<String, Object?>;
            } else {
              mapResult = {'result': toolResult};
            }

            result.add(
              google_ai.Part(
                functionResponse: google_ai.FunctionResponse(
                  id: callId,
                  name: '',
                  response: protobuf.Struct.fromJson(mapResult),
                ),
              ),
            );
          } else {
            // Tool Call
            result.add(
              google_ai.Part(
                functionCall: google_ai.FunctionCall(
                  id: callId,
                  name: toolName,
                  args: protobuf.Struct.fromJson(arguments ?? {}),
                ),
              ),
            );
          }
        case ThinkingPart(:final text):
          result.add(google_ai.Part(text: 'Thinking: $text'));
      }
    }
    return result;
  }
}
