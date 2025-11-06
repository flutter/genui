// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'a2a_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
A2AException _$A2AExceptionFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'jsonRpc':
      return A2AJsonRpcException.fromJson(json);
    case 'parsing':
      return A2AParsingException.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'A2AException',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$A2AException {
  /// The JSON-RPC error message.
  String get message;

  /// Create a copy of A2AException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $A2AExceptionCopyWith<A2AException> get copyWith =>
      _$A2AExceptionCopyWithImpl<A2AException>(
          this as A2AException, _$identity);

  /// Serializes this A2AException to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is A2AException &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'A2AException(message: $message)';
  }
}

/// @nodoc
abstract mixin class $A2AExceptionCopyWith<$Res> {
  factory $A2AExceptionCopyWith(
          A2AException value, $Res Function(A2AException) _then) =
      _$A2AExceptionCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$A2AExceptionCopyWithImpl<$Res> implements $A2AExceptionCopyWith<$Res> {
  _$A2AExceptionCopyWithImpl(this._self, this._then);

  final A2AException _self;
  final $Res Function(A2AException) _then;

  /// Create a copy of A2AException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_self.copyWith(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [A2AException].
extension A2AExceptionPatterns on A2AException {
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
    TResult Function(A2AJsonRpcException value)? jsonRpc,
    TResult Function(A2AParsingException value)? parsing,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case A2AJsonRpcException() when jsonRpc != null:
        return jsonRpc(_that);
      case A2AParsingException() when parsing != null:
        return parsing(_that);
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
    required TResult Function(A2AJsonRpcException value) jsonRpc,
    required TResult Function(A2AParsingException value) parsing,
  }) {
    final _that = this;
    switch (_that) {
      case A2AJsonRpcException():
        return jsonRpc(_that);
      case A2AParsingException():
        return parsing(_that);
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
    TResult? Function(A2AJsonRpcException value)? jsonRpc,
    TResult? Function(A2AParsingException value)? parsing,
  }) {
    final _that = this;
    switch (_that) {
      case A2AJsonRpcException() when jsonRpc != null:
        return jsonRpc(_that);
      case A2AParsingException() when parsing != null:
        return parsing(_that);
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
    TResult Function(int code, String message, Map<String, dynamic>? data)?
        jsonRpc,
    TResult Function(String message)? parsing,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case A2AJsonRpcException() when jsonRpc != null:
        return jsonRpc(_that.code, _that.message, _that.data);
      case A2AParsingException() when parsing != null:
        return parsing(_that.message);
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
            int code, String message, Map<String, dynamic>? data)
        jsonRpc,
    required TResult Function(String message) parsing,
  }) {
    final _that = this;
    switch (_that) {
      case A2AJsonRpcException():
        return jsonRpc(_that.code, _that.message, _that.data);
      case A2AParsingException():
        return parsing(_that.message);
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
    TResult? Function(int code, String message, Map<String, dynamic>? data)?
        jsonRpc,
    TResult? Function(String message)? parsing,
  }) {
    final _that = this;
    switch (_that) {
      case A2AJsonRpcException() when jsonRpc != null:
        return jsonRpc(_that.code, _that.message, _that.data);
      case A2AParsingException() when parsing != null:
        return parsing(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class A2AJsonRpcException implements A2AException {
  const A2AJsonRpcException(
      {required this.code,
      required this.message,
      final Map<String, dynamic>? data,
      final String? $type})
      : _data = data,
        $type = $type ?? 'jsonRpc';
  factory A2AJsonRpcException.fromJson(Map<String, dynamic> json) =>
      _$A2AJsonRpcExceptionFromJson(json);

  /// The JSON-RPC error code.
  final int code;

  /// The JSON-RPC error message.
  @override
  final String message;

  /// Optional data associated with the error.
  final Map<String, dynamic>? _data;

  /// Optional data associated with the error.
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  /// Create a copy of A2AException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $A2AJsonRpcExceptionCopyWith<A2AJsonRpcException> get copyWith =>
      _$A2AJsonRpcExceptionCopyWithImpl<A2AJsonRpcException>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$A2AJsonRpcExceptionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is A2AJsonRpcException &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, code, message, const DeepCollectionEquality().hash(_data));

  @override
  String toString() {
    return 'A2AException.jsonRpc(code: $code, message: $message, data: $data)';
  }
}

/// @nodoc
abstract mixin class $A2AJsonRpcExceptionCopyWith<$Res>
    implements $A2AExceptionCopyWith<$Res> {
  factory $A2AJsonRpcExceptionCopyWith(
          A2AJsonRpcException value, $Res Function(A2AJsonRpcException) _then) =
      _$A2AJsonRpcExceptionCopyWithImpl;
  @override
  @useResult
  $Res call({int code, String message, Map<String, dynamic>? data});
}

/// @nodoc
class _$A2AJsonRpcExceptionCopyWithImpl<$Res>
    implements $A2AJsonRpcExceptionCopyWith<$Res> {
  _$A2AJsonRpcExceptionCopyWithImpl(this._self, this._then);

  final A2AJsonRpcException _self;
  final $Res Function(A2AJsonRpcException) _then;

  /// Create a copy of A2AException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = freezed,
  }) {
    return _then(A2AJsonRpcException(
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _self._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class A2AParsingException implements A2AException {
  const A2AParsingException({required this.message, final String? $type})
      : $type = $type ?? 'parsing';
  factory A2AParsingException.fromJson(Map<String, dynamic> json) =>
      _$A2AParsingExceptionFromJson(json);

  @override
  final String message;

  @JsonKey(name: 'runtimeType')
  final String $type;

  /// Create a copy of A2AException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $A2AParsingExceptionCopyWith<A2AParsingException> get copyWith =>
      _$A2AParsingExceptionCopyWithImpl<A2AParsingException>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$A2AParsingExceptionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is A2AParsingException &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'A2AException.parsing(message: $message)';
  }
}

/// @nodoc
abstract mixin class $A2AParsingExceptionCopyWith<$Res>
    implements $A2AExceptionCopyWith<$Res> {
  factory $A2AParsingExceptionCopyWith(
          A2AParsingException value, $Res Function(A2AParsingException) _then) =
      _$A2AParsingExceptionCopyWithImpl;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$A2AParsingExceptionCopyWithImpl<$Res>
    implements $A2AParsingExceptionCopyWith<$Res> {
  _$A2AParsingExceptionCopyWithImpl(this._self, this._then);

  final A2AParsingException _self;
  final $Res Function(A2AParsingException) _then;

  /// Create a copy of A2AException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(A2AParsingException(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
