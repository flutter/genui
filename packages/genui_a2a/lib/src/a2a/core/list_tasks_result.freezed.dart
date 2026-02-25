// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_tasks_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListTasksResult {

/// The list of [Task] objects matching the specified filters and
/// pagination.
 List<Task> get tasks;/// The total number of tasks available on the server that match the filter
/// criteria (ignoring pagination).
 int get totalSize;/// The maximum number of tasks requested per page.
 int get pageSize;/// An opaque token for retrieving the next page of results.
///
/// If this string is empty, there are no more pages.
 String get nextPageToken;
/// Create a copy of ListTasksResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListTasksResultCopyWith<ListTasksResult> get copyWith => _$ListTasksResultCopyWithImpl<ListTasksResult>(this as ListTasksResult, _$identity);

  /// Serializes this ListTasksResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListTasksResult&&const DeepCollectionEquality().equals(other.tasks, tasks)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.nextPageToken, nextPageToken) || other.nextPageToken == nextPageToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tasks),totalSize,pageSize,nextPageToken);

@override
String toString() {
  return 'ListTasksResult(tasks: $tasks, totalSize: $totalSize, pageSize: $pageSize, nextPageToken: $nextPageToken)';
}


}

/// @nodoc
abstract mixin class $ListTasksResultCopyWith<$Res>  {
  factory $ListTasksResultCopyWith(ListTasksResult value, $Res Function(ListTasksResult) _then) = _$ListTasksResultCopyWithImpl;
@useResult
$Res call({
 List<Task> tasks, int totalSize, int pageSize, String nextPageToken
});




}
/// @nodoc
class _$ListTasksResultCopyWithImpl<$Res>
    implements $ListTasksResultCopyWith<$Res> {
  _$ListTasksResultCopyWithImpl(this._self, this._then);

  final ListTasksResult _self;
  final $Res Function(ListTasksResult) _then;

/// Create a copy of ListTasksResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tasks = null,Object? totalSize = null,Object? pageSize = null,Object? nextPageToken = null,}) {
  return _then(_self.copyWith(
tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,nextPageToken: null == nextPageToken ? _self.nextPageToken : nextPageToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ListTasksResult].
extension ListTasksResultPatterns on ListTasksResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListTasksResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListTasksResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListTasksResult value)  $default,){
final _that = this;
switch (_that) {
case _ListTasksResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListTasksResult value)?  $default,){
final _that = this;
switch (_that) {
case _ListTasksResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Task> tasks,  int totalSize,  int pageSize,  String nextPageToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListTasksResult() when $default != null:
return $default(_that.tasks,_that.totalSize,_that.pageSize,_that.nextPageToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Task> tasks,  int totalSize,  int pageSize,  String nextPageToken)  $default,) {final _that = this;
switch (_that) {
case _ListTasksResult():
return $default(_that.tasks,_that.totalSize,_that.pageSize,_that.nextPageToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Task> tasks,  int totalSize,  int pageSize,  String nextPageToken)?  $default,) {final _that = this;
switch (_that) {
case _ListTasksResult() when $default != null:
return $default(_that.tasks,_that.totalSize,_that.pageSize,_that.nextPageToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListTasksResult implements ListTasksResult {
  const _ListTasksResult({required final  List<Task> tasks, required this.totalSize, required this.pageSize, required this.nextPageToken}): _tasks = tasks;
  factory _ListTasksResult.fromJson(Map<String, dynamic> json) => _$ListTasksResultFromJson(json);

/// The list of [Task] objects matching the specified filters and
/// pagination.
 final  List<Task> _tasks;
/// The list of [Task] objects matching the specified filters and
/// pagination.
@override List<Task> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

/// The total number of tasks available on the server that match the filter
/// criteria (ignoring pagination).
@override final  int totalSize;
/// The maximum number of tasks requested per page.
@override final  int pageSize;
/// An opaque token for retrieving the next page of results.
///
/// If this string is empty, there are no more pages.
@override final  String nextPageToken;

/// Create a copy of ListTasksResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListTasksResultCopyWith<_ListTasksResult> get copyWith => __$ListTasksResultCopyWithImpl<_ListTasksResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListTasksResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListTasksResult&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.nextPageToken, nextPageToken) || other.nextPageToken == nextPageToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks),totalSize,pageSize,nextPageToken);

@override
String toString() {
  return 'ListTasksResult(tasks: $tasks, totalSize: $totalSize, pageSize: $pageSize, nextPageToken: $nextPageToken)';
}


}

/// @nodoc
abstract mixin class _$ListTasksResultCopyWith<$Res> implements $ListTasksResultCopyWith<$Res> {
  factory _$ListTasksResultCopyWith(_ListTasksResult value, $Res Function(_ListTasksResult) _then) = __$ListTasksResultCopyWithImpl;
@override @useResult
$Res call({
 List<Task> tasks, int totalSize, int pageSize, String nextPageToken
});




}
/// @nodoc
class __$ListTasksResultCopyWithImpl<$Res>
    implements _$ListTasksResultCopyWith<$Res> {
  __$ListTasksResultCopyWithImpl(this._self, this._then);

  final _ListTasksResult _self;
  final $Res Function(_ListTasksResult) _then;

/// Create a copy of ListTasksResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tasks = null,Object? totalSize = null,Object? pageSize = null,Object? nextPageToken = null,}) {
  return _then(_ListTasksResult(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,nextPageToken: null == nextPageToken ? _self.nextPageToken : nextPageToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
