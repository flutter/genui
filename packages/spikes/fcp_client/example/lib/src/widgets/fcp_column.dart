// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class FcpColumn extends StatelessWidget {
  const FcpColumn({
    super.key,
    required this.properties,
    required this.children,
  });

  final Map<String, Object?> properties;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final mainAxisAlignment = MainAxisAlignment.values.firstWhere(
      (e) => e.name == properties['mainAxisAlignment'],
      orElse: () => MainAxisAlignment.start,
    );
    final crossAxisAlignment = CrossAxisAlignment.values.firstWhere(
      (e) => e.name == properties['crossAxisAlignment'],
      orElse: () => CrossAxisAlignment.center,
    );
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}
