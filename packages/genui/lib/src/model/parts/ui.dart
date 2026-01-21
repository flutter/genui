// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:genai_primitives/genai_primitives.dart';
import '../../primitives/simple_items.dart';
import '../ui_models.dart';

final class _Json {
  static const definition = 'definition';
  static const surfaceId = 'surfaceId';
  static const interaction = 'interaction';
}

/// A part representing a UI definition to be rendered.
@immutable
final class UiPart extends Part {
  static const type = 'Ui';

  /// Creates a UI part.
  UiPart({required this.definition, String? surfaceId})
    : surfaceId = surfaceId ?? generateId(),
      uiKey = UniqueKey();

  /// The JSON definition of the UI.
  final UiDefinition definition;

  /// The unique ID for this UI surface.
  final String surfaceId;

  /// A unique key for the UI widget.
  final Key uiKey;

  /// Creates a UI part from a JSON map.
  factory UiPart.fromJson(Map<String, Object?> json) {
    return UiPart(
      definition: UiDefinition.fromJson(
        json[_Json.definition] as Map<String, Object?>,
      ),
      surfaceId: json[_Json.surfaceId] as String?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.definition: definition.toJson(),
    _Json.surfaceId: surfaceId,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is UiPart &&
        other.definition == definition &&
        other.surfaceId == surfaceId;
  }

  @override
  int get hashCode => Object.hash(definition, surfaceId);
}

/// A part representing a user's interaction with the UI.
@immutable
final class UiInteractionPart extends Part {
  static const type = 'UiInteraction';

  /// Creates a UI interaction part.
  const UiInteractionPart(this.interaction);

  /// The interaction data (JSON string).
  final String interaction;

  /// Creates a UI interaction part from a JSON map.
  factory UiInteractionPart.fromJson(Map<String, Object?> json) {
    return UiInteractionPart(json[_Json.interaction] as String);
  }

  @override
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.interaction: interaction,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is UiInteractionPart && other.interaction == interaction;
  }

  @override
  int get hashCode => interaction.hashCode;

  @override
  String toString() => 'UiInteractionPart(interaction: $interaction)';
}
