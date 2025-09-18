// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

MarkdownStyleSheet getMarkdownStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  return MarkdownStyleSheet.fromTheme(
    theme,
  ).copyWith(p: theme.textTheme.bodyMedium);
}
