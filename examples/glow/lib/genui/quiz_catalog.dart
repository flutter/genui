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
import 'package:glow/models/quiz_question.dart';
import 'package:glow/widgets/quiz/quiz_choice_inputs.dart';
import 'package:glow/widgets/inputs/glow_inputs.dart';

final quizCatalogItems = [quizQuestionItem];
final quizCatalog = Catalog(quizCatalogItems);

final quizQuestionSchema = S.object(
  properties: {
    'id': S.string(),
    'text': S.string(),
    'type': S.string(
      enumValues: QuestionType.values.map((e) => e.name).toList(),
    ),
    'options': S.list(
      items: S.object(
        properties: {
          'id': S.string(),
          'label': S.string(),
          'imageSeed': S.string(),
        },
        required: ['id', 'label'],
      ),
    ),
    'min': S.number(),
    'max': S.number(),
    'divisions': S.integer(),
  },
  required: ['id', 'text', 'type'],
);

final quizQuestionItem = CatalogItem(
  name: 'QuizQuestion',
  dataSchema: quizQuestionSchema,
  widgetBuilder: (context) {
    final data = context.data as Map<String, dynamic>;
    final id = data['id'] as String;
    final text = data['text'] as String;
    final typeStr = data['type'] as String;
    final type = QuestionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => QuestionType.singleChoiceText,
    );

    final optionsList = (data['options'] as List<dynamic>?)?.map((e) {
      final map = e as Map<String, dynamic>;
      return QuizOption(
        id: map['id'],
        label: map['label'],
        imageSeed: map['imageSeed'],
      );
    }).toList();

    // We need a way to access the view model or data model to store answers.
    // In GenUI, we usually bind to data.
    // But here we are building a specific quiz flow where we want to capture the answer.
    // The simple way is to use a callback or find the ancestor.
    // Since we can't easily pass the VM here without context, we'll use `context.dataContext` if we were doing pure GenUI data binding.
    // BUT, our plan handles answers in `QuizViewModel`.
    // We can use a `GenUiSurface`'s interaction event to send data back.
    // Or we can simple emit a custom event.
    // For now, let's assume we can find the `QuizViewModel` via `Provider` or `context`?
    // No, `QuizViewModel` is passed to `QuizScreen`.
    // Let's rely on standard Flutter widget tree access if we put `QuizViewModel` in a `Provider` or `ListenableBuilder`.
    // Or better: `GenUiSurface` allows `actions`.

    // Simplification: We will just build the UI. User interaction updates the LOCAL state of the widget (if needed) or trigger events.
    // The `QuizScreen` wraps this surface.
    // Wait, the `widgetBuilder` runs inside `GenUiSurface`.
    // We need to capture the answer.

    // Let's use a `GlobalKey` or similar? No.
    // Let's use `top-level` event handler?
    // Actually, `GenUi` encourages data binding. `context.data` is arguments.
    // We need to OUTPUT data.
    // We can use `context.dataContext.update(...)` if we bind.

    // Alternative: The `QuizQuestion` widget we build here should be capable of communicating answer back.
    // Let's create a `DynamicQuizQuestion` widget that finds the `QuizViewModel` via `InheritedWidget` or similar.
    // Or just pass a callback? We can't pass callbacks from `CatalogItem` easily.

    return _DynamicQuizQuestion(
      id: id,
      text: text,
      type: type,
      options: optionsList,
      min: data['min'] as double?,
      max: data['max'] as double?,
      divisions: data['divisions'] as int?,
    );
  },
);

class _DynamicQuizQuestion extends StatelessWidget {
  final String id;
  final String text;
  final QuestionType type;
  final List<QuizOption>? options;
  final double? min;
  final double? max;
  final int? divisions;

  const _DynamicQuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.min,
    this.max,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    // We need to perform "answer handling".
    // We can bubble up an event or use a locally scoped provider.
    // Let's use a specialized InheritedWidget in QuizScreen to expose the callback.
    final handler = QuizAnswerHandler.of(context);

    // Helper for checking selection
    bool isSelected(String optId) => handler?.isSelected(id, optId) ?? false;
    // Helper for handling selection
    void onSelect(dynamic val) => handler?.apiSetAnswer(id, val);

    Widget inputBody;
    switch (type) {
      case QuestionType.singleChoiceImage:
      case QuestionType.multipleChoiceImage:
        inputBody = GlowImageGridSelector(
          options: options ?? [],
          isSelected: isSelected,
          onToggle: (optId) => _handleMultiSelect(handler, id, optId, type),
        );
        break;
      case QuestionType.singleChoiceText:
      case QuestionType.multipleChoiceText:
        inputBody = GlowTextChoiceSelector(
          options: options ?? [],
          isSelected: isSelected,
          onToggle: (optId) => _handleMultiSelect(handler, id, optId, type),
        );
        break;
      case QuestionType.slider:
        final currentVal =
            (handler?.getAnswer(id) as num?)?.toDouble() ?? min ?? 0;
        inputBody = GlowSlider(
          value: currentVal,
          min: min ?? 0,
          max: max ?? 100,
          divisions: divisions,
          onChanged: (val) => onSelect(val),
          label: "${currentVal.round()}%",
        );
        break;
      case QuestionType.toggle:
        final val = (handler?.getAnswer(id) as bool?) ?? false;
        inputBody = GlowToggle(
          value: val,
          title: "Select",
          onChanged: (v) => onSelect(v),
        );
        break;
      case QuestionType.dropdown:
        final val = handler?.getAnswer(id) as String?;
        inputBody = GlowDropdown(
          value: val,
          items: (options ?? [])
              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.label)))
              .toList(),
          onChanged: (v) => onSelect(v),
        );
        break;
      case QuestionType.textInputShort:
      case QuestionType.textInputLong:
        // Text fields need state management or controller.
        // For simplicity, we just use onChanged.
        // In a real app, restore text from handler.
        inputBody = GlowTextField(
          isLong: type == QuestionType.textInputLong,
          onChanged: (v) => onSelect(v),
          // controller can be set if we tracked it
        );
        break;
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: GlowTheme.colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        inputBody,
      ],
    );
  }

  void _handleMultiSelect(
    QuizAnswerHandler? handler,
    String qId,
    String optId,
    QuestionType type,
  ) {
    if (handler == null) return;
    final isMulti =
        type == QuestionType.multipleChoiceImage ||
        type == QuestionType.multipleChoiceText;

    if (isMulti) {
      final current = List<String>.from(handler.getAnswer(qId) as List? ?? []);
      if (current.contains(optId)) {
        current.remove(optId);
      } else {
        current.add(optId);
      }
      handler.apiSetAnswer(qId, current);
    } else {
      handler.apiSetAnswer(qId, optId);
    }
  }
}

// InheritedWidget to pass down the handler
abstract class QuizAnswerHandler {
  void apiSetAnswer(String qId, dynamic value);
  dynamic getAnswer(String qId);
  bool isSelected(String qId, String optId);

  static QuizAnswerHandler? of(BuildContext context) {
    return context
        .findAncestorWidgetOfExactType<_QuizAnswerHandlerScope>()
        ?.handler;
  }
}

class QuizAnswerHandlerScope extends StatelessWidget {
  final QuizAnswerHandler handler;
  final Widget child;

  const QuizAnswerHandlerScope({
    super.key,
    required this.handler,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _QuizAnswerHandlerScope(handler: handler, child: child);
  }
}

class _QuizAnswerHandlerScope extends InheritedWidget {
  final QuizAnswerHandler handler;

  const _QuizAnswerHandlerScope({required this.handler, required super.child});

  @override
  bool updateShouldNotify(_QuizAnswerHandlerScope oldWidget) => false;
}
