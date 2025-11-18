// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PushNotificationConfig {

/// A unique identifier (e.g. UUID) for the push notification configuration,
/// set by the client to support multiple notification callbacks.
 String? get id;/// The callback URL where the agent should send push notifications.
 String get url;/// A unique token for this task or session to validate incoming push
/// notifications.
 String? get token;/// Optional authentication details for the agent to use when calling the
/// notification URL.
 PushNotificationAuthenticationInfo? get authentication;
/// Create a copy of PushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushNotificationConfigCopyWith<PushNotificationConfig> get copyWith => _$PushNotificationConfigCopyWithImpl<PushNotificationConfig>(this as PushNotificationConfig, _$identity);

  /// Serializes this PushNotificationConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushNotificationConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.authentication, authentication) || other.authentication == authentication));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,token,authentication);

@override
String toString() {
  return 'PushNotificationConfig(id: $id, url: $url, token: $token, authentication: $authentication)';
}


}

/// @nodoc
abstract mixin class $PushNotificationConfigCopyWith<$Res>  {
  factory $PushNotificationConfigCopyWith(PushNotificationConfig value, $Res Function(PushNotificationConfig) _then) = _$PushNotificationConfigCopyWithImpl;
@useResult
$Res call({
 String? id, String url, String? token, PushNotificationAuthenticationInfo? authentication
});


$PushNotificationAuthenticationInfoCopyWith<$Res>? get authentication;

}
/// @nodoc
class _$PushNotificationConfigCopyWithImpl<$Res>
    implements $PushNotificationConfigCopyWith<$Res> {
  _$PushNotificationConfigCopyWithImpl(this._self, this._then);

  final PushNotificationConfig _self;
  final $Res Function(PushNotificationConfig) _then;

/// Create a copy of PushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? url = null,Object? token = freezed,Object? authentication = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,authentication: freezed == authentication ? _self.authentication : authentication // ignore: cast_nullable_to_non_nullable
as PushNotificationAuthenticationInfo?,
  ));
}
/// Create a copy of PushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PushNotificationAuthenticationInfoCopyWith<$Res>? get authentication {
    if (_self.authentication == null) {
    return null;
  }

  return $PushNotificationAuthenticationInfoCopyWith<$Res>(_self.authentication!, (value) {
    return _then(_self.copyWith(authentication: value));
  });
}
}


/// Adds pattern-matching-related methods to [PushNotificationConfig].
extension PushNotificationConfigPatterns on PushNotificationConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushNotificationConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushNotificationConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushNotificationConfig value)  $default,){
final _that = this;
switch (_that) {
case _PushNotificationConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushNotificationConfig value)?  $default,){
final _that = this;
switch (_that) {
case _PushNotificationConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String url,  String? token,  PushNotificationAuthenticationInfo? authentication)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushNotificationConfig() when $default != null:
return $default(_that.id,_that.url,_that.token,_that.authentication);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String url,  String? token,  PushNotificationAuthenticationInfo? authentication)  $default,) {final _that = this;
switch (_that) {
case _PushNotificationConfig():
return $default(_that.id,_that.url,_that.token,_that.authentication);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String url,  String? token,  PushNotificationAuthenticationInfo? authentication)?  $default,) {final _that = this;
switch (_that) {
case _PushNotificationConfig() when $default != null:
return $default(_that.id,_that.url,_that.token,_that.authentication);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushNotificationConfig implements PushNotificationConfig {
  const _PushNotificationConfig({this.id, required this.url, this.token, this.authentication});
  factory _PushNotificationConfig.fromJson(Map<String, dynamic> json) => _$PushNotificationConfigFromJson(json);

/// A unique identifier (e.g. UUID) for the push notification configuration,
/// set by the client to support multiple notification callbacks.
@override final  String? id;
/// The callback URL where the agent should send push notifications.
@override final  String url;
/// A unique token for this task or session to validate incoming push
/// notifications.
@override final  String? token;
/// Optional authentication details for the agent to use when calling the
/// notification URL.
@override final  PushNotificationAuthenticationInfo? authentication;

/// Create a copy of PushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushNotificationConfigCopyWith<_PushNotificationConfig> get copyWith => __$PushNotificationConfigCopyWithImpl<_PushNotificationConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushNotificationConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushNotificationConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.authentication, authentication) || other.authentication == authentication));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,token,authentication);

@override
String toString() {
  return 'PushNotificationConfig(id: $id, url: $url, token: $token, authentication: $authentication)';
}


}

/// @nodoc
abstract mixin class _$PushNotificationConfigCopyWith<$Res> implements $PushNotificationConfigCopyWith<$Res> {
  factory _$PushNotificationConfigCopyWith(_PushNotificationConfig value, $Res Function(_PushNotificationConfig) _then) = __$PushNotificationConfigCopyWithImpl;
@override @useResult
$Res call({
 String? id, String url, String? token, PushNotificationAuthenticationInfo? authentication
});


@override $PushNotificationAuthenticationInfoCopyWith<$Res>? get authentication;

}
/// @nodoc
class __$PushNotificationConfigCopyWithImpl<$Res>
    implements _$PushNotificationConfigCopyWith<$Res> {
  __$PushNotificationConfigCopyWithImpl(this._self, this._then);

  final _PushNotificationConfig _self;
  final $Res Function(_PushNotificationConfig) _then;

/// Create a copy of PushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? url = null,Object? token = freezed,Object? authentication = freezed,}) {
  return _then(_PushNotificationConfig(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,authentication: freezed == authentication ? _self.authentication : authentication // ignore: cast_nullable_to_non_nullable
as PushNotificationAuthenticationInfo?,
  ));
}

/// Create a copy of PushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PushNotificationAuthenticationInfoCopyWith<$Res>? get authentication {
    if (_self.authentication == null) {
    return null;
  }

  return $PushNotificationAuthenticationInfoCopyWith<$Res>(_self.authentication!, (value) {
    return _then(_self.copyWith(authentication: value));
  });
}
}


/// @nodoc
mixin _$PushNotificationAuthenticationInfo {

/// A list of supported authentication schemes (e.g., 'Basic', 'Bearer').
 List<String> get schemes;/// Optional credentials required by the push notification endpoint.
 String? get credentials;
/// Create a copy of PushNotificationAuthenticationInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushNotificationAuthenticationInfoCopyWith<PushNotificationAuthenticationInfo> get copyWith => _$PushNotificationAuthenticationInfoCopyWithImpl<PushNotificationAuthenticationInfo>(this as PushNotificationAuthenticationInfo, _$identity);

  /// Serializes this PushNotificationAuthenticationInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushNotificationAuthenticationInfo&&const DeepCollectionEquality().equals(other.schemes, schemes)&&(identical(other.credentials, credentials) || other.credentials == credentials));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(schemes),credentials);

@override
String toString() {
  return 'PushNotificationAuthenticationInfo(schemes: $schemes, credentials: $credentials)';
}


}

/// @nodoc
abstract mixin class $PushNotificationAuthenticationInfoCopyWith<$Res>  {
  factory $PushNotificationAuthenticationInfoCopyWith(PushNotificationAuthenticationInfo value, $Res Function(PushNotificationAuthenticationInfo) _then) = _$PushNotificationAuthenticationInfoCopyWithImpl;
@useResult
$Res call({
 List<String> schemes, String? credentials
});




}
/// @nodoc
class _$PushNotificationAuthenticationInfoCopyWithImpl<$Res>
    implements $PushNotificationAuthenticationInfoCopyWith<$Res> {
  _$PushNotificationAuthenticationInfoCopyWithImpl(this._self, this._then);

  final PushNotificationAuthenticationInfo _self;
  final $Res Function(PushNotificationAuthenticationInfo) _then;

/// Create a copy of PushNotificationAuthenticationInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemes = null,Object? credentials = freezed,}) {
  return _then(_self.copyWith(
schemes: null == schemes ? _self.schemes : schemes // ignore: cast_nullable_to_non_nullable
as List<String>,credentials: freezed == credentials ? _self.credentials : credentials // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushNotificationAuthenticationInfo].
extension PushNotificationAuthenticationInfoPatterns on PushNotificationAuthenticationInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushNotificationAuthenticationInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushNotificationAuthenticationInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushNotificationAuthenticationInfo value)  $default,){
final _that = this;
switch (_that) {
case _PushNotificationAuthenticationInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushNotificationAuthenticationInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PushNotificationAuthenticationInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> schemes,  String? credentials)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushNotificationAuthenticationInfo() when $default != null:
return $default(_that.schemes,_that.credentials);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> schemes,  String? credentials)  $default,) {final _that = this;
switch (_that) {
case _PushNotificationAuthenticationInfo():
return $default(_that.schemes,_that.credentials);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> schemes,  String? credentials)?  $default,) {final _that = this;
switch (_that) {
case _PushNotificationAuthenticationInfo() when $default != null:
return $default(_that.schemes,_that.credentials);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushNotificationAuthenticationInfo implements PushNotificationAuthenticationInfo {
  const _PushNotificationAuthenticationInfo({required final  List<String> schemes, this.credentials}): _schemes = schemes;
  factory _PushNotificationAuthenticationInfo.fromJson(Map<String, dynamic> json) => _$PushNotificationAuthenticationInfoFromJson(json);

/// A list of supported authentication schemes (e.g., 'Basic', 'Bearer').
 final  List<String> _schemes;
/// A list of supported authentication schemes (e.g., 'Basic', 'Bearer').
@override List<String> get schemes {
  if (_schemes is EqualUnmodifiableListView) return _schemes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_schemes);
}

/// Optional credentials required by the push notification endpoint.
@override final  String? credentials;

/// Create a copy of PushNotificationAuthenticationInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushNotificationAuthenticationInfoCopyWith<_PushNotificationAuthenticationInfo> get copyWith => __$PushNotificationAuthenticationInfoCopyWithImpl<_PushNotificationAuthenticationInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushNotificationAuthenticationInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushNotificationAuthenticationInfo&&const DeepCollectionEquality().equals(other._schemes, _schemes)&&(identical(other.credentials, credentials) || other.credentials == credentials));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_schemes),credentials);

@override
String toString() {
  return 'PushNotificationAuthenticationInfo(schemes: $schemes, credentials: $credentials)';
}


}

/// @nodoc
abstract mixin class _$PushNotificationAuthenticationInfoCopyWith<$Res> implements $PushNotificationAuthenticationInfoCopyWith<$Res> {
  factory _$PushNotificationAuthenticationInfoCopyWith(_PushNotificationAuthenticationInfo value, $Res Function(_PushNotificationAuthenticationInfo) _then) = __$PushNotificationAuthenticationInfoCopyWithImpl;
@override @useResult
$Res call({
 List<String> schemes, String? credentials
});




}
/// @nodoc
class __$PushNotificationAuthenticationInfoCopyWithImpl<$Res>
    implements _$PushNotificationAuthenticationInfoCopyWith<$Res> {
  __$PushNotificationAuthenticationInfoCopyWithImpl(this._self, this._then);

  final _PushNotificationAuthenticationInfo _self;
  final $Res Function(_PushNotificationAuthenticationInfo) _then;

/// Create a copy of PushNotificationAuthenticationInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemes = null,Object? credentials = freezed,}) {
  return _then(_PushNotificationAuthenticationInfo(
schemes: null == schemes ? _self._schemes : schemes // ignore: cast_nullable_to_non_nullable
as List<String>,credentials: freezed == credentials ? _self.credentials : credentials // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TaskPushNotificationConfig {

/// The unique identifier (e.g. UUID) of the task.
 String get taskId;/// The push notification configuration for this task.
 PushNotificationConfig get pushNotificationConfig;
/// Create a copy of TaskPushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskPushNotificationConfigCopyWith<TaskPushNotificationConfig> get copyWith => _$TaskPushNotificationConfigCopyWithImpl<TaskPushNotificationConfig>(this as TaskPushNotificationConfig, _$identity);

  /// Serializes this TaskPushNotificationConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskPushNotificationConfig&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.pushNotificationConfig, pushNotificationConfig) || other.pushNotificationConfig == pushNotificationConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,pushNotificationConfig);

@override
String toString() {
  return 'TaskPushNotificationConfig(taskId: $taskId, pushNotificationConfig: $pushNotificationConfig)';
}


}

/// @nodoc
abstract mixin class $TaskPushNotificationConfigCopyWith<$Res>  {
  factory $TaskPushNotificationConfigCopyWith(TaskPushNotificationConfig value, $Res Function(TaskPushNotificationConfig) _then) = _$TaskPushNotificationConfigCopyWithImpl;
@useResult
$Res call({
 String taskId, PushNotificationConfig pushNotificationConfig
});


$PushNotificationConfigCopyWith<$Res> get pushNotificationConfig;

}
/// @nodoc
class _$TaskPushNotificationConfigCopyWithImpl<$Res>
    implements $TaskPushNotificationConfigCopyWith<$Res> {
  _$TaskPushNotificationConfigCopyWithImpl(this._self, this._then);

  final TaskPushNotificationConfig _self;
  final $Res Function(TaskPushNotificationConfig) _then;

/// Create a copy of TaskPushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? pushNotificationConfig = null,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,pushNotificationConfig: null == pushNotificationConfig ? _self.pushNotificationConfig : pushNotificationConfig // ignore: cast_nullable_to_non_nullable
as PushNotificationConfig,
  ));
}
/// Create a copy of TaskPushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PushNotificationConfigCopyWith<$Res> get pushNotificationConfig {
  
  return $PushNotificationConfigCopyWith<$Res>(_self.pushNotificationConfig, (value) {
    return _then(_self.copyWith(pushNotificationConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [TaskPushNotificationConfig].
extension TaskPushNotificationConfigPatterns on TaskPushNotificationConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskPushNotificationConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskPushNotificationConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskPushNotificationConfig value)  $default,){
final _that = this;
switch (_that) {
case _TaskPushNotificationConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskPushNotificationConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TaskPushNotificationConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  PushNotificationConfig pushNotificationConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskPushNotificationConfig() when $default != null:
return $default(_that.taskId,_that.pushNotificationConfig);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  PushNotificationConfig pushNotificationConfig)  $default,) {final _that = this;
switch (_that) {
case _TaskPushNotificationConfig():
return $default(_that.taskId,_that.pushNotificationConfig);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  PushNotificationConfig pushNotificationConfig)?  $default,) {final _that = this;
switch (_that) {
case _TaskPushNotificationConfig() when $default != null:
return $default(_that.taskId,_that.pushNotificationConfig);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskPushNotificationConfig implements TaskPushNotificationConfig {
  const _TaskPushNotificationConfig({required this.taskId, required this.pushNotificationConfig});
  factory _TaskPushNotificationConfig.fromJson(Map<String, dynamic> json) => _$TaskPushNotificationConfigFromJson(json);

/// The unique identifier (e.g. UUID) of the task.
@override final  String taskId;
/// The push notification configuration for this task.
@override final  PushNotificationConfig pushNotificationConfig;

/// Create a copy of TaskPushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskPushNotificationConfigCopyWith<_TaskPushNotificationConfig> get copyWith => __$TaskPushNotificationConfigCopyWithImpl<_TaskPushNotificationConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskPushNotificationConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskPushNotificationConfig&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.pushNotificationConfig, pushNotificationConfig) || other.pushNotificationConfig == pushNotificationConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,pushNotificationConfig);

@override
String toString() {
  return 'TaskPushNotificationConfig(taskId: $taskId, pushNotificationConfig: $pushNotificationConfig)';
}


}

/// @nodoc
abstract mixin class _$TaskPushNotificationConfigCopyWith<$Res> implements $TaskPushNotificationConfigCopyWith<$Res> {
  factory _$TaskPushNotificationConfigCopyWith(_TaskPushNotificationConfig value, $Res Function(_TaskPushNotificationConfig) _then) = __$TaskPushNotificationConfigCopyWithImpl;
@override @useResult
$Res call({
 String taskId, PushNotificationConfig pushNotificationConfig
});


@override $PushNotificationConfigCopyWith<$Res> get pushNotificationConfig;

}
/// @nodoc
class __$TaskPushNotificationConfigCopyWithImpl<$Res>
    implements _$TaskPushNotificationConfigCopyWith<$Res> {
  __$TaskPushNotificationConfigCopyWithImpl(this._self, this._then);

  final _TaskPushNotificationConfig _self;
  final $Res Function(_TaskPushNotificationConfig) _then;

/// Create a copy of TaskPushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? pushNotificationConfig = null,}) {
  return _then(_TaskPushNotificationConfig(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,pushNotificationConfig: null == pushNotificationConfig ? _self.pushNotificationConfig : pushNotificationConfig // ignore: cast_nullable_to_non_nullable
as PushNotificationConfig,
  ));
}

/// Create a copy of TaskPushNotificationConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PushNotificationConfigCopyWith<$Res> get pushNotificationConfig {
  
  return $PushNotificationConfigCopyWith<$Res>(_self.pushNotificationConfig, (value) {
    return _then(_self.copyWith(pushNotificationConfig: value));
  });
}
}

// dart format on
