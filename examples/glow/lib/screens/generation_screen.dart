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
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/scheduler.dart';
import 'package:glow/theme.dart';
import 'package:glow/widgets/branding/glow_logo.dart';
import 'package:glow/widgets/feedback/glow_progress_bar.dart';
import 'package:glow/widgets/backgrounds/glow_shaders.dart';
import 'package:glow/services/gemini_service.dart';
import 'package:glow/utils/prompt_helper.dart';
import 'package:glow/view_models/settings_view_model.dart';
import 'package:glow/view_models/editor_view_model.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';

class GlowGenerationScreen extends StatefulWidget {
  final void Function(BuildContext context, double progress)? onProgressUpdate;
  final Map<String, dynamic>? answers;

  const GlowGenerationScreen({super.key, this.onProgressUpdate, this.answers});

  @override
  State<GlowGenerationScreen> createState() => _GlowGenerationScreenState();
}

class _GlowGenerationScreenState extends State<GlowGenerationScreen>
    with TickerProviderStateMixin {
  // Animation controller for the progress bar
  late final AnimationController _progressController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60), // Slow breathing animation
  );

  // Ticker to drive the shader time uniform
  late final Ticker _ticker;
  double _time = 0.0;

  // Store the compiled shader programs
  ui.FragmentProgram? _orbShaderProgram;
  ui.FragmentProgram? _meshShaderProgram;

  Uint8List? _generatedImage;
  // ignore: unused_field
  bool _isGenerating = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadShader();

    // Start a repeating "breathing" animation for loading
    _progressController.repeat(reverse: true);

    // Start a ticker that updates time for the shader
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _time = elapsed.inMilliseconds / 1000.0;
        });
      }
    });
    _ticker.start();

    _startGeneration();
  }

  Future<void> _startGeneration() async {
    if (widget.answers == null) return;

    setState(() => _isGenerating = true);

    try {
      final apiKey = SettingsViewModel.instance.apiKey;
      final service = GeminiService(apiKey: apiKey);
      final prompt = PromptHelper.fromQuizAnswers(widget.answers!);

      final image = await service.generateImage(prompt);

      if (mounted) {
        setState(() {
          _generatedImage = image;
          _isGenerating = false;
        });

        // Stop repeating and animate to full
        _progressController.stop();
        _progressController
            .animateTo(1.0, duration: const Duration(milliseconds: 500))
            .then((_) {
              _checkCompletion();
            });
      }
    } catch (e) {
      debugPrint("Generation Error: $e");
      if (mounted) {
        setState(() => _isGenerating = false);
        // Fallback or error handling could go here
        context.go('/editor');
      }
    }
  }

  void _checkCompletion() {
    if (_generatedImage != null && !_isNavigating) {
      _isNavigating = true;
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted) {
          // Set the image in the global view model
          EditorViewModel.instance.setImage(_generatedImage);
          // Initialize dynamic controls
          if (widget.answers != null) {
            final prompt = PromptHelper.fromQuizAnswers(widget.answers!);
            await EditorViewModel.instance.initialize(prompt);
          }
          if (mounted) {
            context.go('/editor');
          }
        }
      });
    }
  }

  Future<void> _loadShader() async {
    try {
      final orbProgram = await ui.FragmentProgram.fromAsset(
        'shaders/orb_shader.frag',
      );
      final meshProgram = await ui.FragmentProgram.fromAsset(
        'shaders/mesh_gradient.frag',
      );
      setState(() {
        _orbShaderProgram = orbProgram;
        _meshShaderProgram = meshProgram;
      });
    } catch (e) {
      debugPrint('Error loading shader: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background
          if (_meshShaderProgram != null)
            Positioned.fill(
              child: CustomPaint(
                painter: MeshGradientPainter(
                  shaderProgram: _meshShaderProgram!,
                  time: _time,
                  colors: [
                    GlowTheme.colors.brandBlue,
                    GlowTheme.colors.brandPurple,
                    GlowTheme.colors.brandOrange,
                    GlowTheme.colors.brandCyan,
                  ],
                ),
              ),
            ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const GlowLogoText(),

                    const Spacer(flex: 2),

                    // 2. SHADER ORB REPLACES IMAGE
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 100,
                          minHeight: 100,
                          maxWidth: 250,
                          maxHeight: 250,
                        ),
                        child: SizedBox.expand(
                          child: _orbShaderProgram == null
                              ? const Center(child: CircularProgressIndicator())
                              : CustomPaint(
                                  painter: OrbShaderPainter(
                                    shaderProgram: _orbShaderProgram!,
                                    time: _time,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // 3. Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.generatingGlow,
                                textAlign: TextAlign.center,
                                style: GlowTheme.textStyles.titleLarge.copyWith(
                                  shadows: GlowTheme.shadows.textGlow,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.generationDescription,
                                textAlign: TextAlign.center,
                                style: GlowTheme.textStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // 4. Progress Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 50),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: GlowProgressBar(
                            controller: _progressController,
                            colors: [
                              GlowTheme.colors.tertiary,
                              GlowTheme.colors.secondary,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
