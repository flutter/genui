// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';

import '../../parser/incremental_processor.dart';
import '../../parser/response_part.dart';
import '../../primitives/protocol_version.dart';
import '../../validation/payload_validator.dart';
import 'payload_fixer.dart';

/// One top-level message found in a partially received payload.
class MessageFragment {
  /// The message text, healed if it was still being streamed.
  final String text;

  /// Whether the message's closing brace was actually received.
  final bool complete;

  const MessageFragment({required this.text, required this.complete});
}

/// Splits a partially received A2UI JSON payload into message fragments,
/// repairing the one still in flight.
///
/// A model emits components top-down, so a payload that has only been half
/// received still describes a renderable prefix of the UI. The scanner finds
/// every message whose text is usable and closes the containers the model has
/// not written yet.
class JsonFragmentScanner {
  /// The raw payload text received so far.
  final String source;

  /// Property keys whose truncated string values may be closed early.
  ///
  /// Closing a string for any other key would invent a value; for these keys a
  /// prefix of the final string is a legitimate value that simply grows as
  /// more of the stream arrives.
  final Set<String> progressiveKeys;

  JsonFragmentScanner(this.source, {required this.progressiveKeys});

  /// Returns the message fragments contained in [source].
  List<MessageFragment> scan() {
    final fragments = <MessageFragment>[];
    int index = _skipWhitespace(0);
    if (index < source.length && source[index] == '[') index++;

    while (true) {
      index = _skipWhitespace(index);
      while (index < source.length &&
          (source[index] == ',' || source[index] == ']')) {
        index = _skipWhitespace(index + 1);
      }
      if (index >= source.length) break;
      if (source[index] != '{') break;

      final _WalkResult result = _walk(index);
      if (result.end != null) {
        fragments.add(
          MessageFragment(
            text: source.substring(index, result.end),
            complete: true,
          ),
        );
        index = result.end!;
        continue;
      }

      final String? healed = _heal(index, result);
      if (healed != null) {
        fragments.add(MessageFragment(text: healed, complete: false));
      }
      break;
    }
    return fragments;
  }

  int _skipWhitespace(int from) {
    var index = from;
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
    return index;
  }

  _WalkResult _walk(int start) {
    final stack = <_Frame>[];
    var inString = false;
    var escaped = false;
    var isKeyString = false;
    String? pendingKey;

    for (var i = start; i < source.length; i++) {
      final String char = source[i];

      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
          if (isKeyString) {
            pendingKey = _decodeStringLiteral(source, i);
          } else {
            _completeValue(stack, i + 1);
          }
        }
        continue;
      }

      switch (char) {
        case '"':
          inString = true;
          isKeyString =
              stack.isNotEmpty && stack.last.isObject && stack.last.expectKey;
          break;
        case '{':
        case '[':
          stack.add(
            _Frame(
              isObject: char == '{',
              completeUpTo: i + 1,
              expectKey: char == '{',
            ),
          );
          break;
        case '}':
        case ']':
          if (stack.isEmpty) return _WalkResult(end: null, stack: stack);
          stack.removeLast();
          if (stack.isEmpty) {
            return _WalkResult(end: i + 1, stack: stack);
          }
          _completeValue(stack, i + 1);
          break;
        case ':':
          if (stack.isNotEmpty) {
            stack.last
              ..expectKey = false
              ..currentKey = pendingKey;
          }
          break;
        case ',':
          if (stack.isNotEmpty && stack.last.isObject) {
            stack.last.expectKey = true;
          }
          break;
        default:
          if (char.trim().isEmpty) break;
          final int end = _literalEnd(i);
          _completeValue(stack, end);
          i = end - 1;
      }
    }

    return _WalkResult(
      end: null,
      stack: stack,
      inString: inString,
      isKeyString: isKeyString,
    );
  }

  int _literalEnd(int start) {
    var index = start;
    while (index < source.length) {
      final String char = source[index];
      if (char == ',' ||
          char == '}' ||
          char == ']' ||
          char.trim().isEmpty ||
          char == ':') {
        break;
      }
      index++;
    }
    return index;
  }

  void _completeValue(List<_Frame> stack, int end) {
    if (stack.isEmpty) return;
    stack.last.completeUpTo = end;
    if (stack.last.isObject) stack.last.expectKey = true;
  }

  String? _heal(int start, _WalkResult result) {
    if (result.stack.isEmpty) return null;

    String text;
    if (result.inString) {
      final String? key = result.stack.last.isObject
          ? result.stack.last.currentKey
          : null;
      final bool canClose =
          !result.isKeyString && key != null && progressiveKeys.contains(key);
      text = canClose
          ? '${source.substring(start)}"'
          : source.substring(start, result.stack.last.completeUpTo);
    } else {
      text = source.substring(start, result.stack.last.completeUpTo);
    }

    final closers = StringBuffer();
    for (int i = result.stack.length - 1; i >= 0; i--) {
      closers.write(result.stack[i].isObject ? '}' : ']');
    }
    return '$text$closers';
  }

  /// Decodes the string literal ending at [end] (the index of its closing
  /// quote), so that escape sequences in property keys are honoured.
  static String? _decodeStringLiteral(String source, int end) {
    int start = end - 1;
    while (start >= 0) {
      if (source[start] == '"') {
        var backslashes = 0;
        int index = start - 1;
        while (index >= 0 && source[index] == r'\') {
          backslashes++;
          index--;
        }
        if (backslashes.isEven) break;
      }
      start--;
    }
    if (start < 0) return null;
    try {
      final Object? decoded = jsonDecode(source.substring(start, end + 1));
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

class _Frame {
  _Frame({
    required this.isObject,
    required this.completeUpTo,
    required this.expectKey,
  });

  final bool isObject;

  /// The index just past the last fully received member of this container.
  int completeUpTo;

  /// Whether the next string in this object is a property key.
  bool expectKey;

  /// The key whose value is currently being received.
  String? currentKey;
}

class _WalkResult {
  _WalkResult({
    required this.end,
    required this.stack,
    this.inString = false,
    this.isKeyString = false,
  });

  /// The index just past the closing brace, or null if still open.
  final int? end;
  final List<_Frame> stack;
  final bool inString;
  final bool isKeyString;
}

/// Turns a stream of Direct JSON chunks into incremental A2UI messages.
///
/// Emission is delta-only and idempotent per component: a component is emitted
/// as soon as it is usable and re-emitted only when its content actually
/// changed, which is what lets a renderer show text growing as it streams.
/// `updateComponents` is additive per component id on the renderer, so a
/// partial batch is a valid message rather than a promise of one.
class DirectJsonStreamProcessor extends IncrementalStreamProcessor {
  /// The catalogs compiled payloads are validated against.
  final List<Catalog<ComponentApi>> catalogs;

  /// Property keys whose truncated string values may be closed early.
  final Set<String> progressiveKeys;

  /// The protocol version stamped on messages that omit one.
  final ProtocolVersion protocolVersion;

  final A2uiPayloadValidator _validator;

  /// Component payloads already emitted, keyed by message index and id.
  final Map<String, String> _emittedComponents = {};

  /// Indexes of atomic messages already emitted.
  final Set<int> _emittedMessages = {};

  DirectJsonStreamProcessor({
    required this.catalogs,
    required this.progressiveKeys,
    required super.openTag,
    required super.closeTag,
    this.protocolVersion = ProtocolVersion.current,
  }) : _validator = A2uiPayloadValidator(
         catalogs: catalogs,
         protocolVersion: protocolVersion,
       );

  @override
  void resetBlock() {
    _emittedComponents.clear();
    _emittedMessages.clear();
  }

  @override
  List<AgentToRendererMessage> emitDelta(
    String rawBlock, {
    required bool blockComplete,
  }) {
    final String payload = PayloadFixer.stripMarkdownFence(rawBlock);
    if (payload.trim().isEmpty) return const [];

    final List<MessageFragment> fragments = JsonFragmentScanner(
      payload,
      progressiveKeys: progressiveKeys,
    ).scan();

    final delta = <AgentToRendererMessage>[];
    for (var index = 0; index < fragments.length; index++) {
      final MessageFragment fragment = fragments[index];
      final Map<String, dynamic>? json = _decode(fragment.text);
      if (json == null) continue;

      if (json.containsKey('updateComponents')) {
        final AgentToRendererMessage? message = _componentDelta(index, json);
        if (message != null) delta.add(message);
        continue;
      }

      if (!fragment.complete || !_emittedMessages.add(index)) continue;
      delta.add(A2uiMessage.fromJson(json));
    }

    if (delta.isEmpty) return const [];
    _validator.validateOrThrow(delta, partial: !blockComplete);
    return delta;
  }

  Map<String, dynamic>? _decode(String text) {
    try {
      final Object? decoded = jsonDecode(
        PayloadFixer.normalizeSmartQuotes(text),
      );
      if (decoded is! Map) return null;
      final Map<String, dynamic> json = decoded.cast<String, dynamic>();
      return json.containsKey('version')
          ? json
          : {'version': protocolVersion.wireValue, ...json};
    } on FormatException {
      return null;
    }
  }

  AgentToRendererMessage? _componentDelta(
    int index,
    Map<String, dynamic> json,
  ) {
    final Object? body = json['updateComponents'];
    if (body is! Map) return null;
    final Object? surfaceId = body['surfaceId'];
    final Object? components = body['components'];
    if (surfaceId is! String || components is! List) return null;

    final fresh = <Map<String, dynamic>>[];
    for (final Object? entry in components) {
      if (entry is! Map) continue;
      final Map<String, dynamic> component = entry.cast<String, dynamic>();
      final Object? id = component['id'];
      final Object? type = component['component'];
      // A component without an id or a type is still arriving; it is not
      // renderable and must not be emitted as though it were.
      if (id is! String || id.isEmpty || type is! String || type.isEmpty) {
        continue;
      }
      final String encoded = jsonEncode(component);
      final key = '$index $id';
      if (_emittedComponents[key] == encoded) continue;
      _emittedComponents[key] = encoded;
      fresh.add(component);
    }

    if (fresh.isEmpty) return null;
    return UpdateComponentsMessage(
      version: json['version'] as String? ?? protocolVersion.wireValue,
      surfaceId: surfaceId,
      components: fresh,
    );
  }
}
