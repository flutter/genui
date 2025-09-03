// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

class UiResponse extends StatelessWidget {
  final String surfaceId;
  final GenUiManager manager;
  final void Function(UiEvent) onEvent;

  const UiResponse({
    super.key,
    required this.surfaceId,
    required this.manager,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    return GenUiSurface(
      surfaceId: surfaceId,
      host: manager,
      onEvent: onEvent,
    );
  }
}
