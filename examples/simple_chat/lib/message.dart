// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

class MessageController {
  MessageController({this.text, this.surfaceId})
    : assert((surfaceId == null) != (text == null));

  final String? text;
  final String? surfaceId;
}

class MessageView extends StatelessWidget {
  const MessageView(
    this.messageController,
    this.surfaceController, {
    super.key,
  });

  final MessageController messageController;
  final SurfaceController? surfaceController;

  @override
  Widget build(BuildContext context) {
    final SurfaceController? controller = surfaceController;

    if (controller == null) return Text(messageController.text ?? '');

    return GenUiSurface(controller: controller);
  }
}
