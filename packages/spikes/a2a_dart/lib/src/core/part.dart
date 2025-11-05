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
    required FileWithUri file,
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

/// Represents a file with its content located at a specific URI.
///
/// This class is used in [FilePart] to specify a file that is part of a
/// [Message].
@freezed
abstract class FileWithUri with _$FileWithUri {
  /// Creates a [FileWithUri].
  const factory FileWithUri({
    /// A URL pointing to the file's content.
    required String uri,

    /// An optional name for the file (e.g., "document.pdf").
    String? name,

    /// The MIME type of the file (e.g., "application/pdf").
    String? mimeType,
  }) = _FileWithUri;

  /// Creates a [FileWithUri] from a JSON object.
  factory FileWithUri.fromJson(Map<String, dynamic> json) =>
      _$FileWithUriFromJson(json);
}
