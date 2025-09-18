// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A collection of prompt fragments for use with GenUI.
class GenUiPromptFragments {
  /// A basic chat prompt fragment.
  static const String basicChat = '''

# Outputting UI information

Use the provided tools to respond to the user using rich UI elements.

Important considerations:
- When you are asking for information from the user, you should always include
  at least one submit button of some kind or another submitting element so that
  the user can indicate that they are done providing information.
- After you have modified the UI, be sure to use the provideFinalOutput to give
  control back to the user so they can respond.
''';
}
