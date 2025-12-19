// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_capabilities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentCapabilities {

/// Indicates if the agent supports streaming responses, typically via
/// Server-Sent Events (SSE).
///
/// A value of `true` means the client can use methods like `message/stream`.
 bool? get streaming;/// Indicates if the agent supports sending push notifications for
/// asynchronous task updates to a client-specified endpoint.
 bool? get pushNotifications;/// Indicates if the agent maintains and can provide a history of state
/// transitions for tasks.
 bool? get stateTransitionHistory;/// A list of non-standard protocol extensions supported by the agent.
///
/// See [AgentExtension] for more details.
 List<AgentExtension>? get extensions;
/// Create a copy of AgentCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentCapabilitiesCopyWith<AgentCapabilities> get copyWith => _$AgentCapabilitiesCopyWithImpl<AgentCapabilities>(this as AgentCapabilities, _$identity);

  /// Serializes this AgentCapabilities to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentCapabilities&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.pushNotifications, pushNotifications) || other.pushNotifications == pushNotifications)&&(identical(other.stateTransitionHistory, stateTransitionHistory) || other.stateTransitionHistory == stateTransitionHistory)&&const DeepCollectionEquality().equals(other.extensions, extensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streaming,pushNotifications,stateTransitionHistory,const DeepCollectionEquality().hash(extensions));

@override
String toString() {
  return 'AgentCapabilities(streaming: $streaming, pushNotifications: $pushNotifications, stateTransitionHistory: $stateTransitionHistory, extensions: $extensions)';
}


}

/// @nodoc
abstract mixin class $AgentCapabilitiesCopyWith<$Res>  {
  factory $AgentCapabilitiesCopyWith(AgentCapabilities value, $Res Function(AgentCapabilities) _then) = _$AgentCapabilitiesCopyWithImpl;
@useResult
$Res call({
 bool? streaming, bool? pushNotifications, bool? stateTransitionHistory, List<AgentExtension>? extensions
});




}
/// @nodoc
class _$AgentCapabilitiesCopyWithImpl<$Res>
    implements $AgentCapabilitiesCopyWith<$Res> {
  _$AgentCapabilitiesCopyWithImpl(this._self, this._then);

  final AgentCapabilities _self;
  final $Res Function(AgentCapabilities) _then;

/// Create a copy of AgentCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streaming = freezed,Object? pushNotifications = freezed,Object? stateTransitionHistory = freezed,Object? extensions = freezed,}) {
  return _then(_self.copyWith(
streaming: freezed == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool?,pushNotifications: freezed == pushNotifications ? _self.pushNotifications : pushNotifications // ignore: cast_nullable_to_non_nullable
as bool?,stateTransitionHistory: freezed == stateTransitionHistory ? _self.stateTransitionHistory : stateTransitionHistory // ignore: cast_nullable_to_non_nullable
as bool?,extensions: freezed == extensions ? _self.extensions : extensions // ignore: cast_nullable_to_non_nullable
as List<AgentExtension>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentCapabilities].
extension AgentCapabilitiesPatterns on AgentCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _AgentCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _AgentCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? streaming,  bool? pushNotifications,  bool? stateTransitionHistory,  List<AgentExtension>? extensions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentCapabilities() when $default != null:
return $default(_that.streaming,_that.pushNotifications,_that.stateTransitionHistory,_that.extensions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? streaming,  bool? pushNotifications,  bool? stateTransitionHistory,  List<AgentExtension>? extensions)  $default,) {final _that = this;
switch (_that) {
case _AgentCapabilities():
return $default(_that.streaming,_that.pushNotifications,_that.stateTransitionHistory,_that.extensions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? streaming,  bool? pushNotifications,  bool? stateTransitionHistory,  List<AgentExtension>? extensions)?  $default,) {final _that = this;
switch (_that) {
case _AgentCapabilities() when $default != null:
return $default(_that.streaming,_that.pushNotifications,_that.stateTransitionHistory,_that.extensions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentCapabilities implements AgentCapabilities {
  const _AgentCapabilities({this.streaming, this.pushNotifications, this.stateTransitionHistory, final  List<AgentExtension>? extensions}): _extensions = extensions;
  factory _AgentCapabilities.fromJson(Map<String, dynamic> json) => _$AgentCapabilitiesFromJson(json);

/// Indicates if the agent supports streaming responses, typically via
/// Server-Sent Events (SSE).
///
/// A value of `true` means the client can use methods like `message/stream`.
@override final  bool? streaming;
/// Indicates if the agent supports sending push notifications for
/// asynchronous task updates to a client-specified endpoint.
@override final  bool? pushNotifications;
/// Indicates if the agent maintains and can provide a history of state
/// transitions for tasks.
@override final  bool? stateTransitionHistory;
/// A list of non-standard protocol extensions supported by the agent.
///
/// See [AgentExtension] for more details.
 final  List<AgentExtension>? _extensions;
/// A list of non-standard protocol extensions supported by the agent.
///
/// See [AgentExtension] for more details.
@override List<AgentExtension>? get extensions {
  final value = _extensions;
  if (value == null) return null;
  if (_extensions is EqualUnmodifiableListView) return _extensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AgentCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentCapabilitiesCopyWith<_AgentCapabilities> get copyWith => __$AgentCapabilitiesCopyWithImpl<_AgentCapabilities>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentCapabilitiesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentCapabilities&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.pushNotifications, pushNotifications) || other.pushNotifications == pushNotifications)&&(identical(other.stateTransitionHistory, stateTransitionHistory) || other.stateTransitionHistory == stateTransitionHistory)&&const DeepCollectionEquality().equals(other._extensions, _extensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streaming,pushNotifications,stateTransitionHistory,const DeepCollectionEquality().hash(_extensions));

@override
String toString() {
  return 'AgentCapabilities(streaming: $streaming, pushNotifications: $pushNotifications, stateTransitionHistory: $stateTransitionHistory, extensions: $extensions)';
}


}

/// @nodoc
abstract mixin class _$AgentCapabilitiesCopyWith<$Res> implements $AgentCapabilitiesCopyWith<$Res> {
  factory _$AgentCapabilitiesCopyWith(_AgentCapabilities value, $Res Function(_AgentCapabilities) _then) = __$AgentCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 bool? streaming, bool? pushNotifications, bool? stateTransitionHistory, List<AgentExtension>? extensions
});




}
/// @nodoc
class __$AgentCapabilitiesCopyWithImpl<$Res>
    implements _$AgentCapabilitiesCopyWith<$Res> {
  __$AgentCapabilitiesCopyWithImpl(this._self, this._then);

  final _AgentCapabilities _self;
  final $Res Function(_AgentCapabilities) _then;

/// Create a copy of AgentCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streaming = freezed,Object? pushNotifications = freezed,Object? stateTransitionHistory = freezed,Object? extensions = freezed,}) {
  return _then(_AgentCapabilities(
streaming: freezed == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool?,pushNotifications: freezed == pushNotifications ? _self.pushNotifications : pushNotifications // ignore: cast_nullable_to_non_nullable
as bool?,stateTransitionHistory: freezed == stateTransitionHistory ? _self.stateTransitionHistory : stateTransitionHistory // ignore: cast_nullable_to_non_nullable
as bool?,extensions: freezed == extensions ? _self._extensions : extensions // ignore: cast_nullable_to_non_nullable
as List<AgentExtension>?,
  ));
}


}

// dart format on
