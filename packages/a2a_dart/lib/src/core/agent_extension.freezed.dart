// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_extension.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentExtension {

/// The unique URI identifying the extension.
 String get uri;/// A human-readable description of the extension.
 String? get description;/// If true, the client must understand and comply with the extension's
/// requirements to interact with the agent.
 bool? get required;/// Optional, extension-specific configuration parameters.
 Map<String, Object?>? get params;
/// Create a copy of AgentExtension
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentExtensionCopyWith<AgentExtension> get copyWith => _$AgentExtensionCopyWithImpl<AgentExtension>(this as AgentExtension, _$identity);

  /// Serializes this AgentExtension to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentExtension&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.description, description) || other.description == description)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other.params, params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uri,description,required,const DeepCollectionEquality().hash(params));

@override
String toString() {
  return 'AgentExtension(uri: $uri, description: $description, required: $required, params: $params)';
}


}

/// @nodoc
abstract mixin class $AgentExtensionCopyWith<$Res>  {
  factory $AgentExtensionCopyWith(AgentExtension value, $Res Function(AgentExtension) _then) = _$AgentExtensionCopyWithImpl;
@useResult
$Res call({
 String uri, String? description, bool? required, Map<String, Object?>? params
});




}
/// @nodoc
class _$AgentExtensionCopyWithImpl<$Res>
    implements $AgentExtensionCopyWith<$Res> {
  _$AgentExtensionCopyWithImpl(this._self, this._then);

  final AgentExtension _self;
  final $Res Function(AgentExtension) _then;

/// Create a copy of AgentExtension
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uri = null,Object? description = freezed,Object? required = freezed,Object? params = freezed,}) {
  return _then(_self.copyWith(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,required: freezed == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool?,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentExtension].
extension AgentExtensionPatterns on AgentExtension {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentExtension value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentExtension() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentExtension value)  $default,){
final _that = this;
switch (_that) {
case _AgentExtension():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentExtension value)?  $default,){
final _that = this;
switch (_that) {
case _AgentExtension() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uri,  String? description,  bool? required,  Map<String, Object?>? params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentExtension() when $default != null:
return $default(_that.uri,_that.description,_that.required,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uri,  String? description,  bool? required,  Map<String, Object?>? params)  $default,) {final _that = this;
switch (_that) {
case _AgentExtension():
return $default(_that.uri,_that.description,_that.required,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uri,  String? description,  bool? required,  Map<String, Object?>? params)?  $default,) {final _that = this;
switch (_that) {
case _AgentExtension() when $default != null:
return $default(_that.uri,_that.description,_that.required,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentExtension implements AgentExtension {
  const _AgentExtension({required this.uri, this.description, this.required, final  Map<String, Object?>? params}): _params = params;
  factory _AgentExtension.fromJson(Map<String, dynamic> json) => _$AgentExtensionFromJson(json);

/// The unique URI identifying the extension.
@override final  String uri;
/// A human-readable description of the extension.
@override final  String? description;
/// If true, the client must understand and comply with the extension's
/// requirements to interact with the agent.
@override final  bool? required;
/// Optional, extension-specific configuration parameters.
 final  Map<String, Object?>? _params;
/// Optional, extension-specific configuration parameters.
@override Map<String, Object?>? get params {
  final value = _params;
  if (value == null) return null;
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AgentExtension
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentExtensionCopyWith<_AgentExtension> get copyWith => __$AgentExtensionCopyWithImpl<_AgentExtension>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentExtensionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentExtension&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.description, description) || other.description == description)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other._params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uri,description,required,const DeepCollectionEquality().hash(_params));

@override
String toString() {
  return 'AgentExtension(uri: $uri, description: $description, required: $required, params: $params)';
}


}

/// @nodoc
abstract mixin class _$AgentExtensionCopyWith<$Res> implements $AgentExtensionCopyWith<$Res> {
  factory _$AgentExtensionCopyWith(_AgentExtension value, $Res Function(_AgentExtension) _then) = __$AgentExtensionCopyWithImpl;
@override @useResult
$Res call({
 String uri, String? description, bool? required, Map<String, Object?>? params
});




}
/// @nodoc
class __$AgentExtensionCopyWithImpl<$Res>
    implements _$AgentExtensionCopyWith<$Res> {
  __$AgentExtensionCopyWithImpl(this._self, this._then);

  final _AgentExtension _self;
  final $Res Function(_AgentExtension) _then;

/// Create a copy of AgentExtension
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? description = freezed,Object? required = freezed,Object? params = freezed,}) {
  return _then(_AgentExtension(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,required: freezed == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool?,params: freezed == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

// dart format on
