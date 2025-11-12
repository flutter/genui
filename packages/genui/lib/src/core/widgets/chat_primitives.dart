// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A widget to display an internal message in the chat.
class InternalMessageWidget extends StatelessWidget {
  /// Creates a new [InternalMessageWidget].
  const InternalMessageWidget({super.key, required this.content});

  /// The content of the message.
  final String content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.grey.shade200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Internal message: $content'),
        ),
      ),
    );
  }
}

/// A widget to display a chat message.
class ChatMessageWidget extends StatelessWidget {
  /// Creates a new [ChatMessageWidget].
  const ChatMessageWidget({
    super.key,
    required this.text,
    required this.icon,
    required this.alignment,
  });

  /// The text of the message.
  final String text;

  /// The icon to display next to the message.
  final IconData icon;

  /// The alignment of the message.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == MainAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    alignment == MainAxisAlignment.start ? 5 : 25,
                  ),
                  topRight: Radius.circular(
                    alignment == MainAxisAlignment.start ? 25 : 5,
                  ),
                  bottomLeft: const Radius.circular(25),
                  bottomRight: const Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStart) ...[Icon(icon), const SizedBox(width: 8.0)],
                    Flexible(child: Text(text)),
                    if (!isStart) ...[const SizedBox(width: 8.0), Icon(icon)],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
