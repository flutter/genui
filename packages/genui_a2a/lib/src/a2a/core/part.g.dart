// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: specify_nonobvious_property_types, duplicate_ignore, strict_raw_type, lines_longer_than_80_chars

part of 'part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextPart _$TextPartFromJson(Map<String, dynamic> json) => TextPart(
  kind: json['kind'] as String?,
  text: json['text'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$TextPartToJson(TextPart instance) => <String, dynamic>{
  'kind': instance.kind,
  'metadata': instance.metadata,
  'text': instance.text,
};

FilePart _$FilePartFromJson(Map<String, dynamic> json) => FilePart(
  kind: json['kind'] as String?,
  file: FileType.fromJson(json['file'] as Map<String, dynamic>),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$FilePartToJson(FilePart instance) => <String, dynamic>{
  'kind': instance.kind,
  'metadata': instance.metadata,
  'file': instance.file.toJson(),
};

DataPart _$DataPartFromJson(Map<String, dynamic> json) => DataPart(
  kind: json['kind'] as String?,
  data: json['data'] as Map<String, dynamic>,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$DataPartToJson(DataPart instance) => <String, dynamic>{
  'kind': instance.kind,
  'metadata': instance.metadata,
  'data': instance.data,
};

FileWithUri _$FileWithUriFromJson(Map<String, dynamic> json) => FileWithUri(
  type: json['type'] as String?,
  uri: json['uri'] as String,
  name: json['name'] as String?,
  mimeType: json['mimeType'] as String?,
);

Map<String, dynamic> _$FileWithUriToJson(FileWithUri instance) =>
    <String, dynamic>{
      'type': instance.type,
      'uri': instance.uri,
      'name': instance.name,
      'mimeType': instance.mimeType,
    };

FileWithBytes _$FileWithBytesFromJson(Map<String, dynamic> json) =>
    FileWithBytes(
      type: json['type'] as String?,
      bytes: json['bytes'] as String,
      name: json['name'] as String?,
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$FileWithBytesToJson(FileWithBytes instance) =>
    <String, dynamic>{
      'type': instance.type,
      'bytes': instance.bytes,
      'name': instance.name,
      'mimeType': instance.mimeType,
    };
