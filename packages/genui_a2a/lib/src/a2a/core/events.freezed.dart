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
Event _$EventFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'status-update':
          return StatusUpdate.fromJson(
            json
          );
                case 'task-status-update':
          return TaskStatusUpdate.fromJson(
            json
          );
                case 'artifact-update':
          return ArtifactUpdate.fromJson(
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

/// The type of this event, always 'status-update'.
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StatusUpdate value)?  statusUpdate,TResult Function( TaskStatusUpdate value)?  taskStatusUpdate,TResult Function( ArtifactUpdate value)?  artifactUpdate,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that);case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that);case ArtifactUpdate() when artifactUpdate != null:
return artifactUpdate(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StatusUpdate value)  statusUpdate,required TResult Function( TaskStatusUpdate value)  taskStatusUpdate,required TResult Function( ArtifactUpdate value)  artifactUpdate,}){
final _that = this;
switch (_that) {
case StatusUpdate():
return statusUpdate(_that);case TaskStatusUpdate():
return taskStatusUpdate(_that);case ArtifactUpdate():
return artifactUpdate(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StatusUpdate value)?  statusUpdate,TResult? Function( TaskStatusUpdate value)?  taskStatusUpdate,TResult? Function( ArtifactUpdate value)?  artifactUpdate,}){
final _that = this;
switch (_that) {
case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that);case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that);case ArtifactUpdate() when artifactUpdate != null:
return artifactUpdate(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status, @JsonKey(name: 'final')  bool final_)?  statusUpdate,TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status, @JsonKey(name: 'final')  bool final_)?  taskStatusUpdate,TResult Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)?  artifactUpdate,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case ArtifactUpdate() when artifactUpdate != null:
return artifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status, @JsonKey(name: 'final')  bool final_)  statusUpdate,required TResult Function( String kind,  String taskId,  String contextId,  TaskStatus status, @JsonKey(name: 'final')  bool final_)  taskStatusUpdate,required TResult Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)  artifactUpdate,}) {final _that = this;
switch (_that) {
case StatusUpdate():
return statusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskStatusUpdate():
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case ArtifactUpdate():
return artifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String kind,  String taskId,  String contextId,  TaskStatus status, @JsonKey(name: 'final')  bool final_)?  statusUpdate,TResult? Function( String kind,  String taskId,  String contextId,  TaskStatus status, @JsonKey(name: 'final')  bool final_)?  taskStatusUpdate,TResult? Function( String kind,  String taskId,  String contextId,  Artifact artifact,  bool append,  bool lastChunk)?  artifactUpdate,}) {final _that = this;
switch (_that) {
case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case TaskStatusUpdate() when taskStatusUpdate != null:
return taskStatusUpdate(_that.kind,_that.taskId,_that.contextId,_that.status,_that.final_);case ArtifactUpdate() when artifactUpdate != null:
return artifactUpdate(_that.kind,_that.taskId,_that.contextId,_that.artifact,_that.append,_that.lastChunk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class StatusUpdate implements Event {
  const StatusUpdate({this.kind = 'status-update', required this.taskId, required this.contextId, required this.status, @JsonKey(name: 'final') this.final_ = false});
  factory StatusUpdate.fromJson(Map<String, dynamic> json) => _$StatusUpdateFromJson(json);

/// The type of this event, always 'status-update'.
@override@JsonKey() final  String kind;
/// The unique ID of the updated task.
@override final  String taskId;
/// The unique context ID for the task.
@override final  String contextId;
/// The new status of the task.
 final  TaskStatus status;
/// If `true`, this is the final event for this task stream.
@JsonKey(name: 'final') final  bool final_;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusUpdateCopyWith<StatusUpdate> get copyWith => _$StatusUpdateCopyWithImpl<StatusUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatusUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusUpdate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.status, status) || other.status == status)&&(identical(other.final_, final_) || other.final_ == final_));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId,status,final_);

@override
String toString() {
  return 'Event.statusUpdate(kind: $kind, taskId: $taskId, contextId: $contextId, status: $status, final_: $final_)';
}


}

/// @nodoc
abstract mixin class $StatusUpdateCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory $StatusUpdateCopyWith(StatusUpdate value, $Res Function(StatusUpdate) _then) = _$StatusUpdateCopyWithImpl;
@override @useResult
$Res call({
 String kind, String taskId, String contextId, TaskStatus status,@JsonKey(name: 'final') bool final_
});


$TaskStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$StatusUpdateCopyWithImpl<$Res>
    implements $StatusUpdateCopyWith<$Res> {
  _$StatusUpdateCopyWithImpl(this._self, this._then);

  final StatusUpdate _self;
  final $Res Function(StatusUpdate) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,Object? status = null,Object? final_ = null,}) {
  return _then(StatusUpdate(
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

class TaskStatusUpdate implements Event {
  const TaskStatusUpdate({this.kind = 'task-status-update', required this.taskId, required this.contextId, required this.status, @JsonKey(name: 'final') this.final_ = false});
  factory TaskStatusUpdate.fromJson(Map<String, dynamic> json) => _$TaskStatusUpdateFromJson(json);

/// The type of this event, always 'task-status-update'.
@override@JsonKey() final  String kind;
/// The unique ID of the updated task.
@override final  String taskId;
/// The unique context ID for the task.
@override final  String contextId;
/// The new status of the task.
 final  TaskStatus status;
/// If `true`, this is the final event for this task stream.
@JsonKey(name: 'final') final  bool final_;

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
 String kind, String taskId, String contextId, TaskStatus status,@JsonKey(name: 'final') bool final_
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

class ArtifactUpdate implements Event {
  const ArtifactUpdate({this.kind = 'artifact-update', required this.taskId, required this.contextId, required this.artifact, required this.append, required this.lastChunk});
  factory ArtifactUpdate.fromJson(Map<String, dynamic> json) => _$ArtifactUpdateFromJson(json);

/// The type of this event, always 'task-artifact-update'.
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
$ArtifactUpdateCopyWith<ArtifactUpdate> get copyWith => _$ArtifactUpdateCopyWithImpl<ArtifactUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtifactUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtifactUpdate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.contextId, contextId) || other.contextId == contextId)&&(identical(other.artifact, artifact) || other.artifact == artifact)&&(identical(other.append, append) || other.append == append)&&(identical(other.lastChunk, lastChunk) || other.lastChunk == lastChunk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,taskId,contextId,artifact,append,lastChunk);

@override
String toString() {
  return 'Event.artifactUpdate(kind: $kind, taskId: $taskId, contextId: $contextId, artifact: $artifact, append: $append, lastChunk: $lastChunk)';
}


}

/// @nodoc
abstract mixin class $ArtifactUpdateCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory $ArtifactUpdateCopyWith(ArtifactUpdate value, $Res Function(ArtifactUpdate) _then) = _$ArtifactUpdateCopyWithImpl;
@override @useResult
$Res call({
 String kind, String taskId, String contextId, Artifact artifact, bool append, bool lastChunk
});


$ArtifactCopyWith<$Res> get artifact;

}
/// @nodoc
class _$ArtifactUpdateCopyWithImpl<$Res>
    implements $ArtifactUpdateCopyWith<$Res> {
  _$ArtifactUpdateCopyWithImpl(this._self, this._then);

  final ArtifactUpdate _self;
  final $Res Function(ArtifactUpdate) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? taskId = null,Object? contextId = null,Object? artifact = null,Object? append = null,Object? lastChunk = null,}) {
  return _then(ArtifactUpdate(
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
