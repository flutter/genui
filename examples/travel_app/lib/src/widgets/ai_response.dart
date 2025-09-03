// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class AiResponse extends StatelessWidget {
  final String message;

  const AiResponse({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.smart_toy),
      title: Text(message),
    );
  }
}
