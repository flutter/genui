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

/// The main brand logo for Glow.
///
/// Shows a glowing circle with a smaller inner circle and the "Glow" text.
/// Supports an [isTablet] mode for larger sizing and alignment adjustments.
class GlowLogo extends StatelessWidget {
  /// Whether to use tablet-specific sizing and alignment.
  final bool isTablet;

  const GlowLogo({super.key, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isTablet
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: isTablet ? 80 : 60,
          height: isTablet ? 80 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GlowTheme.colors.brandBlue,
                GlowTheme.colors.brandPurple,
                GlowTheme.colors.brandOrange,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Thickness of the ring
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlowTheme.colors.white, // Inner white cutout
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GlowTheme.colors.logoStart,
                    GlowTheme.colors.logoEnd,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: isTablet ? 20 : 15,
                  height: isTablet ? 20 : 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GlowTheme.colors.glowTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Text
        const GlowLogoText(),
      ],
    );
  }
}

/// A text-only version of the Glow logo with a gradient mask and glow effects.
class GlowLogoText extends StatelessWidget {
  /// Optional font size. If null, uses theme defaults.
  final double? fontSize;

  /// Whether to show the logo glow effect.
  final bool showGlow;

  const GlowLogoText({super.key, this.fontSize, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          GlowTheme.gradients.brand.createShader(bounds),
      child: Text(
        "Glow",
        style: TextStyle(
          fontSize: fontSize ?? 64,
          fontWeight: FontWeight.bold,
          color: GlowTheme.colors.white,
          shadows: showGlow ? GlowTheme.shadows.logoGlow : null,
        ),
      ),
    );
  }
}
