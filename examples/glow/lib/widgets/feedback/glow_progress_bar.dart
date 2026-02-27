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

/// A gradient progress bar with a glowing effect, used across the app to show progress.
class GlowProgressBar extends StatelessWidget {
  /// The current progress value (0.0 to 1.0).
  final double progress;

  /// Optional animation controller to drive the progress bar.
  /// If provided, [progress] is ignored.
  final AnimationController? controller;

  /// Colors for the gradient. Defaults to brand colors.
  final List<Color>? colors;

  /// Height of the progress bar.
  final double height;

  const GlowProgressBar({
    super.key,
    this.progress = 0.0,
    this.controller,
    this.colors,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, child) => _buildBar(context, controller!.value),
      );
    }
    return _buildBar(context, progress);
  }

  Widget _buildBar(BuildContext context, double value) {
    return Stack(
      children: [
        // Background track
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: GlowTheme.colors.outline,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        // Progress track
        Container(
          height: height,
          width: MediaQuery.of(context).size.width * value,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              colors:
                  colors ??
                  [GlowTheme.colors.brandPurple, GlowTheme.colors.brandCyan],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: GlowTheme.colors.primary.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
