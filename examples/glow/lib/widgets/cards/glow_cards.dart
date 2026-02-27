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

/// A circular feature item with an icon and label, used on the welcome screen.
class GlowFeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;

  const GlowFeatureItem({
    super.key,
    required this.icon,
    required this.label,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GlowTheme.colors.white,
            border: Border.all(
              color: GlowTheme.colors.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: GlowTheme.colors.outline,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ).createShader(bounds),
            child: Icon(icon, size: 36, color: GlowTheme.colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.2,
            color: GlowTheme.colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A text-based option card for quizzes.
class GlowQuizOptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GlowQuizOptionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? GlowTheme.colors.surfacePrimary
              : GlowTheme.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? GlowTheme.colors.primary
                : GlowTheme.colors.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: GlowTheme.colors.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: GlowTheme.colors.primary)
            else
              Icon(
                Icons.circle_outlined,
                color: GlowTheme.colors.outlineStrong,
              ),
          ],
        ),
      ),
    );
  }
}

/// An image-based option card for quizzes.
class GlowQuizImageOption extends StatelessWidget {
  final String label;
  final String? imageSeed;
  final bool isSelected;
  final VoidCallback onTap;

  const GlowQuizImageOption({
    super.key,
    required this.label,
    this.imageSeed,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? GlowTheme.colors.primary
                : GlowTheme.colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GlowTheme.colors.primary,
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : [],
          image: DecorationImage(
            image: NetworkImage(
              "https://picsum.photos/seed/$imageSeed/400/300",
            ),
            fit: BoxFit.cover,
            colorFilter: isSelected
                ? null
                : ColorFilter.mode(GlowTheme.colors.dimmer, BlendMode.darken),
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  GlowTheme.colors.surfaceScrim,
                  GlowTheme.colors.transparent,
                ],
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GlowTheme.colors.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card representing a wallpaper style in the editor.
class GlowStyleCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const GlowStyleCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withValues(alpha: GlowTheme.opacityLow),
                border: isSelected
                    ? Border.all(color: GlowTheme.colors.primary, width: 2)
                    : Border.all(color: GlowTheme.colors.transparent, width: 2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: GlowTheme.colors.glowPrimaryStrong,
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Icon(Icons.wallpaper, color: GlowTheme.colors.iconStrong),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? GlowTheme.colors.primary
                    : GlowTheme.colors.onBackgroundSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A toggle button for enabling/disabling elements in the editor.
class GlowElementToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const GlowElementToggle({
    super.key,
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? GlowTheme.colors.primary
              : GlowTheme.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isActive
              ? GlowTheme.colors.onSurface
              : GlowTheme.colors.onBackgroundTertiary,
        ),
      ),
    );
  }
}
