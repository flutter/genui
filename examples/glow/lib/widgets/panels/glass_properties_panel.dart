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
import 'package:glow/widgets/buttons/glow_button.dart';
import 'package:glow/widgets/cards/glow_cards.dart';
import 'package:glow/widgets/inputs/glow_inputs.dart';
import '../../l10n/app_localizations.dart';

/// A glass-morphic properties panel for editing wallpaper settings.
///
/// Supported on both mobile (as a bottom sheet) and tablet (as a sidebar).
class GlassPropertiesPanel extends StatelessWidget {
  final ScrollController? scrollController;
  final VoidCallback? onClose;
  final int selectedIndex;
  final double atmosphere;
  final ValueChanged<int> onStyleSelected;
  final ValueChanged<double> onAtmosphereChanged;
  final bool showDragHandle;
  final VoidCallback? onRegenerate;
  final bool isRegenerating;
  final Widget? customContent;
  final VoidCallback? onSave;

  const GlassPropertiesPanel({
    super.key,
    this.scrollController,
    this.onClose,
    required this.selectedIndex,
    required this.atmosphere,
    required this.onStyleSelected,
    required this.onAtmosphereChanged,
    this.showDragHandle = true,
    this.onRegenerate,
    this.isRegenerating = false,
    this.customContent,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDragHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GlowTheme.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        if (onClose != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: GlowTheme.colors.onBackgroundSecondary,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                if (customContent != null)
                  customContent!
                else
                  _buildDefaultContent(context),
                const SizedBox(height: 32),
                _buildActions(context),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      customContent != null ? l10n.adjustWallpaper : l10n.wallpaperStyle,
      style: GlowTheme.textStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: GlowButton(
            text: l10n.regenerate,
            icon: Icons.refresh,
            isPrimary: true,
            onTap: onRegenerate,
            isLoading: isRegenerating,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlowButton(
            text: l10n.save,
            icon: Icons.check,
            isPrimary: false,
            onTap: onSave,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Style Thumbnails
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GlowStyleCard(
                label: l10n.styleCosmic,
                isSelected: selectedIndex == 0,
                onTap: () => onStyleSelected(0),
                color: GlowTheme.colors.secondary,
              ),
              GlowStyleCard(
                label: l10n.styleAbstract,
                isSelected: selectedIndex == 1,
                onTap: () => onStyleSelected(1),
                color: GlowTheme.colors.secondary,
              ),
              GlowStyleCard(
                label: l10n.styleNature,
                isSelected: selectedIndex == 2,
                onTap: () => onStyleSelected(2),
                color: GlowTheme.colors.tertiary,
              ),
              GlowStyleCard(
                label: l10n.styleCrystal,
                isSelected: selectedIndex == 3,
                onTap: () => onStyleSelected(3),
                color: GlowTheme.colors.secondary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Atmosphere Slider
        GlowSlider(
          value: atmosphere,
          onChanged: onAtmosphereChanged,
          leftIcon: Icons.wb_sunny_outlined,
          rightIcon: Icons.nightlight_round,
          leftLabel: l10n.atmosphereWarmCalm,
          rightLabel: l10n.atmosphereCoolEnergetic,
          label: l10n.atmosphereLabel,
        ),

        const SizedBox(height: 24),

        // Key Elements (Toggles)
        Text(
          l10n.keyElementLabel,
          style: GlowTheme.textStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            GlowElementToggle(icon: Icons.local_florist, isActive: true),
            GlowElementToggle(icon: Icons.grain, isActive: false),
            GlowElementToggle(icon: Icons.water_drop, isActive: true),
          ],
        ),
      ],
    );
  }
}
