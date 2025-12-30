// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart' show XFile;
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
// ignore: implementation_imports
import 'package:mime/src/default_extension_map.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

/// Base class for message content parts.
@immutable
abstract class Part {
  /// Creates a new part.
  const Part();

  /// Creates a part from a JSON-compatible map.
  factory Part.fromJson(Map<String, dynamic> json) => switch (json['type']) {
    'TextPart' => TextPart(json['content'] as String),
    'DataPart' => () {
      final content = json['content'] as Map<String, dynamic>;
      final dataUri = content['bytes'] as String;
      final Uri uri = Uri.parse(dataUri);
      return DataPart(
        uri.data!.contentAsBytes(),
        mimeType: content['mimeType'] as String,
        name: content['name'] as String?,
      );
    }(),
    'LinkPart' => () {
      final content = json['content'] as Map<String, dynamic>;
      return LinkPart(
        Uri.parse(content['url'] as String),
        mimeType: content['mimeType'] as String?,
        name: content['name'] as String?,
      );
    }(),
    'ToolPart' => () {
      final content = json['content'] as Map<String, dynamic>;
      // Check if it's a call or result based on presence of arguments or result
      if (content.containsKey('arguments')) {
        return ToolPart.call(
          callId: content['id'] as String,
          toolName: content['name'] as String,
          arguments: content['arguments'] as Map<String, dynamic>? ?? {},
        );
      } else {
        return ToolPart.result(
          callId: content['id'] as String,
          toolName: content['name'] as String,
          result: content['result'],
        );
      }
    }(),
    _ => throw UnimplementedError('Unknown part type: ${json['type']}'),
  };

  /// The default MIME type for binary data.
  static const defaultMimeType = 'application/octet-stream';

  /// Gets the MIME type for a file.
  static String mimeType(String path, {Uint8List? headerBytes}) =>
      lookupMimeType(path, headerBytes: headerBytes) ?? defaultMimeType;

  /// Gets the name for a MIME type.
  static String nameFromMimeType(String mimeType) {
    final String ext = extensionFromMimeType(mimeType) ?? '.bin';
    return mimeType.startsWith('image/') ? 'image.$ext' : 'file.$ext';
  }

  /// Gets the extension for a MIME type.
  static String? extensionFromMimeType(String mimeType) {
    final String ext = defaultExtensionMap.entries
        .firstWhere(
          (e) => e.value == mimeType,
          orElse: () => const MapEntry('', ''),
        )
        .key;
    return ext.isNotEmpty ? ext : null;
  }

  /// Converts the part to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final String typeName;
    final Object content;
    switch (this) {
      case final TextPart p:
        typeName = 'TextPart';
        content = p.text;
        break;
      case final DataPart p:
        typeName = 'DataPart';
        content = {
          if (p.name != null) 'name': p.name,
          'mimeType': p.mimeType,
          'bytes': 'data:${p.mimeType};base64,${base64Encode(p.bytes)}',
        };
        break;
      case final LinkPart p:
        typeName = 'LinkPart';
        content = {
          if (p.name != null) 'name': p.name,
          if (p.mimeType != null) 'mimeType': p.mimeType,
          'url': p.url.toString(),
        };
        break;
      case final ToolPart p:
        typeName = 'ToolPart';
        content = {
          'id': p.callId,
          'name': p.toolName,
          if (p.arguments != null) 'arguments': p.arguments,
          if (p.result != null) 'result': p.result,
        };
        break;
      default:
        throw UnimplementedError('Unknown part type: $runtimeType');
    }
    return {'type': typeName, 'content': content};
  }
}

/// A text part of a message.
@immutable
class TextPart extends Part {
  /// Creates a new text part.
  const TextPart(this.text);

  /// The text content.
  final String text;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextPart && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextPart($text)';
}

/// A data part containing binary data (e.g., images).
@immutable
class DataPart extends Part {
  /// Creates a new data part.
  DataPart(this.bytes, {required this.mimeType, String? name})
    : name = name ?? Part.nameFromMimeType(mimeType);

  /// Creates a data part from an [XFile].
  static Future<DataPart> fromFile(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    final String? name = _nameFromPath(file.path) ?? _emptyNull(file.name);
    final String mimeType =
        _emptyNull(file.mimeType) ??
        Part.mimeType(
          name ?? '',
          headerBytes: Uint8List.fromList(
            bytes.take(defaultMagicNumbersMaxLength).toList(),
          ),
        );

    return DataPart(bytes, mimeType: mimeType, name: name);
  }

  static String? _nameFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final Uri? url = Uri.tryParse(path);
    if (url == null) return p.basename(path);
    final List<String> segments = url.pathSegments;
    if (segments.isEmpty) return null;
    return segments.last;
  }

  static String? _emptyNull(String? value) =>
      value == null || value.isEmpty ? null : value;

  /// The binary data.
  final Uint8List bytes;

  /// The MIME type of the data.
  final String mimeType;

  /// Optional name for the data.
  final String? name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataPart &&
        listEquals(other.bytes, bytes) &&
        other.mimeType == mimeType &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(mimeType, name, Object.hashAll(bytes));

  @override
  String toString() =>
      'DataPart(mimeType: $mimeType, name: $name, bytes: ${bytes.length})';
}

/// A link part referencing external content.
@immutable
class LinkPart extends Part {
  /// Creates a new link part.
  const LinkPart(this.url, {this.mimeType, this.name});

  /// The URL of the external content.
  final Uri url;

  /// Optional MIME type of the linked content.
  final String? mimeType;

  /// Optional name for the link.
  final String? name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkPart &&
        other.url == url &&
        other.mimeType == mimeType &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(url, mimeType, name);

  @override
  String toString() => 'LinkPart(url: $url, mimeType: $mimeType, name: $name)';
}

/// A tool interaction part of a message.
@immutable
class ToolPart extends Part {
  /// Creates a tool call part.
  /// Creates a tool call part.
  const ToolPart.call({
    required this.callId,
    required this.toolName,
    required this.arguments,
  }) : kind = ToolPartKind.call,
       result = null;

  /// Creates a tool result part.
  const ToolPart.result({
    required this.callId,
    required this.toolName,
    required this.result,
  }) : kind = ToolPartKind.result,
       arguments = null;

  /// The kind of tool interaction.
  final ToolPartKind kind;

  /// The unique identifier for this tool interaction.
  final String callId;

  /// The name of the tool.
  final String toolName;

  /// The arguments for a tool call (null for results).
  final Map<String, dynamic>? arguments;

  /// The result of a tool execution (null for calls).
  final dynamic result;

  /// The arguments as a JSON string.
  String get argumentsRaw => arguments != null
      ? (arguments!.isEmpty ? '{}' : jsonEncode(arguments))
      : '';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolPart &&
        other.kind == kind &&
        other.callId == callId &&
        other.toolName == toolName &&
        mapEquals(other.arguments, arguments) &&
        other.result == result;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    callId,
    toolName,
    arguments != null ? Object.hashAll(arguments!.entries) : null,
    result,
  );

  @override
  String toString() {
    if (kind == ToolPartKind.call) {
      return 'ToolPart.call(callId: $callId, '
          'toolName: $toolName, arguments: $arguments)';
    } else {
      return 'ToolPart.result(callId: $callId, '
          'toolName: $toolName, result: $result)';
    }
  }
}

/// The kind of tool interaction.
enum ToolPartKind {
  /// A request to call a tool.
  call,

  /// The result of a tool execution.
  result,
}

/// Static helper methods for extracting specific types of parts from a list.
extension MessagePartHelpers on Iterable<Part> {
  /// Extracts and concatenates all text content from TextPart instances.
  ///
  /// Returns a single string with all text content concatenated together
  /// without any separators. Empty text parts are included in the result.
  String get text => whereType<TextPart>().map((p) => p.text).join();

  /// Extracts all tool call parts from the list.
  ///
  /// Returns only ToolPart instances where kind == ToolPartKind.call.
  List<ToolPart> get toolCalls =>
      whereType<ToolPart>().where((p) => p.kind == ToolPartKind.call).toList();

  /// Extracts all tool result parts from the list.
  ///
  /// Returns only ToolPart instances where kind == ToolPartKind.result.
  List<ToolPart> get toolResults => whereType<ToolPart>()
      .where((p) => p.kind == ToolPartKind.result)
      .toList();
}
