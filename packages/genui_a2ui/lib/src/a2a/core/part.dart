// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'message.dart';
library;

// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'part.freezed.dart';
part 'part.g.dart';

/// Represents a distinct piece of content within a [Message] or Artifact.
///
/// A [Part] can be text, a file reference, or structured data. The `kind` field
/// acts as a discriminator to determine the specific type of the content part.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
abstract class Part with _$Part {
  /// Represents a plain text content part.
  const factory Part.text({
    /// The type discriminator, always 'text'.
    @Default('text') String kind,

    /// The string content.
    required String text,

    /// Optional metadata associated with this text part.
    Map<String, Object?>? metadata,
  }) = TextPart;

  /// Represents a file content part.
  const factory Part.file({
    /// The type discriminator, always 'file'.
    @Default('file') String kind,

    /// The file details, specifying the file's location (URI) or content
    /// (bytes).
    required FileType file,

    /// Optional metadata associated with this file part.
    Map<String, Object?>? metadata,
  }) = FilePart;

  /// Represents a structured JSON data content part.
  const factory Part.data({
    /// The type discriminator, always 'data'.
    @Default('data') String kind,

    /// The structured data, represented as a map.
    required Map<String, Object?> data,

    /// Optional metadata associated with this data part.
    Map<String, Object?>? metadata,
  }) = DataPart;

  /// Deserializes a [Part] instance from a JSON object.
  factory Part.fromJson(Map<String, Object?> json) => _$PartFromJson(json);
}

/// Represents file data, used within a [FilePart].
///
/// The file content can be provided either as a URI pointing to the file or
/// directly as base64-encoded bytes.
@Freezed(unionKey: 'type')
abstract class FileType with _$FileType {
  /// Represents a file located at a specific URI.
  const factory FileType.uri({
    /// The Uniform Resource Identifier (URI) pointing to the file's content.
    required String uri,

    /// An optional name for the file (e.g., "document.pdf").
    String? name,

    /// The MIME type of the file (e.g., "application/pdf"), if known.
    String? mimeType,
  }) = FileWithUri;

  /// Represents a file with its content embedded as a base64-encoded string.
  const factory FileType.bytes({
    /// The base64-encoded binary content of the file.
    required String bytes,

    /// An optional name for the file (e.g., "image.png").
    String? name,

    /// The MIME type of the file (e.g., "image/png"), if known.
    String? mimeType,
  }) = FileWithBytes;

  /// Deserializes a [FileType] instance from a JSON object.
  factory FileType.fromJson(Map<String, Object?> json) {
    if (!json.containsKey('type')) {
      if (json.containsKey('bytes')) {
        json = <String, Object?>{...json, 'type': 'bytes'};
      } else if (json.containsKey('uri')) {
        json = <String, Object?>{...json, 'type': 'uri'};
      }
    }
    return _$FileTypeFromJson(json);
  }
}
