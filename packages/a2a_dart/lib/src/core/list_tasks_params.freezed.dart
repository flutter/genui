// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_tasks_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListTasksParams {

/// Optional. Filter tasks to only include those belonging to this specific
/// context ID (e.g., a conversation or session).
 String? get contextId;/// Optional. Filter tasks by their current [TaskState].
 TaskState? get status;/// The maximum number of tasks to return in a single response.
///
/// Must be between 1 and 100, inclusive. Defaults to 50.
 int get pageSize;/// An opaque token used to retrieve the next page of results.
///
/// This should be the value of `nextPageToken` from a previous
/// [ListTasksResult]. If omitted, the first page is returned.
 String? get pageToken;/// The number of recent messages to include in each task's history.
///
/// Must be non-negative. Defaults to 0 (no history included).
 int get historyLength;/// Optional. Filter tasks to include only those updated at or after this
/// timestamp (in milliseconds since the Unix epoch).
 int? get lastUpdatedAfter;/// Whether to include associated artifacts in the returned tasks.
///
/// Defaults to `false` to minimize payload size. Set to `true` to retrieve
/// artifacts.
 bool get includeArtifacts;/// Optional. Request-specific metadata for extensions or custom use cases.
 Map<String, Object?>? get metadata;
/// Create a copy of ListTasksParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListTasksParamsCopyWith<ListTasksParams> get copyWith => _$ListTasksParamsCopyWithImpl<ListTasksParams>(this as ListTasksParams, _$identity);

  /// Serializes this ListTasksParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListTasksParams&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.status, status) || other.status == status)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.pageToken, pageToken) || other.pageToken == pageToken)&&(identical(other.historyLength, historyLength) || other.historyLength == historyLength)&&(identical(other.lastUpdatedAfter, lastUpdatedAfter) || other.lastUpdatedAfter == lastUpdatedAfter)&&(identical(other.includeArtifacts, includeArtifacts) || other.includeArtifacts == includeArtifacts)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contextId,status,pageSize,pageToken,historyLength,lastUpdatedAfter,includeArtifacts,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ListTasksParams(contextId: $contextId, status: $status, pageSize: $pageSize, pageToken: $pageToken, historyLength: $historyLength, lastUpdatedAfter: $lastUpdatedAfter, includeArtifacts: $includeArtifacts, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ListTasksParamsCopyWith<$Res>  {
  factory $ListTasksParamsCopyWith(ListTasksParams value, $Res Function(ListTasksParams) _then) = _$ListTasksParamsCopyWithImpl;
@useResult
$Res call({
 String? contextId, TaskState? status, int pageSize, String? pageToken, int historyLength, int? lastUpdatedAfter, bool includeArtifacts, Map<String, Object?>? metadata
});




}
/// @nodoc
class _$ListTasksParamsCopyWithImpl<$Res>
    implements $ListTasksParamsCopyWith<$Res> {
  _$ListTasksParamsCopyWithImpl(this._self, this._then);

  final ListTasksParams _self;
  final $Res Function(ListTasksParams) _then;

/// Create a copy of ListTasksParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contextId = freezed,Object? status = freezed,Object? pageSize = null,Object? pageToken = freezed,Object? historyLength = null,Object? lastUpdatedAfter = freezed,Object? includeArtifacts = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
contextId: freezed == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskState?,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,pageToken: freezed == pageToken ? _self.pageToken : pageToken // ignore: cast_nullable_to_non_nullable
as String?,historyLength: null == historyLength ? _self.historyLength : historyLength // ignore: cast_nullable_to_non_nullable
as int,lastUpdatedAfter: freezed == lastUpdatedAfter ? _self.lastUpdatedAfter : lastUpdatedAfter // ignore: cast_nullable_to_non_nullable
as int?,includeArtifacts: null == includeArtifacts ? _self.includeArtifacts : includeArtifacts // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ListTasksParams].
extension ListTasksParamsPatterns on ListTasksParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListTasksParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListTasksParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListTasksParams value)  $default,){
final _that = this;
switch (_that) {
case _ListTasksParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListTasksParams value)?  $default,){
final _that = this;
switch (_that) {
case _ListTasksParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? contextId,  TaskState? status,  int pageSize,  String? pageToken,  int historyLength,  int? lastUpdatedAfter,  bool includeArtifacts,  Map<String, Object?>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListTasksParams() when $default != null:
return $default(_that.contextId,_that.status,_that.pageSize,_that.pageToken,_that.historyLength,_that.lastUpdatedAfter,_that.includeArtifacts,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? contextId,  TaskState? status,  int pageSize,  String? pageToken,  int historyLength,  int? lastUpdatedAfter,  bool includeArtifacts,  Map<String, Object?>? metadata)  $default,) {final _that = this;
switch (_that) {
case _ListTasksParams():
return $default(_that.contextId,_that.status,_that.pageSize,_that.pageToken,_that.historyLength,_that.lastUpdatedAfter,_that.includeArtifacts,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? contextId,  TaskState? status,  int pageSize,  String? pageToken,  int historyLength,  int? lastUpdatedAfter,  bool includeArtifacts,  Map<String, Object?>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _ListTasksParams() when $default != null:
return $default(_that.contextId,_that.status,_that.pageSize,_that.pageToken,_that.historyLength,_that.lastUpdatedAfter,_that.includeArtifacts,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListTasksParams implements ListTasksParams {
  const _ListTasksParams({this.contextId, this.status, this.pageSize = 50, this.pageToken, this.historyLength = 0, this.lastUpdatedAfter, this.includeArtifacts = false, final  Map<String, Object?>? metadata}): _metadata = metadata;
  factory _ListTasksParams.fromJson(Map<String, dynamic> json) => _$ListTasksParamsFromJson(json);

/// Optional. Filter tasks to only include those belonging to this specific
/// context ID (e.g., a conversation or session).
@override final  String? contextId;
/// Optional. Filter tasks by their current [TaskState].
@override final  TaskState? status;
/// The maximum number of tasks to return in a single response.
///
/// Must be between 1 and 100, inclusive. Defaults to 50.
@override@JsonKey() final  int pageSize;
/// An opaque token used to retrieve the next page of results.
///
/// This should be the value of `nextPageToken` from a previous
/// [ListTasksResult]. If omitted, the first page is returned.
@override final  String? pageToken;
/// The number of recent messages to include in each task's history.
///
/// Must be non-negative. Defaults to 0 (no history included).
@override@JsonKey() final  int historyLength;
/// Optional. Filter tasks to include only those updated at or after this
/// timestamp (in milliseconds since the Unix epoch).
@override final  int? lastUpdatedAfter;
/// Whether to include associated artifacts in the returned tasks.
///
/// Defaults to `false` to minimize payload size. Set to `true` to retrieve
/// artifacts.
@override@JsonKey() final  bool includeArtifacts;
/// Optional. Request-specific metadata for extensions or custom use cases.
 final  Map<String, Object?>? _metadata;
/// Optional. Request-specific metadata for extensions or custom use cases.
@override Map<String, Object?>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ListTasksParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListTasksParamsCopyWith<_ListTasksParams> get copyWith => __$ListTasksParamsCopyWithImpl<_ListTasksParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListTasksParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListTasksParams&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.status, status) || other.status == status)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.pageToken, pageToken) || other.pageToken == pageToken)&&(identical(other.historyLength, historyLength) || other.historyLength == historyLength)&&(identical(other.lastUpdatedAfter, lastUpdatedAfter) || other.lastUpdatedAfter == lastUpdatedAfter)&&(identical(other.includeArtifacts, includeArtifacts) || other.includeArtifacts == includeArtifacts)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contextId,status,pageSize,pageToken,historyLength,lastUpdatedAfter,includeArtifacts,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ListTasksParams(contextId: $contextId, status: $status, pageSize: $pageSize, pageToken: $pageToken, historyLength: $historyLength, lastUpdatedAfter: $lastUpdatedAfter, includeArtifacts: $includeArtifacts, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ListTasksParamsCopyWith<$Res> implements $ListTasksParamsCopyWith<$Res> {
  factory _$ListTasksParamsCopyWith(_ListTasksParams value, $Res Function(_ListTasksParams) _then) = __$ListTasksParamsCopyWithImpl;
@override @useResult
$Res call({
 String? contextId, TaskState? status, int pageSize, String? pageToken, int historyLength, int? lastUpdatedAfter, bool includeArtifacts, Map<String, Object?>? metadata
});




}
/// @nodoc
class __$ListTasksParamsCopyWithImpl<$Res>
    implements _$ListTasksParamsCopyWith<$Res> {
  __$ListTasksParamsCopyWithImpl(this._self, this._then);

  final _ListTasksParams _self;
  final $Res Function(_ListTasksParams) _then;

/// Create a copy of ListTasksParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contextId = freezed,Object? status = freezed,Object? pageSize = null,Object? pageToken = freezed,Object? historyLength = null,Object? lastUpdatedAfter = freezed,Object? includeArtifacts = null,Object? metadata = freezed,}) {
  return _then(_ListTasksParams(
contextId: freezed == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskState?,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,pageToken: freezed == pageToken ? _self.pageToken : pageToken // ignore: cast_nullable_to_non_nullable
as String?,historyLength: null == historyLength ? _self.historyLength : historyLength // ignore: cast_nullable_to_non_nullable
as int,lastUpdatedAfter: freezed == lastUpdatedAfter ? _self.lastUpdatedAfter : lastUpdatedAfter // ignore: cast_nullable_to_non_nullable
as int?,includeArtifacts: null == includeArtifacts ? _self.includeArtifacts : includeArtifacts // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

// dart format on
