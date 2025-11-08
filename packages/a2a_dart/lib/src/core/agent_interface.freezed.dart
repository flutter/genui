// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_interface.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentInterface {

/// The URL where this interface is available.
///
/// In production, this must be a valid absolute HTTPS URL.
 String get url;/// The transport protocol supported at this URL.
 TransportProtocol get transport;
/// Create a copy of AgentInterface
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentInterfaceCopyWith<AgentInterface> get copyWith => _$AgentInterfaceCopyWithImpl<AgentInterface>(this as AgentInterface, _$identity);

  /// Serializes this AgentInterface to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentInterface&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,transport);

@override
String toString() {
  return 'AgentInterface(url: $url, transport: $transport)';
}


}

/// @nodoc
abstract mixin class $AgentInterfaceCopyWith<$Res>  {
  factory $AgentInterfaceCopyWith(AgentInterface value, $Res Function(AgentInterface) _then) = _$AgentInterfaceCopyWithImpl;
@useResult
$Res call({
 String url, TransportProtocol transport
});




}
/// @nodoc
class _$AgentInterfaceCopyWithImpl<$Res>
    implements $AgentInterfaceCopyWith<$Res> {
  _$AgentInterfaceCopyWithImpl(this._self, this._then);

  final AgentInterface _self;
  final $Res Function(AgentInterface) _then;

/// Create a copy of AgentInterface
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? transport = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as TransportProtocol,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentInterface].
extension AgentInterfacePatterns on AgentInterface {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentInterface value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentInterface() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentInterface value)  $default,){
final _that = this;
switch (_that) {
case _AgentInterface():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentInterface value)?  $default,){
final _that = this;
switch (_that) {
case _AgentInterface() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  TransportProtocol transport)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentInterface() when $default != null:
return $default(_that.url,_that.transport);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  TransportProtocol transport)  $default,) {final _that = this;
switch (_that) {
case _AgentInterface():
return $default(_that.url,_that.transport);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  TransportProtocol transport)?  $default,) {final _that = this;
switch (_that) {
case _AgentInterface() when $default != null:
return $default(_that.url,_that.transport);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentInterface implements AgentInterface {
  const _AgentInterface({required this.url, required this.transport});
  factory _AgentInterface.fromJson(Map<String, dynamic> json) => _$AgentInterfaceFromJson(json);

/// The URL where this interface is available.
///
/// In production, this must be a valid absolute HTTPS URL.
@override final  String url;
/// The transport protocol supported at this URL.
@override final  TransportProtocol transport;

/// Create a copy of AgentInterface
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentInterfaceCopyWith<_AgentInterface> get copyWith => __$AgentInterfaceCopyWithImpl<_AgentInterface>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentInterfaceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentInterface&&(identical(other.url, url) || other.url == url)&&(identical(other.transport, transport) || other.transport == transport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,transport);

@override
String toString() {
  return 'AgentInterface(url: $url, transport: $transport)';
}


}

/// @nodoc
abstract mixin class _$AgentInterfaceCopyWith<$Res> implements $AgentInterfaceCopyWith<$Res> {
  factory _$AgentInterfaceCopyWith(_AgentInterface value, $Res Function(_AgentInterface) _then) = __$AgentInterfaceCopyWithImpl;
@override @useResult
$Res call({
 String url, TransportProtocol transport
});




}
/// @nodoc
class __$AgentInterfaceCopyWithImpl<$Res>
    implements _$AgentInterfaceCopyWith<$Res> {
  __$AgentInterfaceCopyWithImpl(this._self, this._then);

  final _AgentInterface _self;
  final $Res Function(_AgentInterface) _then;

/// Create a copy of AgentInterface
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? transport = null,}) {
  return _then(_AgentInterface(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as TransportProtocol,
  ));
}


}

// dart format on
