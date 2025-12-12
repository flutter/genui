// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'part.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Part _$PartFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'text':
          return TextPart.fromJson(
            json
          );
                case 'file':
          return FilePart.fromJson(
            json
          );
                case 'data':
          return DataPart.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'Part',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$Part {

/// The type discriminator, always 'text'.
 String get kind;/// Optional metadata associated with this text part.
 Map<String, Object?>? get metadata;
/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartCopyWith<Part> get copyWith => _$PartCopyWithImpl<Part>(this as Part, _$identity);

  /// Serializes this Part to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Part&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'Part(kind: $kind, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $PartCopyWith<$Res>  {
  factory $PartCopyWith(Part value, $Res Function(Part) _then) = _$PartCopyWithImpl;
@useResult
$Res call({
 String kind, Map<String, Object?>? metadata
});




}
/// @nodoc
class _$PartCopyWithImpl<$Res>
    implements $PartCopyWith<$Res> {
  _$PartCopyWithImpl(this._self, this._then);

  final Part _self;
  final $Res Function(Part) _then;

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Part].
extension PartPatterns on Part {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextPart value)?  text,TResult Function( FilePart value)?  file,TResult Function( DataPart value)?  data,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that);case FilePart() when file != null:
return file(_that);case DataPart() when data != null:
return data(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextPart value)  text,required TResult Function( FilePart value)  file,required TResult Function( DataPart value)  data,}){
final _that = this;
switch (_that) {
case TextPart():
return text(_that);case FilePart():
return file(_that);case DataPart():
return data(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextPart value)?  text,TResult? Function( FilePart value)?  file,TResult? Function( DataPart value)?  data,}){
final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that);case FilePart() when file != null:
return file(_that);case DataPart() when data != null:
return data(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String kind,  String text,  Map<String, Object?>? metadata)?  text,TResult Function( String kind,  FileType file,  Map<String, Object?>? metadata)?  file,TResult Function( String kind,  Map<String, Object?> data,  Map<String, Object?>? metadata)?  data,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that.kind,_that.text,_that.metadata);case FilePart() when file != null:
return file(_that.kind,_that.file,_that.metadata);case DataPart() when data != null:
return data(_that.kind,_that.data,_that.metadata);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String kind,  String text,  Map<String, Object?>? metadata)  text,required TResult Function( String kind,  FileType file,  Map<String, Object?>? metadata)  file,required TResult Function( String kind,  Map<String, Object?> data,  Map<String, Object?>? metadata)  data,}) {final _that = this;
switch (_that) {
case TextPart():
return text(_that.kind,_that.text,_that.metadata);case FilePart():
return file(_that.kind,_that.file,_that.metadata);case DataPart():
return data(_that.kind,_that.data,_that.metadata);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String kind,  String text,  Map<String, Object?>? metadata)?  text,TResult? Function( String kind,  FileType file,  Map<String, Object?>? metadata)?  file,TResult? Function( String kind,  Map<String, Object?> data,  Map<String, Object?>? metadata)?  data,}) {final _that = this;
switch (_that) {
case TextPart() when text != null:
return text(_that.kind,_that.text,_that.metadata);case FilePart() when file != null:
return file(_that.kind,_that.file,_that.metadata);case DataPart() when data != null:
return data(_that.kind,_that.data,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TextPart implements Part {
  const TextPart({this.kind = 'text', required this.text, final  Map<String, Object?>? metadata}): _metadata = metadata;
  factory TextPart.fromJson(Map<String, dynamic> json) => _$TextPartFromJson(json);

/// The type discriminator, always 'text'.
@override@JsonKey() final  String kind;
/// The string content.
 final  String text;
/// Optional metadata associated with this text part.
 final  Map<String, Object?>? _metadata;
/// Optional metadata associated with this text part.
@override Map<String, Object?>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextPartCopyWith<TextPart> get copyWith => _$TextPartCopyWithImpl<TextPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextPartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextPart&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,text,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'Part.text(kind: $kind, text: $text, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $TextPartCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory $TextPartCopyWith(TextPart value, $Res Function(TextPart) _then) = _$TextPartCopyWithImpl;
@override @useResult
$Res call({
 String kind, String text, Map<String, Object?>? metadata
});




}
/// @nodoc
class _$TextPartCopyWithImpl<$Res>
    implements $TextPartCopyWith<$Res> {
  _$TextPartCopyWithImpl(this._self, this._then);

  final TextPart _self;
  final $Res Function(TextPart) _then;

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? text = null,Object? metadata = freezed,}) {
  return _then(TextPart(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class FilePart implements Part {
  const FilePart({this.kind = 'file', required this.file, final  Map<String, Object?>? metadata}): _metadata = metadata;
  factory FilePart.fromJson(Map<String, dynamic> json) => _$FilePartFromJson(json);

/// The type discriminator, always 'file'.
@override@JsonKey() final  String kind;
/// The file details, specifying the file's location (URI) or content
/// (bytes).
 final  FileType file;
/// Optional metadata associated with this file part.
 final  Map<String, Object?>? _metadata;
/// Optional metadata associated with this file part.
@override Map<String, Object?>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilePartCopyWith<FilePart> get copyWith => _$FilePartCopyWithImpl<FilePart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FilePartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilePart&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.file, file) || other.file == file)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,file,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'Part.file(kind: $kind, file: $file, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $FilePartCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory $FilePartCopyWith(FilePart value, $Res Function(FilePart) _then) = _$FilePartCopyWithImpl;
@override @useResult
$Res call({
 String kind, FileType file, Map<String, Object?>? metadata
});


$FileTypeCopyWith<$Res> get file;

}
/// @nodoc
class _$FilePartCopyWithImpl<$Res>
    implements $FilePartCopyWith<$Res> {
  _$FilePartCopyWithImpl(this._self, this._then);

  final FilePart _self;
  final $Res Function(FilePart) _then;

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? file = null,Object? metadata = freezed,}) {
  return _then(FilePart(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as FileType,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FileTypeCopyWith<$Res> get file {
  
  return $FileTypeCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class DataPart implements Part {
  const DataPart({this.kind = 'data', required final  Map<String, Object?> data, final  Map<String, Object?>? metadata}): _data = data,_metadata = metadata;
  factory DataPart.fromJson(Map<String, dynamic> json) => _$DataPartFromJson(json);

/// The type discriminator, always 'data'.
@override@JsonKey() final  String kind;
/// The structured data, represented as a map.
 final  Map<String, Object?> _data;
/// The structured data, represented as a map.
 Map<String, Object?> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

/// Optional metadata associated with this data part.
 final  Map<String, Object?>? _metadata;
/// Optional metadata associated with this data part.
@override Map<String, Object?>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataPartCopyWith<DataPart> get copyWith => _$DataPartCopyWithImpl<DataPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DataPartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataPart&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._data, _data)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_data),const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'Part.data(kind: $kind, data: $data, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $DataPartCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory $DataPartCopyWith(DataPart value, $Res Function(DataPart) _then) = _$DataPartCopyWithImpl;
@override @useResult
$Res call({
 String kind, Map<String, Object?> data, Map<String, Object?>? metadata
});




}
/// @nodoc
class _$DataPartCopyWithImpl<$Res>
    implements $DataPartCopyWith<$Res> {
  _$DataPartCopyWithImpl(this._self, this._then);

  final DataPart _self;
  final $Res Function(DataPart) _then;

/// Create a copy of Part
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? data = null,Object? metadata = freezed,}) {
  return _then(DataPart(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

FileType _$FileTypeFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'uri':
          return FileWithUri.fromJson(
            json
          );
                case 'bytes':
          return FileWithBytes.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'FileType',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$FileType {

/// An optional name for the file (e.g., "document.pdf").
 String? get name;/// The MIME type of the file (e.g., "application/pdf"), if known.
 String? get mimeType;
/// Create a copy of FileType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileTypeCopyWith<FileType> get copyWith => _$FileTypeCopyWithImpl<FileType>(this as FileType, _$identity);

  /// Serializes this FileType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileType&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,mimeType);

@override
String toString() {
  return 'FileType(name: $name, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $FileTypeCopyWith<$Res>  {
  factory $FileTypeCopyWith(FileType value, $Res Function(FileType) _then) = _$FileTypeCopyWithImpl;
@useResult
$Res call({
 String? name, String? mimeType
});




}
/// @nodoc
class _$FileTypeCopyWithImpl<$Res>
    implements $FileTypeCopyWith<$Res> {
  _$FileTypeCopyWithImpl(this._self, this._then);

  final FileType _self;
  final $Res Function(FileType) _then;

/// Create a copy of FileType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? mimeType = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileType].
extension FileTypePatterns on FileType {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FileWithUri value)?  uri,TResult Function( FileWithBytes value)?  bytes,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FileWithUri() when uri != null:
return uri(_that);case FileWithBytes() when bytes != null:
return bytes(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FileWithUri value)  uri,required TResult Function( FileWithBytes value)  bytes,}){
final _that = this;
switch (_that) {
case FileWithUri():
return uri(_that);case FileWithBytes():
return bytes(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FileWithUri value)?  uri,TResult? Function( FileWithBytes value)?  bytes,}){
final _that = this;
switch (_that) {
case FileWithUri() when uri != null:
return uri(_that);case FileWithBytes() when bytes != null:
return bytes(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String uri,  String? name,  String? mimeType)?  uri,TResult Function( String bytes,  String? name,  String? mimeType)?  bytes,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FileWithUri() when uri != null:
return uri(_that.uri,_that.name,_that.mimeType);case FileWithBytes() when bytes != null:
return bytes(_that.bytes,_that.name,_that.mimeType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String uri,  String? name,  String? mimeType)  uri,required TResult Function( String bytes,  String? name,  String? mimeType)  bytes,}) {final _that = this;
switch (_that) {
case FileWithUri():
return uri(_that.uri,_that.name,_that.mimeType);case FileWithBytes():
return bytes(_that.bytes,_that.name,_that.mimeType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String uri,  String? name,  String? mimeType)?  uri,TResult? Function( String bytes,  String? name,  String? mimeType)?  bytes,}) {final _that = this;
switch (_that) {
case FileWithUri() when uri != null:
return uri(_that.uri,_that.name,_that.mimeType);case FileWithBytes() when bytes != null:
return bytes(_that.bytes,_that.name,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class FileWithUri implements FileType {
  const FileWithUri({required this.uri, this.name, this.mimeType, final  String? $type}): $type = $type ?? 'uri';
  factory FileWithUri.fromJson(Map<String, dynamic> json) => _$FileWithUriFromJson(json);

/// The Uniform Resource Identifier (URI) pointing to the file's content.
 final  String uri;
/// An optional name for the file (e.g., "document.pdf").
@override final  String? name;
/// The MIME type of the file (e.g., "application/pdf"), if known.
@override final  String? mimeType;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of FileType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileWithUriCopyWith<FileWithUri> get copyWith => _$FileWithUriCopyWithImpl<FileWithUri>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileWithUriToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileWithUri&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uri,name,mimeType);

@override
String toString() {
  return 'FileType.uri(uri: $uri, name: $name, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $FileWithUriCopyWith<$Res> implements $FileTypeCopyWith<$Res> {
  factory $FileWithUriCopyWith(FileWithUri value, $Res Function(FileWithUri) _then) = _$FileWithUriCopyWithImpl;
@override @useResult
$Res call({
 String uri, String? name, String? mimeType
});




}
/// @nodoc
class _$FileWithUriCopyWithImpl<$Res>
    implements $FileWithUriCopyWith<$Res> {
  _$FileWithUriCopyWithImpl(this._self, this._then);

  final FileWithUri _self;
  final $Res Function(FileWithUri) _then;

/// Create a copy of FileType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? name = freezed,Object? mimeType = freezed,}) {
  return _then(FileWithUri(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class FileWithBytes implements FileType {
  const FileWithBytes({required this.bytes, this.name, this.mimeType, final  String? $type}): $type = $type ?? 'bytes';
  factory FileWithBytes.fromJson(Map<String, dynamic> json) => _$FileWithBytesFromJson(json);

/// The base64-encoded binary content of the file.
 final  String bytes;
/// An optional name for the file (e.g., "image.png").
@override final  String? name;
/// The MIME type of the file (e.g., "image/png"), if known.
@override final  String? mimeType;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of FileType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileWithBytesCopyWith<FileWithBytes> get copyWith => _$FileWithBytesCopyWithImpl<FileWithBytes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileWithBytesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileWithBytes&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bytes,name,mimeType);

@override
String toString() {
  return 'FileType.bytes(bytes: $bytes, name: $name, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $FileWithBytesCopyWith<$Res> implements $FileTypeCopyWith<$Res> {
  factory $FileWithBytesCopyWith(FileWithBytes value, $Res Function(FileWithBytes) _then) = _$FileWithBytesCopyWithImpl;
@override @useResult
$Res call({
 String bytes, String? name, String? mimeType
});




}
/// @nodoc
class _$FileWithBytesCopyWithImpl<$Res>
    implements $FileWithBytesCopyWith<$Res> {
  _$FileWithBytesCopyWithImpl(this._self, this._then);

  final FileWithBytes _self;
  final $Res Function(FileWithBytes) _then;

/// Create a copy of FileType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bytes = null,Object? name = freezed,Object? mimeType = freezed,}) {
  return _then(FileWithBytes(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
