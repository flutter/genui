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
Part _$PartFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'text':
      return TextPart.fromJson(json);
    case 'file':
      return FilePart.fromJson(json);
    case 'data':
      return DataPart.fromJson(json);

    default:
      throw CheckedFromJsonException(
          json, 'kind', 'Part', 'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$Part {
  String get kind;
  Map<String, dynamic>? get metadata;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PartCopyWith<Part> get copyWith =>
      _$PartCopyWithImpl<Part>(this as Part, _$identity);

  /// Serializes this Part to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Part &&
            (identical(other.kind, kind) || other.kind == kind) &&
            const DeepCollectionEquality().equals(other.metadata, metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, kind, const DeepCollectionEquality().hash(metadata));

  @override
  String toString() {
    return 'Part(kind: $kind, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $PartCopyWith<$Res> {
  factory $PartCopyWith(Part value, $Res Function(Part) _then) =
      _$PartCopyWithImpl;
  @useResult
  $Res call({String kind, Map<String, dynamic>? metadata});
}

/// @nodoc
class _$PartCopyWithImpl<$Res> implements $PartCopyWith<$Res> {
  _$PartCopyWithImpl(this._self, this._then);

  final Part _self;
  final $Res Function(Part) _then;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? metadata = freezed,
  }) {
    return _then(_self.copyWith(
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextPart value)? text,
    TResult Function(FilePart value)? file,
    TResult Function(DataPart value)? data,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TextPart() when text != null:
        return text(_that);
      case FilePart() when file != null:
        return file(_that);
      case DataPart() when data != null:
        return data(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextPart value) text,
    required TResult Function(FilePart value) file,
    required TResult Function(DataPart value) data,
  }) {
    final _that = this;
    switch (_that) {
      case TextPart():
        return text(_that);
      case FilePart():
        return file(_that);
      case DataPart():
        return data(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextPart value)? text,
    TResult? Function(FilePart value)? file,
    TResult? Function(DataPart value)? data,
  }) {
    final _that = this;
    switch (_that) {
      case TextPart() when text != null:
        return text(_that);
      case FilePart() when file != null:
        return file(_that);
      case DataPart() when data != null:
        return data(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String kind, String text, Map<String, dynamic>? metadata)?
        text,
    TResult Function(
            String kind, FileWithUri file, Map<String, dynamic>? metadata)?
        file,
    TResult Function(String kind, Map<String, dynamic> data,
            Map<String, dynamic>? metadata)?
        data,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TextPart() when text != null:
        return text(_that.kind, _that.text, _that.metadata);
      case FilePart() when file != null:
        return file(_that.kind, _that.file, _that.metadata);
      case DataPart() when data != null:
        return data(_that.kind, _that.data, _that.metadata);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String kind, String text, Map<String, dynamic>? metadata)
        text,
    required TResult Function(
            String kind, FileWithUri file, Map<String, dynamic>? metadata)
        file,
    required TResult Function(String kind, Map<String, dynamic> data,
            Map<String, dynamic>? metadata)
        data,
  }) {
    final _that = this;
    switch (_that) {
      case TextPart():
        return text(_that.kind, _that.text, _that.metadata);
      case FilePart():
        return file(_that.kind, _that.file, _that.metadata);
      case DataPart():
        return data(_that.kind, _that.data, _that.metadata);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String kind, String text, Map<String, dynamic>? metadata)?
        text,
    TResult? Function(
            String kind, FileWithUri file, Map<String, dynamic>? metadata)?
        file,
    TResult? Function(String kind, Map<String, dynamic> data,
            Map<String, dynamic>? metadata)?
        data,
  }) {
    final _that = this;
    switch (_that) {
      case TextPart() when text != null:
        return text(_that.kind, _that.text, _that.metadata);
      case FilePart() when file != null:
        return file(_that.kind, _that.file, _that.metadata);
      case DataPart() when data != null:
        return data(_that.kind, _that.data, _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class TextPart implements Part {
  const TextPart(
      {this.kind = 'text',
      required this.text,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;
  factory TextPart.fromJson(Map<String, dynamic> json) =>
      _$TextPartFromJson(json);

  @override
  @JsonKey()
  final String kind;
  final String text;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TextPartCopyWith<TextPart> get copyWith =>
      _$TextPartCopyWithImpl<TextPart>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TextPartToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TextPart &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, kind, text, const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'Part.text(kind: $kind, text: $text, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $TextPartCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory $TextPartCopyWith(TextPart value, $Res Function(TextPart) _then) =
      _$TextPartCopyWithImpl;
  @override
  @useResult
  $Res call({String kind, String text, Map<String, dynamic>? metadata});
}

/// @nodoc
class _$TextPartCopyWithImpl<$Res> implements $TextPartCopyWith<$Res> {
  _$TextPartCopyWithImpl(this._self, this._then);

  final TextPart _self;
  final $Res Function(TextPart) _then;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? kind = null,
    Object? text = null,
    Object? metadata = freezed,
  }) {
    return _then(TextPart(
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class FilePart implements Part {
  const FilePart(
      {this.kind = 'file',
      required this.file,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;
  factory FilePart.fromJson(Map<String, dynamic> json) =>
      _$FilePartFromJson(json);

  @override
  @JsonKey()
  final String kind;
  final FileWithUri file;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilePartCopyWith<FilePart> get copyWith =>
      _$FilePartCopyWithImpl<FilePart>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FilePartToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilePart &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.file, file) || other.file == file) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, kind, file, const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'Part.file(kind: $kind, file: $file, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $FilePartCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory $FilePartCopyWith(FilePart value, $Res Function(FilePart) _then) =
      _$FilePartCopyWithImpl;
  @override
  @useResult
  $Res call({String kind, FileWithUri file, Map<String, dynamic>? metadata});

  $FileWithUriCopyWith<$Res> get file;
}

/// @nodoc
class _$FilePartCopyWithImpl<$Res> implements $FilePartCopyWith<$Res> {
  _$FilePartCopyWithImpl(this._self, this._then);

  final FilePart _self;
  final $Res Function(FilePart) _then;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? kind = null,
    Object? file = null,
    Object? metadata = freezed,
  }) {
    return _then(FilePart(
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      file: null == file
          ? _self.file
          : file // ignore: cast_nullable_to_non_nullable
              as FileWithUri,
      metadata: freezed == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FileWithUriCopyWith<$Res> get file {
    return $FileWithUriCopyWith<$Res>(_self.file, (value) {
      return _then(_self.copyWith(file: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class DataPart implements Part {
  const DataPart(
      {this.kind = 'data',
      required final Map<String, dynamic> data,
      final Map<String, dynamic>? metadata})
      : _data = data,
        _metadata = metadata;
  factory DataPart.fromJson(Map<String, dynamic> json) =>
      _$DataPartFromJson(json);

  @override
  @JsonKey()
  final String kind;
  final Map<String, dynamic> _data;
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DataPartCopyWith<DataPart> get copyWith =>
      _$DataPartCopyWithImpl<DataPart>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DataPartToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DataPart &&
            (identical(other.kind, kind) || other.kind == kind) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      kind,
      const DeepCollectionEquality().hash(_data),
      const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'Part.data(kind: $kind, data: $data, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $DataPartCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory $DataPartCopyWith(DataPart value, $Res Function(DataPart) _then) =
      _$DataPartCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String kind, Map<String, dynamic> data, Map<String, dynamic>? metadata});
}

/// @nodoc
class _$DataPartCopyWithImpl<$Res> implements $DataPartCopyWith<$Res> {
  _$DataPartCopyWithImpl(this._self, this._then);

  final DataPart _self;
  final $Res Function(DataPart) _then;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? kind = null,
    Object? data = null,
    Object? metadata = freezed,
  }) {
    return _then(DataPart(
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _self._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      metadata: freezed == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
mixin _$FileWithUri {
  /// A URL pointing to the file's content.
  String get uri;

  /// An optional name for the file (e.g., "document.pdf").
  String? get name;

  /// The MIME type of the file (e.g., "application/pdf").
  String? get mimeType;

  /// Create a copy of FileWithUri
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FileWithUriCopyWith<FileWithUri> get copyWith =>
      _$FileWithUriCopyWithImpl<FileWithUri>(this as FileWithUri, _$identity);

  /// Serializes this FileWithUri to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FileWithUri &&
            (identical(other.uri, uri) || other.uri == uri) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uri, name, mimeType);

  @override
  String toString() {
    return 'FileWithUri(uri: $uri, name: $name, mimeType: $mimeType)';
  }
}

/// @nodoc
abstract mixin class $FileWithUriCopyWith<$Res> {
  factory $FileWithUriCopyWith(
          FileWithUri value, $Res Function(FileWithUri) _then) =
      _$FileWithUriCopyWithImpl;
  @useResult
  $Res call({String uri, String? name, String? mimeType});
}

/// @nodoc
class _$FileWithUriCopyWithImpl<$Res> implements $FileWithUriCopyWith<$Res> {
  _$FileWithUriCopyWithImpl(this._self, this._then);

  final FileWithUri _self;
  final $Res Function(FileWithUri) _then;

  /// Create a copy of FileWithUri
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uri = null,
    Object? name = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(_self.copyWith(
      uri: null == uri
          ? _self.uri
          : uri // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      mimeType: freezed == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FileWithUri].
extension FileWithUriPatterns on FileWithUri {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FileWithUri value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FileWithUri() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FileWithUri value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileWithUri():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FileWithUri value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileWithUri() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String uri, String? name, String? mimeType)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FileWithUri() when $default != null:
        return $default(_that.uri, _that.name, _that.mimeType);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String uri, String? name, String? mimeType) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileWithUri():
        return $default(_that.uri, _that.name, _that.mimeType);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String uri, String? name, String? mimeType)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileWithUri() when $default != null:
        return $default(_that.uri, _that.name, _that.mimeType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FileWithUri implements FileWithUri {
  const _FileWithUri({required this.uri, this.name, this.mimeType});
  factory _FileWithUri.fromJson(Map<String, dynamic> json) =>
      _$FileWithUriFromJson(json);

  /// A URL pointing to the file's content.
  @override
  final String uri;

  /// An optional name for the file (e.g., "document.pdf").
  @override
  final String? name;

  /// The MIME type of the file (e.g., "application/pdf").
  @override
  final String? mimeType;

  /// Create a copy of FileWithUri
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FileWithUriCopyWith<_FileWithUri> get copyWith =>
      __$FileWithUriCopyWithImpl<_FileWithUri>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FileWithUriToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FileWithUri &&
            (identical(other.uri, uri) || other.uri == uri) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uri, name, mimeType);

  @override
  String toString() {
    return 'FileWithUri(uri: $uri, name: $name, mimeType: $mimeType)';
  }
}

/// @nodoc
abstract mixin class _$FileWithUriCopyWith<$Res>
    implements $FileWithUriCopyWith<$Res> {
  factory _$FileWithUriCopyWith(
          _FileWithUri value, $Res Function(_FileWithUri) _then) =
      __$FileWithUriCopyWithImpl;
  @override
  @useResult
  $Res call({String uri, String? name, String? mimeType});
}

/// @nodoc
class __$FileWithUriCopyWithImpl<$Res> implements _$FileWithUriCopyWith<$Res> {
  __$FileWithUriCopyWithImpl(this._self, this._then);

  final _FileWithUri _self;
  final $Res Function(_FileWithUri) _then;

  /// Create a copy of FileWithUri
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? uri = null,
    Object? name = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(_FileWithUri(
      uri: null == uri
          ? _self.uri
          : uri // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      mimeType: freezed == mimeType
          ? _self.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
