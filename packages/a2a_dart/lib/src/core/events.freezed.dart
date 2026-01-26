// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
StreamingEvent _$StreamingEventFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'task_status_update':
          return TaskStatusUpdateEvent.fromJson(
            json
          );
                case 'task_artifact_update':
          return TaskArtifactUpdateEvent.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'StreamingEvent',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$StreamingEvent {

/// The type of this event, always 'task_status_update'.
 String get kind;/// The unique ID of the updated task.
 String get taskId;/// The unique context ID for the task.
 String get contextId;
/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamingEventCopyWith<StreamingEvent> get copyWith => _$StreamingEventCopyWithImpl<StreamingEvent>(this as StreamingEvent, _$identity);

  /// Serializes this StreamingEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamingEvent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId);

@override
String toString() {
  return 'StreamingEvent(kind: $kind, taskId: $taskId, contextId: $contextId)';
}


}

/// @nodoc
abstract mixin class $StreamingEventCopyWith<$Res>  {
  factory $StreamingEventCopyWith(StreamingEvent value, $Res Function(StreamingEvent) _then) = _$StreamingEventCopyWithImpl;
@useResult
$Res call({
 String kind, String taskId, String contextId
});




}
/// @nodoc
class _$StreamingEventCopyWithImpl<$Res>
    implements $StreamingEventCopyWith<$Res> {
  _$StreamingEventCopyWithImpl(this._self, this._then);

  final StreamingEvent _self;
  final $Res Function(StreamingEvent) _then;

/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,contextId: null == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamingEvent].
extension StreamingEventPatterns on StreamingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskStatusUpdateEvent value)?  taskStatusUpdate,TResult Function( TaskArtifactUpdateEvent value)?  taskArtifactUpdate,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskStatusUpdateEvent() when taskStatusUpdate != null:
return taskStatusUpdate(_that);case TaskArtifactUpdateEvent() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskStatusUpdateEvent value)  taskStatusUpdate,required TResult Function( TaskArtifactUpdateEvent value)  taskArtifactUpdate,}){
final _that = this;
switch (_that) {
case TaskStatusUpdateEvent():
return taskStatusUpdate(_that);case TaskArtifactUpdateEvent():
return taskArtifactUpdate(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskStatusUpdateEvent value)?  taskStatusUpdate,TResult? Function( TaskArtifactUpdateEvent value)?  taskArtifactUpdate,}){
final _that = this;
switch (_that) {
case TaskStatusUpdateEvent() when taskStatusUpdate != null:
return taskStatusUpdate(_that);case TaskArtifactUpdateEvent() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status,  bool final_)?  taskStatusUpdate,TResult Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)?  taskArtifactUpdate,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskStatusUpdateEvent() when taskStatusUpdate != null:
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskArtifactUpdateEvent() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status,  bool final_)  taskStatusUpdate,required TResult Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)  taskArtifactUpdate,}) {final _that = this;
switch (_that) {
case TaskStatusUpdateEvent():
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskArtifactUpdateEvent():
return taskArtifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String kind,  String taskId,  String contextId,  TaskStatus status,  bool final_)?  taskStatusUpdate,TResult? Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)?  taskArtifactUpdate,}) {final _that = this;
switch (_that) {
case TaskStatusUpdateEvent() when taskStatusUpdate != null:
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskArtifactUpdateEvent() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TaskStatusUpdateEvent implements StreamingEvent {
  const TaskStatusUpdateEvent({this.kind = 'task_status_update', required this.taskId, required this.contextId, required this.status, required this.final_});
  factory TaskStatusUpdateEvent.fromJson(Map<String, dynamic> json) => _$TaskStatusUpdateEventFromJson(json);

/// The type of this event, always 'task_status_update'.
@override@JsonKey() final  String kind;
/// The unique ID of the updated task.
@override final  String taskId;
/// The unique context ID for the task.
@override final  String contextId;
/// The new status of the task.
 final  TaskStatus status;
/// If `true`, this is the final event for this task stream.
 final  bool final_;

/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStatusUpdateEventCopyWith<TaskStatusUpdateEvent> get copyWith => _$TaskStatusUpdateEventCopyWithImpl<TaskStatusUpdateEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskStatusUpdateEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskStatusUpdateEvent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.status, status) || other.status == status)&&(identical(other.final_, final_) || other.final_ == final_));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId,status,final_);

@override
String toString() {
  return 'StreamingEvent.taskStatusUpdate(kind: $kind, taskId: $taskId, contextId: $contextId, status: $status, final_: $final_)';
}


}

/// @nodoc
abstract mixin class $TaskStatusUpdateEventCopyWith<$Res> implements $StreamingEventCopyWith<$Res> {
  factory $TaskStatusUpdateEventCopyWith(TaskStatusUpdateEvent value, $Res Function(TaskStatusUpdateEvent) _then) = _$TaskStatusUpdateEventCopyWithImpl;
@override @useResult
$Res call({
 String kind, String taskId, String contextId, TaskStatus status, bool final_
});


$TaskStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$TaskStatusUpdateEventCopyWithImpl<$Res>
    implements $TaskStatusUpdateEventCopyWith<$Res> {
  _$TaskStatusUpdateEventCopyWithImpl(this._self, this._then);

  final TaskStatusUpdateEvent _self;
  final $Res Function(TaskStatusUpdateEvent) _then;

/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,Object? status = null,Object? final_ = null,}) {
  return _then(TaskStatusUpdateEvent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,contextId: null == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,final_: null == final_ ? _self.final_ : final_ // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskStatusCopyWith<$Res> get status {
  
  return $TaskStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class TaskArtifactUpdateEvent implements StreamingEvent {
  const TaskArtifactUpdateEvent({this.kind = 'task_artifact_update', required this.taskId, required this.contextId, required this.artifact, required this.append, required this.lastChunk});
  factory TaskArtifactUpdateEvent.fromJson(Map<String, dynamic> json) => _$TaskArtifactUpdateEventFromJson(json);

/// The type of this event, always 'task_artifact_update'.
@override@JsonKey() final  String kind;
/// The unique ID of the task this artifact belongs to.
@override final  String taskId;
/// The unique context ID for the task.
@override final  String contextId;
/// The artifact data.
 final  Artifact artifact;
/// If `true`, this artifact's content should be appended to any previous
/// content for the same `artifact.artifactId`.
 final  bool append;
/// If `true`, this is the last chunk of data for this artifact.
 final  bool lastChunk;

/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskArtifactUpdateEventCopyWith<TaskArtifactUpdateEvent> get copyWith => _$TaskArtifactUpdateEventCopyWithImpl<TaskArtifactUpdateEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskArtifactUpdateEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskArtifactUpdateEvent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.artifact, artifact) || other.artifact == artifact)&&(identical(other.append, append) || other.append == append)&&(identical(other.lastChunk, lastChunk) || other.lastChunk == lastChunk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId,artifact,append,lastChunk);

@override
String toString() {
  return 'StreamingEvent.taskArtifactUpdate(kind: $kind, taskId: $taskId, contextId: $contextId, artifact: $artifact, append: $append, lastChunk: $lastChunk)';
}


}

/// @nodoc
abstract mixin class $TaskArtifactUpdateEventCopyWith<$Res> implements $StreamingEventCopyWith<$Res> {
  factory $TaskArtifactUpdateEventCopyWith(TaskArtifactUpdateEvent value, $Res Function(TaskArtifactUpdateEvent) _then) = _$TaskArtifactUpdateEventCopyWithImpl;
@override @useResult
$Res call({
 String kind, String taskId, String contextId, Artifact artifact, bool append, bool lastChunk
});


$ArtifactCopyWith<$Res> get artifact;

}
/// @nodoc
class _$TaskArtifactUpdateEventCopyWithImpl<$Res>
    implements $TaskArtifactUpdateEventCopyWith<$Res> {
  _$TaskArtifactUpdateEventCopyWithImpl(this._self, this._then);

  final TaskArtifactUpdateEvent _self;
  final $Res Function(TaskArtifactUpdateEvent) _then;

/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,Object? artifact = null,Object? append = null,Object? lastChunk = null,}) {
  return _then(TaskArtifactUpdateEvent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,contextId: null == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String,artifact: null == artifact ? _self.artifact : artifact // ignore: cast_nullable_to_non_nullable
as Artifact,append: null == append ? _self.append : append // ignore: cast_nullable_to_non_nullable
as bool,lastChunk: null == lastChunk ? _self.lastChunk : lastChunk // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of StreamingEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtifactCopyWith<$Res> get artifact {
  
  return $ArtifactCopyWith<$Res>(_self.artifact, (value) {
    return _then(_self.copyWith(artifact: value));
  });
}
}

Event _$EventFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'task_status_update':
          return TaskStatusUpdate.fromJson(
            json
          );
                case 'task_artifact_update':
          return TaskArtifactUpdate.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'Event',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$Event {

/// The type of this event, always 'task_status_update'.
 String get kind;/// The unique ID of the updated task.
 String get taskId;/// The unique context ID for the task.
 String get contextId;
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCopyWith<Event> get copyWith => _$EventCopyWithImpl<Event>(this as Event, _$identity);

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Event&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId);

@override
String toString() {
  return 'Event(kind: $kind, taskId: $taskId, contextId: $contextId)';
}


}

/// @nodoc
abstract mixin class $EventCopyWith<$Res>  {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) = _$EventCopyWithImpl;
@useResult
$Res call({
 String kind, String taskId, String contextId
});




}
/// @nodoc
class _$EventCopyWithImpl<$Res>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,contextId: null == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Event].
extension EventPatterns on Event {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskStatusUpdate value)?  taskStatusUpdate,TResult Function( TaskArtifactUpdate value)?  taskArtifactUpdate,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that);case TaskArtifactUpdate() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskStatusUpdate value)  taskStatusUpdate,required TResult Function( TaskArtifactUpdate value)  taskArtifactUpdate,}){
final _that = this;
switch (_that) {
case TaskStatusUpdate():
return taskStatusUpdate(_that);case TaskArtifactUpdate():
return taskArtifactUpdate(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskStatusUpdate value)?  taskStatusUpdate,TResult? Function( TaskArtifactUpdate value)?  taskArtifactUpdate,}){
final _that = this;
switch (_that) {
case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that);case TaskArtifactUpdate() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status,  bool final_)?  taskStatusUpdate,TResult Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)?  taskArtifactUpdate,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskArtifactUpdate() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status,  bool final_)  taskStatusUpdate,required TResult Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)  taskArtifactUpdate,}) {final _that = this;
switch (_that) {
case TaskStatusUpdate():
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskArtifactUpdate():
return taskArtifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String kind,  String taskId,  String contextId,  TaskStatus status,  bool final_)?  taskStatusUpdate,TResult? Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)?  taskArtifactUpdate,}) {final _that = this;
switch (_that) {
case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskArtifactUpdate() when taskArtifactUpdate != null:
return taskArtifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TaskStatusUpdate implements Event {
  const TaskStatusUpdate({this.kind = 'task_status_update', required this.taskId, required this.contextId, required this.status, required this.final_});
  factory TaskStatusUpdate.fromJson(Map<String, dynamic> json) => _$TaskStatusUpdateFromJson(json);

/// The type of this event, always 'task_status_update'.
@override@JsonKey() final  String kind;
/// The unique ID of the updated task.
@override final  String taskId;
/// The unique context ID for the task.
@override final  String contextId;
/// The new status of the task.
 final  TaskStatus status;
/// If `true`, this is the final event for this task stream.
 final  bool final_;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStatusUpdateCopyWith<TaskStatusUpdate> get copyWith => _$TaskStatusUpdateCopyWithImpl<TaskStatusUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskStatusUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskStatusUpdate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.status, status) || other.status == status)&&(identical(other.final_, final_) || other.final_ == final_));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId,status,final_);

@override
String toString() {
  return 'Event.taskStatusUpdate(kind: $kind, taskId: $taskId, contextId: $contextId, status: $status, final_: $final_)';
}


}

/// @nodoc
abstract mixin class $TaskStatusUpdateCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory $TaskStatusUpdateCopyWith(TaskStatusUpdate value, $Res Function(TaskStatusUpdate) _then) = _$TaskStatusUpdateCopyWithImpl;
@override @useResult
$Res call({
 String kind, String taskId, String contextId, TaskStatus status, bool final_
});


$TaskStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$TaskStatusUpdateCopyWithImpl<$Res>
    implements $TaskStatusUpdateCopyWith<$Res> {
  _$TaskStatusUpdateCopyWithImpl(this._self, this._then);

  final TaskStatusUpdate _self;
  final $Res Function(TaskStatusUpdate) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,Object? status = null,Object? final_ = null,}) {
  return _then(TaskStatusUpdate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,contextId: null == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,final_: null == final_ ? _self.final_ : final_ // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskStatusCopyWith<$Res> get status {
  
  return $TaskStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class TaskArtifactUpdate implements Event {
  const TaskArtifactUpdate({this.kind = 'task_artifact_update', required this.taskId, required this.contextId, required this.artifact, required this.append, required this.lastChunk});
  factory TaskArtifactUpdate.fromJson(Map<String, dynamic> json) => _$TaskArtifactUpdateFromJson(json);

/// The type of this event, always 'task_artifact_update'.
@override@JsonKey() final  String kind;
/// The unique ID of the task this artifact belongs to.
@override final  String taskId;
/// The unique context ID for the task.
@override final  String contextId;
/// The artifact data.
 final  Artifact artifact;
/// If `true`, this artifact's content should be appended to any previous
/// content for the same `artifact.artifactId`.
 final  bool append;
/// If `true`, this is the last chunk of data for this artifact.
 final  bool lastChunk;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskArtifactUpdateCopyWith<TaskArtifactUpdate> get copyWith => _$TaskArtifactUpdateCopyWithImpl<TaskArtifactUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskArtifactUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskArtifactUpdate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.artifact, artifact) || other.artifact == artifact)&&(identical(other.append, append) || other.append == append)&&(identical(other.lastChunk, lastChunk) || other.lastChunk == lastChunk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId,artifact,append,lastChunk);

@override
String toString() {
  return 'Event.taskArtifactUpdate(kind: $kind, taskId: $taskId, contextId: $contextId, artifact: $artifact, append: $append, lastChunk: $lastChunk)';
}


}

/// @nodoc
abstract mixin class $TaskArtifactUpdateCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory $TaskArtifactUpdateCopyWith(TaskArtifactUpdate value, $Res Function(TaskArtifactUpdate) _then) = _$TaskArtifactUpdateCopyWithImpl;
@override @useResult
$Res call({
 String kind, String taskId, String contextId, Artifact artifact, bool append, bool lastChunk
});


$ArtifactCopyWith<$Res> get artifact;

}
/// @nodoc
class _$TaskArtifactUpdateCopyWithImpl<$Res>
    implements $TaskArtifactUpdateCopyWith<$Res> {
  _$TaskArtifactUpdateCopyWithImpl(this._self, this._then);

  final TaskArtifactUpdate _self;
  final $Res Function(TaskArtifactUpdate) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,Object? artifact = null,Object? append = null,Object? lastChunk = null,}) {
  return _then(TaskArtifactUpdate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,contextId: null == contextId ? _self.contextId : contextId // ignore: cast_nullable_to_non_nullable
as String,artifact: null == artifact ? _self.artifact : artifact // ignore: cast_nullable_to_non_nullable
as Artifact,append: null == append ? _self.append : append // ignore: cast_nullable_to_non_nullable
as bool,lastChunk: null == lastChunk ? _self.lastChunk : lastChunk // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtifactCopyWith<$Res> get artifact {
  
  return $ArtifactCopyWith<$Res>(_self.artifact, (value) {
    return _then(_self.copyWith(artifact: value));
  });
}
}

// dart format on
