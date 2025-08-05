// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

Future<void> scrollToBottom(ScrollController controller) async {
  await controller.animateTo(
    controller.position.maxScrollExtent,
    duration: const Duration(milliseconds: 600),
    curve: Curves.fastOutSlowIn,
  );
}
