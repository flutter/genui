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
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';
import 'package:glow/genui/quiz_catalog.dart';
import 'package:glow/models/quiz_question.dart';
import 'package:glow/services/genui_service.dart';
import 'package:glow/view_models/settings_view_model.dart';

class QuizViewModel extends ChangeNotifier {
  final List<QuizQuestion> questions;
  final Logger _log = Logger('QuizViewModel');

  int _currentIndex = 0;
  final Map<String, dynamic> _answers = {};

  // GenUI State
  late final GenUiService _genUiService;
  GenUiService get genUiService => _genUiService;

  // Track the most recent surface for the current step
  String? _latestSurfaceId;
  String? _currentRootId;
  bool _isGenerating = false;

  // System Instruction
  static const _systemInstruction = '''
  You are an expert AI Digital Artist & Wallpaper Curator for 'Glow'.
  Your goal is to create a stunning, personalized DIGITAL WALLPAPER (for a phone or desktop screen) based on the user's taste.
  
  CONTEXT:
  - This is NOT about home decor or physical wall paper.
  - This IS about digital art, abstract backgrounds, landscapes, or artistic scenes for a SCREEN.
  
  STRATEGY:
  - Start with MOOD and VIBE (e.g., "Dreamy & Ethereal", "Cyberpunk", "Minimalist Nature").
  - Ask about ARTISTIC STYLE relative to digital art (e.g., "3D Render", "Oil Painting", "Vector Art", "Neon").
  - Ask about specific ELEMENTS (e.g., "Clouds", "Geometric shapes", "Gradient").
  - You can ask up to 10 questions.
  
  RULES:
  RULES:
  1. Ask EXACTLY ONE question at a time using the 'QuizQuestion' tool.
  2. STOP and WAIT for the user to answer. DO NOT simulate the user's answer.
  3. DO NOT generate multiple questions in a sequence.
  4. NEVER ask questions in plain text. ALWAYS use the 'QuizQuestion' tool.
  5. If the user asks to "Skip" or says they are done, output "SUMMARY: " followed by the final prompt.
  6. After the 10th question is answered, output "SUMMARY: " followed by the final prompt.
  
  CRITICAL:
  - You MUST wait for the user's response after every question.
  - Do NOT advance the conversation yourself.
  
  Action: Ask Question 1 using the QuizQuestion tool.
  ''';

  QuizViewModel({required List<QuizQuestion> questions}) : questions = [] {
    _log.info('Initialized Step-by-Step Dynamic Quiz');
    _initGenUi();
  }

  // Completion State
  bool _isFinished = false;
  bool get isFinished => _isFinished;
  String? _summaryPrompt;
  String? get summaryPrompt => _summaryPrompt;

  void _initGenUi() {
    final apiKey = SettingsViewModel.instance.apiKey;
    _genUiService = GenUiService(
      apiKey: apiKey,
      systemInstruction: _systemInstruction,
      additionalItems: quizCatalogItems,
      onSurfaceAdded: (surface) {
        final rootId = surface.definition.rootComponentId;
        _log.info('Surface Added: ${surface.surfaceId} Root: $rootId');
        _latestSurfaceId = surface.surfaceId;
        _currentRootId = rootId;
        _isGenerating = false;
        notifyListeners();
      },
      onSurfaceUpdated: (update) {
        _log.info('Surface Updated: ${update.surfaceId}');
        if (_isGenerating) {
          // Check if root has changed to prevent flashing old content
          final definition = update.definition;
          final rootId = definition.rootComponentId;

          if (rootId != null && rootId != _currentRootId) {
            _log.info('Root Changed: $_currentRootId -> $rootId');
            _currentRootId = rootId;
            _latestSurfaceId = update.surfaceId;
            _isGenerating = false;
            notifyListeners();
          } else {
            _log.info(
              'Surface updated but root is same ($_currentRootId). Keeping spinner...',
            );
          }
        }
      },
      onTextResponse: (text) {
        _log.info('Text Response: $text');

        if (text.contains("SUMMARY:")) {
          _summaryPrompt = text.split("SUMMARY:").last.trim();
          _answers['prompt'] = _summaryPrompt;
          _isFinished = true;
          _isGenerating = false;
          _log.info('Quiz Finished. Summary: $_summaryPrompt');
          notifyListeners();
        } else if (_isGenerating) {
          _log.warning('Model returned text but we expected a tool call (UI).');
          // Auto-recover by asking for the tool
          _genUiService.sendRequest(
            UserMessage.text(
              "Please display the question using the 'QuizQuestion' tool. Do not just say it.",
            ),
          );
        }
      },
    );

    // Start the conversation
    _isGenerating = true;
    _genUiService.sendRequest(
      UserMessage.text(
        "Hi! Let's start the wallpaper personalization quiz. Please ask the first question.",
      ),
    );
  }

  // Current State
  int get currentIndex => _currentIndex;

  double get progress {
    if (_isFinished) return 1.0;
    // 0..9 -> 10 questions.
    return (_currentIndex + 1) / 10.0;
  }

  Map<String, dynamic> get answers => _answers;

  // Surface Logic
  QuizQuestion? get currentStaticQuestion => null; // No static questions
  bool get isDynamic => true;

  String? get currentSurfaceId => _latestSurfaceId;
  bool get isGenerating => _isGenerating;

  @override
  void dispose() {
    _genUiService.dispose();
    super.dispose();
  }

  Future<void> nextQuestion() async {
    _log.info('nextQuestion called. Stack: ${StackTrace.current}');
    // 1. Mark as generating (UI shows spinner)
    _isGenerating = true;
    notifyListeners();

    // 2. Prepare context
    final currentAnswers = _answers.toString();
    _log.info('Submitting answer for Q${_currentIndex + 1}...');

    // 3. Send request
    _genUiService.sendRequest(
      UserMessage.text(
        "I have answered. Current State: $currentAnswers. Please save this and ASK THE NEXT QUESTION (Question ${_currentIndex + 2}).",
      ),
    );

    // 4. Advance index logic
    // We increment index to show progress, but we wait for `isGenerating` to flip back to false before showing surface.
    _currentIndex++;
    notifyListeners();
  }

  Future<void> skipToGeneration() async {
    _isGenerating = true;
    notifyListeners();

    _log.info('User requested Skip/Finish.');
    final currentAnswers = _answers.toString();

    _genUiService.sendRequest(
      UserMessage.text(
        "I am satisfied with my answers so far: $currentAnswers. Please STOP asking questions and generate the SUMMARY now.",
      ),
    );
  }

  // Helpers
  void setAnswer(String questionId, dynamic value) {
    _answers[questionId] = value;
    notifyListeners();
  }

  // Support for dynamic widgets calling back
  void apiSetAnswer(String qId, dynamic value) {
    setAnswer(qId, value);
  }

  dynamic getAnswer(String qId) => _answers[qId];

  bool isSelected(String qId, String optId) {
    final ans = _answers[qId];
    if (ans is List) {
      return ans.contains(optId);
    }
    return ans == optId;
  }

  void handleSelection(QuizQuestion q, String optId) {
    if (q.type == QuestionType.multipleChoiceImage ||
        q.type == QuestionType.multipleChoiceText) {
      List<String> current = List.from(_answers[q.id] ?? []);
      if (current.contains(optId)) {
        current.remove(optId);
      } else {
        current.add(optId);
      }
      setAnswer(q.id, current);
    } else {
      setAnswer(q.id, optId);
    }
  }
}
