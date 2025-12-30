// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentProvider {

/// The name of the agent provider's organization.
 String get organization;/// A URL for the agent provider's website or relevant documentation.
 String get url;
/// Create a copy of AgentProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentProviderCopyWith<AgentProvider> get copyWith => _$AgentProviderCopyWithImpl<AgentProvider>(this as AgentProvider, _$identity);

  /// Serializes this AgentProvider to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentProvider&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organization,url);

@override
String toString() {
  return 'AgentProvider(organization: $organization, url: $url)';
}


}

/// @nodoc
abstract mixin class $AgentProviderCopyWith<$Res>  {
  factory $AgentProviderCopyWith(AgentProvider value, $Res Function(AgentProvider) _then) = _$AgentProviderCopyWithImpl;
@useResult
$Res call({
 String organization, String url
});




}
/// @nodoc
class _$AgentProviderCopyWithImpl<$Res>
    implements $AgentProviderCopyWith<$Res> {
  _$AgentProviderCopyWithImpl(this._self, this._then);

  final AgentProvider _self;
  final $Res Function(AgentProvider) _then;

/// Create a copy of AgentProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organization = null,Object? url = null,}) {
  return _then(_self.copyWith(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentProvider].
extension AgentProviderPatterns on AgentProvider {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentProvider value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentProvider() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentProvider value)  $default,){
final _that = this;
switch (_that) {
case _AgentProvider():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentProvider value)?  $default,){
final _that = this;
switch (_that) {
case _AgentProvider() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String organization,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentProvider() when $default != null:
return $default(_that.organization,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String organization,  String url)  $default,) {final _that = this;
switch (_that) {
case _AgentProvider():
return $default(_that.organization,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String organization,  String url)?  $default,) {final _that = this;
switch (_that) {
case _AgentProvider() when $default != null:
return $default(_that.organization,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentProvider implements AgentProvider {
  const _AgentProvider({required this.organization, required this.url});
  factory _AgentProvider.fromJson(Map<String, dynamic> json) => _$AgentProviderFromJson(json);

/// The name of the agent provider's organization.
@override final  String organization;
/// A URL for the agent provider's website or relevant documentation.
@override final  String url;

/// Create a copy of AgentProvider
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentProviderCopyWith<_AgentProvider> get copyWith => __$AgentProviderCopyWithImpl<_AgentProvider>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentProviderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentProvider&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,organization,url);

@override
String toString() {
  return 'AgentProvider(organization: $organization, url: $url)';
}


}

/// @nodoc
abstract mixin class _$AgentProviderCopyWith<$Res> implements $AgentProviderCopyWith<$Res> {
  factory _$AgentProviderCopyWith(_AgentProvider value, $Res Function(_AgentProvider) _then) = __$AgentProviderCopyWithImpl;
@override @useResult
$Res call({
 String organization, String url
});




}
/// @nodoc
class __$AgentProviderCopyWithImpl<$Res>
    implements _$AgentProviderCopyWith<$Res> {
  __$AgentProviderCopyWithImpl(this._self, this._then);

  final _AgentProvider _self;
  final $Res Function(_AgentProvider) _then;

/// Create a copy of AgentProvider
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? url = null,}) {
  return _then(_AgentProvider(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
