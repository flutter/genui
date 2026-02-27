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

/// A themed text field for the Glow design system.
class GlowTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool isLong;
  final ValueChanged<String>? onChanged;

  const GlowTextField({
    super.key,
    this.controller,
    this.hintText,
    this.isLong = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: isLong ? 5 : 1,
      style: TextStyle(color: GlowTheme.colors.onBackground),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: GlowTheme.colors.surfaceContainerLow,
        hintText: hintText ?? "Type your answer here...",
        hintStyle: TextStyle(color: GlowTheme.colors.onBackgroundDisabled),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: GlowTheme.colors.primary),
        ),
      ),
    );
  }
}

/// A themed dropdown for the Glow design system.
class GlowDropdown extends StatelessWidget {
  final String? value;
  final String? hintText;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const GlowDropdown({
    super.key,
    this.value,
    this.hintText,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: GlowTheme.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlowTheme.colors.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hintText ?? "Choose an option",
            style: TextStyle(color: GlowTheme.colors.onBackgroundTertiary),
          ),
          isExpanded: true,
          dropdownColor: GlowTheme.colors.surface,
          style: TextStyle(color: GlowTheme.colors.onBackground, fontSize: 16),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// A themed slider for the Glow design system.
class GlowSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;
  final String? leftLabel;
  final String? rightLabel;
  final IconData? leftIcon;
  final IconData? rightIcon;

  const GlowSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChanged,
    this.label,
    this.leftLabel,
    this.rightLabel,
    this.leftIcon,
    this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label != null)
          Text(
            label!,
            style: GlowTheme.textStyles.titleLarge.copyWith(
              color: GlowTheme.colors.primary,
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (leftIcon != null)
              Icon(
                leftIcon,
                color: GlowTheme.colors.onBackgroundSecondary,
                size: 20,
              ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: GlowTheme.colors.primary,
                  inactiveTrackColor: GlowTheme.colors.outlineStrong,
                  thumbColor: GlowTheme.colors.onBackground,
                  overlayColor: GlowTheme.colors.surfacePrimaryLow,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
            if (rightIcon != null)
              Icon(
                rightIcon,
                color: GlowTheme.colors.onBackgroundSecondary,
                size: 20,
              ),
          ],
        ),
        if (leftLabel != null || rightLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (leftLabel != null)
                  Text(
                    leftLabel!,
                    style: TextStyle(
                      color: GlowTheme.colors.onBackgroundTertiary,
                    ),
                  ),
                if (rightLabel != null)
                  Text(
                    rightLabel!,
                    style: TextStyle(
                      color: GlowTheme.colors.onBackgroundTertiary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A themed toggle/switch for the Glow design system.
class GlowToggle extends StatelessWidget {
  final bool value;
  final String title;
  final ValueChanged<bool>? onChanged;

  const GlowToggle({
    super.key,
    required this.value,
    required this.title,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GlowTheme.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(color: GlowTheme.colors.onBackground),
        ),
        value: value,
        activeThumbColor: GlowTheme.colors.primary,
        contentPadding: const EdgeInsets.all(16),
        onChanged: onChanged,
      ),
    );
  }
}
