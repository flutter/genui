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

/// A consistent button for the Glow app supporting multiple styles and loading states.
class GlowButton extends StatelessWidget {
  /// The text to display on the button.
  final String text;

  /// Optional icon to display before the text.
  final IconData? icon;

  /// Callback when the button is pressed.
  final VoidCallback? onTap;

  /// If true, shows a loading indicator instead of the icon/text.
  final bool isLoading;

  /// Whether this is a primary action button (gradient background).
  final bool isPrimary;

  /// Whether this is a glass-style button (translucent).
  final bool isGlass;

  /// Full width button.
  final bool isFullWidth;

  const GlowButton({
    super.key,
    required this.text,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.isPrimary = true,
    this.isGlass = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isLoading || onTap == null) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isFullWidth ? double.infinity : null,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isGlass ? 16 : 30),
          gradient: isPrimary
              ? GlowTheme.gradients.brand
              : (isGlass ? GlowTheme.gradients.glassButton : null),
          color: (!isPrimary && !isGlass)
              ? GlowTheme.colors.surfaceContainer
              : null,
          border: (!isPrimary && !isGlass)
              ? Border.all(color: GlowTheme.colors.outlineStrong)
              : (isGlass ? Border.all(color: GlowTheme.colors.outline) : null),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: GlowTheme.colors.glowSecondary,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isPrimary
                        ? GlowTheme.colors.onPrimary
                        : GlowTheme.colors.onBackground,
                  ),
                )
              else ...[
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isPrimary
                        ? GlowTheme.colors.onPrimary
                        : GlowTheme.colors.onBackground,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isPrimary
                          ? GlowTheme.colors.onPrimary
                          : GlowTheme.colors.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
