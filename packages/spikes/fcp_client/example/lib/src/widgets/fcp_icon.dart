// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class FcpIcon extends StatelessWidget {
  const FcpIcon({super.key, required this.properties});

  final Map<String, Object?> properties;

  @override
  Widget build(BuildContext context) {
    return Icon(_iconData(properties['icon'] as String?));
  }

  IconData _iconData(String? iconName) {
    switch (iconName) {
      case 'add':
        return Icons.add;
      case 'remove':
        return Icons.remove;
      default:
        return Icons.error;
    }
  }
}
