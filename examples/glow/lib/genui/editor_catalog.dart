// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:glow/theme.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:glow/widgets/inputs/glow_inputs.dart'; // Reusing Glow inputs

/// Catalog definition for dynamic Editor Controls
final editorCatalogItems = [editorControlItem];
final editorCatalog = Catalog(editorCatalogItems);

enum ControlType { slider, toggle, dropdown }

// Schema for an Editor Control
final editorControlSchema = S.object(
  properties: {
    'id': S.string(),
    'label': S.string(),
    'type': S.string(
      enumValues: ControlType.values.map((e) => e.name).toList(),
    ),
    'min': S.number(),
    'max': S.number(),
    'defaultValue': S.any(),
    'options': S.list(
      // For dropdown
      items: S.string(),
    ),
  },
  required: ['id', 'label', 'type'],
);

final editorControlItem = CatalogItem(
  name: 'EditorControl',
  dataSchema: editorControlSchema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, dynamic>;
    final id = data['id'] as String;
    final label = data['label'] as String;
    final typeStr = data['type'] as String;
    final type = ControlType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ControlType.slider,
    );

    // We need to access the EditorViewModel to read/write values.
    // We will use the QuizAnswerHandler pattern (renamed effectively to ControlHandler)
    // or just look up the handler we injected in the screen.
    return _DynamicEditorControl(
      id: id,
      label: label,
      type: type,
      min: (data['min'] as num?)?.toDouble() ?? 0.0,
      max: (data['max'] as num?)?.toDouble() ?? 100.0,
      defaultValue: data['defaultValue'],
      options: (data['options'] as List?)?.cast<String>(),
    );
  },
);

class _DynamicEditorControl extends StatelessWidget {
  final String id;
  final String label;
  final ControlType type;
  final double min;
  final double max;
  final dynamic defaultValue;
  final List<String>? options;

  const _DynamicEditorControl({
    required this.id,
    required this.label,
    required this.type,
    this.min = 0,
    this.max = 100,
    this.defaultValue,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    // We expect an ancestor that implements a handler interface
    // reusing the QuizAnswerHandler for simplicity as it matches the signature (id, value)
    // We can rename/alias it if needed, but for now we essentially need "Get" and "Set".
    // Let's assume the scoped handler uses the same interface class but semantically it's for editor.
    final handler = _EditorControlHandler.of(context);

    final currentValue = handler?.getValue(id) ?? defaultValue;

    switch (type) {
      case ControlType.slider:
        final double val = (currentValue is num)
            ? currentValue.toDouble()
            : min;
        return GlowSlider(
          label: label,
          value: val,
          min: min,
          max: max,
          onChanged: (v) => handler?.setValue(id, v),
        );
      case ControlType.toggle:
        final bool val = (currentValue is bool) ? currentValue : false;
        return GlowToggle(
          title: label,
          value: val,
          onChanged: (v) => handler?.setValue(id, v),
        );
      case ControlType.dropdown:
        final String? val = (currentValue is String)
            ? currentValue
            : options?.firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GlowTheme.textStyles.bodyMedium),
            const SizedBox(height: 8),
            GlowDropdown(
              value: val,
              items: (options ?? [])
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => handler?.setValue(id, v),
            ),
          ],
        );
    }
  }
}

// Specialized Handler Interface for Editor
abstract class EditorControlHandler {
  void setValue(String id, dynamic value);
  dynamic getValue(String id);
}

class _EditorControlHandler extends InheritedWidget {
  final EditorControlHandler handler;

  const _EditorControlHandler({required this.handler, required super.child});

  static EditorControlHandler? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_EditorControlHandler>()
        ?.handler;
  }

  @override
  bool updateShouldNotify(_EditorControlHandler oldWidget) => false;
}

// Public wrapper for the screen to use
class EditorControlScope extends StatelessWidget {
  final EditorControlHandler handler;
  final Widget child;
  const EditorControlScope({
    super.key,
    required this.handler,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _EditorControlHandler(handler: handler, child: child);
  }
}
