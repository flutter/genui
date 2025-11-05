import 'package:freezed_annotation/freezed_annotation.dart';

part 'part.freezed.dart';

part 'part.g.dart';

/// A discriminated union representing a part of a message or artifact, which can
/// be text, a file, or structured data.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
abstract class Part with _$Part {
  const factory Part.text({
    @Default('text') String kind,
    required String text,
    Map<String, dynamic>? metadata,
  }) = TextPart;

  const factory Part.file({
    @Default('file') String kind,
    required FileWithUri file,
    Map<String, dynamic>? metadata,
  }) = FilePart;

  const factory Part.data({
    @Default('data') String kind,
    required Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  }) = DataPart;

  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);
}

/// Represents a file with its content located at a specific URI.
@freezed
abstract class FileWithUri with _$FileWithUri {
  const factory FileWithUri({
    /// A URL pointing to the file's content.
    required String uri,

    /// An optional name for the file (e.g., "document.pdf").
    String? name,

    /// The MIME type of the file (e.g., "application/pdf").
    String? mimeType,
  }) = _FileWithUri;

  factory FileWithUri.fromJson(Map<String, dynamic> json) =>
      _$FileWithUriFromJson(json);
}
