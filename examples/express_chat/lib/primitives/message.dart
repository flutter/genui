// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:genui/genui.dart';

class Message {
  Message({this.text, this.surfaceId, this.isUser = false})
    : assert((surfaceId == null) != (text == null));

  String? text;
  final String? surfaceId;
  final bool isUser;
}

class MessageView extends StatelessWidget {
  const MessageView(this.message, this.host, {super.key});

  final Message message;

  /// The surface host used to render generative UI surfaces. Required only
  /// when [Message.surfaceId] is non-null.
  final SurfaceHost? host;

  @override
  Widget build(BuildContext context) {
    final String? surfaceId = message.surfaceId;

    if (surfaceId == null) {
      if (message.isUser) {
        return Text(message.text ?? '');
      } else {
        return MarkdownBody(data: message.text ?? '');
      }
    }

    final SurfaceHost? host = this.host;
    if (host == null) {
      return Text('Error: Missing SurfaceHost for surface $surfaceId');
    }
    return Surface(surfaceContext: host.contextFor(surfaceId));
  }
}
