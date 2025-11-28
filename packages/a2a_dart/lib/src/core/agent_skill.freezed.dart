// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_skill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentSkill {

/// A unique identifier for the agent's skill (e.g., "weather-forecast").
 String get id;/// A human-readable name for the skill (e.g., "Weather Forecast").
 String get name;/// A detailed description of the skill, intended to help clients or users
/// understand its purpose and functionality.
 String get description;/// A set of keywords describing the skill's capabilities.
 List<String> get tags;/// Example prompts or scenarios that this skill can handle, providing a
/// hint to the client on how to use the skill.
 List<String>? get examples;/// The set of supported input MIME types for this skill, overriding the
/// agent's defaults.
 List<String>? get inputModes;/// The set of supported output MIME types for this skill, overriding the
/// agent's defaults.
 List<String>? get outputModes;/// Security schemes necessary for the agent to leverage this skill.
 List<Map<String, List<String>>>? get security;
/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentSkillCopyWith<AgentSkill> get copyWith => _$AgentSkillCopyWithImpl<AgentSkill>(this as AgentSkill, _$identity);

  /// Serializes this AgentSkill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentSkill&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.examples, examples)&&const DeepCollectionEquality().equals(other.inputModes, inputModes)&&const DeepCollectionEquality().equals(other.outputModes, outputModes)&&const DeepCollectionEquality().equals(other.security, security));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(examples),const DeepCollectionEquality().hash(inputModes),const DeepCollectionEquality().hash(outputModes),const DeepCollectionEquality().hash(security));

@override
String toString() {
  return 'AgentSkill(id: $id, name: $name, description: $description, tags: $tags, examples: $examples, inputModes: $inputModes, outputModes: $outputModes, security: $security)';
}


}

/// @nodoc
abstract mixin class $AgentSkillCopyWith<$Res>  {
  factory $AgentSkillCopyWith(AgentSkill value, $Res Function(AgentSkill) _then) = _$AgentSkillCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, List<String> tags, List<String>? examples, List<String>? inputModes, List<String>? outputModes, List<Map<String, List<String>>>? security
});




}
/// @nodoc
class _$AgentSkillCopyWithImpl<$Res>
    implements $AgentSkillCopyWith<$Res> {
  _$AgentSkillCopyWithImpl(this._self, this._then);

  final AgentSkill _self;
  final $Res Function(AgentSkill) _then;

/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? tags = null,Object? examples = freezed,Object? inputModes = freezed,Object? outputModes = freezed,Object? security = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,examples: freezed == examples ? _self.examples : examples // ignore: cast_nullable_to_non_nullable
as List<String>?,inputModes: freezed == inputModes ? _self.inputModes : inputModes // ignore: cast_nullable_to_non_nullable
as List<String>?,outputModes: freezed == outputModes ? _self.outputModes : outputModes // ignore: cast_nullable_to_non_nullable
as List<String>?,security: freezed == security ? _self.security : security // ignore: cast_nullable_to_non_nullable
as List<Map<String, List<String>>>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentSkill].
extension AgentSkillPatterns on AgentSkill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentSkill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentSkill value)  $default,){
final _that = this;
switch (_that) {
case _AgentSkill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentSkill value)?  $default,){
final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> tags,  List<String>? examples,  List<String>? inputModes,  List<String>? outputModes,  List<Map<String, List<String>>>? security)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.tags,_that.examples,_that.inputModes,_that.outputModes,_that.security);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> tags,  List<String>? examples,  List<String>? inputModes,  List<String>? outputModes,  List<Map<String, List<String>>>? security)  $default,) {final _that = this;
switch (_that) {
case _AgentSkill():
return $default(_that.id,_that.name,_that.description,_that.tags,_that.examples,_that.inputModes,_that.outputModes,_that.security);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  List<String> tags,  List<String>? examples,  List<String>? inputModes,  List<String>? outputModes,  List<Map<String, List<String>>>? security)?  $default,) {final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.tags,_that.examples,_that.inputModes,_that.outputModes,_that.security);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentSkill implements AgentSkill {
  const _AgentSkill({required this.id, required this.name, required this.description, required final  List<String> tags, final  List<String>? examples, final  List<String>? inputModes, final  List<String>? outputModes, final  List<Map<String, List<String>>>? security}): _tags = tags,_examples = examples,_inputModes = inputModes,_outputModes = outputModes,_security = security;
  factory _AgentSkill.fromJson(Map<String, dynamic> json) => _$AgentSkillFromJson(json);

/// A unique identifier for the agent's skill (e.g., "weather-forecast").
@override final  String id;
/// A human-readable name for the skill (e.g., "Weather Forecast").
@override final  String name;
/// A detailed description of the skill, intended to help clients or users
/// understand its purpose and functionality.
@override final  String description;
/// A set of keywords describing the skill's capabilities.
 final  List<String> _tags;
/// A set of keywords describing the skill's capabilities.
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Example prompts or scenarios that this skill can handle, providing a
/// hint to the client on how to use the skill.
 final  List<String>? _examples;
/// Example prompts or scenarios that this skill can handle, providing a
/// hint to the client on how to use the skill.
@override List<String>? get examples {
  final value = _examples;
  if (value == null) return null;
  if (_examples is EqualUnmodifiableListView) return _examples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// The set of supported input MIME types for this skill, overriding the
/// agent's defaults.
 final  List<String>? _inputModes;
/// The set of supported input MIME types for this skill, overriding the
/// agent's defaults.
@override List<String>? get inputModes {
  final value = _inputModes;
  if (value == null) return null;
  if (_inputModes is EqualUnmodifiableListView) return _inputModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// The set of supported output MIME types for this skill, overriding the
/// agent's defaults.
 final  List<String>? _outputModes;
/// The set of supported output MIME types for this skill, overriding the
/// agent's defaults.
@override List<String>? get outputModes {
  final value = _outputModes;
  if (value == null) return null;
  if (_outputModes is EqualUnmodifiableListView) return _outputModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Security schemes necessary for the agent to leverage this skill.
 final  List<Map<String, List<String>>>? _security;
/// Security schemes necessary for the agent to leverage this skill.
@override List<Map<String, List<String>>>? get security {
  final value = _security;
  if (value == null) return null;
  if (_security is EqualUnmodifiableListView) return _security;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentSkillCopyWith<_AgentSkill> get copyWith => __$AgentSkillCopyWithImpl<_AgentSkill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentSkillToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentSkill&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._examples, _examples)&&const DeepCollectionEquality().equals(other._inputModes, _inputModes)&&const DeepCollectionEquality().equals(other._outputModes, _outputModes)&&const DeepCollectionEquality().equals(other._security, _security));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_examples),const DeepCollectionEquality().hash(_inputModes),const DeepCollectionEquality().hash(_outputModes),const DeepCollectionEquality().hash(_security));

@override
String toString() {
  return 'AgentSkill(id: $id, name: $name, description: $description, tags: $tags, examples: $examples, inputModes: $inputModes, outputModes: $outputModes, security: $security)';
}


}

/// @nodoc
abstract mixin class _$AgentSkillCopyWith<$Res> implements $AgentSkillCopyWith<$Res> {
  factory _$AgentSkillCopyWith(_AgentSkill value, $Res Function(_AgentSkill) _then) = __$AgentSkillCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, List<String> tags, List<String>? examples, List<String>? inputModes, List<String>? outputModes, List<Map<String, List<String>>>? security
});




}
/// @nodoc
class __$AgentSkillCopyWithImpl<$Res>
    implements _$AgentSkillCopyWith<$Res> {
  __$AgentSkillCopyWithImpl(this._self, this._then);

  final _AgentSkill _self;
  final $Res Function(_AgentSkill) _then;

/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? tags = null,Object? examples = freezed,Object? inputModes = freezed,Object? outputModes = freezed,Object? security = freezed,}) {
  return _then(_AgentSkill(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,examples: freezed == examples ? _self._examples : examples // ignore: cast_nullable_to_non_nullable
as List<String>?,inputModes: freezed == inputModes ? _self._inputModes : inputModes // ignore: cast_nullable_to_non_nullable
as List<String>?,outputModes: freezed == outputModes ? _self._outputModes : outputModes // ignore: cast_nullable_to_non_nullable
as List<String>?,security: freezed == security ? _self._security : security // ignore: cast_nullable_to_non_nullable
as List<Map<String, List<String>>>?,
  ));
}


}

// dart format on
