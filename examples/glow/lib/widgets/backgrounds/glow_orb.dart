// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:glow/theme.dart';

/// A glowing orb widget used for creating ambient background effects.
class GlowOrb extends StatelessWidget {
  /// The base color of the orb.
  final Color color;

  /// The diameter of the orb.
  final double size;

  /// Optional opacity for the orb's core.
  final double? opacity;

  const GlowOrb({
    super.key,
    required this.color,
    required this.size,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity ?? GlowTheme.opacityMedium),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: GlowTheme.opacityHigh),
            blurRadius: size / 4,
            spreadRadius: size / 20,
          ),
        ],
      ),
    );
  }
}
