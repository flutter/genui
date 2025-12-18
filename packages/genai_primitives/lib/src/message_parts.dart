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
          id: content['id'] as String,
          name: content['name'] as String,
          arguments: content['arguments'] as Map<String, dynamic>? ?? {},
        );
      } else {
        return ToolPart.result(
          id: content['id'] as String,
          name: content['name'] as String,
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
  Map<String, dynamic> toJson() => {
    'type': runtimeType.toString(),
    'content': switch (this) {
      TextPart(text: final text) => text,
      DataPart(
        bytes: final bytes,
        mimeType: final mimeType,
        name: final name,
      ) =>
        {
          if (name != null) 'name': name,
          'mimeType': mimeType,
          'bytes': 'data:$mimeType;base64,${base64Encode(bytes)}',
        },
      LinkPart(url: final url, mimeType: final mimeType, name: final name) => {
        if (name != null) 'name': name,
        if (mimeType != null) 'mimeType': mimeType,
        'url': url.toString(),
      },
      ToolPart(
        id: final id,
        name: final name,
        arguments: final arguments,
        result: final result,
      ) =>
        {
          'id': id,
          'name': name,
          if (arguments != null) 'arguments': arguments,
          if (result != null) 'result': result,
        },
      _ => throw UnimplementedError('Unknown part type: $runtimeType'),
    },
  };
}

/// A text part of a message.
@immutable
class TextPart extends Part {
  /// Creates a new text part.
  const TextPart(this.text);

  /// The text content.
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextPart &&
          runtimeType == other.runtimeType &&
          text == other.text;

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPart &&
          runtimeType == other.runtimeType &&
          listEquals(bytes, other.bytes) &&
          mimeType == other.mimeType &&
          name == other.name;

  @override
  int get hashCode => bytes.hashCode ^ mimeType.hashCode ^ name.hashCode;

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkPart &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          mimeType == other.mimeType &&
          name == other.name;

  @override
  int get hashCode => url.hashCode ^ mimeType.hashCode ^ name.hashCode;

  @override
  String toString() => 'LinkPart(url: $url, mimeType: $mimeType, name: $name)';
}

/// A tool interaction part of a message.
@immutable
class ToolPart extends Part {
  /// Creates a tool call part.
  const ToolPart.call({
    required this.id,
    required this.name,
    required this.arguments,
  }) : kind = ToolPartKind.call,
       result = null;

  /// Creates a tool result part.
  const ToolPart.result({
    required this.id,
    required this.name,
    required this.result,
  }) : kind = ToolPartKind.result,
       arguments = null;

  /// The kind of tool interaction.
  final ToolPartKind kind;

  /// The unique identifier for this tool interaction.
  final String id;

  /// The name of the tool.
  final String name;

  /// The arguments for a tool call (null for results).
  final Map<String, dynamic>? arguments;

  /// The result of a tool execution (null for calls).
  final dynamic result;

  /// The arguments as a JSON string.
  String get argumentsRaw => arguments != null
      ? (arguments!.isEmpty ? '{}' : jsonEncode(arguments))
      : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolPart &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          id == other.id &&
          name == other.name &&
          mapEquals(arguments, other.arguments) &&
          result == other.result;

  @override
  int get hashCode =>
      kind.hashCode ^
      id.hashCode ^
      name.hashCode ^
      arguments.hashCode ^
      result.hashCode;

  @override
  String toString() {
    if (kind == ToolPartKind.call) {
      return 'ToolPart.call(id: $id, name: $name, arguments: $arguments)';
    } else {
      return 'ToolPart.result(id: $id, name: $name, result: $result)';
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
