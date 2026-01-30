// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

class MessageController {
  MessageController({this.text, this.surfaceId, this.isUser = false})
    : assert((surfaceId == null) != (text == null));

  String? text;
  final String? surfaceId;
  final bool isUser;
}

class MessageView extends StatelessWidget {
  const MessageView(this.controller, this.host, {super.key});

  final MessageController controller;
  final GenUiHost host;

  @override
  Widget build(BuildContext context) {
    final String? surfaceId = controller.surfaceId;

    if (surfaceId == null) return Text(controller.text ?? '');

    return GenUiSurface(host: host, surfaceId: surfaceId);
  }
}
