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
import 'package:glow/models/quiz_question.dart';
import 'package:glow/widgets/cards/glow_cards.dart';

// --- Reusable Image Grid ---
class GlowImageGrid extends StatelessWidget {
  final List<QuizOption> options;
  final String? selectedId;
  final void Function(String id) onOptionSelected;

  const GlowImageGrid({
    super.key,
    required this.options,
    this.selectedId,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        // We will lift the selection state up.
        // For the static quiz, the parent handles checking selection.
        // For dynamic UI, we'll need a way to checking against DataModel.
        // The most flexible way is to ask the parent "isSelected".
        return GlowQuizImageOption(
          label: option.label,
          imageSeed: option.imageSeed,
          isSelected:
              selectedId ==
              option.id, // Simplification for now, might need list
          onTap: () => onOptionSelected(option.id),
        );
      },
    );
  }
}

// Redefining for flexibility:
class GlowImageGridSelector extends StatelessWidget {
  final List<QuizOption> options;
  final bool Function(String id) isSelected;
  final void Function(String id) onToggle;

  const GlowImageGridSelector({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return GlowQuizImageOption(
          label: option.label,
          imageSeed: option.imageSeed,
          isSelected: isSelected(option.id),
          onTap: () => onToggle(option.id),
        );
      },
    );
  }
}

// --- Reusable Text Choices ---
class GlowTextChoiceSelector extends StatelessWidget {
  final List<QuizOption> options;
  final bool Function(String id) isSelected;
  final void Function(String id) onToggle;

  const GlowTextChoiceSelector({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlowQuizOptionCard(
            label: option.label,
            isSelected: isSelected(option.id),
            onTap: () => onToggle(option.id),
          ),
        );
      }).toList(),
    );
  }
}
