// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class FcpRow extends StatelessWidget {
  const FcpRow({super.key, required this.properties, required this.children});

  final Map<String, Object?> properties;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(children: children);
  }
}
