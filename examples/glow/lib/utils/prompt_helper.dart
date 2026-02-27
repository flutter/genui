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

import 'package:glow/models/editor_state.dart';

class PromptHelper {
  static String fromQuizAnswers(Map<String, dynamic> answers) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Generate a high quality abstract phone wallpaper based on these preferences:',
    );

    answers.forEach((key, value) {
      if (value is List) {
        buffer.writeln('- $key: ${value.join(", ")}');
      } else {
        buffer.writeln('- $key: $value');
      }
    });

    buffer.writeln(
      '\nThe image should be colorful, vibrant, and suitable for a mobile background.',
    );
    return buffer.toString();
  }

  static String fromEditorState(EditorState state, {String? baseDescription}) {
    final buffer = StringBuffer();
    buffer.writeln('Generate a phone wallpaper.');
    if (baseDescription != null) {
      buffer.writeln('Base concept: $baseDescription');
    }

    // Styles based on index (Mapping valid as of current EditorScreen UI)
    final styles = ['Minimalist', 'Abstract', 'Cyberpunk', 'Nature', 'Retro'];
    final style = state.selectedStyleIndex < styles.length
        ? styles[state.selectedStyleIndex]
        : 'Abstract';

    buffer.writeln('Style: $style');
    buffer.writeln(
      'Atmosphere Intensity: ${state.atmosphereValue.toStringAsFixed(2)}',
    );

    // Interpret atmosphere
    if (state.atmosphereValue < 0.3) {
      buffer.writeln('Mood: Calm, soft, muted colors.');
    } else if (state.atmosphereValue > 0.7) {
      buffer.writeln('Mood: Intense, high contrast, dynamic.');
    } else {
      buffer.writeln('Mood: Balanced, pleasing aesthetics.');
    }

    return buffer.toString();
  }
}
