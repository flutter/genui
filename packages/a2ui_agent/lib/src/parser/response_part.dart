// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

/// A message sent from an agent to a renderer.
///
/// The A2UI specification names this concept `AgentToRendererMessage`; in Dart
/// it is modelled by [A2uiMessage] from `package:a2ui_core`.
typedef AgentToRendererMessage = A2uiMessage;

/// A compiled slice of an LLM response, ready to hand to the caller.
///
/// Either conversational [TextPart] or a compiled [A2uiPart].
sealed class ResponsePart {
  const ResponsePart();
}

/// An uncompiled slice of an LLM response, as emitted by the model.
///
/// Either conversational [TextPart] or a still-raw [RawA2uiPart].
sealed class RawPart {
  const RawPart();
}

/// Conversational text extracted from an LLM response.
final class TextPart extends ResponsePart implements RawPart {
  /// The conversational text content intended for user display.
  final String text;

  const TextPart(this.text);

  @override
  bool operator ==(Object other) => other is TextPart && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextPart(${_preview(text)})';
}

/// An uncompiled A2UI format content block extracted from an LLM response.
final class RawA2uiPart extends RawPart {
  /// The raw uncompiled format content (e.g. raw JSON or Express DSL), with
  /// the enclosing sentinel tags removed.
  final String a2uiRaw;

  const RawA2uiPart(this.a2uiRaw);

  @override
  bool operator ==(Object other) =>
      other is RawA2uiPart && other.a2uiRaw == a2uiRaw;

  @override
  int get hashCode => a2uiRaw.hashCode;

  @override
  String toString() => 'RawA2uiPart(${_preview(a2uiRaw)})';
}

/// An uncompiled token from an LLM response stream.
final class RawResponsePart {
  /// The underlying content: conversational [TextPart] or uncompiled
  /// [RawA2uiPart].
  final RawPart part;

  /// Whether this part is complete, i.e. not truncated mid-stream.
  ///
  /// A [RawA2uiPart] is final once its closing sentinel tag has been seen; a
  /// [TextPart] is final once a following sentinel tag or the end of the
  /// response proves that no more text can be appended to it.
  final bool isFinal;

  const RawResponsePart(this.part, {this.isFinal = true});

  @override
  String toString() => 'RawResponsePart($part, isFinal: $isFinal)';
}

/// Extracted and compiled A2UI payload messages.
final class A2uiPart extends ResponsePart {
  /// The compiled messages to deliver to client renderers.
  final List<AgentToRendererMessage> a2ui;

  const A2uiPart(this.a2ui);

  /// The messages serialized back to their JSON envelopes.
  List<Map<String, dynamic>> toJson() => [
    for (final AgentToRendererMessage message in a2ui) message.toJson(),
  ];

  @override
  String toString() => 'A2uiPart(${a2ui.length} message(s))';
}

String _preview(String value) {
  const maxLength = 40;
  final String collapsed = value.replaceAll('\n', r'\n');
  if (collapsed.length <= maxLength) return "'$collapsed'";
  return "'${collapsed.substring(0, maxLength)}…'";
}
