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
import 'package:go_router/go_router.dart';
import 'package:glow/theme.dart';
import '../../l10n/app_localizations.dart';

/// A glass-morphic top navigation bar used across different screens.
class GlassTopBar extends StatelessWidget {
  /// Whether to use tablet-optimized layout.
  final bool isTablet;

  /// Callback for the menu/tune button (typically on mobile).
  final VoidCallback? onMenuTap;

  /// Whether the associated settings menu is currently open.
  final bool isMenuOpen;

  /// Title text to display in the center.
  final String? title;

  const GlassTopBar({
    super.key,
    required this.isTablet,
    this.onMenuTap,
    this.isMenuOpen = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 10,
        left: 20,
        right: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: CircleAvatar(
              backgroundColor: GlowTheme.colors.scrim,
              child: Icon(
                Icons.arrow_back,
                color: GlowTheme.colors.onBackground,
              ),
            ),
          ),
          Text(
            title ?? AppLocalizations.of(context)!.myGlowWallpaper,
            style: GlowTheme.textStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: GlowTheme.colors.scrim,
                child: Icon(
                  Icons.ios_share,
                  color: GlowTheme.colors.onBackground,
                ),
              ),
              if (!isTablet) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onMenuTap,
                  child: CircleAvatar(
                    backgroundColor: isMenuOpen
                        ? GlowTheme.colors.primary
                        : GlowTheme.colors.surfacePrimaryLow,
                    child: Icon(
                      Icons.tune,
                      color: isMenuOpen
                          ? GlowTheme.colors.onSurface
                          : GlowTheme.colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
