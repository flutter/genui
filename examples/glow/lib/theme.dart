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

class GlowTheme {
  static const colors = GlowColors();
  static const textStyles = GlowTextStyles();
  static const gradients = GlowGradients();
  static const shadows = GlowShadows();

  static const double opacityLow = 0.2;
  static const double opacityMedium = 0.3;
  static const double opacityHigh = 0.4;
}

class GlowColors {
  const GlowColors();

  // Brand Colors
  final Color deepPurple = const Color(0xFF2A1A3F);
  final Color orangeGlow = const Color(0xFFD96C3A);
  final Color purpleAccent = const Color(0xFF9A75E6);
  final Color peach = const Color(0xFFF4B097);
  final Color blue = const Color(0xFF448AFF);
  final Color lightPurple = const Color(0xFFA682FF);
  final Color lightOrange = const Color(0xFFFF8A65);

  // Backgrounds
  final Color darkBackground = const Color(0xFF121225);
  final Color dropdownBackground = const Color(0xFF1E1E2E);
  final Color lightBackgroundStart = const Color(0xFFF5F7FA);
  final Color lightBackgroundEnd = const Color(0xFFFFF3E0);
  final Color logoLightStart = const Color(0xFFF0F4FF);
  final Color logoLightEnd = const Color(0xFFFFF0EE);

  // Accents
  final Color cyanAccent = Colors.cyanAccent;
  final Color blueAccent = Colors.blueAccent;
  final Color orangeAccent = Colors.orangeAccent;

  // Basic Colors
  final Color white = Colors.white;
  final Color white10 = Colors.white10;
  final Color white24 = Colors.white24;
  final Color white30 = Colors.white30;
  final Color white54 = Colors.white54;
  final Color white70 = Colors.white70;

  final Color black = Colors.black;
  final Color black87 = Colors.black87;
  final Color black54 = Colors.black54;

  final Color transparent = Colors.transparent;
  final Color grey = Colors.grey;
  final Color grey200 = const Color(0xFFEEEEEE);

  // Extended Accents
  final Color purple = Colors.purple;
  final Color teal = Colors.teal;
  final Color pinkAccent = Colors.pinkAccent;
  final Color cyan = Colors.cyan;

  // Text
  final Color textDark = Colors.black87;
  final Color textLight = Colors.white;
  final Color textLight70 = Colors.white70;
  final Color textLight54 = Colors.white54;
  final Color textLight30 = Colors.white30;

  // Semantic Tokens
  Color get background => darkBackground;
  Color get surface => dropdownBackground;

  Color get onBackground => white;
  Color get onBackgroundSecondary => white70;
  Color get onBackgroundTertiary => white54;
  Color get onBackgroundDisabled => white30;

  Color get onSurface => black87;
  Color get onSurfaceSecondary => black54;

  Color get primary => cyanAccent;
  Color get onPrimary => black87;

  Color get secondary => purpleAccent;
  Color get tertiary => orangeAccent;

  Color get outline => white10;
  Color get outlineMedium => onBackground.withValues(alpha: 0.2);
  Color get outlineStrong => white24;
  Color get outlineVariant => grey200;

  Color get scrim => black.withValues(alpha: 0.3);
  Color get surfaceVariant => const Color(0xFF1E293B).withValues(alpha: 0.6);

  Color get logoStart => logoLightStart;
  Color get logoEnd => logoLightEnd;

  Color get dimmer => black.withValues(alpha: 0.2);
  Color get surfaceScrim => black.withValues(alpha: 0.9);

  // Brand Semantic Tokens
  Color get brandBlue => blueAccent;
  Color get brandPurple => purpleAccent;
  Color get brandOrange => orangeAccent;
  Color get brandCyan => cyanAccent;
  Color get brandBlueMaterial => Colors.blue;

  // Surface Opacities
  Color get surfacePrimary => primary.withValues(alpha: 0.15);
  Color get surfacePrimaryLow => primary.withValues(alpha: 0.2);
  Color get surfaceContainerLow => onBackground.withValues(alpha: 0.05);
  Color get surfaceContainer => onBackground.withValues(alpha: 0.1);
  Color get surfaceContainerHigh => onBackground.withValues(alpha: 0.3);

  // Glows & Shadows
  Color get glowPrimary => primary.withValues(alpha: 0.2);
  Color get glowPrimaryStrong => primary.withValues(alpha: 0.4);
  Color get glowSecondary => secondary.withValues(alpha: 0.4);
  Color get glowTertiary => tertiary.withValues(alpha: 0.5);
  Color get glowTertiaryStrong => tertiary.withValues(alpha: 0.6);

  // Text & Icons
  Color get textMedium => onBackground.withValues(alpha: 0.6);
  Color get iconStrong => onBackground.withValues(alpha: 0.8);

  // Waves
  Color get waveTertiary => tertiary.withValues(alpha: 0.2);
  Color get wavePrimary => primary.withValues(alpha: 0.15);
  Color get waveTertiaryWeak => tertiary.withValues(alpha: 0.1);
}

class GlowTextStyles {
  const GlowTextStyles();

  TextStyle get logo =>
      const TextStyle(fontWeight: FontWeight.bold, color: Colors.white);

  TextStyle get titleLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  TextStyle get titleMedium => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  TextStyle get bodyLarge => const TextStyle(fontSize: 18, color: Colors.white);

  TextStyle get bodyMedium =>
      const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5);

  TextStyle get bodySmall =>
      const TextStyle(fontSize: 14, color: Colors.white54);

  // Light Theme Text Styles
  TextStyle get lightTitleLarge => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  TextStyle get lightBodyLarge =>
      const TextStyle(fontSize: 18, height: 1.6, color: Colors.black87);

  TextStyle get lightBodyMedium =>
      const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87);
}

class GlowGradients {
  const GlowGradients();

  LinearGradient get logoMask => const LinearGradient(
    colors: [Colors.white, Color(0xFFF4B097)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  LinearGradient get brand => const LinearGradient(
    colors: [
      Color(0xFF448AFF), // Blue
      Color(0xFFA682FF), // Purple
      Color(0xFFFF8A65), // Orange/Peach
    ],
  );

  LinearGradient get quizProgressBar =>
      const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]);

  LinearGradient get glassButton => LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.15),
      Colors.white.withValues(alpha: 0.05),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  LinearGradient get backgroundLight => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5F7FA),
      Colors.white,
      Color(0xFFFFF3E0),
      Color(0xFFF5F7FA),
    ],
  );

  LinearGradient get backgroundDark => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // Deep Blue/Black
      Color(0xFF312E81), // Indigo
      Color(0xFF059669), // Emerald tint
      Color(0xFF0F172A),
    ],
  );
}

class GlowShadows {
  const GlowShadows();

  List<Shadow> get logoGlow => [
    const Shadow(color: Color(0xAAFFA726), blurRadius: 15.0),
  ];

  List<Shadow> get textGlow => [
    const Shadow(color: Color(0xFFD96C3A), blurRadius: 20.0),
  ];

  List<Shadow> get neonBlue => [
    const Shadow(color: Colors.cyan, blurRadius: 25),
    const Shadow(color: Colors.blue, blurRadius: 45),
  ];
}
