// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextPart _$TextPartFromJson(Map<String, dynamic> json) => TextPart(
  kind: json['kind'] as String? ?? 'text',
  text: json['text'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$TextPartToJson(TextPart instance) => <String, dynamic>{
  'kind': instance.kind,
  'text': instance.text,
  'metadata': instance.metadata,
};

FilePart _$FilePartFromJson(Map<String, dynamic> json) => FilePart(
  kind: json['kind'] as String? ?? 'file',
  file: FileWithUri.fromJson(json['file'] as Map<String, dynamic>),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$FilePartToJson(FilePart instance) => <String, dynamic>{
  'kind': instance.kind,
  'file': instance.file.toJson(),
  'metadata': instance.metadata,
};

DataPart _$DataPartFromJson(Map<String, dynamic> json) => DataPart(
  kind: json['kind'] as String? ?? 'data',
  data: json['data'] as Map<String, dynamic>,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$DataPartToJson(DataPart instance) => <String, dynamic>{
  'kind': instance.kind,
  'data': instance.data,
  'metadata': instance.metadata,
};

_FileWithUri _$FileWithUriFromJson(Map<String, dynamic> json) => _FileWithUri(
  uri: json['uri'] as String,
  name: json['name'] as String?,
  mimeType: json['mimeType'] as String?,
);

Map<String, dynamic> _$FileWithUriToJson(_FileWithUri instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'name': instance.name,
      'mimeType': instance.mimeType,
    };
