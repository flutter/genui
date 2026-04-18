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
import 'package:glow/widgets/branding/glow_logo.dart';
import 'package:glow/widgets/backgrounds/glow_background.dart';
import 'package:glow/widgets/buttons/glow_button.dart';
import 'package:glow/widgets/cards/glow_cards.dart';
import 'package:glow/view_models/settings_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

class GlowWelcomeScreen extends StatelessWidget {
  const GlowWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsViewModel.instance,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              // 1. Background with Wavy Lines
              const Positioned.fill(child: GlowBackground()),

              // 2. Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return const _TabletLayout();
                    } else {
                      return const _MobileLayout();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Logo Section
                const GlowLogo(),
                const SizedBox(height: 20),

                // Subtitle
                Text(
                  l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: GlowTheme.textStyles.lightTitleLarge.copyWith(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 40),

                // Description Text
                Text(
                  l10n.welcomeDescription,
                  textAlign: TextAlign.center,
                  style: GlowTheme.textStyles.lightBodyMedium,
                ),

                const SizedBox(height: 40),

                // Features Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlowFeatureItem(
                      icon: Icons.psychology_outlined,
                      label: l10n.personalityQuiz,
                      gradientColors: [
                        GlowTheme.colors.brandPurple,
                        GlowTheme.colors.brandOrange,
                      ],
                    ),
                    GlowFeatureItem(
                      icon: Icons.brush_outlined,
                      label: l10n.aiGeneration,
                      gradientColors: [
                        GlowTheme.colors.brandBlue,
                        GlowTheme.colors.brandPurple,
                      ],
                    ),
                    GlowFeatureItem(
                      icon: Icons.sync,
                      label: l10n.iterativeRefinement,
                      gradientColors: [
                        GlowTheme.colors.brandBlueMaterial,
                        GlowTheme.colors.brandCyan,
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Gradient Button
                GlowButton(
                  text: l10n.getStarted,
                  onTap: () => _handleGetStarted(context),
                ),
                if (SettingsViewModel.instance.hasApiKey) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _showApiKeyDialog(context),
                    child: Text(
                      l10n.changeApiKey,
                      style: TextStyle(
                        color: GlowTheme.colors.brandPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),

                // Footer
                Text(
                  l10n.poweredBy,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlowTheme.colors.outlineVariant,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        child: Row(
          children: [
            // Left Side: Branding
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GlowLogo(isTablet: true),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeSubtitle,
                    style: GlowTheme.textStyles.lightTitleLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.poweredBy,
                    style: TextStyle(
                      fontSize: 14,
                      color: GlowTheme.colors.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 60),
            // Right Side: Content & Actions
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.welcomeDescription,
                    style: GlowTheme.textStyles.lightBodyLarge,
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlowFeatureItem(
                        icon: Icons.psychology_outlined,
                        label: l10n.personalityQuiz,
                        gradientColors: [
                          GlowTheme.colors.brandPurple,
                          GlowTheme.colors.brandOrange,
                        ],
                      ),
                      GlowFeatureItem(
                        icon: Icons.brush_outlined,
                        label: l10n.aiGeneration,
                        gradientColors: [
                          GlowTheme.colors.brandBlue,
                          GlowTheme.colors.brandPurple,
                        ],
                      ),
                      GlowFeatureItem(
                        icon: Icons.sync,
                        label: l10n.iterativeRefinement,
                        gradientColors: [
                          GlowTheme.colors.brandBlueMaterial,
                          GlowTheme.colors.brandCyan,
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 300,
                    child: GlowButton(
                      text: l10n.getStarted,
                      onTap: () => _handleGetStarted(context),
                    ),
                  ),
                  if (SettingsViewModel.instance.hasApiKey) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _showApiKeyDialog(context),
                      child: Text(
                        l10n.changeApiKey,
                        style: TextStyle(
                          color: GlowTheme.colors.brandPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _handleGetStarted(BuildContext context) {
  if (SettingsViewModel.instance.hasApiKey) {
    context.go('/quiz');
  } else {
    _showApiKeyDialog(context);
  }
}

void _showApiKeyDialog(BuildContext context) {
  final controller = TextEditingController(
    text: SettingsViewModel.instance.apiKey,
  );
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.apiKeyDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.apiKeyDialogDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                const url = "https://aistudio.google.com/app/apikey";
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
              child: Text(
                l10n.getApiKeyHere,
                style: TextStyle(
                  color: GlowTheme.colors.brandBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.apiKeyLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await SettingsViewModel.instance.setApiKey(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      );
    },
  );
}
