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

final class _Json {
  static const type = 'type';
  static const content = 'content';
  static const mimeType = 'mimeType';
  static const name = 'name';
  static const bytes = 'bytes';
  static const url = 'url';
  static const id = 'id';
  static const arguments = 'arguments';
  static const result = 'result';
}

final class _Part {
  static const text = 'Text';
  static const data = 'Data';
  static const link = 'Link';
  static const tool = 'Tool';
}

/// Base class for message content parts.
///
/// To create a custom part implementation, extend this class and ensure the
/// following requirements are met for a robust implementation:
///
/// * **Equality and Hashing**: Override [operator ==] and [hashCode] to
///   ensure value-based equality.
/// * **Serialization**: Implement a `toJson()` method that returns a
///   JSON-encodable [Map]. The map must contain a `type` field with a unique
///   string identifier for the custom part. See [defaultPartConverterRegistry]
///   for the default registry and existing part types.
/// * **Deserialization**: Implement a `JsonToPartConverter` that can recreate
///   the part from its JSON representation.
/// * Pass extended [defaultPartConverterRegistry] to all methods `fromJson`
///   that accept a converter registry.
@immutable
abstract base class Part {
  /// Creates a new part.
  const Part();

  /// Deserializes a part from a JSON map.
  ///
  /// The [converterRegistry] parameter is a map of part types to converters.
  /// If the registry is not provided, [defaultPartConverterRegistry] is used.
  ///
  /// If you need to deserialize a part that is not in the default registry,
  /// extend [defaultPartConverterRegistry] and pass it to this method.
  factory Part.fromJson(
    Map<String, Object?> json, {
    Map<String, JsonToPartConverter> converterRegistry =
        defaultPartConverterRegistry,
  }) {
    final type = json[_Json.type] as String;
    final JsonToPartConverter? converter = converterRegistry[type];
    if (converter == null) {
      throw UnimplementedError('Unknown part type: $type');
    }
    return converter.convert(json);
  }

  /// Serializes the part to a JSON map.
  ///
  /// The returned map must contain a key `type` with a unique string
  /// identifier for the custom part. See keys of [defaultPartConverterRegistry]
  /// for existing part types.
  Map<String, Object?> toJson();
}

typedef JsonToPartConverter = Converter<Map<String, Object?>, Part>;
typedef _JsonToPartFunction = Part Function(Map<String, Object?> json);

/// Converter registry.
///
/// The key of a map entry is the part type.
/// The value is the converter that knows how to convert that part type.
const defaultPartConverterRegistry = <String, JsonToPartConverter>{
  _Part.text: PartConverter(TextPart.fromJson),
  _Part.data: PartConverter(DataPart.fromJson),
  _Part.link: PartConverter(LinkPart.fromJson),
  _Part.tool: PartConverter(ToolPart.fromJson),
};

/// A converter that converts a JSON map to a [Part].
@visibleForTesting
class PartConverter extends JsonToPartConverter {
  const PartConverter(this._function);

  final _JsonToPartFunction _function;

  @override
  Part convert(Map<String, Object?> input) {
    return _function(input);
  }
}

/// A text part of a message.
@immutable
final class TextPart extends Part {
  /// Creates a new text part.
  const TextPart(this.text);

  /// The text content.
  final String text;

  /// Creates a text part from a JSON-compatible map.
  factory TextPart.fromJson(Map<String, Object?> json) {
    return TextPart(json[_Json.content] as String);
  }

  @override
  Map<String, Object?> toJson() => {
    _Json.type: _Part.text,
    _Json.content: text,
  };

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
final class DataPart extends Part {
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
    _Json.type: _Part.data,
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
final class LinkPart extends Part {
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
    _Json.type: _Part.link,
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
final class ToolPart extends Part {
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
    _Json.type: _Part.tool,
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
