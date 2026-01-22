// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart' show XFile;
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
// ignore: implementation_imports
import 'package:mime/src/default_extension_map.dart';
import 'package:path/path.dart' as p;

import 'model.dart';

/// Converter registry for parts in this package.
///
/// The key of a map entry is the part type.
/// The value is the converter that knows how to convert that part type.
///
/// To add support for additional part types, extend this map.
///
/// To limit supported part types, or to remove support for part types
/// in future versions of `genai_primitives`, define a new map.
const Map<String, JsonToPartConverter<Part>> defaultPartConverterRegistry =
    _standardPartConverterRegistry;

const _standardPartConverterRegistry =
    <String, JsonToPartConverter<StandardPart>>{
      TextPart.type: PartConverter(TextPart.fromJson),
      DataPart.type: PartConverter(DataPart.fromJson),
      LinkPart.type: PartConverter(LinkPart.fromJson),
      ToolPart.type: PartConverter(ToolPart.fromJson),
      ThinkingPart.type: PartConverter(ThinkingPart.fromJson),
    };

/// Base class for parts that became de-facto standard for AI messages.
///
/// It is sealed to prevent extensions.
sealed class StandardPart extends Part {
  const StandardPart();

  /// Deserializes a part from a JSON map.
  factory StandardPart.fromJson(Map<String, Object?> json) {
    final type = json[Part.typeKey] as String;
    final JsonToPartConverter<StandardPart> converter =
        _standardPartConverterRegistry[type]!;
    return converter.convert(json);
  }
}

final class _Json {
  static const content = 'content';
  static const mimeType = 'mimeType';
  static const name = 'name';
  static const bytes = 'bytes';
  static const url = 'url';
  static const id = 'id';
  static const arguments = 'arguments';
  static const result = 'result';
}

/// A text part of a message.
@immutable
final class TextPart extends StandardPart {
  static const type = 'Text';

  /// Creates a new text part.
  const TextPart(this.text);

  /// The text content.
  final String text;

  /// Creates a text part from a JSON-compatible map.
  factory TextPart.fromJson(Map<String, Object?> json) {
    return TextPart(json[_Json.content] as String);
  }

  @override
  Map<String, Object?> toJson() => {Part.typeKey: type, _Json.content: text};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is TextPart && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextPart($text)';
}

/// A data part containing binary data (e.g., images).
@immutable
final class DataPart extends StandardPart {
  static const type = 'Data';

  /// Creates a new data part.
  DataPart(this.bytes, {required this.mimeType, String? name})
    : name = name ?? nameFromMimeType(mimeType);

  /// Creates a data part from a JSON-compatible map.
  factory DataPart.fromJson(Map<String, Object?> json) {
    final content = json[_Json.content] as Map<String, Object?>;
    final dataUri = content[_Json.bytes] as String;
    final Uri uri = Uri.parse(dataUri);
    return DataPart(
      uri.data!.contentAsBytes(),
      mimeType: content[_Json.mimeType] as String,
      name: content[_Json.name] as String?,
    );
  }

  /// Creates a data part from an [XFile].
  static Future<DataPart> fromFile(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    final String? name = _nameFromPath(file.path) ?? _emptyNull(file.name);
    final String mimeType =
        _emptyNull(file.mimeType) ??
        mimeTypeForFile(
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
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.content: {
      if (name != null) _Json.name: name,
      _Json.mimeType: mimeType,
      _Json.bytes: 'data:$mimeType;base64,${base64Encode(bytes)}',
    },
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    const deepEquality = DeepCollectionEquality();
    return other is DataPart &&
        deepEquality.equals(other.bytes, bytes) &&
        other.mimeType == mimeType &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(mimeType, name, Object.hashAll(bytes));

  @override
  String toString() =>
      'DataPart(mimeType: $mimeType, name: $name, bytes: ${bytes.length})';

  @visibleForTesting
  static const defaultMimeType = 'application/octet-stream';

  /// Gets the MIME type for a file.
  @visibleForTesting
  static String mimeTypeForFile(String path, {Uint8List? headerBytes}) =>
      lookupMimeType(path, headerBytes: headerBytes) ?? defaultMimeType;

  /// Gets the name for a MIME type.
  @visibleForTesting
  static String nameFromMimeType(String mimeType) {
    final String ext = extensionFromMimeType(mimeType) ?? 'bin';
    return mimeType.startsWith('image/') ? 'image.$ext' : 'file.$ext';
  }

  /// Gets the extension for a MIME type.
  @visibleForTesting
  static String? extensionFromMimeType(String mimeType) {
    final String ext = defaultExtensionMap.entries
        .firstWhere(
          (e) => e.value == mimeType,
          orElse: () => const MapEntry('', ''),
        )
        .key;
    return ext.isNotEmpty ? ext : null;
  }
}

/// A link part referencing external content.
@immutable
final class LinkPart extends StandardPart {
  static const type = 'Link';

  /// Creates a new link part.
  const LinkPart(this.url, {this.mimeType, this.name});

  /// The URL of the external content.
  final Uri url;

  /// Optional MIME type of the linked content.
  final String? mimeType;

  /// Optional name for the link.
  final String? name;

  /// Creates a link part from a JSON-compatible map.
  factory LinkPart.fromJson(Map<String, Object?> json) {
    final content = json[_Json.content] as Map<String, Object?>;
    return LinkPart(
      Uri.parse(content[_Json.url] as String),
      mimeType: content[_Json.mimeType] as String?,
      name: content[_Json.name] as String?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.content: {
      if (name != null) _Json.name: name,
      if (mimeType != null) _Json.mimeType: mimeType,
      _Json.url: url.toString(),
    },
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

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
final class ToolPart extends StandardPart {
  static const type = 'Tool';

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
  final Map<String, Object?>? arguments;

  /// The result of a tool execution (null for calls).
  final Object? result;

  /// The arguments as a JSON string.
  String get argumentsRaw => arguments == null ? '' : jsonEncode(arguments);

  /// Creates a tool part from a JSON-compatible map.
  factory ToolPart.fromJson(Map<String, Object?> json) {
    final content = json[_Json.content] as Map<String, Object?>;
    if (content.containsKey(_Json.arguments)) {
      return ToolPart.call(
        callId: content[_Json.id] as String,
        toolName: content[_Json.name] as String,
        arguments: content[_Json.arguments] as Map<String, Object?>? ?? {},
      );
    } else {
      return ToolPart.result(
        callId: content[_Json.id] as String,
        toolName: content[_Json.name] as String,
        result: content[_Json.result],
      );
    }
  }

  @override
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.content: {
      _Json.id: callId,
      _Json.name: toolName,
      if (arguments != null) _Json.arguments: arguments,
      if (result != null) _Json.result: result,
    },
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    const deepEquality = DeepCollectionEquality();
    return other is ToolPart &&
        other.kind == kind &&
        other.callId == callId &&
        other.toolName == toolName &&
        deepEquality.equals(other.arguments, arguments) &&
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

/// A "thinking" part of a message, used by some models to show reasoning.
@immutable
final class ThinkingPart extends StandardPart {
  static const type = 'Thinking';

  /// Creates a thinking part.
  const ThinkingPart(this.text);

  /// The thinking content.
  final String text;

  /// Creates a thinking part from a JSON map.
  factory ThinkingPart.fromJson(Map<String, Object?> json) {
    return ThinkingPart(json[_Json.content] as String);
  }

  @override
  Map<String, Object?> toJson() => {Part.typeKey: type, _Json.content: text};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ThinkingPart && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'ThinkingPart(text: $text)';
}
