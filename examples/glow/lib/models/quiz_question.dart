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

enum QuestionType {
  singleChoiceImage,
  multipleChoiceImage,
  singleChoiceText,
  multipleChoiceText,
  slider,
  toggle,
  dropdown,
  textInputShort,
  textInputLong,
}

class QuizOption {
  final String id;
  final String label;
  final String? imageSeed;

  QuizOption({required this.id, required this.label, this.imageSeed});
}

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<QuizOption>? options;
  final double? min;
  final double? max;
  final int? divisions;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.min,
    this.max,
    this.divisions,
  });
}

final List<QuizQuestion> demoQuestions = [
  QuizQuestion(
    id: 'q1',
    text: "What atmosphere resonates with you?",
    type: QuestionType.singleChoiceImage,
    options: [
      QuizOption(id: '1', label: 'Ethereal Dream', imageSeed: 'galaxy'),
      QuizOption(id: '2', label: 'Urban Nightlife', imageSeed: 'city'),
      QuizOption(id: '3', label: 'Cozy Cabin', imageSeed: 'cabin'),
      QuizOption(id: '4', label: 'Digital Zen', imageSeed: 'geometric'),
      QuizOption(id: '5', label: 'Retro Neon', imageSeed: 'neon'),
      QuizOption(id: '6', label: 'Sunlit Garden', imageSeed: 'flowers'),
    ],
  ),
  QuizQuestion(
    id: 'q2',
    text: "How much energy do you want in your design?",
    type: QuestionType.slider,
    min: 0,
    max: 100,
    divisions: 10,
  ),
  QuizQuestion(
    id: 'q3',
    text: "Pick a primary color palette.",
    type: QuestionType.singleChoiceText,
    options: [
      QuizOption(id: 'warm', label: 'Warm (Red, Orange, Yellow)'),
      QuizOption(id: 'cool', label: 'Cool (Blue, Green, Purple)'),
      QuizOption(id: 'mono', label: 'Monochrome (Black, White, Grey)'),
    ],
  ),
  QuizQuestion(
    id: 'q4',
    text: "Enable dark mode optimization?",
    type: QuestionType.toggle,
  ),
  QuizQuestion(
    id: 'q5',
    text: "Select your art style.",
    type: QuestionType.dropdown,
    options: [
      QuizOption(id: 'real', label: 'Photorealistic'),
      QuizOption(id: 'abstr', label: 'Abstract'),
      QuizOption(id: 'illus', label: 'Illustration'),
      QuizOption(id: '3d', label: '3D Render'),
    ],
  ),
  QuizQuestion(
    id: 'q6',
    text: "Describe your dream wallpaper in a few words.",
    type: QuestionType.textInputLong,
  ),
];
