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
import 'package:glow/view_models/quiz_view_model.dart';
import 'package:glow/widgets/feedback/glow_progress_bar.dart';
import 'package:glow/genui/quiz_catalog.dart';
import 'package:genui/genui.dart';

import '../l10n/app_localizations.dart';

// --- Main Screen ---

class GlowQuizScreen extends StatefulWidget {
  const GlowQuizScreen({super.key});

  @override
  State<GlowQuizScreen> createState() => _GlowQuizScreenState();
}

class _GlowQuizScreenState extends State<GlowQuizScreen>
    with SingleTickerProviderStateMixin {
  late final QuizViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // We pass an empty list now as the VM handles everything dynamically
    _viewModel = QuizViewModel(questions: []);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Scroll to the absolute maximum extent to show new content at the bottom
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final double progress = _viewModel.progress;

        // Auto-scroll trigger: If we just finished generating a new question
        if (!_viewModel.isGenerating && _viewModel.currentSurfaceId != null) {
          _scrollToBottom();
        }

        // Auto-navigation when finished
        if (_viewModel.isFinished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (GoRouter.of(
                  context,
                ).routerDelegate.currentConfiguration.fullPath ==
                '/quiz') {
              context.go('/generation', extra: _viewModel.answers);
            }
          });
        }

        return Scaffold(
          backgroundColor: GlowTheme.colors.background,
          appBar: AppBar(
            backgroundColor: GlowTheme.colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              AppLocalizations.of(context)!.quizTitle,
              style: GlowTheme.textStyles.bodyMedium.copyWith(
                color: GlowTheme.colors.onBackground,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: GlowTheme.colors.onBackground,
              ),
              onPressed: () => context.go('/'),
            ),
          ),
          body: Column(
            children: [
              // Custom Gradient Progress Bar
              GlowProgressBar(progress: progress),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.questionCount(_viewModel.currentIndex + 1, 10),
                            style: TextStyle(
                              color: GlowTheme.colors.onBackgroundTertiary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // DYNAMIC BODY GENERATOR
                          // If generating or no surface yet, show spinner.
                          if (_viewModel.isGenerating ||
                              _viewModel.currentSurfaceId == null)
                            const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            // We need to wrap this in the HandlerScope so the deep widget can find it.
                            QuizAnswerHandlerScope(
                              handler: _QuizBinding(_viewModel),
                              child: GenUiSurface(
                                surfaceId: _viewModel.currentSurfaceId!,
                                host: _viewModel.genUiService.conversation.host,
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Footer Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // NEXT Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: GlowTheme.gradients.glassButton,
                            border: Border.all(color: GlowTheme.colors.outline),
                          ),
                          child: ElevatedButton(
                            onPressed: _viewModel.isGenerating
                                ? null
                                : () => _viewModel.nextQuestion(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlowTheme.colors.transparent,
                              shadowColor: GlowTheme.colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _viewModel.isGenerating
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.next,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: GlowTheme.colors.onBackground,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SKIP TO GENERATION Button (Secondary)
                        TextButton(
                          onPressed: _viewModel.isGenerating
                              ? null
                              : () => _viewModel.skipToGeneration(),
                          child: Text(
                            AppLocalizations.of(context)!.skipToGeneration,
                            style: TextStyle(
                              color: GlowTheme.colors.onBackgroundTertiary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _QuizBinding implements QuizAnswerHandler {
  final QuizViewModel vm;
  _QuizBinding(this.vm);

  @override
  void apiSetAnswer(String qId, dynamic value) {
    vm.apiSetAnswer(qId, value);
  }

  @override
  dynamic getAnswer(String qId) {
    return vm.getAnswer(qId);
  }

  @override
  bool isSelected(String qId, String optId) {
    return vm.isSelected(qId, optId);
  }
}
