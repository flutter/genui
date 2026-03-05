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
A2AException _$A2AExceptionFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'jsonRpc':
          return A2AJsonRpcException.fromJson(
            json
          );
                case 'taskNotFound':
          return A2ATaskNotFoundException.fromJson(
            json
          );
                case 'taskNotCancelable':
          return A2ATaskNotCancelableException.fromJson(
            json
          );
                case 'pushNotificationNotSupported':
          return A2APushNotificationNotSupportedException.fromJson(
            json
          );
                case 'pushNotificationConfigNotFound':
          return A2APushNotificationConfigNotFoundException.fromJson(
            json
          );
                case 'http':
          return A2AHttpException.fromJson(
            json
          );
                case 'network':
          return A2ANetworkException.fromJson(
            json
          );
                case 'parsing':
          return A2AParsingException.fromJson(
            json
          );
                case 'unsupportedOperation':
          return A2AUnsupportedOperationException.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'A2AException',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$A2AException {



  /// Serializes this A2AException to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2AException);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'A2AException()';
}


}

/// @nodoc
class $A2AExceptionCopyWith<$Res>  {
$A2AExceptionCopyWith(A2AException _, $Res Function(A2AException) __);
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( A2AJsonRpcException value)?  jsonRpc,TResult Function( A2ATaskNotFoundException value)?  taskNotFound,TResult Function( A2ATaskNotCancelableException value)?  taskNotCancelable,TResult Function( A2APushNotificationNotSupportedException value)?  pushNotificationNotSupported,TResult Function( A2APushNotificationConfigNotFoundException value)?  pushNotificationConfigNotFound,TResult Function( A2AHttpException value)?  http,TResult Function( A2ANetworkException value)?  network,TResult Function( A2AParsingException value)?  parsing,TResult Function( A2AUnsupportedOperationException value)?  unsupportedOperation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case A2AJsonRpcException() when jsonRpc != null:
return jsonRpc(_that);case A2ATaskNotFoundException() when taskNotFound != null:
return taskNotFound(_that);case A2ATaskNotCancelableException() when taskNotCancelable != null:
return taskNotCancelable(_that);case A2APushNotificationNotSupportedException() when pushNotificationNotSupported != null:
return pushNotificationNotSupported(_that);case A2APushNotificationConfigNotFoundException() when pushNotificationConfigNotFound != null:
return pushNotificationConfigNotFound(_that);case A2AHttpException() when http != null:
return http(_that);case A2ANetworkException() when network != null:
return network(_that);case A2AParsingException() when parsing != null:
return parsing(_that);case A2AUnsupportedOperationException() when unsupportedOperation != null:
return unsupportedOperation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( A2AJsonRpcException value)  jsonRpc,required TResult Function( A2ATaskNotFoundException value)  taskNotFound,required TResult Function( A2ATaskNotCancelableException value)  taskNotCancelable,required TResult Function( A2APushNotificationNotSupportedException value)  pushNotificationNotSupported,required TResult Function( A2APushNotificationConfigNotFoundException value)  pushNotificationConfigNotFound,required TResult Function( A2AHttpException value)  http,required TResult Function( A2ANetworkException value)  network,required TResult Function( A2AParsingException value)  parsing,required TResult Function( A2AUnsupportedOperationException value)  unsupportedOperation,}){
final _that = this;
switch (_that) {
case A2AJsonRpcException():
return jsonRpc(_that);case A2ATaskNotFoundException():
return taskNotFound(_that);case A2ATaskNotCancelableException():
return taskNotCancelable(_that);case A2APushNotificationNotSupportedException():
return pushNotificationNotSupported(_that);case A2APushNotificationConfigNotFoundException():
return pushNotificationConfigNotFound(_that);case A2AHttpException():
return http(_that);case A2ANetworkException():
return network(_that);case A2AParsingException():
return parsing(_that);case A2AUnsupportedOperationException():
return unsupportedOperation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( A2AJsonRpcException value)?  jsonRpc,TResult? Function( A2ATaskNotFoundException value)?  taskNotFound,TResult? Function( A2ATaskNotCancelableException value)?  taskNotCancelable,TResult? Function( A2APushNotificationNotSupportedException value)?  pushNotificationNotSupported,TResult? Function( A2APushNotificationConfigNotFoundException value)?  pushNotificationConfigNotFound,TResult? Function( A2AHttpException value)?  http,TResult? Function( A2ANetworkException value)?  network,TResult? Function( A2AParsingException value)?  parsing,TResult? Function( A2AUnsupportedOperationException value)?  unsupportedOperation,}){
final _that = this;
switch (_that) {
case A2AJsonRpcException() when jsonRpc != null:
return jsonRpc(_that);case A2ATaskNotFoundException() when taskNotFound != null:
return taskNotFound(_that);case A2ATaskNotCancelableException() when taskNotCancelable != null:
return taskNotCancelable(_that);case A2APushNotificationNotSupportedException() when pushNotificationNotSupported != null:
return pushNotificationNotSupported(_that);case A2APushNotificationConfigNotFoundException() when pushNotificationConfigNotFound != null:
return pushNotificationConfigNotFound(_that);case A2AHttpException() when http != null:
return http(_that);case A2ANetworkException() when network != null:
return network(_that);case A2AParsingException() when parsing != null:
return parsing(_that);case A2AUnsupportedOperationException() when unsupportedOperation != null:
return unsupportedOperation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int code,  String message,  Map<String, Object?>? data)?  jsonRpc,TResult Function( String message,  Map<String, Object?>? data)?  taskNotFound,TResult Function( String message,  Map<String, Object?>? data)?  taskNotCancelable,TResult Function( String message,  Map<String, Object?>? data)?  pushNotificationNotSupported,TResult Function( String message,  Map<String, Object?>? data)?  pushNotificationConfigNotFound,TResult Function( int statusCode,  String? reason)?  http,TResult Function( String message)?  network,TResult Function( String message)?  parsing,TResult Function( String message)?  unsupportedOperation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case A2AJsonRpcException() when jsonRpc != null:
return jsonRpc(_that.code,_that.message,_that.data);case A2ATaskNotFoundException() when taskNotFound != null:
return taskNotFound(_that.message,_that.data);case A2ATaskNotCancelableException() when taskNotCancelable != null:
return taskNotCancelable(_that.message,_that.data);case A2APushNotificationNotSupportedException() when pushNotificationNotSupported != null:
return pushNotificationNotSupported(_that.message,_that.data);case A2APushNotificationConfigNotFoundException() when pushNotificationConfigNotFound != null:
return pushNotificationConfigNotFound(_that.message,_that.data);case A2AHttpException() when http != null:
return http(_that.statusCode,_that.reason);case A2ANetworkException() when network != null:
return network(_that.message);case A2AParsingException() when parsing != null:
return parsing(_that.message);case A2AUnsupportedOperationException() when unsupportedOperation != null:
return unsupportedOperation(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int code,  String message,  Map<String, Object?>? data)  jsonRpc,required TResult Function( String message,  Map<String, Object?>? data)  taskNotFound,required TResult Function( String message,  Map<String, Object?>? data)  taskNotCancelable,required TResult Function( String message,  Map<String, Object?>? data)  pushNotificationNotSupported,required TResult Function( String message,  Map<String, Object?>? data)  pushNotificationConfigNotFound,required TResult Function( int statusCode,  String? reason)  http,required TResult Function( String message)  network,required TResult Function( String message)  parsing,required TResult Function( String message)  unsupportedOperation,}) {final _that = this;
switch (_that) {
case A2AJsonRpcException():
return jsonRpc(_that.code,_that.message,_that.data);case A2ATaskNotFoundException():
return taskNotFound(_that.message,_that.data);case A2ATaskNotCancelableException():
return taskNotCancelable(_that.message,_that.data);case A2APushNotificationNotSupportedException():
return pushNotificationNotSupported(_that.message,_that.data);case A2APushNotificationConfigNotFoundException():
return pushNotificationConfigNotFound(_that.message,_that.data);case A2AHttpException():
return http(_that.statusCode,_that.reason);case A2ANetworkException():
return network(_that.message);case A2AParsingException():
return parsing(_that.message);case A2AUnsupportedOperationException():
return unsupportedOperation(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int code,  String message,  Map<String, Object?>? data)?  jsonRpc,TResult? Function( String message,  Map<String, Object?>? data)?  taskNotFound,TResult? Function( String message,  Map<String, Object?>? data)?  taskNotCancelable,TResult? Function( String message,  Map<String, Object?>? data)?  pushNotificationNotSupported,TResult? Function( String message,  Map<String, Object?>? data)?  pushNotificationConfigNotFound,TResult? Function( int statusCode,  String? reason)?  http,TResult? Function( String message)?  network,TResult? Function( String message)?  parsing,TResult? Function( String message)?  unsupportedOperation,}) {final _that = this;
switch (_that) {
case A2AJsonRpcException() when jsonRpc != null:
return jsonRpc(_that.code,_that.message,_that.data);case A2ATaskNotFoundException() when taskNotFound != null:
return taskNotFound(_that.message,_that.data);case A2ATaskNotCancelableException() when taskNotCancelable != null:
return taskNotCancelable(_that.message,_that.data);case A2APushNotificationNotSupportedException() when pushNotificationNotSupported != null:
return pushNotificationNotSupported(_that.message,_that.data);case A2APushNotificationConfigNotFoundException() when pushNotificationConfigNotFound != null:
return pushNotificationConfigNotFound(_that.message,_that.data);case A2AHttpException() when http != null:
return http(_that.statusCode,_that.reason);case A2ANetworkException() when network != null:
return network(_that.message);case A2AParsingException() when parsing != null:
return parsing(_that.message);case A2AUnsupportedOperationException() when unsupportedOperation != null:
return unsupportedOperation(_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class A2AJsonRpcException implements A2AException {
  const A2AJsonRpcException({required this.code, required this.message, final  Map<String, Object?>? data, final  String? $type}): _data = data,$type = $type ?? 'jsonRpc';
  factory A2AJsonRpcException.fromJson(Map<String, dynamic> json) => _$A2AJsonRpcExceptionFromJson(json);

/// The integer error code as defined by the JSON-RPC 2.0 specification
/// or A2A-specific error codes.
 final  int code;
/// A human-readable string describing the error.
 final  String message;
/// Optional additional data provided by the server about the error.
 final  Map<String, Object?>? _data;
/// Optional additional data provided by the server about the error.
 Map<String, Object?>? get data {
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
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2AJsonRpcExceptionCopyWith<A2AJsonRpcException> get copyWith => _$A2AJsonRpcExceptionCopyWithImpl<A2AJsonRpcException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2AJsonRpcExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2AJsonRpcException&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'A2AException.jsonRpc(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $A2AJsonRpcExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2AJsonRpcExceptionCopyWith(A2AJsonRpcException value, $Res Function(A2AJsonRpcException) _then) = _$A2AJsonRpcExceptionCopyWithImpl;
@useResult
$Res call({
 int code, String message, Map<String, Object?>? data
});




}
/// @nodoc
class _$A2AJsonRpcExceptionCopyWithImpl<$Res>
    implements $A2AJsonRpcExceptionCopyWith<$Res> {
  _$A2AJsonRpcExceptionCopyWithImpl(this._self, this._then);

  final A2AJsonRpcException _self;
  final $Res Function(A2AJsonRpcException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = freezed,}) {
  return _then(A2AJsonRpcException(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2ATaskNotFoundException implements A2AException {
  const A2ATaskNotFoundException({required this.message, final  Map<String, Object?>? data, final  String? $type}): _data = data,$type = $type ?? 'taskNotFound';
  factory A2ATaskNotFoundException.fromJson(Map<String, dynamic> json) => _$A2ATaskNotFoundExceptionFromJson(json);

 final  String message;
 final  Map<String, Object?>? _data;
 Map<String, Object?>? get data {
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
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2ATaskNotFoundExceptionCopyWith<A2ATaskNotFoundException> get copyWith => _$A2ATaskNotFoundExceptionCopyWithImpl<A2ATaskNotFoundException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2ATaskNotFoundExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2ATaskNotFoundException&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'A2AException.taskNotFound(message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $A2ATaskNotFoundExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2ATaskNotFoundExceptionCopyWith(A2ATaskNotFoundException value, $Res Function(A2ATaskNotFoundException) _then) = _$A2ATaskNotFoundExceptionCopyWithImpl;
@useResult
$Res call({
 String message, Map<String, Object?>? data
});




}
/// @nodoc
class _$A2ATaskNotFoundExceptionCopyWithImpl<$Res>
    implements $A2ATaskNotFoundExceptionCopyWith<$Res> {
  _$A2ATaskNotFoundExceptionCopyWithImpl(this._self, this._then);

  final A2ATaskNotFoundException _self;
  final $Res Function(A2ATaskNotFoundException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? data = freezed,}) {
  return _then(A2ATaskNotFoundException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2ATaskNotCancelableException implements A2AException {
  const A2ATaskNotCancelableException({required this.message, final  Map<String, Object?>? data, final  String? $type}): _data = data,$type = $type ?? 'taskNotCancelable';
  factory A2ATaskNotCancelableException.fromJson(Map<String, dynamic> json) => _$A2ATaskNotCancelableExceptionFromJson(json);

 final  String message;
 final  Map<String, Object?>? _data;
 Map<String, Object?>? get data {
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
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2ATaskNotCancelableExceptionCopyWith<A2ATaskNotCancelableException> get copyWith => _$A2ATaskNotCancelableExceptionCopyWithImpl<A2ATaskNotCancelableException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2ATaskNotCancelableExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2ATaskNotCancelableException&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'A2AException.taskNotCancelable(message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $A2ATaskNotCancelableExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2ATaskNotCancelableExceptionCopyWith(A2ATaskNotCancelableException value, $Res Function(A2ATaskNotCancelableException) _then) = _$A2ATaskNotCancelableExceptionCopyWithImpl;
@useResult
$Res call({
 String message, Map<String, Object?>? data
});




}
/// @nodoc
class _$A2ATaskNotCancelableExceptionCopyWithImpl<$Res>
    implements $A2ATaskNotCancelableExceptionCopyWith<$Res> {
  _$A2ATaskNotCancelableExceptionCopyWithImpl(this._self, this._then);

  final A2ATaskNotCancelableException _self;
  final $Res Function(A2ATaskNotCancelableException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? data = freezed,}) {
  return _then(A2ATaskNotCancelableException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2APushNotificationNotSupportedException implements A2AException {
  const A2APushNotificationNotSupportedException({required this.message, final  Map<String, Object?>? data, final  String? $type}): _data = data,$type = $type ?? 'pushNotificationNotSupported';
  factory A2APushNotificationNotSupportedException.fromJson(Map<String, dynamic> json) => _$A2APushNotificationNotSupportedExceptionFromJson(json);

 final  String message;
 final  Map<String, Object?>? _data;
 Map<String, Object?>? get data {
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
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2APushNotificationNotSupportedExceptionCopyWith<A2APushNotificationNotSupportedException> get copyWith => _$A2APushNotificationNotSupportedExceptionCopyWithImpl<A2APushNotificationNotSupportedException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2APushNotificationNotSupportedExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2APushNotificationNotSupportedException&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'A2AException.pushNotificationNotSupported(message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $A2APushNotificationNotSupportedExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2APushNotificationNotSupportedExceptionCopyWith(A2APushNotificationNotSupportedException value, $Res Function(A2APushNotificationNotSupportedException) _then) = _$A2APushNotificationNotSupportedExceptionCopyWithImpl;
@useResult
$Res call({
 String message, Map<String, Object?>? data
});




}
/// @nodoc
class _$A2APushNotificationNotSupportedExceptionCopyWithImpl<$Res>
    implements $A2APushNotificationNotSupportedExceptionCopyWith<$Res> {
  _$A2APushNotificationNotSupportedExceptionCopyWithImpl(this._self, this._then);

  final A2APushNotificationNotSupportedException _self;
  final $Res Function(A2APushNotificationNotSupportedException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? data = freezed,}) {
  return _then(A2APushNotificationNotSupportedException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2APushNotificationConfigNotFoundException implements A2AException {
  const A2APushNotificationConfigNotFoundException({required this.message, final  Map<String, Object?>? data, final  String? $type}): _data = data,$type = $type ?? 'pushNotificationConfigNotFound';
  factory A2APushNotificationConfigNotFoundException.fromJson(Map<String, dynamic> json) => _$A2APushNotificationConfigNotFoundExceptionFromJson(json);

 final  String message;
 final  Map<String, Object?>? _data;
 Map<String, Object?>? get data {
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
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2APushNotificationConfigNotFoundExceptionCopyWith<A2APushNotificationConfigNotFoundException> get copyWith => _$A2APushNotificationConfigNotFoundExceptionCopyWithImpl<A2APushNotificationConfigNotFoundException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2APushNotificationConfigNotFoundExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2APushNotificationConfigNotFoundException&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'A2AException.pushNotificationConfigNotFound(message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $A2APushNotificationConfigNotFoundExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2APushNotificationConfigNotFoundExceptionCopyWith(A2APushNotificationConfigNotFoundException value, $Res Function(A2APushNotificationConfigNotFoundException) _then) = _$A2APushNotificationConfigNotFoundExceptionCopyWithImpl;
@useResult
$Res call({
 String message, Map<String, Object?>? data
});




}
/// @nodoc
class _$A2APushNotificationConfigNotFoundExceptionCopyWithImpl<$Res>
    implements $A2APushNotificationConfigNotFoundExceptionCopyWith<$Res> {
  _$A2APushNotificationConfigNotFoundExceptionCopyWithImpl(this._self, this._then);

  final A2APushNotificationConfigNotFoundException _self;
  final $Res Function(A2APushNotificationConfigNotFoundException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? data = freezed,}) {
  return _then(A2APushNotificationConfigNotFoundException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2AHttpException implements A2AException {
  const A2AHttpException({required this.statusCode, this.reason, final  String? $type}): $type = $type ?? 'http';
  factory A2AHttpException.fromJson(Map<String, dynamic> json) => _$A2AHttpExceptionFromJson(json);

/// The HTTP status code (e.g., 404, 500).
 final  int statusCode;
/// An optional human-readable reason phrase associated with the status
/// code.
 final  String? reason;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2AHttpExceptionCopyWith<A2AHttpException> get copyWith => _$A2AHttpExceptionCopyWithImpl<A2AHttpException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2AHttpExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2AHttpException&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,statusCode,reason);

@override
String toString() {
  return 'A2AException.http(statusCode: $statusCode, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $A2AHttpExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2AHttpExceptionCopyWith(A2AHttpException value, $Res Function(A2AHttpException) _then) = _$A2AHttpExceptionCopyWithImpl;
@useResult
$Res call({
 int statusCode, String? reason
});




}
/// @nodoc
class _$A2AHttpExceptionCopyWithImpl<$Res>
    implements $A2AHttpExceptionCopyWith<$Res> {
  _$A2AHttpExceptionCopyWithImpl(this._self, this._then);

  final A2AHttpException _self;
  final $Res Function(A2AHttpException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusCode = null,Object? reason = freezed,}) {
  return _then(A2AHttpException(
statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2ANetworkException implements A2AException {
  const A2ANetworkException({required this.message, final  String? $type}): $type = $type ?? 'network';
  factory A2ANetworkException.fromJson(Map<String, dynamic> json) => _$A2ANetworkExceptionFromJson(json);

/// A message describing the network error.
 final  String message;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2ANetworkExceptionCopyWith<A2ANetworkException> get copyWith => _$A2ANetworkExceptionCopyWithImpl<A2ANetworkException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2ANetworkExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2ANetworkException&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'A2AException.network(message: $message)';
}


}

/// @nodoc
abstract mixin class $A2ANetworkExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2ANetworkExceptionCopyWith(A2ANetworkException value, $Res Function(A2ANetworkException) _then) = _$A2ANetworkExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$A2ANetworkExceptionCopyWithImpl<$Res>
    implements $A2ANetworkExceptionCopyWith<$Res> {
  _$A2ANetworkExceptionCopyWithImpl(this._self, this._then);

  final A2ANetworkException _self;
  final $Res Function(A2ANetworkException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(A2ANetworkException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2AParsingException implements A2AException {
  const A2AParsingException({required this.message, final  String? $type}): $type = $type ?? 'parsing';
  factory A2AParsingException.fromJson(Map<String, dynamic> json) => _$A2AParsingExceptionFromJson(json);

/// A message describing the parsing failure.
 final  String message;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2AParsingExceptionCopyWith<A2AParsingException> get copyWith => _$A2AParsingExceptionCopyWithImpl<A2AParsingException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2AParsingExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2AParsingException&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'A2AException.parsing(message: $message)';
}


}

/// @nodoc
abstract mixin class $A2AParsingExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2AParsingExceptionCopyWith(A2AParsingException value, $Res Function(A2AParsingException) _then) = _$A2AParsingExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$A2AParsingExceptionCopyWithImpl<$Res>
    implements $A2AParsingExceptionCopyWith<$Res> {
  _$A2AParsingExceptionCopyWithImpl(this._self, this._then);

  final A2AParsingException _self;
  final $Res Function(A2AParsingException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(A2AParsingException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class A2AUnsupportedOperationException implements A2AException {
  const A2AUnsupportedOperationException({required this.message, final  String? $type}): $type = $type ?? 'unsupportedOperation';
  factory A2AUnsupportedOperationException.fromJson(Map<String, dynamic> json) => _$A2AUnsupportedOperationExceptionFromJson(json);

 final  String message;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2AUnsupportedOperationExceptionCopyWith<A2AUnsupportedOperationException> get copyWith => _$A2AUnsupportedOperationExceptionCopyWithImpl<A2AUnsupportedOperationException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2AUnsupportedOperationExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2AUnsupportedOperationException&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'A2AException.unsupportedOperation(message: $message)';
}


}

/// @nodoc
abstract mixin class $A2AUnsupportedOperationExceptionCopyWith<$Res> implements $A2AExceptionCopyWith<$Res> {
  factory $A2AUnsupportedOperationExceptionCopyWith(A2AUnsupportedOperationException value, $Res Function(A2AUnsupportedOperationException) _then) = _$A2AUnsupportedOperationExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$A2AUnsupportedOperationExceptionCopyWithImpl<$Res>
    implements $A2AUnsupportedOperationExceptionCopyWith<$Res> {
  _$A2AUnsupportedOperationExceptionCopyWithImpl(this._self, this._then);

  final A2AUnsupportedOperationException _self;
  final $Res Function(A2AUnsupportedOperationException) _then;

/// Create a copy of A2AException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(A2AUnsupportedOperationException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
