// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF386641);
const Color backgroundLight = Color(0xFFF6F8F6);
const Color backgroundDark = Color(0xFF152111);
const Color textLight = Color(0xFF131711);
const Color textDark = Color(0xFFF6F8F6);
const Color accentColor = Color(0xFFB84749);

// Button color: rgb(56, 102, 65)
// Also text foreground color on light background.
const Color buttonColor = Color(0xFF386641);

final ThemeData baseTheme = ThemeData(
  fontFamily: 'SpaceGrotesk',
  primaryColor: primaryColor,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
  ),
  cardTheme: CardThemeData(
    margin: const EdgeInsets.all(4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

final ElevatedButtonThemeData lightElevatedButtonTheme =
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
    );

final ElevatedButtonThemeData darkElevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    backgroundColor: Colors.white,
    foregroundColor: buttonColor,
  ),
);

final ThemeData lightTheme = baseTheme.copyWith(
  scaffoldBackgroundColor: backgroundLight,
  textTheme: ThemeData.light().textTheme.copyWith(
    bodyLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    bodyMedium: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    bodySmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    titleLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    titleMedium: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    titleSmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    labelLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    labelMedium: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    labelSmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    displayLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    displayMedium: const TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: textLight,
    ),
    displaySmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textLight),
    headlineLarge: const TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: textLight,
    ),
    headlineMedium: const TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: textLight,
    ),
    headlineSmall: const TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: textLight,
    ),
  ),
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        surface: Colors.white,
        onPrimary: Colors.white,
        secondary: accentColor,
      ),
  elevatedButtonTheme: lightElevatedButtonTheme,
);

final ThemeData darkTheme = baseTheme.copyWith(
  textTheme: ThemeData.dark().textTheme.copyWith(
    bodyLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    bodyMedium: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    bodySmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    titleLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    titleMedium: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    titleSmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    labelLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    labelMedium: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    labelSmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    displayLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    displayMedium: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    displaySmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    headlineLarge: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
    headlineMedium: const TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: textDark,
    ),
    headlineSmall: const TextStyle(fontFamily: 'SpaceGrotesk', color: textDark),
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  ).copyWith(surface: backgroundDark, secondary: accentColor),
  elevatedButtonTheme: darkElevatedButtonTheme,
);
