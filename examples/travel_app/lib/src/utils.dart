// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class MarkdownWidget extends StatelessWidget {
  const MarkdownWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    return GptMarkdownTheme(
      gptThemeData: GptMarkdownThemeData(
        brightness: theme.brightness,
        highlightColor: theme.colorScheme.onSurfaceVariant.withAlpha(50),
        h1: textTheme.headlineLarge,
        h2: textTheme.headlineMedium,
        h3: textTheme.headlineSmall,
        h4: textTheme.titleLarge,
        h5: textTheme.titleMedium,
        h6: textTheme.titleSmall,
        hrLineThickness: 1,
        hrLineColor: theme.colorScheme.outline,
        linkColor: Colors.blue,
        linkHoverColor: Colors.red,
      ),
      child: GptMarkdown(text),
    );
  }
}
