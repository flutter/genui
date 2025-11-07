// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'message.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'part.freezed.dart';
part 'part.g.dart';

/// A discriminated union representing a distinct piece of content within a
/// [Message] or `Artifact`.
///
/// A `Part` can be text, a file, or structured data. The `kind` field is used
/// as a discriminator to determine the type of the part.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
abstract class Part with _$Part {
  /// For conveying plain textual content.
  const factory Part.text({
    /// The type of this part.
    @Default('text') String kind,

    /// The string content of the text part.
    required String text,

    /// Optional metadata associated with this part.
    Map<String, Object?>? metadata,
  }) = TextPart;

  /// For conveying file-based content.
  const factory Part.file({
    /// The type of this part.
    @Default('file') String kind,

    /// The file content, represented as either a URI or as base64-encoded bytes.
    required FileType file,

    /// Optional metadata associated with this part.
    Map<String, Object?>? metadata,
  }) = FilePart;

  /// For conveying structured JSON data.
  const factory Part.data({
    /// The type of this part.
    @Default('data') String kind,

    /// The structured data content.
    required Map<String, Object?> data,

    /// Optional metadata associated with this part.
    Map<String, Object?>? metadata,
  }) = DataPart;

  /// Creates a [Part] from a JSON object.
  factory Part.fromJson(Map<String, Object?> json) => _$PartFromJson(json);
}

/// Represents a file, used within a [FilePart].
///
/// The file content can be provided either directly as bytes or as a URI.
@Freezed(unionKey: 'type')
abstract class FileType with _$FileType {
  /// Represents a file with its content located at a specific URI.
  const factory FileType.uri({
    /// A URL pointing to the file's content.
    required String uri,

    /// An optional name for the file (e.g., "document.pdf").
    String? name,

    /// The MIME type of the file (e.g., "application/pdf").
    String? mimeType,
  }) = FileWithUri;

  /// Represents a file with its content provided directly as a base64-encoded
  /// string.
  const factory FileType.bytes({
    /// The base64-encoded content of the file.
    required String bytes,

    /// An optional name for the file (e.g., "document.pdf").
    String? name,

    /// The MIME type of the file (e.g., "application/pdf").
    String? mimeType,
  }) = FileWithBytes;

  /// Creates a [FileType] from a JSON object.
  factory FileType.fromJson(Map<String, Object?> json) =>
      _$FileTypeFromJson(json);
}
