// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'part.freezed.dart';
part 'part.g.dart';

/// A discriminated union representing a part of a [Message].
///
/// A message can be composed of multiple parts, which can be text, a file, or
/// structured data. The `kind` field is used as a discriminator to determine the
/// type of the part.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
abstract class Part with _$Part {
  /// A text part of a message.
  const factory Part.text({
    /// The type of this part, always 'text'.
    @Default('text') String kind,

    /// The text content.
    required String text,

    /// Optional metadata for the part.
    Map<String, dynamic>? metadata,
  }) = TextPart;

  /// A file part of a message.
  const factory Part.file({
    /// The type of this part, always 'file'.
    @Default('file') String kind,

    /// The file to be included in the message.
    required FileType file,

    /// Optional metadata for the part.
    Map<String, dynamic>? metadata,
  }) = FilePart;

  /// A structured data part of a message.
  const factory Part.data({
    /// The type of this part, always 'data'.
    @Default('data') String kind,

    /// The structured data, represented as a JSON object.
    required Map<String, dynamic> data,

    /// Optional metadata for the part.
    Map<String, dynamic>? metadata,
  }) = DataPart;

  /// Creates a [Part] from a JSON object.
  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);
}

/// Represents a file with its content located at a specific URI or bytes.
///
/// This class is used in [FilePart] to specify a file that is part of a
/// [Message].
@Freezed(unionKey: 'type')
abstract class FileType with _$FileType {
  /// A file represented by a URI.
  const factory FileType.uri({
    /// A URL pointing to the file's content.
    required String uri,

    /// An optional name for the file (e.g., "document.pdf").
    String? name,

    /// The MIME type of the file (e.g., "application/pdf").
    String? mimeType,
  }) = FileWithUri;

  /// A file represented by its raw bytes.
  const factory FileType.bytes({
    /// The base64-encoded content of the file.
    required String bytes,

    /// An optional name for the file (e.g., "document.pdf").
    String? name,

    /// The MIME type of the file (e.g., "application/pdf").
    String? mimeType,
  }) = FileWithBytes;

  /// Creates a [FileType] from a JSON object.
  factory FileType.fromJson(Map<String, dynamic> json) =>
      _$FileTypeFromJson(json);
}
