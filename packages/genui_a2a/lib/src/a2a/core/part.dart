// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport "message.dart";
library;

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'part.g.dart';

// ignore_for_file: invalid_annotation_target

/// Represents a distinct piece of content within a [Message] or Artifact.
///
/// A [Part] can be text, a file reference, or structured data. The `kind` field
/// acts as a discriminator to determine the specific type of the content part.
sealed class Part {
  /// The type discriminator.
  final String kind;

  /// Optional metadata associated with this part.
  final Map<String, Object?>? metadata;

  const Part({required this.kind, this.metadata});

  /// Deserializes a [Part] instance from a JSON object.
  factory Part.fromJson(Map<String, Object?> json) {
    final kind = json['kind'] as String?;
    switch (kind) {
      case 'text':
        return TextPart.fromJson(json);
      case 'file':
        return FilePart.fromJson(json);
      case 'data':
        return DataPart.fromJson(json);
      default:
        throw ArgumentError('Unknown Part kind: $kind');
    }
  }

  /// Represents a plain text content part.
  const factory Part.text({
    String? kind,
    required String text,
    Map<String, Object?>? metadata,
  }) = TextPart;

  /// Represents a file content part.
  const factory Part.file({
    String? kind,
    required FileType file,
    Map<String, Object?>? metadata,
  }) = FilePart;

  /// Represents a structured JSON data content part.
  const factory Part.data({
    String? kind,
    required Map<String, Object?> data,
    Map<String, Object?>? metadata,
  }) = DataPart;

  /// Creates a JSON object from a [Part].
  Map<String, Object?> toJson();
}

/// Represents a plain text content part.
@JsonSerializable()
class TextPart extends Part {
  /// The string content.
  final String text;

  const TextPart({String? kind, required this.text, super.metadata})
    : super(kind: kind ?? 'text');

  factory TextPart.fromJson(Map<String, Object?> json) =>
      _$TextPartFromJson(json);

  @override
  Map<String, Object?> toJson() => _$TextPartToJson(this)..['kind'] = kind;

  TextPart copyWith({String? text, Map<String, Object?>? metadata}) {
    return TextPart(
      text: text ?? this.text,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextPart &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          const DeepCollectionEquality().equals(metadata, other.metadata);

  @override
  int get hashCode =>
      Object.hash(text, const DeepCollectionEquality().hash(metadata));

  @override
  String toString() => 'TextPart(text: $text, metadata: $metadata)';
}

/// Represents a file content part.
@JsonSerializable()
class FilePart extends Part {
  /// The file details, specifying the file's location (URI) or content
  /// (bytes).
  final FileType file;

  const FilePart({String? kind, required this.file, super.metadata})
    : super(kind: kind ?? 'file');

  factory FilePart.fromJson(Map<String, Object?> json) =>
      _$FilePartFromJson(json);

  @override
  Map<String, Object?> toJson() => _$FilePartToJson(this)..['kind'] = kind;

  FilePart copyWith({FileType? file, Map<String, Object?>? metadata}) {
    return FilePart(
      file: file ?? this.file,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilePart &&
          runtimeType == other.runtimeType &&
          file == other.file &&
          const DeepCollectionEquality().equals(metadata, other.metadata);

  @override
  int get hashCode =>
      Object.hash(file, const DeepCollectionEquality().hash(metadata));

  @override
  String toString() => 'FilePart(file: $file, metadata: $metadata)';
}

/// Represents a structured JSON data content part.
@JsonSerializable()
class DataPart extends Part {
  /// The structured data, represented as a map.
  final Map<String, Object?> data;

  const DataPart({String? kind, required this.data, super.metadata})
    : super(kind: kind ?? 'data');

  factory DataPart.fromJson(Map<String, Object?> json) =>
      _$DataPartFromJson(json);

  @override
  Map<String, Object?> toJson() => _$DataPartToJson(this)..['kind'] = kind;

  DataPart copyWith({
    Map<String, Object?>? data,
    Map<String, Object?>? metadata,
  }) {
    return DataPart(
      data: data ?? this.data,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPart &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(data, other.data) &&
          const DeepCollectionEquality().equals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
    const DeepCollectionEquality().hash(data),
    const DeepCollectionEquality().hash(metadata),
  );

  @override
  String toString() => 'DataPart(data: $data, metadata: $metadata)';
}

/// Represents file data, used within a [FilePart].
///
/// The file content can be provided either as a URI pointing to the file or
/// directly as base64-encoded bytes.
sealed class FileType {
  /// The type discriminator.
  final String type;

  const FileType({required this.type});

  /// Deserializes a [FileType] instance from a JSON object.
  factory FileType.fromJson(Map<String, Object?> json) {
    Map<String, Object?> processedJson = Map.from(json);
    if (!processedJson.containsKey('type')) {
      if (processedJson.containsKey('bytes')) {
        processedJson['type'] = 'bytes';
      } else if (processedJson.containsKey('uri')) {
        processedJson['type'] = 'uri';
      }
    }

    final type = processedJson['type'] as String?;
    switch (type) {
      case 'uri':
        return FileWithUri.fromJson(processedJson);
      case 'bytes':
        return FileWithBytes.fromJson(processedJson);
      default:
        throw ArgumentError('Unknown FileType type: $type');
    }
  }

  /// Represents a file located at a specific URI.
  const factory FileType.uri({
    String? type,
    required String uri,
    String? name,
    String? mimeType,
  }) = FileWithUri;

  /// Represents a file with its content embedded as a base64-encoded string.
  const factory FileType.bytes({
    String? type,
    required String bytes,
    String? name,
    String? mimeType,
  }) = FileWithBytes;

  /// Creates a JSON object from a [FileType].
  Map<String, Object?> toJson();
}

/// Represents a file located at a specific URI.
@JsonSerializable()
class FileWithUri extends FileType {
  /// The Uniform Resource Identifier (URI) pointing to the file's content.
  final String uri;

  /// An optional name for the file (e.g., "document.pdf").
  final String? name;

  /// The MIME type of the file (e.g., "application/pdf"), if known.
  final String? mimeType;

  const FileWithUri({String? type, required this.uri, this.name, this.mimeType})
    : super(type: type ?? 'uri');

  factory FileWithUri.fromJson(Map<String, Object?> json) =>
      _$FileWithUriFromJson(json);

  @override
  Map<String, Object?> toJson() => _$FileWithUriToJson(this)..['type'] = type;

  FileWithUri copyWith({String? uri, String? name, String? mimeType}) {
    return FileWithUri(
      uri: uri ?? this.uri,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileWithUri &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          name == other.name &&
          mimeType == other.mimeType;

  @override
  int get hashCode => Object.hash(uri, name, mimeType);

  @override
  String toString() =>
      'FileWithUri(uri: $uri, name: $name, mimeType: $mimeType)';
}

/// Represents a file with its content embedded as a base64-encoded string.
@JsonSerializable()
class FileWithBytes extends FileType {
  /// The base64-encoded binary content of the file.
  final String bytes;

  /// An optional name for the file (e.g., "image.png").
  final String? name;

  /// The MIME type of the file (e.g., "image/png"), if known.
  final String? mimeType;

  const FileWithBytes({
    String? type,
    required this.bytes,
    this.name,
    this.mimeType,
  }) : super(type: type ?? 'bytes');

  factory FileWithBytes.fromJson(Map<String, Object?> json) =>
      _$FileWithBytesFromJson(json);

  @override
  Map<String, Object?> toJson() => _$FileWithBytesToJson(this)..['type'] = type;

  FileWithBytes copyWith({String? bytes, String? name, String? mimeType}) {
    return FileWithBytes(
      bytes: bytes ?? this.bytes,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileWithBytes &&
          runtimeType == other.runtimeType &&
          bytes == other.bytes &&
          name == other.name &&
          mimeType == other.mimeType;

  @override
  int get hashCode => Object.hash(bytes, name, mimeType);

  @override
  String toString() =>
      'FileWithBytes(bytes: $bytes, name: $name, mimeType: $mimeType)';
}
