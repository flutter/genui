// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A message in the chat history.
class ChatMessage {
  /// Creates a [ChatMessage].
  const ChatMessage({required this.text, required this.isUser});

  /// The text of the message.
  final String text;

  /// Whether the message is from the user.
  final bool isUser;
}
