// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;

/// An exception thrown by this package.
class GoogleAiClientException implements Exception {
  /// Creates a [GoogleAiClientException] with the given [message].
  GoogleAiClientException(this.message);

  /// The message associated with the exception.
  final String message;

  @override
  String toString() => '$GoogleAiClientException: $message';
}

/// A class to convert between the generic `ChatMessage` and the `google_ai`
/// specific `Content` classes.
///
/// This class is responsible for translating the abstract [ChatMessage]
/// representation into the concrete `google_ai.Content` representation
/// required by the `google_cloud_ai_generativelanguage_v1beta` package.
class GoogleContentConverter {
  /// Converts a list of `ChatMessage` objects to a list of
  /// `google_ai.Content` objects.
  List<google_ai.Content> toGoogleAiContent(Iterable<ChatMessage> messages) {
    final result = <google_ai.Content>[];
    for (final message in messages) {
      final (String? role, List<google_ai.Part> parts) = switch (message) {
        UserMessage() => ('user', _convertParts(message.parts)),
        UserUiInteractionMessage() => ('user', _convertParts(message.parts)),
        AiTextMessage() => ('model', _convertParts(message.parts)),
        ToolResponseMessage() => ('user', _convertToolResults(message.results)),
        AiUiMessage() => ('model', _convertParts(message.parts)),
        InternalMessage() => (null, <google_ai.Part>[]), // Not sent to model
      };

      if (role != null && parts.isNotEmpty) {
        result.add(google_ai.Content(role: role, parts: parts));
      }
    }
    return result;
  }

  List<google_ai.Part> _convertParts(List<MessagePart> parts) {
    final result = <google_ai.Part>[];
    for (final part in parts) {
      switch (part) {
        case TextPart():
          result.add(google_ai.Part(text: part.text));
        case ImagePart():
          if (part.bytes != null) {
            result.add(
              google_ai.Part(
                inlineData: google_ai.Blob(
                  mimeType: part.mimeType,
                  data: part
                      .bytes!, // Assuming bytes is not null here as per logic
                ),
              ),
            );
          } else if (part.base64 != null) {
            result.add(
              google_ai.Part(
                inlineData: google_ai.Blob(
                  mimeType: part.mimeType,
                  data: Uint8List.fromList(base64.decode(part.base64!)),
                ),
              ),
            );
          } else if (part.url != null) {
            // Google Cloud API supports file URIs
            result.add(
              google_ai.Part(
                fileData: google_ai.FileData(fileUri: part.url.toString()),
              ),
            );
          } else {
            throw GoogleAiClientException('ImagePart has no data.');
          }
        case ToolCallPart():
          result.add(
            google_ai.Part(
              functionCall: google_ai.FunctionCall(
                id: part.id,
                name: part.toolName,
                args: protobuf.Struct.fromJson(part.arguments),
              ),
            ),
          );
        case ToolResultPart():
          result.add(
            google_ai.Part(
              functionResponse: google_ai.FunctionResponse(
                id: part.callId,
                // ToolResultPart will be removed in the future.
                // Function calling history is managed within the
                // Content Generator.
                name: '',
                // The result from ToolResultPart is a JSON string
                response: protobuf.Struct.fromJson(
                  jsonDecode(part.result) as Map<String, Object?>,
                ),
              ),
            ),
          );
        case ThinkingPart():
          // Represent thoughts as text.
          result.add(google_ai.Part(text: 'Thinking: ${part.text}'));
        case DataPart():
          throw GoogleAiClientException(
            'DataPart is not supported for Google AI conversion.',
          );
      }
    }
    return result;
  }

  List<google_ai.Part> _convertToolResults(List<MessagePart> parts) {
    final result = <google_ai.Part>[];
    for (final part in parts) {
      if (part is ToolResultPart) {
        result.add(
          google_ai.Part(
            functionResponse: google_ai.FunctionResponse(
              id: part.callId,
              // ToolResultPart will be removed in the future.
              // Function calling history is managed within the
              // Content Generator.
              name: '',
              response: protobuf.Struct.fromJson(
                jsonDecode(part.result) as Map<String, Object?>,
              ),
            ),
          ),
        );
      }
    }
    return result;
  }
}
