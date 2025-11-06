// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextPart _$TextPartFromJson(Map<String, Object?> json) => TextPart(
      kind: json['kind'] as String? ?? 'text',
      text: json['text'] as String,
  metadata: json['metadata'] as Map<String, Object?>?,
    );

Map<String, Object?> _$TextPartToJson(TextPart instance) => <String, Object?>{
      'kind': instance.kind,
      'text': instance.text,
      'metadata': instance.metadata,
    };

FilePart _$FilePartFromJson(Map<String, Object?> json) => FilePart(
      kind: json['kind'] as String? ?? 'file',
  file: FileType.fromJson(json['file'] as Map<String, Object?>),
  metadata: json['metadata'] as Map<String, Object?>?,
    );

Map<String, Object?> _$FilePartToJson(FilePart instance) => <String, Object?>{
      'kind': instance.kind,
      'file': instance.file.toJson(),
      'metadata': instance.metadata,
    };

DataPart _$DataPartFromJson(Map<String, Object?> json) => DataPart(
      kind: json['kind'] as String? ?? 'data',
  data: json['data'] as Map<String, Object?>,
  metadata: json['metadata'] as Map<String, Object?>?,
    );

Map<String, Object?> _$DataPartToJson(DataPart instance) => <String, Object?>{
      'kind': instance.kind,
      'data': instance.data,
      'metadata': instance.metadata,
    };

FileWithUri _$FileWithUriFromJson(Map<String, Object?> json) => FileWithUri(
      uri: json['uri'] as String,
      name: json['name'] as String?,
      mimeType: json['mimeType'] as String?,
      $type: json['type'] as String?,
    );

Map<String, Object?> _$FileWithUriToJson(FileWithUri instance) =>
    <String, Object?>{
      'uri': instance.uri,
      'name': instance.name,
      'mimeType': instance.mimeType,
      'type': instance.$type,
    };

FileWithBytes _$FileWithBytesFromJson(Map<String, Object?> json) =>
    FileWithBytes(
      bytes: json['bytes'] as String,
      name: json['name'] as String?,
      mimeType: json['mimeType'] as String?,
      $type: json['type'] as String?,
    );

Map<String, Object?> _$FileWithBytesToJson(FileWithBytes instance) =>
    <String, Object?>{
      'bytes': instance.bytes,
      'name': instance.name,
      'mimeType': instance.mimeType,
      'type': instance.$type,
    };
